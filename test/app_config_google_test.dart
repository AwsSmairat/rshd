import 'package:flutter_test/flutter_test.dart';
import 'package:rshd/core/config/app_config.dart';

void main() {
  group('AppConfig Google client validation', () {
    test('rejects placeholder client ids', () {
      expect(
        AppConfig.isValidGoogleClientId(
          'YOUR_WEB_CLIENT_ID.apps.googleusercontent.com',
        ),
        isFalse,
      );
      expect(
        AppConfig.isValidGoogleClientId(
          'YOUR_IOS_CLIENT_ID.apps.googleusercontent.com',
        ),
        isFalse,
      );
    });

    test('accepts real-looking client ids', () {
      const iosId =
          '479882132969-9i9aqik3jfjd7qhci1nqf0bm2g71rm1u.apps.googleusercontent.com';

      expect(AppConfig.isValidGoogleClientId(iosId), isTrue);
      expect(
        AppConfig.reversedIosClientId(iosId),
        'com.googleusercontent.apps.479882132969-9i9aqik3jfjd7qhci1nqf0bm2g71rm1u',
      );
    });
  });
}
