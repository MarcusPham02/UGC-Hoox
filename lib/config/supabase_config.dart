class SupabaseConfig {
  // These will come from your Supabase project dashboard.
  // For now, they're placeholders — replace them once your
  // Supabase project is created via the MCP or dashboard.
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://your-project.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'your-anon-key',
  );
}
