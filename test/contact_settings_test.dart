import 'package:flutter_test/flutter_test.dart';

import 'package:rshd/features/contact/data/contact_channels.dart';

void main() {
  group('ContactChannels', () {
    test('shows placeholder when values are missing', () {
      const channels = ContactChannels();

      expect(channels.displayFor(channels.email), 'لم يضاف بعد');
      expect(channels.websiteDisplay, 'لم يضاف بعد');
      expect(channels.youtubeDisplay, 'لم يضاف بعد');
      expect(channels.linkedinDisplay, 'لم يضاف بعد');
      expect(channels.hasWebsite, isFalse);
    });

    test('uses API values when provided', () {
      const channels = ContactChannels(
        email: 'new@example.com',
        phone: '0799000000',
        websiteUrl: 'https://rshdacademy.com',
        instagramUrl: 'https://www.instagram.com/newpage/',
        facebookUrl: 'https://facebook.com/newpage',
        youtubeUrl: 'https://youtube.com/@rshd',
        linkedinUrl: 'https://linkedin.com/company/rshd',
        whatsappNumber: '962790000000',
      );

      expect(channels.email, 'new@example.com');
      expect(channels.instagramDisplay, '@newpage');
      expect(channels.websiteDisplay, 'rshdacademy.com');
      expect(channels.youtubeDisplay, 'youtube.com/@rshd');
      expect(channels.linkedinDisplay, 'linkedin.com/company/rshd');
      expect(channels.mailtoUri?.path, 'new@example.com');
      expect(channels.websiteUri?.toString(), 'https://rshdacademy.com');
      expect(channels.youtubeUri?.toString(), 'https://youtube.com/@rshd');
      expect(channels.linkedinUri?.toString(), 'https://linkedin.com/company/rshd');
    });

    test('fromJson keeps empty values without fallback', () {
      final channels = ContactChannels.fromJson({
        'email': 'contact@rshd.com',
        'website_url': '',
        'youtube_url': null,
      });

      expect(channels.email, 'contact@rshd.com');
      expect(channels.hasWebsite, isFalse);
      expect(channels.hasYoutube, isFalse);
      expect(channels.websiteDisplay, 'لم يضاف بعد');
    });
  });
}
