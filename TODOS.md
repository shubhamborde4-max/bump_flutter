# TODOS

## P0 — Before Validation Event

### Shared error wrapper for Supabase calls
- **What:** Add a `safeCall()` method to `AuthenticatedRepository` mixin that wraps all Supabase calls with 10s timeout + catch for SocketException, TimeoutException, AuthException. Show user-friendly error with retry.
- **Why:** 9 Supabase calls across all repositories have zero error handling. At a networking event with spotty WiFi, any of these will hang or crash the app. This is the most likely failure mode at the validation event.
- **Effort:** S (human: ~4 hours / CC: ~15 min)
- **Priority:** P0
- **Depends on:** Nothing — can start immediately

### Critical path tests
- **What:** Add 6-8 tests: Prospect model roundtrip, NFC vCard builder, exchange RPC mock, auth guard. Covers the core event demo path.
- **Why:** 62 bugs were just fixed but there are no regression tests. The exchange flow is the core demo at the validation event.
- **Effort:** S (human: ~3 days / CC: ~20 min)
- **Priority:** P0
- **Depends on:** Nothing — can start immediately

### Replace hardcoded colors in ALL screens
- **What:** Replace hardcoded color constants with `AppColors` references in: events_screen, analytics_screen, prospect_detail_screen, onboarding_screen, empty_state, main_shell, privacy_policy_screen. (HomeScreen already fixed.)
- **Why:** 7 files bypass the design system. Prerequisite for dark mode, blocks brand consistency.
- **Effort:** S (human: ~1 day / CC: ~20 min)
- **Priority:** P0
- **Depends on:** Nothing — can start immediately

### Reusable ErrorState widget + apply to 6 screens
- **What:** Create an ErrorState widget (like EmptyState) with error message + retry button. Apply to Bump, Analytics, Profile, QR Scanner, and other screens missing error UI.
- **Why:** The safeCall error wrapper throws RepositoryException with user-friendly messages, but 6 screens have no way to display them. At events with spotty WiFi, users see blank screens.
- **Effort:** S (human: ~3 hours / CC: ~15 min)
- **Priority:** P0
- **Depends on:** Shared error wrapper (done)

### First-use nudge on Home screen
- **What:** When prospects list is empty and user is new, show a prominent "Try your first Bump!" card that navigates to the Bump tab.
- **Why:** New users land on an empty dashboard with no guidance. The "aha moment" (NFC exchange) requires discovering the Bump tab on their own.
- **Effort:** S (human: ~2 hours / CC: ~10 min)
- **Priority:** P1
- **Depends on:** Nothing

### Post-exchange notes prompt
- **What:** After a successful NFC/QR exchange, show a quick prompt: "Add notes about [name]?" with a text field. Captures context in the moment.
- **Why:** Context capture is the core product thesis. Without a prompt, users won't add notes and the follow-up value proposition dies.
- **Effort:** S (human: ~3 hours / CC: ~15 min)
- **Priority:** P1
- **Depends on:** Nothing

### Basic accessibility: Semantics on key widgets
- **What:** Add Semantics wrappers to bottom nav items, action buttons, status badges, and form fields. Not a full a11y audit — just screen reader basics.
- **Why:** Zero accessibility currently. Legal risk for app store distribution. Excludes users with disabilities.
- **Effort:** S (human: ~3 hours / CC: ~30 min)
- **Priority:** P1
- **Depends on:** Nothing

## P1 — Before/During Validation

### One-tap WhatsApp message
- **What:** After exchanging contacts, add a button that opens WhatsApp with a pre-filled ice-breaker message using the person's name and event context.
- **Why:** WhatsApp is the founder's primary follow-up channel. This is the shortest path from exchange to relationship.
- **Effort:** S (human: ~2 days / CC: ~15 min)
- **Priority:** P2
- **Depends on:** Validation event (confirm WhatsApp is actually the channel users want)

### Add tests (zero to something)
- **What:** Platform-channel mocks for NFC/QR, widget tests for key screens. Bootstrap a test harness from nothing.
- **Why:** 62 bugs were fixed in QA but there are no regression tests. Any new code risks re-introducing bugs.
- **Effort:** M (human: ~1 week / CC: ~30 min)
- **Priority:** P1
- **Depends on:** Nothing — can start immediately

### Firebase Crashlytics integration
- **What:** Connect the existing `FlutterError.onError` handler in main.dart to Firebase Crashlytics. Firebase is already initialized.
- **Why:** Captures crash reports from real users at the validation event — invaluable debugging data.
- **Effort:** S (human: ~1 day / CC: ~15 min)
- **Priority:** P1
- **Depends on:** Nothing — Firebase already initialized

### Privacy policy + data deletion endpoint
- **What:** Implement a server-side data deletion endpoint (Supabase Edge Function or RPC). Update privacy policy screen content. Required for app store distribution.
- **Why:** GDPR requires data deletion capability. App stores require a privacy policy URL.
- **Effort:** S (human: ~2 days / CC: ~15 min)
- **Priority:** P1
- **Depends on:** Nothing — can start immediately

## Gated on Validation Event

### Business card scanner (OCR)
- **What:** Camera mode that scans physical business cards using ML Kit OCR and auto-creates prospects.
- **Why:** Bridges physical-to-digital gap. Build IF people hand you physical cards at the event.
- **Effort:** M (human: ~1 week / CC: ~30 min)
- **Depends on:** Validation event data

### Voice notes after exchange
- **What:** Microphone button with auto-transcription saved as prospect notes.
- **Why:** Captures context before it's forgotten. Build IF you forget context about people you met.
- **Effort:** M (human: ~1 week / CC: ~30 min)
- **Depends on:** Validation event data

### Contact enrichment
- **What:** Auto-pull LinkedIn/company data via email-based lookup API (Supabase Edge Function).
- **Why:** Makes prospect cards rich without manual entry. Build IF prospect cards feel empty.
- **Effort:** M (human: ~1 week / CC: ~30 min)
- **Depends on:** Validation event data + GDPR resolution

### Dark mode
- **What:** Dark theme variant following system preference.
- **Why:** Events have dim lighting. Build IF the app was hard to use in dim settings.
- **Effort:** S (human: ~3 days / CC: ~20 min)
- **Depends on:** Validation event data

### Home screen widget (Android)
- **What:** Android home screen widget showing profile QR code.
- **Why:** Removes one friction step from exchange. Build IF opening the app was too slow.
- **Effort:** L (human: ~1-2 weeks / CC: ~45 min)
- **Depends on:** Validation event data

## Deferred (No Timeline)

- iOS home screen widget (WidgetKit complexity)
- Apple Wallet integration (Pass Type ID + server signing)
- Physical NFC tag ordering (logistics, not software)
- Time badges + follow-up reminders
- Create DESIGN.md via /design-consultation (formal design system document)
- Full accessibility audit (reduced-motion, focus management, contrast, all Semantics)
- QR scanner first-use guidance text
- NFC failure recovery UX (specific error states for different failure modes)
