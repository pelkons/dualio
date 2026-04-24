class AppConfig {
  const AppConfig({
    required this.supabaseUrl,
    required this.supabaseAnonKey,
  });

  static const current = AppConfig(
    supabaseUrl: String.fromEnvironment('SUPABASE_URL'),
    supabaseAnonKey: String.fromEnvironment('SUPABASE_ANON_KEY'),
  );

  static const authRedirectUri = 'dualio://auth/callback';

  final String supabaseUrl;
  final String supabaseAnonKey;

  bool get hasSupabase {
    return supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
  }
}
