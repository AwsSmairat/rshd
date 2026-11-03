import 'package:flutter/material.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/widgets/app_page_header.dart';

/// Page header in the app's light style (see [AppPageHeader]).
class LuxuryAssignmentHeader extends StatelessWidget {
  const LuxuryAssignmentHeader({
    super.key,
    required this.title,
    this.watermarkIcon = Icons.assignment_outlined,
  });

  final String title;

  /// No longer drawn; kept so existing call sites compile unchanged.
  final IconData watermarkIcon;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return AppPageHeader(title: strings.t(title));
  }
}
