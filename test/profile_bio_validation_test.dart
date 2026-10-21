import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mi_primera_app/controllers/profile_controller.dart';
import 'package:mi_primera_app/models/user_profile.dart';
import 'package:mi_primera_app/services/profile_service.dart';

class FakeProfileRepository implements ProfileRepository {
  UserProfile currentProfile = const UserProfile(
    id: 'user-123',
    email: 'roger@gmail.com',
    displayName: 'Roger',
    bio: '',
  );

  @override
  Future<void> ensureProfile() async {}

  @override
  Future<UserProfile> getProfile() async => currentProfile;

  @override
  Future<void> updateDisplayName(String displayName) async {
    currentProfile = currentProfile.copyWith(displayName: displayName.trim());
  }

  @override
  Future<void> updateBio(String bio) async {
    currentProfile = currentProfile.copyWith(bio: bio.trim());
  }

  @override
  Future<void> updateProfile({
    required String displayName,
    required String bio,
  }) async {
    currentProfile = currentProfile.copyWith(
      displayName: displayName.trim(),
      bio: bio.trim(),
    );
  }

  @override
  Future<XFile?> pickAvatar() async => null;

  @override
  Future<String> changeAvatar(XFile image) async => 'https://example.com/a.jpg';
}

void main() {
  group('Reto 7: Pruebas unitarias de validación de biografía (máx. 120 caracteres)', () {
    test('validateBio acepta biografía vacía o nula por ser opcional', () {
      expect(UserProfile.validateBio(null), isNull);
      expect(UserProfile.validateBio(''), isNull);
    });

    test('validateBio acepta biografía de hasta 120 caracteres', () {
      final validBio = 'Desarrollador Flutter aprendiendo Supabase y pruebas.';
      final exact120Bio = 'a' * 120;

      expect(UserProfile.validateBio(validBio), isNull);
      expect(UserProfile.validateBio(exact120Bio), isNull);
    });

    test('validateBio rechaza biografía que supera los 120 caracteres', () {
      final tooLongBio = 'a' * 121;
      final result = UserProfile.validateBio(tooLongBio);

      expect(result, isNotNull);
      expect(result, contains('120 caracteres'));
    });

    test('ProfileController guarda biografía válida y bloquea si excede 120 caracteres', () async {
      final repo = FakeProfileRepository();
      final controller = ProfileController(repo);
      await controller.load();

      // Caso válido
      final ok = await controller.saveProfile(
        displayName: 'Roger Perera',
        bio: 'Estudiante de Ingeniería de Software',
      );
      expect(ok, isTrue);
      expect(controller.profile?.bio, 'Estudiante de Ingeniería de Software');
      expect(controller.error, isNull);

      // Caso inválido (> 120 caracteres)
      final invalidBio = 'x' * 130;
      final failed = await controller.saveProfile(
        displayName: 'Roger Perera',
        bio: invalidBio,
      );
      expect(failed, isFalse);
      expect(controller.error, isNotNull);
      // El perfil conservó la biografía anterior
      expect(controller.profile?.bio, 'Estudiante de Ingeniería de Software');
    });
  });
}
