import 'package:flutter_test/flutter_test.dart';
import 'package:rshd/core/config/release_environment_guard.dart';

void main() {
  group('ReleaseEnvironmentGuard.isProductionSafeUrl', () {
    test('accepts https production hosts', () {
      expect(
        ReleaseEnvironmentGuard.isProductionSafeUrl(
          'https://api.example.com/api/v1',
        ),
        isTrue,
      );
      expect(
        ReleaseEnvironmentGuard.isProductionSafeUrl(
          'https://api.rshd.test/api/v1',
        ),
        isTrue,
      );
    });

    test('rejects localhost, emulator, and cleartext URLs', () {
      expect(
        ReleaseEnvironmentGuard.isProductionSafeUrl(
          'http://127.0.0.1:8765/api/v1',
        ),
        isFalse,
      );
      expect(
        ReleaseEnvironmentGuard.isProductionSafeUrl(
          'http://localhost:8765/api/v1',
        ),
        isFalse,
      );
      expect(
        ReleaseEnvironmentGuard.isProductionSafeUrl(
          'http://10.0.2.2:8765/api/v1',
        ),
        isFalse,
      );
      const localhostHttps = 'https://localhost/api/v1';
      expect(
        ReleaseEnvironmentGuard.isProductionSafeUrl(localhostHttps),
        isFalse,
      );
    });

    test('allows https staging hosts for release-mode QA', () {
      expect(
        ReleaseEnvironmentGuard.isProductionSafeUrl(
          'https://staging-api.example.com/api/v1',
        ),
        isTrue,
      );
    });
  });
}
