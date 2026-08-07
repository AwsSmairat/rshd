import '../../../core/config/contact_settings.dart';

/// Contact channels loaded from backend public settings.
class ContactChannels {
  const ContactChannels({
    this.email,
    this.phone,
    this.websiteUrl,
    this.facebookUrl,
    this.instagramUrl,
    this.youtubeUrl,
    this.linkedinUrl,
    this.whatsappNumber,
  });

  factory ContactChannels.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const ContactChannels();
    }

    return ContactChannels(
      email: _clean(json['email']),
      phone: _clean(json['phone']),
      websiteUrl: _clean(json['website_url']),
      facebookUrl: _clean(json['facebook_url']),
      instagramUrl: _clean(json['instagram_url']),
      youtubeUrl: _clean(json['youtube_url']),
      linkedinUrl: _clean(json['linkedin_url']),
      whatsappNumber: _clean(json['whatsapp_number']),
    );
  }

  static const empty = ContactChannels();

  final String? email;
  final String? phone;
  final String? websiteUrl;
  final String? facebookUrl;
  final String? instagramUrl;
  final String? youtubeUrl;
  final String? linkedinUrl;
  final String? whatsappNumber;

  bool get hasEmail => _hasValue(email);
  bool get hasPhone => _hasValue(phone);
  bool get hasWebsite => _hasValue(websiteUrl);
  bool get hasFacebook => _hasValue(facebookUrl);
  bool get hasInstagram => _hasValue(instagramUrl);
  bool get hasYoutube => _hasValue(youtubeUrl);
  bool get hasLinkedin => _hasValue(linkedinUrl);
  bool get hasWhatsapp => _hasValue(whatsappNumber);

  String get emailSubject => ContactSettings.emailSubject;

  String get whatsappMessage => ContactSettings.whatsappMessage;

  String displayFor(String? value) =>
      _hasValue(value) ? value!.trim() : 'لم يضاف بعد';

  String get instagramDisplay {
    if (!hasInstagram) {
      return 'لم يضاف بعد';
    }

    final handle = _instagramHandle(instagramUrl);
    if (handle != null) {
      return '@$handle';
    }

    return _shortUrl(instagramUrl!);
  }

  String get facebookDisplay =>
      hasFacebook ? _shortUrl(facebookUrl!) : 'لم يضاف بعد';

  String get websiteDisplay =>
      hasWebsite ? _shortUrl(websiteUrl!) : 'لم يضاف بعد';

  String get youtubeDisplay =>
      hasYoutube ? _shortUrl(youtubeUrl!) : 'لم يضاف بعد';

  String get linkedinDisplay =>
      hasLinkedin ? _shortUrl(linkedinUrl!) : 'لم يضاف بعد';

  String get phoneDisplay => displayFor(phone);

  String get whatsappDisplay => displayFor(whatsappNumber);

  Uri? get mailtoUri {
    if (!hasEmail) {
      return null;
    }

    return Uri(
      scheme: 'mailto',
      path: email!.trim(),
      queryParameters: {'subject': emailSubject},
    );
  }

  Uri? get telUri {
    if (!hasPhone) {
      return null;
    }

    return Uri(scheme: 'tel', path: _normalizePhone(phone!));
  }

  Uri? get whatsappUri {
    final digits = _whatsappDigits(whatsappNumber);
    if (digits == null) {
      return null;
    }

    return Uri.https('wa.me', digits, {'text': whatsappMessage});
  }

  Uri? get instagramWebUri => _externalUri(instagramUrl);

  Uri? get instagramAppUri {
    final handle = _instagramHandle(instagramUrl);
    if (handle == null) {
      return null;
    }

    return Uri.parse('instagram://user?username=$handle');
  }

  Uri? get facebookUri => _externalUri(facebookUrl);

  Uri? get websiteUri => _externalUri(websiteUrl);

  Uri? get youtubeUri => _externalUri(youtubeUrl);

  Uri? get linkedinUri => _externalUri(linkedinUrl);

  static bool _hasValue(String? value) =>
      value != null && value.trim().isNotEmpty;

  static String? _clean(dynamic value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) {
      return null;
    }
    return text;
  }

  static Uri? _externalUri(String? value) {
    if (!_hasValue(value)) {
      return null;
    }

    return Uri.tryParse(value!.trim());
  }

  static String _shortUrl(String value) {
    final uri = Uri.tryParse(value);
    if (uri == null) {
      return value;
    }

    final host = uri.host.replaceFirst(RegExp(r'^www\.'), '');
    final path = uri.pathSegments.where((part) => part.isNotEmpty).join('/');
    if (path.isEmpty) {
      return host;
    }

    return '$host/$path';
  }

  static String? _instagramHandle(String? url) {
    if (!_hasValue(url)) {
      return null;
    }

    final uri = Uri.tryParse(url!);
    if (uri == null) {
      return null;
    }

    final segments = uri.pathSegments.where((part) => part.isNotEmpty).toList();
    if (segments.isEmpty) {
      return null;
    }

    return segments.last.replaceAll('@', '');
  }

  static String _normalizePhone(String value) {
    final trimmed = value.trim();
    if (trimmed.startsWith('+')) {
      return trimmed;
    }

    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('962')) {
      return '+$digits';
    }
    if (digits.startsWith('0')) {
      return '+962${digits.substring(1)}';
    }
    return trimmed;
  }

  static String? _whatsappDigits(String? value) {
    if (!_hasValue(value)) {
      return null;
    }

    final digits = value!.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) {
      return null;
    }

    if (digits.startsWith('962')) {
      return digits;
    }
    if (digits.startsWith('0')) {
      return '962${digits.substring(1)}';
    }

    return digits;
  }
}
