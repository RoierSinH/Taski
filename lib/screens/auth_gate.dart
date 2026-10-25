import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';
import 'login_page.dart';
import 'home_screen.dart';
import 'reset_password_page.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final client = Supabase.instance.client;

    return ValueListenableBuilder<bool>(
      valueListenable: recoveryModeNotifier,
      builder: (context, inRecovery, _) {
        return StreamBuilder<AuthState>(
          stream: client.auth.onAuthStateChange,
          builder: (context, snapshot) {
            final session = client.auth.currentSession;
            if (inRecovery && session != null) {
              return const ResetPasswordPage();
            }
            if (session == null) {
              return const LoginPage();
            }
            return const HomeScreen();
          },
        );
      },
    );
  }
}
