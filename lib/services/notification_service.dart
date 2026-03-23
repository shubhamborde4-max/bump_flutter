import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// Initialize FCM, request permissions, get token, save to Supabase
  static Future<void> initialize() async {
    // Request permission
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      // Get FCM token
      final token = await _messaging.getToken();
      if (token != null) {
        await _saveToken(token);
      }

      // Listen for token refresh
      _messaging.onTokenRefresh.listen(_saveToken);

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle background message tap (app was in background)
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageTap);
    }
  }

  static Future<void> _saveToken(String token) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await Supabase.instance.client.from('devices').upsert({
        'user_id': userId,
        'fcm_token': token,
        'platform': 'android',
        'is_active': true,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id,fcm_token');
    } catch (_) {
      // Silently fail — token will be retried on next app launch
    }
  }

  static void _handleForegroundMessage(RemoteMessage message) {
    // Show in-app notification banner
    debugPrint('FCM foreground: ${message.notification?.title}');
  }

  static void _handleMessageTap(RemoteMessage message) {
    // Navigate based on data payload
    debugPrint('FCM tap: ${message.data}');
  }

  /// Deactivate token on logout
  static Future<void> deactivateCurrentToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        final userId = Supabase.instance.client.auth.currentUser?.id;
        if (userId != null) {
          await Supabase.instance.client
              .from('devices')
              .update({'is_active': false})
              .eq('user_id', userId)
              .eq('fcm_token', token);
        }
      }
    } catch (_) {
      // Silently fail — don't block sign-out if token deactivation fails
    }
  }
}
