# Bump Flutter App — Master Fix & Improvement Prompt

> **Context:** You are a senior Flutter/Dart engineer. Below is a complete QA audit of the Bump app (a networking/contact-exchange Flutter app using Supabase + Riverpod + GoRouter). Your job is to systematically fix every issue, implement every improvement, and bring this app to production-ready quality. Work through each section in order. Do not skip any item. Preserve existing functionality while fixing bugs. Run `flutter analyze` and `flutter test` after each major section to catch regressions.

---

## TABLE OF CONTENTS

1. [CRITICAL BUG FIXES (P0)](#1-critical-bug-fixes-p0)
2. [HIGH SEVERITY BUG FIXES (P1)](#2-high-severity-bug-fixes-p1)
3. [MEDIUM SEVERITY BUG FIXES (P2)](#3-medium-severity-bug-fixes-p2)
4. [LOW SEVERITY BUG FIXES (P3)](#4-low-severity-bug-fixes-p3)
5. [SECURITY HARDENING](#5-security-hardening)
6. [PERFORMANCE OPTIMIZATION](#6-performance-optimization)
7. [ACCESSIBILITY AUDIT IMPLEMENTATION](#7-accessibility-audit-implementation)
8. [UX IMPROVEMENT SUGGESTIONS](#8-ux-improvement-suggestions)
9. [MISSED EDGE CASES](#9-missed-edge-cases)
10. [RELEASE READINESS CHECKLIST](#10-release-readiness-checklist)

---

## 1. CRITICAL BUG FIXES (P0)

These are crash-causing or data-corrupting issues. Fix ALL of these first before moving to any other section.

### BUG-001: Remove hardcoded Supabase anon key from source

**File:** `lib/core/config/supabase_config.dart`

**Problem:** The Supabase URL and anon key are stored as static const with hardcoded JWT default values. Anyone who decompiles the APK can extract these credentials.

**Fix:**
- Remove the hardcoded default JWT values entirely from the `String.fromEnvironment()` calls
- Make the app fail fast at startup if environment variables are not set
- Add a `.env` file approach using `flutter_dotenv` package, OR require `--dart-define` flags at build time
- Add `supabase_config.dart` to `.gitignore` if it contains real keys
- Create a `supabase_config.example.dart` with placeholder values for developers
- Update the build scripts / CI to inject real values

```
Expected pattern:
static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

// Add startup validation in main.dart:
if (SupabaseConfig.supabaseUrl.isEmpty || SupabaseConfig.supabaseAnonKey.isEmpty) {
  throw StateError('Supabase credentials not configured. Use --dart-define.');
}
```

---

### BUG-002: Fix force-unwrap `currentUser!.id` crash on expired sessions

**Files:** ALL files in `lib/data/repositories_impl/` — specifically:
- `supabase_prospect_repository.dart`
- `supabase_event_repository.dart`
- `supabase_nudge_repository.dart`
- `supabase_profile_repository.dart`
- `supabase_template_repository.dart`
- `supabase_device_repository.dart`

**Problem:** Every repository method accesses `_client.auth.currentUser!.id` with a force unwrap. If the session expires or is null, this throws a null check exception and crashes the app.

**Fix:**
- Create a helper method/mixin that all repositories use:
```dart
mixin AuthenticatedRepository {
  SupabaseClient get client;

  String get currentUserId {
    final user = client.auth.currentUser;
    if (user == null) {
      throw AuthException('Session expired. Please sign in again.');
    }
    return user.id;
  }
}
```
- Apply this mixin to all `Supabase*Repository` classes
- Replace every `_client.auth.currentUser!.id` with `currentUserId`
- In the providers, catch `AuthException` specifically and trigger navigation to `/auth`
- Add a global `onAuthStateChange` listener in `main.dart` that redirects to `/auth` on `signedOut` or `tokenRefreshFailed` events

---

### BUG-003: Fix race condition in event activation (no DB transaction)

**File:** `lib/data/repositories_impl/supabase_event_repository.dart`

**Problem:** `setActiveEvent()` uses two separate UPDATE queries (deactivate all, then activate one). Concurrent calls can leave multiple events active or none active.

**Fix:**
- Create a Supabase Edge Function / RPC that performs both operations in a single database transaction:
```sql
CREATE OR REPLACE FUNCTION set_active_event(p_user_id UUID, p_event_id UUID)
RETURNS VOID AS $$
BEGIN
  UPDATE events SET is_active = false WHERE user_id = p_user_id AND is_active = true;
  UPDATE events SET is_active = true WHERE id = p_event_id AND user_id = p_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```
- Update the repository to call this RPC instead of two separate queries
- Add a unique partial index on the DB: `CREATE UNIQUE INDEX one_active_event_per_user ON events (user_id) WHERE is_active = true;`

---

### BUG-004: Fix unsafe type casts on Supabase RPC/query responses

**Files:** ALL `lib/data/repositories_impl/supabase_*.dart`

**Problem:** Every repository uses `response as List` or `response as Map<String, dynamic>` without null/type checking. If Supabase returns an unexpected type (null, empty, wrong type), the app crashes.

**Specific locations to fix:**
- `supabase_prospect_repository.dart` lines 33, 105: `(response as List)`
- `supabase_event_repository.dart` line 25: `(response as List)`
- `supabase_exchange_repository.dart` lines 24, 38, 41: `response as Map` and `response.first`
- `supabase_nudge_repository.dart` line 30: `(response as List)`
- `supabase_template_repository.dart` line 26: `(response as List)`

**Fix:**
- Create a safe cast utility:
```dart
List<Map<String, dynamic>> safeListCast(dynamic response) {
  if (response == null) return [];
  if (response is! List) throw FormatException('Expected List, got ${response.runtimeType}');
  return response.cast<Map<String, dynamic>>();
}

Map<String, dynamic> safeMapCast(dynamic response) {
  if (response == null) throw FormatException('Response was null');
  if (response is! Map) throw FormatException('Expected Map, got ${response.runtimeType}');
  return Map<String, dynamic>.from(response);
}
```
- Replace all unsafe casts with these safe utilities
- In `supabase_exchange_repository.dart`, guard `.first` access:
```dart
if (response is List && response.isNotEmpty) {
  return Map<String, dynamic>.from(response.first);
}
throw FormatException('Empty or invalid exchange response');
```

---

### BUG-005: Fix concurrent provider mutation race conditions

**Files:** `lib/providers/prospects_provider.dart`, `lib/providers/events_provider.dart`, `lib/providers/nudges_provider.dart`

**Problem:** Optimistic updates read stale `.valueOrNull` snapshots. Two concurrent mutations can overwrite each other because both read the same initial state.

Example: state=[A,B], concurrent call1 adds C=[C,A,B], call2 also reads [A,B] adds D=[D,A,B], overwriting C.

**Fix:**
- Add an `AsyncMutex` utility class:
```dart
class AsyncMutex {
  Completer<void>? _completer;

  Future<T> protect<T>(Future<T> Function() fn) async {
    while (_completer != null) {
      await _completer!.future;
    }
    _completer = Completer<void>();
    try {
      return await fn();
    } finally {
      _completer!.complete();
      _completer = null;
    }
  }
}
```
- Add a `_mutex` instance to each `AsyncNotifier` that performs optimistic updates
- Wrap all state-mutating methods (`addProspect`, `updateProspect`, `deleteProspect`, `updateProspectStatus`, `createEvent`, `updateEvent`, `deleteEvent`, `setActiveEvent`, `sendNudge`) inside `_mutex.protect(() async { ... })`
- Read `state.valueOrNull` INSIDE the mutex to get the latest snapshot

---

### BUG-006: Fix Toast widget memory leak and double-removal crash

**File:** `lib/widgets/toast.dart`

**Problem:** Static `_currentEntry` causes race between removal and insertion. Timer never cancelled on dispose. Double `entry.remove()` throws.

**Fix:**
- Replace the static OverlayEntry pattern with `ScaffoldMessenger` (the standard Flutter approach):
```dart
class BumpToast {
  static void show(BuildContext context, {
    required String message,
    ToastType type = ToastType.success,
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Row(children: [
          Icon(_iconForType(type), color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(message, maxLines: 2, overflow: TextOverflow.ellipsis)),
        ]),
        backgroundColor: _colorForType(type),
        behavior: SnackBarBehavior.floating,
        duration: duration,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ));
  }
}
```
- This eliminates the memory leak, handles queue management, and integrates with TalkBack accessibility

---

### BUG-007: Add CAMERA permission to AndroidManifest

**File:** `android/app/src/main/AndroidManifest.xml`

**Problem:** QR scanner uses the camera but CAMERA permission is not declared. App will crash on fresh installs.

**Fix:** Add these permissions to the manifest (before `<application>` tag):
```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-feature android:name="android.hardware.camera" android:required="false" />
```

Also add runtime permission request in `qr_scanner_screen.dart` before initializing scanner:
- Add `permission_handler` package to `pubspec.yaml`
- Check and request camera permission before showing scanner
- Show explanation dialog if permission denied
- Show settings redirect if permission permanently denied

---

### BUG-008: Add POST_NOTIFICATIONS permission for Android 13+

**File:** `android/app/src/main/AndroidManifest.xml`

**Problem:** FCM notifications silently fail on Android 13+ because POST_NOTIFICATIONS permission is not declared.

**Fix:**
```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
```

Update `lib/services/notification_service.dart` to request runtime permission:
```dart
if (Platform.isAndroid) {
  final status = await Permission.notification.request();
  if (!status.isGranted) {
    debugPrint('Notification permission denied');
    return;
  }
}
```

---

### BUG-009: Fix StatusBadge crash on empty/short status strings

**File:** `lib/widgets/status_badge.dart`

**Problem:** `status[0].toUpperCase() + status.substring(1).toLowerCase()` crashes on empty strings (RangeError) and may misbehave on single-character strings.

**Fix:**
```dart
String _capitalize(String s) {
  if (s.isEmpty) return 'Unknown';
  if (s.length == 1) return s.toUpperCase();
  return s[0].toUpperCase() + s.substring(1).toLowerCase();
}
```
- Apply this safe capitalization throughout the widget
- Also add a default status fallback in the Prospect model `fromJson`:
```dart
status: ProspectStatus.fromString(json['status'] as String? ?? 'new'),
```

---

## 2. HIGH SEVERITY BUG FIXES (P1)

Fix these after all Critical issues are resolved.

### BUG-010: Add email format validation

**Files:** `lib/screens/auth_screen.dart`, `lib/screens/profile_setup_screen.dart`, `lib/screens/edit_profile_screen.dart`

**Fix:**
- Create a `validators.dart` utility file in `lib/core/`:
```dart
class Validators {
  static final _emailRegex = RegExp(r'^[\w.-]+@[\w.-]+\.[a-zA-Z]{2,}$');
  static final _phoneRegex = RegExp(r'^\+?[\d\s()-]{7,20}$');
  static final _urlRegex = RegExp(r'^https?://[\w.-]+(\.[\w.-]+)+[/\w .-]*$');

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    if (!_emailRegex.hasMatch(value.trim())) return 'Enter a valid email address';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) return null; // Optional field
    if (!_phoneRegex.hasMatch(value.trim())) return 'Enter a valid phone number';
    return null;
  }

  static String? url(String? value) {
    if (value == null || value.trim().isEmpty) return null; // Optional field
    final withScheme = value.startsWith('http') ? value : 'https://$value';
    if (!_urlRegex.hasMatch(withScheme)) return 'Enter a valid URL';
    return null;
  }

  static String? required(String? value, [String fieldName = 'This field']) {
    if (value == null || value.trim().isEmpty) return '$fieldName is required';
    return null;
  }
}
```
- Apply `Validators.email()` to all email TextFormFields
- Use `Form` widget with `GlobalKey<FormState>` for validation on submit
- Show inline error messages below fields

---

### BUG-011: Add password strength + confirmation on signup

**File:** `lib/screens/auth_screen.dart`

**Fix:**
- Add a `_confirmPasswordController` TextEditingController
- Add confirm password field below password field (only visible in signup mode)
- Add validation:
  - Minimum 6 characters
  - Passwords match
- Add visual password strength indicator (optional but recommended)
- Validate before calling Supabase auth

---

### BUG-012: Fix CSV export PII security and escaping

**File:** `lib/services/export_service.dart`

**Fix:**
- Use `getApplicationDocumentsDirectory()` (app-private) instead of temp directory
- Add proper CSV escaping for fields containing commas, quotes, or newlines:
```dart
String _escapeCsv(String value) {
  if (value.contains(',') || value.contains('"') || value.contains('\n')) {
    return '"${value.replaceAll('"', '""')}"';
  }
  return value;
}
```
- Add null checks for all prospect fields before formatting
- Delete the file after sharing (in a post-share callback, not `finally`)
- Add a try-catch around file write with user-facing error message
- Check available disk space before write

---

### BUG-013: Add empty message validation for nudge

**File:** `lib/screens/nudge_sheet.dart`

**Fix:**
- Add a `ValueListenableBuilder` or `onChanged` to message controller that enables/disables the send button
- Disable send button when `_messageController.text.trim().isEmpty`
- Show validation text below field: "Message cannot be empty"
- Also add character limit indicator showing `{current}/{max}` and enforce SMS limit warning (160 chars)

---

### BUG-014: Add phone number validation before call/WhatsApp

**Files:** `lib/screens/prospect_detail_screen.dart`, `lib/screens/nudge_sheet.dart`

**Fix:**
- Before launching WhatsApp/call URL, validate phone format using `Validators.phone()`
- Normalize phone to E.164 format before WhatsApp deep link:
```dart
String normalizePhone(String phone) {
  return phone.replaceAll(RegExp(r'[\s()\-]'), '');
}
```
- Show error toast if phone is invalid: "Invalid phone number format"
- Wrap ALL `url_launcher` calls in try-catch with user-facing error:
```dart
try {
  final uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } else {
    BumpToast.show(context, message: 'Could not open $appName', type: ToastType.error);
  }
} catch (e) {
  BumpToast.show(context, message: 'Failed to open $appName', type: ToastType.error);
}
```

---

### BUG-015: Fix non-functional settings menu items

**File:** `lib/screens/profile_screen.dart`

**Fix:** For each settings item, either:
1. **Implement the screen** (Edit Profile, Notifications, Privacy, Help, About), OR
2. **Show "Coming Soon" dialog** for unimplemented items:
```dart
onTap: () => BumpToast.show(context, message: 'Coming soon!', type: ToastType.info),
```
3. **Remove items entirely** if not planned for this release

At minimum:
- "Edit Profile" → Navigate to `EditProfileScreen` (already exists at `edit_profile_screen.dart`)
- "About" → Navigate to `AboutScreen` (already exists at `about_screen.dart`)
- "Privacy" → Navigate to `PrivacyPolicyScreen` (already exists)
- Others → Show "Coming Soon" toast

---

### BUG-016: Add basic offline caching layer

**Fix:**
- Add `hive_flutter` package to `pubspec.yaml`
- Create a `lib/core/cache/local_cache.dart`:
```dart
class LocalCache {
  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox('prospects');
    await Hive.openBox('events');
    await Hive.openBox('nudges');
    await Hive.openBox('profile');
  }

  static Future<void> cacheList<T>(String boxName, List<T> items, String Function(T) getId, Map<String, dynamic> Function(T) toJson) async {
    final box = Hive.box(boxName);
    await box.clear();
    for (final item in items) {
      await box.put(getId(item), jsonEncode(toJson(item)));
    }
  }

  static List<T> getCached<T>(String boxName, T Function(Map<String, dynamic>) fromJson) {
    final box = Hive.box(boxName);
    return box.values.map((v) => fromJson(jsonDecode(v as String))).toList();
  }
}
```
- Update each repository to: (a) cache data after successful fetch, (b) return cached data if network fails
- Add an offline banner widget that shows when `connectivity_plus` reports no connection
- Queue mutations (create/update/delete) when offline, sync when online

---

### BUG-017: Fix optimistic updates without rollback in prospects provider

**File:** `lib/providers/prospects_provider.dart`

**Problem:** `addProspect()` (lines 72-102) and `addQuickCaptureProspect()` (lines 104-149) have NO try-catch. If the server rejects, the optimistic state persists.

**Fix:**
- Wrap both methods in try-catch with state rollback:
```dart
Future<void> addProspect(Prospect prospect) async {
  final previous = state;
  state = AsyncData([prospect, ...state.valueOrNull ?? []]);
  try {
    final created = await ref.read(prospectsRepositoryProvider).createProspect(prospect);
    state = AsyncData([created, ...previous.valueOrNull ?? []]);
  } catch (e) {
    state = previous; // Rollback
    rethrow;
  }
}
```
- Apply same pattern to `addQuickCaptureProspect`

---

### BUG-018: Fix profile provider dual-pattern divergence

**File:** `lib/providers/profile_provider.dart`

**Problem:** `profileProvider` (FutureProvider) and `profileNotifierProvider` (AsyncNotifierProvider) are independent. Updating the notifier doesn't invalidate the FutureProvider. Screens reading from different providers see inconsistent data.

**Fix:**
- Remove `profileProvider` FutureProvider entirely
- Use `profileNotifierProvider` as the single source of truth
- Update all screens that consume `profileProvider` to use `profileNotifierProvider` instead
- In `ProfileNotifier.updateProfile()` and `uploadAvatar()`, ensure state is always updated

---

### BUG-019: Fix auth provider desynchronization after logout

**File:** `lib/providers/auth_provider.dart`

**Problem:** `authStateProvider` is StreamProvider (reactive), but `currentUserIdProvider` is sync Provider that reads `repo.currentUserId`. After logout, `currentUserIdProvider` may still return old UID.

**Fix:**
- Make `currentUserIdProvider` derive from `authStateProvider`:
```dart
final currentUserIdProvider = Provider<String?>((ref) {
  final isAuthenticated = ref.watch(authStateProvider).valueOrNull ?? false;
  if (!isAuthenticated) return null;
  return ref.read(supabaseClientProvider).auth.currentUser?.id;
});
```
- This ensures the userId is always in sync with auth state

---

### BUG-020: Add max length to all text input fields

**Files:** ALL screen files with TextFields

**Fix:** Add `maxLength` property to every TextField:

| Field | maxLength |
|-------|-----------|
| First Name | 50 |
| Last Name | 50 |
| Email | 255 |
| Phone | 20 |
| Company | 100 |
| Job Title | 100 |
| LinkedIn URL | 500 |
| Website URL | 500 |
| Username | 30 |
| Notes | 2000 |
| Nudge Message | 2000 |
| Event Name | 100 |
| Event Location | 200 |

Set `maxLengthEnforcement: MaxLengthEnforcement.enforced` on all.

---

### BUG-021: Add auth validation before getProfileByUsername RPC

**File:** `lib/data/repositories_impl/supabase_profile_repository.dart`

**Fix:**
- Add authentication check before calling the RPC:
```dart
Future<User?> getProfileByUsername(String username) async {
  final userId = currentUserId; // From AuthenticatedRepository mixin
  final response = await _client.rpc('get_profile_by_username', params: {'p_username': username});
  // ... rest of logic
}
```
- Also ensure the Supabase RPC function has `SECURITY DEFINER` with RLS checks

---

### BUG-022: Strip calculated fields from profile update payload

**File:** `lib/data/repositories_impl/supabase_profile_repository.dart`

**Problem:** `updateProfile` sends `user.toJson()` including server-calculated stats like `total_bumps`, `total_nudges`, `conversion_rate`.

**Fix:**
- Create a `toUpdateJson()` method on the User model that excludes calculated fields:
```dart
Map<String, dynamic> toUpdateJson() {
  final json = toJson();
  json.remove('total_bumps');
  json.remove('total_nudges');
  json.remove('total_events');
  json.remove('conversion_rate');
  json.remove('created_at');
  json.remove('updated_at');
  return json;
}
```
- Use `user.toUpdateJson()` instead of `user.toJson()` in the update call

---

### BUG-023: Fix FCM platform detection

**File:** `lib/services/notification_service.dart`

**Fix:**
```dart
import 'dart:io' show Platform;

// Replace hardcoded 'android' with:
'platform': Platform.isIOS ? 'ios' : 'android',
```

---

### BUG-024: Add Forgot Password flow

**Files:** `lib/screens/auth_screen.dart` (add link), create new `lib/screens/forgot_password_screen.dart`

**Fix:**
- Add "Forgot Password?" link below password field in auth screen
- Create `ForgotPasswordScreen` with:
  - Email input field with validation
  - Submit button that calls `Supabase.instance.client.auth.resetPasswordForEmail(email)`
  - Success state: "Check your email for reset instructions"
  - Error handling for invalid email, rate limiting
- Add route in `app_router.dart`: `/forgot-password`
- Add to `_publicRoutes` list

---

### BUG-025: Add session token expiry handling

**File:** `lib/main.dart`, `lib/providers/auth_provider.dart`

**Fix:**
- Add an `onAuthStateChange` listener in `main.dart` or the root widget:
```dart
Supabase.instance.client.auth.onAuthStateChange.listen((data) {
  if (data.event == AuthChangeEvent.signedOut ||
      data.event == AuthChangeEvent.tokenRefreshed && data.session == null) {
    // Clear all cached state
    // Navigate to /auth
    router.go('/auth');
  }
});
```
- Update `app_router.dart` redirect to also check token validity:
```dart
final session = supabase.auth.currentSession;
if (session == null || session.isExpired) {
  return isPublicRoute ? null : '/auth';
}
```

---

## 3. MEDIUM SEVERITY BUG FIXES (P2)

### BUG-026: Prevent duplicate QR scan exchanges

**File:** `lib/screens/qr_scanner_screen.dart`

**Fix:**
- Call `controller.stop()` immediately when barcode detected (before setting `_isProcessing = true`)
- Only call `controller.start()` after exchange completes or fails
- Add server-side idempotency: unique constraint on `(user_id, scanned_user_id, event_id)` within a time window

---

### BUG-027: Debounce notes field updates

**File:** `lib/screens/prospect_detail_screen.dart`

**Fix:**
- Add a debounce timer:
```dart
Timer? _notesDebounce;

void _onNotesChanged(String value) {
  _notesDebounce?.cancel();
  _notesDebounce = Timer(const Duration(milliseconds: 500), () {
    ref.read(prospectsProvider.notifier).updateProspect(
      prospect.copyWith(notes: value),
    );
  });
}

@override
void dispose() {
  _notesDebounce?.cancel();
  super.dispose();
}
```

---

### BUG-028: Implement deep link route handling in GoRouter

**File:** `lib/navigation/app_router.dart`

**Fix:**
- Add a top-level route for handling `bump://exchange/{userId}` deep links:
```dart
GoRoute(
  path: '/exchange/:userId',
  redirect: (context, state) {
    final userId = state.pathParameters['userId'];
    final eventId = state.uri.queryParameters['event'];
    if (userId == null || userId.isEmpty) return '/home';
    // Store deep link data and redirect to exchange handler
    return null;
  },
  builder: (context, state) => ExchangeHandlerScreen(
    userId: state.pathParameters['userId']!,
    eventId: state.uri.queryParameters['event'],
  ),
),
```

---

### BUG-029 & BUG-030: Fix non-functional Share Card and Notification bell

**File:** `lib/screens/home_screen.dart`

**Fix for Share Card:**
```dart
onTap: () async {
  final profile = ref.read(profileNotifierProvider).valueOrNull;
  if (profile == null) return;
  final link = 'bump://exchange/${profile.id}';
  await Share.share('Connect with me on Bump! $link');
},
```

**Fix for Notification bell:** Either implement a basic notifications screen or remove the icon for now:
```dart
// Option A: Remove
// Just remove the IconButton from the AppBar

// Option B: Coming Soon
onTap: () => BumpToast.show(context, message: 'Notifications coming soon!', type: ToastType.info),
```

---

### BUG-031: Fix non-functional Tag button

**File:** `lib/screens/event_detail_screen.dart`

**Fix:** Either implement tag management or remove the Tag chip:
```dart
// Remove from the action chips row, OR implement:
onTap: () => _showTagSelector(context, prospect),
```

---

### BUG-032: Fix getProspectCount to use COUNT query

**File:** `lib/data/repositories_impl/supabase_prospect_repository.dart`

**Fix:**
```dart
Future<int> getProspectCount({String? eventId}) async {
  var query = _client.from('prospects').select('id', const FetchOptions(count: CountOption.exact));
  if (eventId != null) query = query.eq('event_id', eventId);
  query = query.eq('user_id', currentUserId);
  final response = await query;
  return response.count ?? 0;
}
```

---

### BUG-033: Add pagination to all list queries

**Files:** ALL `lib/data/repositories/` interfaces and `lib/data/repositories_impl/` implementations

**Fix:**
- Add pagination parameters to all list-fetch methods:
```dart
// Interface
Future<List<Prospect>> getProspects({String? eventId, String? status, int limit = 50, int offset = 0});

// Implementation
Future<List<Prospect>> getProspects({String? eventId, String? status, int limit = 50, int offset = 0}) async {
  var query = _client.from('prospects').select().eq('user_id', currentUserId);
  if (eventId != null) query = query.eq('event_id', eventId);
  if (status != null) query = query.eq('status', status);
  final response = await query.order('exchange_time', ascending: false).range(offset, offset + limit - 1);
  return safeListCast(response).map((json) => Prospect.fromJson(json)).toList();
}
```
- Apply same pattern to events, nudges, templates
- Update providers to support infinite scroll loading

---

### BUG-034: Add image caching for avatars

**File:** `lib/widgets/avatar.dart`

**Fix:**
- Add `cached_network_image` package to `pubspec.yaml`
- Replace `Image.network()` with `CachedNetworkImage`:
```dart
CachedNetworkImage(
  imageUrl: avatarUrl!,
  placeholder: (context, url) => _buildInitials(),
  errorWidget: (context, url, error) => _buildInitials(),
  fit: BoxFit.cover,
  memCacheHeight: (size * 2).toInt(),
  memCacheWidth: (size * 2).toInt(),
)
```

---

### BUG-035: Add timeout/retry to splash screen profile fetch

**File:** `lib/screens/splash_screen.dart`

**Fix:**
```dart
Future<void> _checkAuthAndNavigate() async {
  try {
    final profile = await ref.read(profileNotifierProvider.future)
        .timeout(const Duration(seconds: 10));
    // Navigate based on profile state
  } on TimeoutException {
    if (!mounted) return;
    // Show retry dialog or navigate to auth as fallback
    _showRetryDialog();
  } catch (e) {
    if (!mounted) return;
    context.go('/auth');
  }
}
```

---

### BUG-036: Add URL validation for LinkedIn/Website

**Files:** `lib/screens/profile_setup_screen.dart`, `lib/screens/edit_profile_screen.dart`

**Fix:**
- Apply `Validators.url()` to LinkedIn and Website text fields
- Auto-prefix `https://` if user enters URL without scheme:
```dart
String normalizeUrl(String url) {
  if (url.isEmpty) return url;
  if (!url.startsWith('http://') && !url.startsWith('https://')) {
    return 'https://$url';
  }
  return url;
}
```

---

### BUG-037: Fix analytics flash of 0 during loading

**File:** `lib/screens/analytics_screen.dart`

**Fix:**
- Check if ANY upstream provider is still loading before rendering stats:
```dart
final prospectsAsync = ref.watch(prospectsProvider);
final eventsAsync = ref.watch(eventsProvider);
final nudgesAsync = ref.watch(nudgesProvider);

if (prospectsAsync.isLoading || eventsAsync.isLoading || nudgesAsync.isLoading) {
  return _buildSkeletonLoaders(); // Use existing SkeletonLoader widget
}
```

---

### BUG-038: Fix Google OAuth button UX

**File:** `lib/screens/auth_screen.dart`

**Fix:**
```dart
// Visually indicate it's unavailable:
Opacity(
  opacity: 0.5,
  child: AbsorbPointer(
    child: _buildOAuthButton(),
  ),
),
const SizedBox(height: 4),
Text('Coming soon', style: TextStyle(fontSize: 12, color: Colors.grey)),
```

---

### BUG-039 & BUG-040: Fix notification tap handler and foreground display

**File:** `lib/services/notification_service.dart`

**Fix for tap handler:**
```dart
void _handleMessageTap(RemoteMessage message) {
  final data = message.data;
  final type = data['type']; // e.g., 'prospect', 'event', 'nudge'
  final id = data['id'];

  if (type != null && id != null) {
    switch (type) {
      case 'prospect': _router.go('/prospects/$id'); break;
      case 'event': _router.go('/events/$id'); break;
      default: _router.go('/home'); break;
    }
  }
}
```

**Fix for foreground notifications:** Add `flutter_local_notifications` package and display incoming messages as local notifications when app is in foreground.

---

### BUG-041: Enable R8 minification for release builds

**File:** `android/app/build.gradle.kts`

**Fix:**
```kotlin
buildTypes {
    release {
        isMinifyEnabled = true
        isShrinkResources = true
        proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        signingConfig = signingConfigs.getByName("release")
    }
}
```
Create `android/app/proguard-rules.pro`:
```
-keep class io.supabase.** { *; }
-keep class com.google.firebase.** { *; }
-dontwarn io.supabase.**
```

---

### BUG-042: Fix color mismatch between AppTheme and MainShell

**File:** `lib/shell/main_shell.dart`

**Fix:**
- Replace `_primaryContainer = Color(0xFF6C5CE7)` with `AppColors.primary`
- Replace all other hardcoded colors in the shell with `AppColors` constants
- Remove local color declarations

---

### BUG-043: Memoize event filtering/sorting

**File:** `lib/screens/events_screen.dart`

**Fix:**
- Extract filter logic to a Riverpod computed provider:
```dart
final filteredEventsProvider = Provider.family<List<Event>, String>((ref, filter) {
  final events = ref.watch(eventsProvider).valueOrNull ?? [];
  if (filter == 'all') return events;
  return events.where((e) => e.status == filter).toList();
});
```
- Remove filtering from `build()` method

---

### BUG-044: Prevent self-scan in QR scanner

**File:** `lib/screens/qr_scanner_screen.dart`

**Fix:**
```dart
// After extracting userId from QR:
final currentUser = ref.read(currentUserIdProvider);
if (userId == currentUser) {
  BumpToast.show(context, message: 'You cannot exchange with yourself!', type: ToastType.error);
  return;
}
```

---

### BUG-045: Add account deletion flow

**File:** Create `lib/screens/delete_account_screen.dart`, update `lib/screens/profile_screen.dart`

**Fix:**
- Add "Delete Account" option at bottom of profile settings (red text)
- Create deletion confirmation screen with:
  - Warning message explaining data will be permanently deleted
  - Password re-entry for confirmation
  - "Delete My Account" button
- Implementation:
```dart
Future<void> deleteAccount() async {
  await _client.rpc('delete_user_account'); // Server-side cascade delete
  await _client.auth.signOut();
  context.go('/auth');
}
```
- Create corresponding Supabase RPC that cascade-deletes all user data

---

### BUG-046: Fix Nudge model DateTime.now() default

**File:** `lib/data/models/nudge_model.dart`

**Fix:**
```dart
// Change from:
sentAt: DateTime.parse(json['sent_at'] as String? ?? DateTime.now().toIso8601String()),
// To:
sentAt: json['sent_at'] != null ? DateTime.parse(json['sent_at'] as String) : DateTime.now(),
```
And validate in the repository that `sent_at` is always set server-side.

---

## 4. LOW SEVERITY BUG FIXES (P3)

### BUG-047: Replace NFC pulsing animation with static placeholder
**File:** `lib/screens/bump_screen.dart`
- Remove 3 AnimationControllers for NFC tab
- Replace with a static "NFC Coming Soon" card with icon

### BUG-048: Add pull-to-refresh on Analytics screen
**File:** `lib/screens/analytics_screen.dart`
- Wrap content in `RefreshIndicator`
- On refresh, invalidate all analytics-related providers

### BUG-049: Add reduced-motion support
**Files:** All files with animations
- Create utility: `bool get reduceMotion => MediaQuery.of(context).disableAnimations;`
- Conditionally set animation durations to `Duration.zero` when enabled
- Apply to splash, onboarding, home, analytics, event animations

### BUG-050: Integrate crash reporting
**File:** `lib/main.dart`
- Add `firebase_crashlytics` to pubspec.yaml
- Update main.dart error handlers:
```dart
FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
PlatformDispatcher.instance.onError = (error, stack) {
  FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
  return true;
};
```

### BUG-051: Add dark mode support
**File:** `lib/core/theme/app_theme.dart`
- Create `AppTheme.dark` ThemeData
- In `main.dart`, use `themeMode: ThemeMode.system`

### BUG-052: Fix GradientButton text overflow
**File:** `lib/widgets/gradient_button.dart`
- Add `maxLines: 1, overflow: TextOverflow.ellipsis` to Text widget

### BUG-053: Fix BumpAvatar blank circle on empty names
**File:** `lib/widgets/avatar.dart`
- Default initials to `'?'` when both names are empty:
```dart
final initials = _getInitials();
if (initials.isEmpty) return Icon(Icons.person, size: size * 0.5);
```

### BUG-054: Fix avatar gradient determinism
**File:** `lib/widgets/avatar.dart`
- Replace `hashCode` with deterministic hash:
```dart
int _djb2Hash(String str) {
  var hash = 5381;
  for (var i = 0; i < str.length; i++) {
    hash = ((hash << 5) + hash) + str.codeUnitAt(i);
  }
  return hash.abs();
}
```

### BUG-055: Fix toast text overflow
Already addressed in BUG-006 by switching to ScaffoldMessenger (SnackBar handles overflow natively).

### BUG-056: Clamp GlassCard opacity
**File:** `lib/widgets/glass_card.dart`
- Add: `final clampedOpacity = opacity.clamp(0.0, 1.0);`

### BUG-057: Set up i18n infrastructure
- Run: `flutter pub add flutter_localizations --sdk=flutter`
- Create `lib/l10n/app_en.arb` with all hardcoded strings
- Generate localizations: `flutter gen-l10n`
- Use `AppLocalizations.of(context)!.stringKey` throughout

### BUG-058: Localize export date format
**File:** `lib/services/export_service.dart`
- Use: `DateFormat.yMd(Platform.localeName).add_Hm().format(date)`

### BUG-059: Increase small button touch target
**File:** `lib/widgets/gradient_button.dart`
- Change small height from 36/44 to 48:
```dart
height: small ? 48 : 56,
```

### BUG-060: Fix SafeArea top in MainShell
**File:** `lib/shell/main_shell.dart`
- Change `top: false` to `top: true` in SafeArea

### BUG-061: Fix shell navigation index string matching
**File:** `lib/shell/main_shell.dart`
- Use exact path matching:
```dart
int _calculateSelectedIndex(BuildContext context) {
  final location = GoRouterState.of(context).uri.path;
  if (location == '/home') return 0;
  if (location == '/bump') return 1;
  if (location == '/events') return 2;
  if (location == '/analytics') return 3;
  if (location == '/profile') return 4;
  return 0;
}
```

### BUG-062: Add version check mechanism
**File:** `lib/main.dart`
- Add remote config or simple API check for minimum app version
- Show force-update dialog if current version < minimum

---

## 5. SECURITY HARDENING

Complete these security tasks after all bug fixes:

1. **Supabase RLS audit:** Verify Row Level Security policies on ALL tables ensure users can only access their own data. Test with raw SQL queries using the anon key.

2. **Input sanitization:** All user-input strings should be trimmed and sanitized before DB storage. Create a `sanitize()` utility.

3. **Rate limiting:** Add rate limiting awareness — catch Supabase 429 errors and show "Please wait" message.

4. **Certificate pinning:** Consider adding SSL certificate pinning for Supabase API calls in production.

5. **Secure storage:** Use `flutter_secure_storage` for any locally cached auth tokens instead of SharedPreferences.

6. **Avatar upload validation:** Restrict file types to jpg/png/webp. Validate file size < 5MB. Validate image dimensions.

7. **Deep link validation:** Validate all deep link parameters are valid UUIDs before processing.

---

## 6. PERFORMANCE OPTIMIZATION

1. **Implement pagination** (BUG-033) across all list views with infinite scroll
2. **Add image caching** (BUG-034) with `cached_network_image`
3. **Compress avatar uploads** before sending to Supabase storage (use `image` package to resize to max 500x500)
4. **Memoize computed providers** (BUG-043) for filtered/sorted lists
5. **Debounce search and notes fields** (BUG-027)
6. **Remove unnecessary animations** (BUG-047) for placeholder features
7. **Use `const` constructors** everywhere possible to reduce widget rebuilds
8. **Add `RepaintBoundary`** around expensive custom paint widgets (charts, QR code)
9. **Replace BackdropFilter** in MainShell with static blur or pre-computed image
10. **Add `cacheExtent`** to long ListViews for smoother scrolling
11. **Splash screen:** Use `Future.wait` with timeout instead of fixed 2.5s delay

---

## 7. ACCESSIBILITY AUDIT IMPLEMENTATION

### 7.1 Add Semantics to all interactive widgets
```dart
// Every custom button:
Semantics(
  button: true,
  label: 'Share your digital card',
  child: GradientButton(...),
)

// Every image/avatar:
Semantics(
  label: '${person.firstName} ${person.lastName} avatar',
  image: true,
  child: BumpAvatar(...),
)

// Every status badge:
Semantics(
  label: 'Prospect status: $status',
  child: StatusBadge(...),
)
```

### 7.2 Add ExcludeSemantics for decorative elements
```dart
ExcludeSemantics(child: decorativeGlow)
ExcludeSemantics(child: backgroundGradient)
```

### 7.3 Add MergeSemantics for grouped elements
```dart
MergeSemantics(
  child: Row(children: [Icon(...), Text('Call')]),
)
```

### 7.4 Add live region announcements
```dart
// For toast/snackbar (already handled by ScaffoldMessenger after BUG-006 fix)
// For loading states:
Semantics(
  liveRegion: true,
  child: Text(isLoading ? 'Loading...' : 'Content loaded'),
)
```

### 7.5 Fix color contrast
- All text on colored backgrounds must meet WCAG AA 4.5:1 ratio
- StatusBadge: Add text label alongside color indicator
- Glass card: Increase background opacity for better text contrast

### 7.6 Ensure minimum touch targets
- All interactive elements: minimum 48x48dp
- Add `MaterialTapTargetSize.padded` to all buttons

### 7.7 Add reduced motion support (BUG-049)
- Check `MediaQuery.of(context).disableAnimations` before every animation

### 7.8 Screen reader navigation order
- Ensure logical focus order on each screen
- Add `FocusTraversalGroup` where needed

---

## 8. UX IMPROVEMENT SUGGESTIONS

Implement these after all bugs are fixed:

1. **Profile completion indicator** on home screen (circular progress showing % complete)
2. **Copy Link button** below QR code display
3. **Haptic feedback** on successful QR scan: `HapticFeedback.mediumImpact()`
4. **Search bar** in prospect list with name/company filter
5. **Expandable nudge history items** (show full message on tap)
6. **Custom date range picker** for analytics (in addition to fixed periods)
7. **CSV/XLSX format chooser** in export dialog
8. **Dynamic welcome messages** based on time of day and activity
9. **Empty state CTAs** with action buttons instead of plain text
10. **Loading indicator during sign-out** before redirect
11. **QR fullscreen toggle** for easier scanning
12. **Schedule nudge** feature for timed follow-ups
13. **Bulk actions** on prospect list (select multiple → change status, send nudge)

---

## 9. MISSED EDGE CASES

Implement defensive handling for each:

1. **Self-scan prevention** (BUG-044): Check userId matches before exchange
2. **Duplicate exchange prevention:** Add unique constraint `(user_id, target_user_id, event_id)` in DB, handle conflict in UI
3. **Unicode/emoji in names:** URL-encode all dynamic values in deep links, escape in CSV
4. **Long text overflow:** Add `maxLines` + `overflow: TextOverflow.ellipsis` to all user-provided text displays
5. **Timezone handling:** Store all dates as UTC, convert to local for display using `toLocal()`
6. **Screen rotation lock:** Add `SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])` in main.dart
7. **Android back button:** Add `WillPopScope` / `PopScope` to multi-step flows (onboarding, profile setup)
8. **App backgrounding during exchange:** Use `WidgetsBindingObserver` to handle lifecycle
9. **Cascade deletes:** Ensure Supabase foreign keys have `ON DELETE CASCADE` for prospects → events
10. **Multi-device session:** Add last-write-wins with `updated_at` timestamps
11. **Nudge to prospect without contact info:** Disable channel buttons when corresponding contact info is missing
12. **Internet connectivity check:** Before any API call, check connectivity and show offline message
13. **Account deletion flow** (BUG-045): Required for Play Store and GDPR

---

## 10. RELEASE READINESS CHECKLIST

Run through this checklist after all fixes are implemented:

### Pre-Release (All must pass ✅)
- [ ] All 9 Critical bugs fixed and verified
- [ ] All 16 High bugs fixed and verified
- [ ] `flutter analyze` returns 0 issues
- [ ] `flutter test` all tests pass
- [ ] Supabase RLS policies verified on all tables
- [ ] No hardcoded API keys in source
- [ ] R8 minification enabled for release build
- [ ] CAMERA, POST_NOTIFICATIONS permissions declared
- [ ] Forgot Password flow works end-to-end
- [ ] Account deletion flow works end-to-end
- [ ] Session expiry redirects to login gracefully
- [ ] Empty states display correctly on all screens
- [ ] Crash reporting integrated (Crashlytics)
- [ ] QR scanner requests camera permission properly
- [ ] All settings buttons either work or show "Coming Soon"
- [ ] Back button behavior correct on all multi-step flows

### Quality Gate
- [ ] No force unwraps (`!`) on auth-related code
- [ ] No unsafe type casts without validation
- [ ] All forms have input validation
- [ ] All async operations have error handling
- [ ] All optimistic updates have rollback
- [ ] All url_launcher calls wrapped in try-catch
- [ ] All text fields have maxLength set

### Play Store Compliance
- [ ] Account deletion available
- [ ] Privacy policy accessible from app
- [ ] All permissions justified in Play Store listing
- [ ] Target SDK meets Play Store requirements (34+)
- [ ] 64-bit build support enabled

---

**END OF PROMPT — Execute sections 1-10 in order. Do not skip any item. After each section, run `flutter analyze` to catch regressions.**
