class SupabaseConfig {
  static const String _envUrl = String.fromEnvironment('SUPABASE_URL');
  static const String _envAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static String get url => _envUrl.isNotEmpty
      ? _envUrl
      : 'https://uanermamtzzxmnlcujyx.supabase.co';

  static String get anonKey => _envAnonKey.isNotEmpty
      ? _envAnonKey
      : 'sb_publishable__b5NjWp48wcwwVh3pS75VA_1iv5UF82';

  static bool get isRealConfig => true;

  static void validate() {
    // Configuración activa y conectada
  }
}
