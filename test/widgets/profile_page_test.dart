import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:mi_primera_app/controllers/profile_controller.dart';
import 'package:mi_primera_app/models/user_profile.dart';
import 'package:mi_primera_app/screens/profile_page.dart';
import 'package:mi_primera_app/services/profile_service.dart';

class FakeWidgetProfileRepository implements ProfileRepository {
  UserProfile profile = const UserProfile(
    id: 'user-1',
    email: 'roger@gmail.com',
    displayName: 'Roger',
    bio: 'Bio inicial',
  );

  @override
  Future<void> ensureProfile() async {}

  @override
  Future<UserProfile> getProfile() async => profile;

  @override
  Future<void> updateDisplayName(String displayName) async {
    profile = profile.copyWith(displayName: displayName.trim());
  }

  @override
  Future<void> updateBio(String bio) async {
    profile = profile.copyWith(bio: bio.trim());
  }

  @override
  Future<void> updateProfile({
    required String displayName,
    required String bio,
  }) async {
    profile = profile.copyWith(
      displayName: displayName.trim(),
      bio: bio.trim(),
    );
  }

  @override
  Future<XFile?> pickAvatar() async => null;

  @override
  Future<String> changeAvatar(XFile image) async => '';
}

void main() {
  group('Reto 7: Pruebas de widget para ProfilePage y formulario de biografía', () {
    testWidgets('muestra contador de caracteres y guarda biografía válida', (tester) async {
      final repo = FakeWidgetProfileRepository();
      final controller = ProfileController(repo);

      await tester.pumpWidget(
        ChangeNotifierProvider<ProfileController>.value(
          value: controller,
          child: const MaterialApp(
            home: ProfilePage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verifica correo e información inicial
      expect(find.text('roger@gmail.com'), findsOneWidget);
      expect(find.text('11/120 caracteres'), findsOneWidget);

      // Escribir nueva biografía válida
      const nuevaBio = 'Apasionado por Flutter y el desarrollo móvil en la nube.';
      await tester.enterText(
        find.byKey(const Key('profile_bio')),
        nuevaBio,
      );
      await tester.pump();

      // Verificar que el contador se actualiza dinámicamente
      expect(find.text('${nuevaBio.length}/120 caracteres'), findsOneWidget);

      // Guardar formulario
      await tester.tap(find.byKey(const Key('profile_save_button')));
      await tester.pumpAndSettle();

      expect(repo.profile.bio, nuevaBio);
      expect(find.text('Perfil guardado correctamente'), findsOneWidget);
    });

    testWidgets('muestra error de validación si la biografía supera 120 caracteres', (tester) async {
      final repo = FakeWidgetProfileRepository();
      final controller = ProfileController(repo);

      await tester.pumpWidget(
        ChangeNotifierProvider<ProfileController>.value(
          value: controller,
          child: const MaterialApp(
            home: ProfilePage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Ingresar texto de 125 caracteres (> 120 permitidos)
      final bioExcedida = 'a' * 125;
      await tester.enterText(
        find.byKey(const Key('profile_bio')),
        bioExcedida,
      );
      await tester.pump();

      expect(find.text('125/120 caracteres'), findsOneWidget);

      // Intentar guardar
      await tester.tap(find.byKey(const Key('profile_save_button')));
      await tester.pump();

      // Debe mostrarse el mensaje de validación del formulario
      expect(
        find.text('La biografía no puede superar los 120 caracteres'),
        findsOneWidget,
      );
      // No se modificó en el repositorio
      expect(repo.profile.bio, 'Bio inicial');
    });
  });
}
