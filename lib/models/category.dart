class Category {
  const Category({
    this.id,
    required this.name,
  });

  final int? id;
  final String name;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as int?,
      name: map['name'] as String,
    );
  }

  factory Category.fromSupabase(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as int?,
      name: map['name'] as String,
    );
  }

  Map<String, dynamic> toSupabaseMap(String userId) {
    return {
      'user_id': userId,
      'name': name.trim(),
    };
  }
}
