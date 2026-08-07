import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'data/contact_channels.dart';

/// Opens RSHD contact channels via platform handlers.
class ContactLauncher {
  ContactLauncher(this.channels);

  final ContactChannels channels;

  static const String launchFailedMessage =
      'تعذر فتح الرابط. يرجى المحاولة لاحقاً.';

  Future<void> openEmail(BuildContext context) async {
    await _openUri(
      context,
      channels.mailtoUri,
      unavailableMessage: 'البريد الإلكتروني غير متوفر',
      failureMessage: 'تعذر فتح تطبيق البريد',
    );
  }

  Future<void> openWebsite(BuildContext context) async {
    await _openUri(
      context,
      channels.websiteUri,
      unavailableMessage: 'رابط الموقع غير متوفر',
      failureMessage: 'تعذر فتح الموقع',
      external: true,
    );
  }

  Future<void> openInstagram(BuildContext context) async {
    if (!channels.hasInstagram) {
      _showError(context, 'رابط إنستغرام غير متوفر');
      return;
    }

    var launched = false;
    final appUri = channels.instagramAppUri;
    if (appUri != null) {
      launched = await _launch(
        appUri,
        mode: LaunchMode.externalApplication,
      );
    }
    if (!launched) {
      await _openUri(
        context,
        channels.instagramWebUri,
        unavailableMessage: 'رابط إنستغرام غير متوفر',
        external: true,
      );
    }
  }

  Future<void> openFacebook(BuildContext context) async {
    await _openUri(
      context,
      channels.facebookUri,
      unavailableMessage: 'رابط فيسبوك غير متوفر',
      failureMessage: 'تعذر فتح فيسبوك',
      external: true,
    );
  }

  Future<void> openYoutube(BuildContext context) async {
    await _openUri(
      context,
      channels.youtubeUri,
      unavailableMessage: 'رابط يوتيوب غير متوفر',
      failureMessage: 'تعذر فتح يوتيوب',
      external: true,
    );
  }

  Future<void> openLinkedin(BuildContext context) async {
    await _openUri(
      context,
      channels.linkedinUri,
      unavailableMessage: 'رابط لينكدإن غير متوفر',
      failureMessage: 'تعذر فتح لينكدإن',
      external: true,
    );
  }

  Future<void> openPhone(BuildContext context) async {
    await _openUri(
      context,
      channels.telUri,
      unavailableMessage: 'رقم الهاتف غير متوفر',
      failureMessage: 'تعذر فتح تطبيق الاتصال',
    );
  }

  Future<void> openWhatsApp(BuildContext context) async {
    await _openUri(
      context,
      channels.whatsappUri,
      unavailableMessage: 'رقم واتساب غير متوفر',
      failureMessage: 'تعذر فتح واتساب',
      external: true,
    );
  }

  Future<void> _openUri(
    BuildContext context,
    Uri? uri, {
    required String unavailableMessage,
    String? failureMessage,
    bool external = false,
  }) async {
    if (uri == null) {
      _showError(context, unavailableMessage);
      return;
    }

    final launched = await _launch(
      uri,
      mode: external ? LaunchMode.externalApplication : LaunchMode.platformDefault,
      failureMessage: failureMessage,
    );
    if (!launched && context.mounted) {
      _showError(context, failureMessage);
    }
  }

  Future<bool> _launch(
    Uri uri, {
    LaunchMode mode = LaunchMode.platformDefault,
    String? failureMessage,
  }) async {
    if (kDebugMode) {
      debugPrint('ContactLauncher: attempting ${uri.scheme} link');
    }

    try {
      if (!await canLaunchUrl(uri)) {
        if (kDebugMode && failureMessage != null) {
          debugPrint('ContactLauncher: canLaunchUrl=false');
        }
        return false;
      }
      return await launchUrl(uri, mode: mode);
    } catch (error) {
      if (kDebugMode) {
        debugPrint('ContactLauncher: launch failed ($error)');
      }
      return false;
    }
  }

  void _showError(BuildContext context, [String? message]) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message ?? launchFailedMessage)),
    );
  }
}
