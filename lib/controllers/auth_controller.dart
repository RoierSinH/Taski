import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';

class AuthController extends ChangeNotifier {
  AuthController(this._service);
  final AuthService _service;

  bool _loading = false;
  String? _error;

  bool get loading => _loading;
  String? get error => _error;
  User? get user => _service.currentUser;
  bool get isAuthenticated => user != null;

  Future<bool> signIn(String email, String password) async {
    if (_loading) return false;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await _service.signIn(email: email, password: password);
      try {
        await _service.asegurarPerfil();
      } catch (_) {}
      return true;
    } on AuthException catch (e) {
      _error = AuthService.classifyError(e);
      return false;
    } catch (e) {
      _error = AuthService.classifyError(e);
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> signUp(String email, String password) async {
    if (_loading) return false;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final response = await _service.signUp(email: email, password: password);
      try {
        await _service.asegurarPerfil();
      } catch (_) {}
      return response.user != null;
    } on AuthException catch (e) {
      _error = AuthService.classifyError(e);
      return false;
    } catch (e) {
      _error = AuthService.classifyError(e);
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> signInWithGoogle() async {
    if (_loading) return false;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final launched = await _service.signInWithGoogle();
      return launched;
    } on AuthException catch (e) {
      _error = 'No fue posible iniciar sesión con Google: ${e.message}';
      return false;
    } catch (e) {
      _error = AuthService.classifyError(e);
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteAccount() async {
    if (_loading) return false;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await _service.solicitarEliminacion();
      return true;
    } catch (e) {
      _error = AuthService.classifyError(e);
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    _loading = true;
    notifyListeners();
    try {
      await _service.signOut();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
