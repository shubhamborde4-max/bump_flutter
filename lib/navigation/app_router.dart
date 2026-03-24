import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:bump/screens/splash_screen.dart';
import 'package:bump/screens/onboarding_screen.dart';
import 'package:bump/screens/auth_screen.dart';
import 'package:bump/screens/profile_setup_screen.dart';
import 'package:bump/screens/home_screen.dart';
import 'package:bump/screens/bump_screen.dart';
import 'package:bump/screens/events_screen.dart';
import 'package:bump/screens/event_detail_screen.dart';
import 'package:bump/screens/prospect_detail_screen.dart';
import 'package:bump/screens/analytics_screen.dart';
import 'package:bump/screens/profile_screen.dart';
import 'package:bump/screens/qr_scanner_screen.dart';
import 'package:bump/screens/edit_profile_screen.dart';
import 'package:bump/screens/privacy_policy_screen.dart';
import 'package:bump/screens/about_screen.dart';
import 'package:bump/shell/main_shell.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

/// Routes that do not require authentication.
const _publicRoutes = {'/', '/onboarding', '/auth'};

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    redirect: (context, state) {
      final location = state.matchedLocation;

      // Allow public routes without auth check
      if (_publicRoutes.contains(location)) return null;

      final session = Supabase.instance.client.auth.currentSession;

      // Not authenticated -> send to /auth
      if (session == null) return '/auth';

      // Authenticated but visiting /profile-setup is always ok
      if (location == '/profile-setup') return null;

      // All other protected routes are allowed when authenticated
      return null;
    },
    routes: [
      // Splash
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      // Onboarding
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      // Auth
      GoRoute(
        path: '/auth',
        builder: (context, state) => const AuthScreen(),
      ),
      // Profile Setup
      GoRoute(
        path: '/profile-setup',
        builder: (context, state) => const ProfileSetupScreen(),
      ),

      // Main app with bottom navigation
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HomeScreen(),
            ),
          ),
          GoRoute(
            path: '/bump',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: BumpScreen(),
            ),
          ),
          GoRoute(
            path: '/events',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: EventsScreen(),
            ),
          ),
          GoRoute(
            path: '/analytics',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: AnalyticsScreen(),
            ),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ProfileScreen(),
            ),
          ),
        ],
      ),

      // Detail screens (outside shell, full screen)
      GoRoute(
        path: '/events/:eventId',
        builder: (context, state) => EventDetailScreen(
          eventId: state.pathParameters['eventId']!,
        ),
      ),
      GoRoute(
        path: '/prospects/:prospectId',
        builder: (context, state) => ProspectDetailScreen(
          prospectId: state.pathParameters['prospectId']!,
        ),
      ),
      GoRoute(
        path: '/qr-scanner',
        builder: (context, state) => QrScannerScreen(
          eventId: state.extra as String?,
        ),
      ),
      GoRoute(
        path: '/edit-profile',
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/privacy-policy',
        builder: (context, state) => const PrivacyPolicyScreen(),
      ),
      GoRoute(
        path: '/about',
        builder: (context, state) => const AboutScreen(),
      ),
    ],
  );
});
