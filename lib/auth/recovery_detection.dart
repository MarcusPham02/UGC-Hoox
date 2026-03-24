/// Parses a URL to detect a password recovery redirect via token hash.
///
/// Supabase email templates link to `/auth/confirm` with query params:
///   /auth/confirm?token_hash=xxx&type=recovery&next=/reset-password
/// This function extracts the token hash and detects recovery redirects.
({String? tokenHash, String? type, bool isPasswordRecovery})
    detectRecoveryFromUrl(Uri uri) {
  if (!uri.path.endsWith('/auth/confirm')) {
    return (tokenHash: null, type: null, isPasswordRecovery: false);
  }
  final tokenHash = uri.queryParameters['token_hash'];
  final type = uri.queryParameters['type'];
  final isRecovery = tokenHash != null && type == 'recovery';
  return (tokenHash: tokenHash, type: type, isPasswordRecovery: isRecovery);
}
