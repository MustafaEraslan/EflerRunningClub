class AppConfig {
  const AppConfig({required this.supabaseUrl, required this.anonKey});

  static const appId = 'efeler';
  final String supabaseUrl;
  final String anonKey;

  factory AppConfig.fromEnvironment() {
    const url = String.fromEnvironment('SUPABASE_URL');
    const key = String.fromEnvironment('SUPABASE_ANON_KEY');
    if (url.isEmpty || key.isEmpty) {
      throw StateError(
        'SUPABASE_URL ve SUPABASE_ANON_KEY --dart-define ile verilmelidir.',
      );
    }
    return const AppConfig(supabaseUrl: url, anonKey: key);
  }
}
