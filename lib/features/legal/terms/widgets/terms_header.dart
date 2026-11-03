import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/widgets/app_page_header.dart';

/// Page header in the app's light style (see [AppPageHeader]).
class TermsHeader extends StatelessWidget {
  const TermsHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.version,
    required this.lastUpdated,
  });

  final String title;
  final String subtitle;
  final String version;
  final String lastUpdated;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final meta = [
      if (version.isNotEmpty) strings.t('الإصدار: $version'),
      if (lastUpdated.isNotEmpty) strings.t('آخر تحديث: $lastUpdated'),
    ].join(' · ');
    return AppPageHeader(
      title: strings.t(title),
      subtitle: [
        if (subtitle.isNotEmpty) strings.t(subtitle),
        if (meta.isNotEmpty) meta,
      ].join('\n'),
    );
  }
}
