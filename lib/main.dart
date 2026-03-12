import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';
import 'config/supabase_config.dart';

// App entry point — initialize Supabase before anything else, then launch.
Future<void> main() async {
  // Need this before any async calls in main
  WidgetsFlutterBinding.ensureInitialized();

  // Connect to Supabase using credentials from compile-time env vars
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );

  runApp(const HooksApp());
}
