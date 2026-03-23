abstract class AuthRepository {
  Future<void> signUp({
    required String email,
    required String password,
    String? firstName,
    String? lastName,
  });

  Future<void> signIn({
    required String email,
    required String password,
  });

  Future<void> signOut();

  Future<bool> hasSession();

  Stream<bool> onAuthStateChange();

  String? get currentUserId;
}
