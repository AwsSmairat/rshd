import 'package:flutter_test/flutter_test.dart';

import 'package:rshd/core/config/contact_settings.dart';

void main() {
  group('ContactSettings', () {
    test('mailto includes support email and default subject', () {
      final uri = ContactSettings.mailtoUri;

      expect(uri.scheme, 'mailto');
      expect(uri.path, ContactSettings.supportEmail);
      expect(uri.queryParameters['subject'], ContactSettings.emailSubject);
    });

    test('tel uses international phone number', () {
      final uri = ContactSettings.telUri;

      expect(uri.scheme, 'tel');
      expect(uri.path, ContactSettings.phoneInternational);
    });

    test('whatsapp uri encodes default message', () {
      final uri = ContactSettings.whatsappUri;

      expect(uri.host, 'wa.me');
      expect(uri.path, '/${ContactSettings.whatsappNumber}');
      expect(uri.queryParameters['text'], ContactSettings.whatsappMessage);
      expect(uri.toString(), startsWith('https://wa.me/962799532264?text='));
    });

    test('instagram handle strips @ from username', () {
      expect(ContactSettings.instagramHandle, 'rshdacademy');
      expect(
        ContactSettings.instagramAppUri.toString(),
        'instagram://user?username=rshdacademy',
      );
    });

    test('social urls match official endpoints', () {
      expect(
        ContactSettings.instagramWebUri.toString(),
        ContactSettings.instagramUrl,
      );
      expect(
        ContactSettings.facebookUri.toString(),
        ContactSettings.facebookUrl,
      );
    });
  });
}
