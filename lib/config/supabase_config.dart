// Pulls Supabase credentials from compile-time env vars.
// Run with --dart-define-from-file=.env.json so these get populated.
// I'm keeping secrets out of source — the .env.json file is gitignored.
class SupabaseConfig {
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const String siteUrl = String.fromEnvironment('SITE_URL');
}
