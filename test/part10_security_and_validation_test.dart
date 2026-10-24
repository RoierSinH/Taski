import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mi_primera_app/controllers/auth_controller.dart';
import 'package:mi_primera_app/screens/login_page.dart';
import 'package:mi_primera_app/services/auth_service.dart';

class MockAuthService extends Mock implements AuthService {}

bool nombreValido(String valor) =>
    valor.trim().isNotEmpty && valor.trim().length <= 80;

void main() {
  group('Sección 15 (Parte 10): Pruebas unitarias de validadores y clasificación de errores', () {
    test('rechaza nombres vacíos', () {
      expect(nombreValido('   '), false);
    });

    test('acepta un nombre válido', () {
      expect(nombreValido('Mi tarea'), true);
    });

    test('AuthService.classifyError distingue Auth, RLS, Storage y Validación sin exponer secretos', () {
      final authErr = AuthService.classifyError(
        const AuthException('Invalid login credentials'),
      );
      expect(authErr, contains('Autenticación:'));

      final rlsErr = AuthService.classifyError(
        const PostgrestException(
          message: 'new row violates row-level security policy',
          code: '42501',
        ),
      );
      expect(rlsErr, contains('Autorización (RLS):'));

      final storageErr = AuthService.classifyError(
        const StorageException('Payload too large: size exceeds limit', statusCode: '413'),
      );
      expect(storageErr, contains('Almacenamiento:'));

      final valErr = AuthService.classifyError(
        const FormatException('Formato inválido'),
      );
      expect(valErr, contains('Validación:'));
    });

    testWidgets('LoginPage muestra tanto el botón de correo como el botón Continuar con Google', (tester) async {
      final mockService = MockAuthService();
      when(() => mockService.currentUser).thenReturn(null);
      final authController = AuthController(mockService);

      await tester.pumpWidget(
        ChangeNotifierProvider<AuthController>.value(
          value: authController,
          child: const MaterialApp(
            home: LoginPage(),
          ),
        ),
      );

      expect(find.byKey(const Key('login_submit')), findsOneWidget);
      expect(find.byKey(const Key('login_google_button')), findsOneWidget);
      expect(find.text('Continuar con Google'), findsOneWidget);
    });
  });
}
