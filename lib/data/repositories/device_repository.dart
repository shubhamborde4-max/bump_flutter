abstract class DeviceRepository {
  Future<void> upsertDevice({
    required String fcmToken,
    required String platform,
    String? deviceName,
  });

  Future<void> deactivateDevice(String fcmToken);
}
