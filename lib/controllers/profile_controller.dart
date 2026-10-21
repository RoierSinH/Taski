import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user_profile.dart';
import '../services/profile_service.dart';

class ProfileController extends ChangeNotifier {
  ProfileController(this._service);

  final ProfileRepository _service;

  UserProfile? _profile;
  bool _loading = false;
  String? _error;

  UserProfile? get profile => _profile;
  bool get loading => _loading;
  String? get error => _error;

  String? validateBio(String? bio) {
    return UserProfile.validateBio(bio);
  }

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await _service.ensureProfile();
      _profile = await _service.getProfile();
    } catch (e) {
      _error = 'No fue posible cargar el perfil';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> changeName(String name) async {
    await _service.updateDisplayName(name);
    await load();
  }

  Future<bool> changeBio(String bio) async {
    final validationError = validateBio(bio);
    if (validationError != null) {
      _error = validationError;
      notifyListeners();
      return false;
    }

    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await _service.updateBio(bio);
      await load();
      return true;
    } catch (_) {
      _error = 'No fue posible actualizar la biografía';
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> saveProfile({
    required String displayName,
    required String bio,
  }) async {
    final validationError = validateBio(bio);
    if (validationError != null) {
      _error = validationError;
      notifyListeners();
      return false;
    }

    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await _service.updateProfile(
        displayName: displayName,
        bio: bio,
      );
      await load();
      return true;
    } catch (_) {
      _error = 'No fue posible guardar los cambios del perfil';
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> changeAvatar(XFile image) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await _service.changeAvatar(image);
      await load();
    } catch (_) {
      _error = 'No fue posible actualizar la fotografía';
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> pickAndChangeAvatar() async {
    final image = await _service.pickAvatar();
    if (image == null) return;
    await changeAvatar(image);
  }
}
