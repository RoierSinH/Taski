import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mi_primera_app/controllers/auth_controller.dart';
import 'package:mi_primera_app/screens/login_page.dart';
import 'package:mi_primera_app/services/auth_service.dart';

class MockAuthService extends Mock implements AuthService {}

void main() {
  group('Pruebas de widget para LoginPage (Pasos 25 y 26 Parte 7)', () {
    late MockAuthService mockAuthService;

    setUp(() {
      mockAuthService = MockAuthService();
    });

    testWidgets('muestra validaciones al enviar vacío', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => AuthController(mockAuthService),
          child: const MaterialApp(
            home: LoginPage(),
          ),
        ),
      );

      await tester.tap(find.text('Iniciar sesión'));
      await tester.pump();

      expect(find.text('Ingresa tu correo'), findsOneWidget);
      expect(find.text('Ingresa tu contraseña'), findsOneWidget);
    });

    testWidgets('permite ingresar credenciales y enviar el formulario', (tester) async {
      when(
        () => mockAuthService.signIn(
          email: 'persona@ejemplo.com',
          password: 'Password123',
        ),
      ).thenAnswer((_) async => AuthResponse());

      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => AuthController(mockAuthService),
          child: const MaterialApp(
            home: LoginPage(),
          ),
        ),
      );

      await tester.enterText(
        find.byKey(const Key('login_email')),
        'persona@ejemplo.com',
      );
      await tester.enterText(
        find.byKey(const Key('login_password')),
        'Password123',
      );
      await tester.tap(find.byKey(const Key('login_submit')));
      await tester.pump();

      verify(
        () => mockAuthService.signIn(
          email: 'persona@ejemplo.com',
          password: 'Password123',
        ),
      ).called(1);
    });
  });
}
