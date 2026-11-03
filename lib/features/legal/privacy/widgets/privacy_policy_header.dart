import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/widgets/app_page_header.dart';

/// Page header in the app's light style (see [AppPageHeader]).
class PrivacyPolicyHeader extends StatelessWidget {
  const PrivacyPolicyHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.lastUpdated,
  });

  final String title;
  final String subtitle;
  final String lastUpdated;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return AppPageHeader(
      title: strings.t(title),
      subtitle: [
        if (subtitle.isNotEmpty) strings.t(subtitle),
        if (lastUpdated.isNotEmpty) strings.t('آخر تحديث: $lastUpdated'),
      ].join('\n'),
    );
  }
}
