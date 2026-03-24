import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_app/auth/recovery_detection.dart';

void main() {
  group('detectRecoveryFromUrl', () {
    test('detects recovery on /auth/confirm with token_hash and type=recovery',
        () {
      final uri = Uri.parse(
        'http://localhost:3000/auth/confirm?token_hash=abc123&type=recovery&next=/reset-password',
      );
      final result = detectRecoveryFromUrl(uri);

      expect(result.tokenHash, 'abc123');
      expect(result.type, 'recovery');
      expect(result.isPasswordRecovery, true);
    });

    test('returns token_hash but not recovery when type is not recovery', () {
      final uri = Uri.parse(
        'http://localhost:3000/auth/confirm?token_hash=abc123&type=signup',
      );
      final result = detectRecoveryFromUrl(uri);

      expect(result.tokenHash, 'abc123');
      expect(result.type, 'signup');
      expect(result.isPasswordRecovery, false);
    });

    test('returns no recovery when path is not /auth/confirm', () {
      final uri = Uri.parse(
        'http://localhost:3000/reset-password?token_hash=abc123&type=recovery',
      );
      final result = detectRecoveryFromUrl(uri);

      expect(result.tokenHash, isNull);
      expect(result.type, isNull);
      expect(result.isPasswordRecovery, false);
    });

    test('returns no recovery when token_hash is missing', () {
      final uri = Uri.parse(
        'http://localhost:3000/auth/confirm?type=recovery',
      );
      final result = detectRecoveryFromUrl(uri);

      expect(result.tokenHash, isNull);
      expect(result.type, 'recovery');
      expect(result.isPasswordRecovery, false);
    });

    test('returns no recovery for plain URL', () {
      final uri = Uri.parse('http://localhost:3000/');
      final result = detectRecoveryFromUrl(uri);

      expect(result.tokenHash, isNull);
      expect(result.type, isNull);
      expect(result.isPasswordRecovery, false);
    });
  });
}
