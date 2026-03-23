import 'package:bump/data/models/user_model.dart';

abstract class ProfileRepository {
  Future<User?> getProfile(String userId);

  Future<User?> getMyProfile();

  Future<void> updateProfile(User user);

  Future<void> createProfile(User user);

  Future<bool> isUsernameAvailable(String username);

  Future<String> uploadAvatar(String filePath);
}
