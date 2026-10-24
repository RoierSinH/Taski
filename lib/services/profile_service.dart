import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';

abstract interface class ProfileRepository {
  Future<void> ensureProfile();
  Future<UserProfile> getProfile();
  Future<void> updateDisplayName(String displayName);
  Future<void> updateBio(String bio);
  Future<void> updateProfile({
    required String displayName,
    required String bio,
  });
  Future<XFile?> pickAvatar();
  Future<String> changeAvatar(XFile image);
}

class ProfileService implements ProfileRepository {
  ProfileService(this._client);

  final SupabaseClient _client;
  final ImagePicker _picker = ImagePicker();

  @override
  Future<void> ensureProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    // Verificar si ya existe para no sobrescribir display_name o bio existentes
    final existing = await _client
        .from('profiles')
        .select('id')
        .eq('id', user.id)
        .maybeSingle();

    if (existing == null) {
      await _client.from('profiles').insert({
        'id': user.id,
        'display_name': user.userMetadata?['full_name'] ??
            user.userMetadata?['name'] ??
            user.userMetadata?['display_name'] ??
            'Usuario',
        'bio': '',
      });
    }
  }

  @override
  Future<UserProfile> getProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError('Sesión no disponible');
    }

    final row = await _client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .single();

    return UserProfile.fromMap(
      row,
      user.email ?? '',
    );
  }

  @override
  Future<void> updateDisplayName(String displayName) async {
    final userId = _client.auth.currentUser!.id;
    await _client
        .from('profiles')
        .update({
          'display_name': displayName.trim(),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', userId);
  }

  @override
  Future<void> updateBio(String bio) async {
    final validationError = UserProfile.validateBio(bio);
    if (validationError != null) {
      throw ArgumentError(validationError);
    }

    final userId = _client.auth.currentUser!.id;
    await _client
        .from('profiles')
        .update({
          'bio': bio.trim(),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', userId);
  }

  @override
  Future<void> updateProfile({
    required String displayName,
    required String bio,
  }) async {
    final validationError = UserProfile.validateBio(bio);
    if (validationError != null) {
      throw ArgumentError(validationError);
    }

    final userId = _client.auth.currentUser!.id;
    await _client
        .from('profiles')
        .update({
          'display_name': displayName.trim(),
          'bio': bio.trim(),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', userId);
  }

  @override
  Future<XFile?> pickAvatar() {
    return _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1200,
    );
  }

  String extensionFromPath(String filePath) {
    final value = path.extension(filePath).toLowerCase();
    return switch (value) {
      '.png' => '.png',
      '.webp' => '.webp',
      _ => '.jpg',
    };
  }

  Future<String> uploadAvatar(XFile image) async {
    final userId = _client.auth.currentUser!.id;
    final fileName = image.name.isNotEmpty ? image.name : image.path;
    final extension = extensionFromPath(fileName);
    final storagePath = '$userId/avatar$extension';
    final bytes = await image.readAsBytes();

    await _client.storage.from('avatars').uploadBinary(
          storagePath,
          bytes,
          fileOptions: const FileOptions(
            upsert: true,
            cacheControl: '3600',
          ),
        );

    final baseUrl = _client.storage.from('avatars').getPublicUrl(storagePath);
    final nonce = DateTime.now().millisecondsSinceEpoch;
    return '$baseUrl?t=$nonce';
  }

  @override
  Future<String> changeAvatar(XFile image) async {
    final avatarUrl = await uploadAvatar(image);
    final userId = _client.auth.currentUser!.id;

    await _client
        .from('profiles')
        .update({
          'avatar_url': avatarUrl,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', userId);

    return avatarUrl;
  }
}
