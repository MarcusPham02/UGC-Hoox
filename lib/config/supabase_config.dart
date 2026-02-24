class SupabaseConfig {
  // Passed at build time via --dart-define-from-file=.env.json
  // Never hardcode real keys here.
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
}
