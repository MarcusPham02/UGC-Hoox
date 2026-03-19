import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';
import 'config/supabase_config.dart';

// App entry point — initialize Supabase before anything else, then launch.
Future<void> main() async {
  // Need this before any async calls in main
  WidgetsFlutterBinding.ensureInitialized();

  // On web with implicit flow, the password recovery redirect lands with
  // tokens in the URL hash (e.g. #access_token=...&type=recovery).
  // Detect this BEFORE Supabase.initialize() processes and clears the hash.
  bool isPasswordRecovery = false;
  if (kIsWeb) {
    final fragment = Uri.base.fragment;
    isPasswordRecovery = fragment.contains('type=recovery');
  }

  // Connect to Supabase using credentials from compile-time env vars.
  // Use implicit auth flow on web — tokens arrive in the URL hash and the
  // SDK handles session setup automatically. This avoids the PKCE
  // code_verifier problem where the verifier stored in localStorage during
  // resetPasswordForEmail is unavailable if the origin (port) changes
  // between the email send and the redirect landing.
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
    authOptions: FlutterAuthClientOptions(
      authFlowType: kIsWeb ? AuthFlowType.implicit : AuthFlowType.pkce,
    ),
  );

  runApp(HooksApp(isPasswordRecovery: isPasswordRecovery));
}
