/// Official RSHD contact channels — single source of truth for the app.
class ContactSettings {
  ContactSettings._();

  static const String supportEmail = 'Rshdacademy@gmail.com';

  static const String emailSubject = 'استفسار من تطبيق RSHD';

  static const String instagramUsername = '@rshdacademy';

  static const String instagramUrl = 'https://www.instagram.com/rshdacademy/';

  static const String facebookDisplayName = 'RSHD Academy';

  static const String facebookUrl =
      'https://www.facebook.com/share/1RFgoDFN8Q/?mibextid=wwXIfr';

  static const String phoneDisplay = '0799532264';

  static const String phoneInternational = '+962799532264';

  static const String whatsappNumber = '962799532264';

  static const String whatsappMessage = 'مرحبًا، لدي استفسار بخصوص منصة RSHD.';

  static String get instagramHandle => instagramUsername.replaceFirst('@', '');

  static Uri get mailtoUri => Uri(
    scheme: 'mailto',
    path: supportEmail,
    queryParameters: {'subject': emailSubject},
  );

  static Uri get telUri => Uri(scheme: 'tel', path: phoneInternational);

  static Uri get whatsappUri =>
      Uri.https('wa.me', whatsappNumber, {'text': whatsappMessage});

  static Uri get instagramWebUri => Uri.parse(instagramUrl);

  static Uri get instagramAppUri =>
      Uri.parse('instagram://user?username=$instagramHandle');

  static Uri get facebookUri => Uri.parse(facebookUrl);
}
