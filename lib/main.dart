import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:bump/core/config/supabase_config.dart';
import 'package:bump/core/theme/app_theme.dart';
import 'package:bump/navigation/app_router.dart';
import 'package:bump/services/notification_service.dart';

// TODO: Add reduced-motion support (MediaQuery.disableAnimations) as a
// future improvement. This would respect the user's OS-level accessibility
// setting and disable or simplify animations across all screens.

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // BUG-025: Global error handler for crash reporting
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    // TODO: Send to Firebase Crashlytics when integrated
  };

  // Initialise Supabase
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  // Initialise Firebase & FCM (wrapped in try-catch so the app works
  // even without google-services.json or Google Play Services)
  try {
    await Firebase.initializeApp();
    await NotificationService.initialize();
  } catch (e) {
    debugPrint('Firebase init failed (FCM disabled): $e');
  }

  // Set system UI overlay style for light theme
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.white,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));

  runApp(const ProviderScope(child: BumpApp()));
}

class BumpApp extends ConsumerStatefulWidget {
  const BumpApp({super.key});

  @override
  ConsumerState<BumpApp> createState() => _BumpAppState();
}

class _BumpAppState extends ConsumerState<BumpApp> {
  late final StreamSubscription<AuthState> _authSub;

  @override
  void initState() {
    super.initState();

    // Listen for auth state changes and redirect to /auth on sign-out
    // or token refresh failure.
    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.signedOut ||
          data.session == null && data.event != AuthChangeEvent.initialSession) {
        final router = ref.read(routerProvider);
        router.go('/auth');
      }
    });
  }

  @override
  void dispose() {
    _authSub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Bump',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light.copyWith(
        textTheme: GoogleFonts.interTextTheme(
          AppTheme.light.textTheme,
        ),
      ),
      routerConfig: router,
    );
  }
}
