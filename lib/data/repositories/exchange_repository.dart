abstract class ExchangeRepository {
  Future<Map<String, dynamic>> performExchange({
    required String receiverId,
    required String method,
    String? eventId,
  });

  Future<Map<String, dynamic>?> getProfileByUsername(String username);
}
