import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';
import 'auth/recovery_detection.dart';
import 'config/supabase_config.dart';
import 'utils/clear_url_stub.dart'
    if (dart.library.js_interop) 'utils/clear_url_web.dart';

// App entry point — initialize Supabase before anything else, then launch.
Future<void> main() async {
  // Need this before any async calls in main
  WidgetsFlutterBinding.ensureInitialized();

  // On web, Supabase password reset emails link to
  // /auth/confirm?token_hash=xxx&type=recovery&next=/reset-password.
  // Detect the token hash and recovery flag BEFORE Supabase.initialize()
  // processes the URL.
  String? tokenHash;
  bool isPasswordRecovery = false;
  if (kIsWeb) {
    final result = detectRecoveryFromUrl(Uri.base);
    tokenHash = result.tokenHash;
    isPasswordRecovery = result.isPasswordRecovery;
  }

  // Connect to Supabase using credentials from compile-time env vars.
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );

  // Verify the token hash to establish a session for the recovery flow.
  if (tokenHash != null) {
    try {
      await Supabase.instance.client.auth.verifyOTP(
        tokenHash: tokenHash,
        type: OtpType.recovery,
      );
    } catch (e) {
      debugPrint('Failed to verify OTP: $e');
    }
    // Remove sensitive token params from browser URL/history.
    clearSensitiveUrlParams();
  }

  runApp(HooksApp(isPasswordRecovery: isPasswordRecovery));
}
