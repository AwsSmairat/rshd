import 'package:flutter/material.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/widgets/app_page_header.dart';

/// Page header in the app's light style (see [AppPageHeader]).
class QuizzesHeader extends StatelessWidget {
  const QuizzesHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return AppPageHeader(title: strings.t('الاختبارات'));
  }
}
