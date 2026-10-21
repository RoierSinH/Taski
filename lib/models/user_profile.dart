class UserProfile {
  const UserProfile({
    required this.id,
    required this.email,
    this.displayName,
    this.avatarUrl,
    this.bio,
  });

  static const int maxBioLength = 120;

  final String id;
  final String email;
  final String? displayName;
  final String? avatarUrl;
  final String? bio;

  /// Valida que la biografía opcional no exceda los 120 caracteres (Reto 7).
  /// Devuelve `null` si es válida, o un mensaje de error si excede el límite.
  static String? validateBio(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Es opcional
    }
    if (value.length > maxBioLength) {
      return 'La biografía no puede superar los $maxBioLength caracteres';
    }
    return null;
  }

  UserProfile copyWith({
    String? id,
    String? email,
    String? displayName,
    String? avatarUrl,
    String? bio,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
    );
  }

  factory UserProfile.fromMap(
    Map<String, dynamic> map,
    String email,
  ) {
    return UserProfile(
      id: map['id'] as String,
      email: email,
      displayName: map['display_name'] as String?,
      avatarUrl: map['avatar_url'] as String?,
      bio: map['bio'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'display_name': displayName,
      'avatar_url': avatarUrl,
      'bio': bio,
    };
  }
}
