import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  AuthService(this._client);
  final SupabaseClient _client;

  static const String mobileRedirectUri = 'io.taski.app://login-callback';

  User? get currentUser => _client.auth.currentUser;
  Session? get currentSession => _client.auth.currentSession;

  Stream<AuthState> get authChanges => _client.auth.onAuthStateChange;

  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) {
    return _client.auth.signUp(
      email: email.trim(),
      password: password,
    );
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) {
    return _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Inicio de sesión con Google OAuth reutilizando el cliente Supabase inicializado (Parte 10).
  Future<bool> signInWithGoogle() async {
    return _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: kIsWeb ? null : mobileRedirectUri,
    );
  }

  Future<void> signOut() {
    return _client.auth.signOut();
  }

  /// Recuperación de acceso reutilizando la URI de redirección autorizada (Parte 10).
  Future<void> sendPasswordReset(String email) async {
    await _client.auth.resetPasswordForEmail(
      email.trim(),
      redirectTo: kIsWeb ? Uri.base.origin : mobileRedirectUri,
    );
  }

  Future<void> updatePassword(String newPassword) async {
    await _client.auth.updateUser(
      UserAttributes(
        password: newPassword,
      ),
    );
  }

  /// Asegura el registro del perfil social en public.profiles sin sobrescribir datos personalizados (Sección 6).
  Future<void> asegurarPerfil() async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    final existente = await _client
        .from('profiles')
        .select('id')
        .eq('id', user.id)
        .maybeSingle();

    if (existente != null) return;

    await _client.from('profiles').insert({
      'id': user.id,
      'display_name': user.userMetadata?['full_name'] ??
          user.userMetadata?['name'] ??
          user.userMetadata?['display_name'] ??
          'Usuario',
      'bio': '',
    });
  }

  /// Solicita la eliminación completa de cuenta, archivos en Storage y metadatos (Secciones 10, 11 y 12).
  Future<void> solicitarEliminacion() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError('No hay una sesión activa para eliminar.');
    }
    final uid = user.id;

    // 1. Limpiar objetos del bucket privado 'task-attachments' en lotes de 100
    try {
      final rows = await _client
          .from('task_attachments')
          .select('storage_path')
          .eq('user_id', uid);
      final paths = (rows as List)
          .map((r) => r['storage_path'])
          .whereType<String>()
          .where((s) => s.isNotEmpty)
          .toList();

      for (var i = 0; i < paths.length; i += 100) {
        final end = (i + 100 < paths.length) ? i + 100 : paths.length;
        await _client.storage
            .from('task-attachments')
            .remove(paths.sublist(i, end));
      }
    } catch (_) {}

    // 2. Limpiar objetos del bucket 'avatars' bajo el prefijo del usuario
    try {
      await _client.storage.from('avatars').remove([
        '$uid/avatar.jpg',
        '$uid/avatar.png',
        '$uid/avatar.webp',
      ]);
    } catch (_) {}

    // 3. Invocar Edge Function 'delete-account' y/o función segura de servidor delete_own_account()
    bool deletedOnServer = false;
    try {
      final response = await _client.functions.invoke(
        'delete-account',
        method: HttpMethod.post,
      );
      if (response.status == 200) {
        deletedOnServer = true;
      }
    } catch (_) {
      // Si la Edge Function devuelve 404/501 en entorno gratuito, ejecutamos la función RPC SECURITY DEFINER verificada por JWT.
    }

    if (!deletedOnServer) {
      await _client.rpc('delete_own_account');
    }

    // 4. Cerrar sesión local únicamente tras confirmar la eliminación en el servidor
    try {
      await _client.auth.signOut();
    } catch (_) {}
  }

  /// Clasifica excepciones de red, Auth, PostgreSQL y Storage sin exponer datos sensibles (Sección 14).
  static String classifyError(Object error) {
    if (error is AuthException) {
      final msg = error.message.toLowerCase();
      if (msg.contains('invalid login credentials')) {
        return 'Autenticación: Correo o contraseña incorrectos.';
      }
      if (msg.contains('expired') || msg.contains('jwt')) {
        return 'Autenticación: Tu sesión ha expirado. Inicia sesión nuevamente.';
      }
      return 'Autenticación: ${error.message}';
    }
    if (error is PostgrestException) {
      if (error.code == '42501' ||
          error.message.toLowerCase().contains('row-level security')) {
        return 'Autorización (RLS): No tienes permiso para acceder o modificar este recurso.';
      }
      return 'Datos: No se pudo completar la operación en la base de datos (${error.message}).';
    }
    if (error is StorageException) {
      if (error.statusCode == '413' ||
          error.message.toLowerCase().contains('size')) {
        return 'Almacenamiento: El archivo supera el tamaño máximo permitido (15 MB).';
      }
      return 'Almacenamiento: ${error.message}';
    }
    if (error is FormatException || error is ArgumentError || error is StateError) {
      return 'Validación: $error';
    }
    final text = error.toString().toLowerCase();
    if (text.contains('socketexception') ||
        text.contains('failed host lookup') ||
        text.contains('network')) {
      return 'Conectividad: Sin conexión a internet. Verifica tu red e inténtalo de nuevo.';
    }
    return 'Error inesperado: No fue posible completar la solicitud.';
  }
}
