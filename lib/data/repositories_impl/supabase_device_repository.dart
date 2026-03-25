import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:bump/core/utils/authenticated_repository.dart';
import 'package:bump/data/repositories/device_repository.dart';

class SupabaseDeviceRepository
    with AuthenticatedRepository
    implements DeviceRepository {
  @override
  SupabaseClient get client => Supabase.instance.client;

  @override
  Future<void> upsertDevice({
    required String fcmToken,
    required String platform,
    String? deviceName,
  }) async {
    await client.from('devices').upsert(
      {
        'user_id': currentUserId,
        'fcm_token': fcmToken,
        'platform': platform,
        'device_name': deviceName,
        'is_active': true,
        'updated_at': DateTime.now().toIso8601String(),
      },
      onConflict: 'fcm_token',
    );
  }

  @override
  Future<void> deactivateDevice(String fcmToken) async {
    await client
        .from('devices')
        .update({
          'is_active': false,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('fcm_token', fcmToken)
        .eq('user_id', currentUserId);
  }
}
