import 'package:flutter_test/flutter_test.dart';
import 'package:rshd/core/config/release_environment_guard.dart';
import 'package:rshd/core/security/safe_external_url.dart';

void main() {
  group('ReleaseEnvironmentGuard', () {
    test('accepts production https API URL', () {
      expect(
        ReleaseEnvironmentGuard.isProductionSafeUrl(
          'https://api.rshd.test/api/v1',
        ),
        isTrue,
      );
    });

    test('rejects localhost and cleartext URLs', () {
      expect(
        ReleaseEnvironmentGuard.isProductionSafeUrl(
          'http://127.0.0.1:8765/api/v1',
        ),
        isFalse,
      );
      expect(
        ReleaseEnvironmentGuard.isProductionSafeUrl('https://10.0.2.2/api/v1'),
        isFalse,
      );
    });
  });

  group('SafeExternalUrl', () {
    test('blocks dangerous launcher schemes', () {
      expect(
        SafeExternalUrl.isLaunchAllowed(Uri.parse('javascript:alert(1)')),
        isFalse,
      );
      expect(
        SafeExternalUrl.isLaunchAllowed(Uri.parse('file:///etc/passwd')),
        isFalse,
      );
    });

    test('allows https mailto and tel', () {
      expect(
        SafeExternalUrl.isLaunchAllowed(Uri.parse('https://rshd.test')),
        isTrue,
      );
      expect(
        SafeExternalUrl.isLaunchAllowed(Uri.parse('mailto:support@rshd.test')),
        isTrue,
      );
      expect(
        SafeExternalUrl.isLaunchAllowed(Uri.parse('tel:+962700000000')),
        isTrue,
      );
    });

    test('allows bunny embed webview hosts only', () {
      expect(
        SafeExternalUrl.isWebViewNavigationAllowed(
          Uri.parse('https://iframe.mediadelivery.net/embed/123'),
        ),
        isTrue,
      );
      expect(
        SafeExternalUrl.isWebViewNavigationAllowed(
          Uri.parse('https://evil.example/phish'),
        ),
        isFalse,
      );
      expect(
        SafeExternalUrl.isWebViewNavigationAllowed(Uri.parse('about:blank')),
        isTrue,
      );
    });
  });
}
