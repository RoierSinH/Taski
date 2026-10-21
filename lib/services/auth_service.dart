import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  AuthService(this._client);
  final SupabaseClient _client;

  User? get currentUser => _client.auth.currentUser;
  Session? get currentSession => _client.auth.currentSession;

  Stream<AuthState> get authChanges => _client.auth.onAuthStateChange;

  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) {
    return _client.auth.signUp(
      email: email,
      password: password,
    );
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) {
    return _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() {
    return _client.auth.signOut();
  }

  Future<void> sendPasswordReset(String email) async {
    await _client.auth.resetPasswordForEmail(
      email.trim(),
      redirectTo: 'io.taski.app://reset-password',
    );
  }

  Future<void> updatePassword(String newPassword) async {
    await _client.auth.updateUser(
      UserAttributes(
        password: newPassword,
      ),
    );
  }
}
