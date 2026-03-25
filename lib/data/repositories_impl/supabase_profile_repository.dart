import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart' hide User;

import 'package:bump/core/config/supabase_config.dart';
import 'package:bump/core/utils/authenticated_repository.dart';
import 'package:bump/core/utils/safe_cast.dart';
import 'package:bump/data/models/user_model.dart';
import 'package:bump/data/repositories/profile_repository.dart';

class SupabaseProfileRepository
    with AuthenticatedRepository
    implements ProfileRepository {
  @override
  SupabaseClient get client => Supabase.instance.client;

  @override
  Future<User?> getProfile(String userId) async {
    final response = await client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (response == null) return null;
    return User.fromJson(response);
  }

  @override
  Future<User?> getMyProfile() async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) return null;
    return getProfile(userId);
  }

  @override
  Future<void> createProfile(User user) async {
    await client.from('profiles').insert(user.toJson());
  }

  @override
  Future<void> updateProfile(User user) async {
    final data = user.toJson();
    data.remove('id'); // Don't include id in update payload
    await client.from('profiles').update(data).eq('id', user.id);
  }

  @override
  Future<bool> isUsernameAvailable(String username) async {
    final userId = client.auth.currentUser?.id;
    var query = client
        .from('profiles')
        .select('id')
        .eq('username', username.toLowerCase());

    if (userId != null) {
      query = query.neq('id', userId);
    }

    final response = await query;
    return safeListCast(response).isEmpty;
  }

  @override
  Future<String> uploadAvatar(String filePath) async {
    final userId = currentUserId;
    final fileExt = filePath.split('.').last;
    final fileName = '$userId/avatar.$fileExt';

    await client.storage
        .from(SupabaseConfig.avatarsBucket)
        .upload(
          fileName,
          File(filePath),
          fileOptions: const FileOptions(upsert: true),
        );

    final publicUrl = client.storage
        .from(SupabaseConfig.avatarsBucket)
        .getPublicUrl(fileName);

    return publicUrl;
  }
}
