import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config/contact_settings.dart';

/// Opens official RSHD contact channels via platform handlers.
class ContactLauncher {
  ContactLauncher._();

  static const String launchFailedMessage =
      'تعذر فتح الرابط. يرجى المحاولة لاحقاً.';

  static Future<void> openEmail(BuildContext context) async {
    final launched = await _launch(
      ContactSettings.mailtoUri,
      failureMessage: 'تعذر فتح تطبيق البريد',
    );
    if (!launched && context.mounted) {
      _showError(context, 'تعذر فتح تطبيق البريد');
    }
  }

  static Future<void> openInstagram(BuildContext context) async {
    var launched = await _launch(
      ContactSettings.instagramAppUri,
      mode: LaunchMode.externalApplication,
    );
    if (!launched) {
      launched = await _launch(
        ContactSettings.instagramWebUri,
        mode: LaunchMode.externalApplication,
      );
    }
    if (!launched && context.mounted) {
      _showError(context);
    }
  }

  static Future<void> openFacebook(BuildContext context) async {
    final launched = await _launch(
      ContactSettings.facebookUri,
      mode: LaunchMode.externalApplication,
      failureMessage: 'تعذر فتح فيسبوك',
    );
    if (!launched && context.mounted) {
      _showError(context, 'تعذر فتح فيسبوك');
    }
  }

  static Future<void> openPhone(BuildContext context) async {
    final launched = await _launch(ContactSettings.telUri);
    if (!launched && context.mounted) {
      _showError(context, 'تعذر فتح تطبيق الاتصال');
    }
  }

  static Future<void> openWhatsApp(BuildContext context) async {
    final launched = await _launch(
      ContactSettings.whatsappUri,
      mode: LaunchMode.externalApplication,
      failureMessage: 'تعذر فتح واتساب',
    );
    if (!launched && context.mounted) {
      _showError(context, 'تعذر فتح واتساب');
    }
  }

  static Future<bool> _launch(
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

  static void _showError(BuildContext context, [String? message]) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message ?? launchFailedMessage)),
    );
  }
}
