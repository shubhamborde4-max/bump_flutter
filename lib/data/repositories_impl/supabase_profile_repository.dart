import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart' hide User;

import 'package:bump/core/config/supabase_config.dart';
import 'package:bump/data/models/user_model.dart';
import 'package:bump/data/repositories/profile_repository.dart';

class SupabaseProfileRepository implements ProfileRepository {
  SupabaseClient get _client => Supabase.instance.client;

  @override
  Future<User?> getProfile(String userId) async {
    final response = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (response == null) return null;
    return User.fromJson(response);
  }

  @override
  Future<User?> getMyProfile() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;
    return getProfile(userId);
  }

  @override
  Future<void> createProfile(User user) async {
    await _client.from('profiles').insert(user.toJson());
  }

  @override
  Future<void> updateProfile(User user) async {
    final data = user.toJson();
    data.remove('id'); // Don't include id in update payload
    await _client.from('profiles').update(data).eq('id', user.id);
  }

  @override
  Future<bool> isUsernameAvailable(String username) async {
    final currentUserId = _client.auth.currentUser?.id;
    var query = _client
        .from('profiles')
        .select('id')
        .eq('username', username.toLowerCase());

    if (currentUserId != null) {
      query = query.neq('id', currentUserId);
    }

    final response = await query;
    return (response as List).isEmpty;
  }

  @override
  Future<String> uploadAvatar(String filePath) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw AuthException('Session expired. Please sign in again.');
    }
    final userId = user.id;
    final fileExt = filePath.split('.').last;
    final fileName = '$userId/avatar.$fileExt';

    await _client.storage
        .from(SupabaseConfig.avatarsBucket)
        .upload(
          fileName,
          File(filePath),
          fileOptions: const FileOptions(upsert: true),
        );

    final publicUrl = _client.storage
        .from(SupabaseConfig.avatarsBucket)
        .getPublicUrl(fileName);

    return publicUrl;
  }
}
