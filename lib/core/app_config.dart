class AppConfig {
  static const _supabaseUrlRaw = String.fromEnvironment('SUPABASE_URL');
  static const supabaseKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

  static String get supabaseUrl {
    final value = _supabaseUrlRaw.trim();
    if (value.endsWith('/')) return value.substring(0, value.length - 1);
    return value;
  }

  static bool get hasSupabase =>
      supabaseUrl.isNotEmpty &&
      supabaseUrl.startsWith('https://') &&
      supabaseUrl.contains('.supabase.co') &&
      supabaseKey.trim().isNotEmpty;
}
