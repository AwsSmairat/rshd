import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'data/help_center_model.dart';
import '../../core/l10n/app_strings.dart';

Future<void> launchHelpEmail({
  required String email,
  required String subject,
  String? body,
  BuildContext? context,
}) async {
  if (email.isEmpty) {
    if (context != null && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppStrings.of(context).t('بريد التواصل غير متوفر'))));
    }
    return;
  }

  final params = <String, String>{'subject': subject};
  if (body != null && body.isNotEmpty) {
    params['body'] = body;
  }

  final uri = Uri(scheme: 'mailto', path: email, queryParameters: params);
  final launched = await launchUrl(uri);
  if (!launched && context != null && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppStrings.of(context).t(email))));
  }
}

void contactTeacher({
  required BuildContext context,
  required TeacherContactModel teacher,
  required String supportEmail,
}) {
  final email = teacher.contactViaSupport || teacher.contactEmail == null
      ? supportEmail
      : teacher.contactEmail!;

  final subject = teacher.contactViaSupport
      ? 'استفسار للمدرس ${teacher.instructorName} — ${teacher.subjectTitle}'
      : 'استفسار بخصوص مادة ${teacher.subjectTitle}';

  final body = teacher.contactViaSupport
      ? 'مرحباً،\n\nأود التواصل مع المدرس ${teacher.instructorName} بخصوص مادة «${teacher.subjectTitle}».\n\n'
      : 'مرحباً ${teacher.instructorName}،\n\n';

  launchHelpEmail(email: email, subject: subject, body: body, context: context);
}

void contactTechnicalSupport({
  required BuildContext context,
  required String supportEmail,
}) {
  launchHelpEmail(
    email: supportEmail,
    subject: 'طلب دعم فني — RSHD',
    body: 'مرحباً،\n\nأحتاج مساعدة بخصوص:\n\n',
    context: context,
  );
}
