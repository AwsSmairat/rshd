import 'package:flutter/material.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/widgets/app_page_header.dart';

/// Page header in the app's light style (see [AppPageHeader]).
class SubjectsHeader extends StatelessWidget {
  const SubjectsHeader({
    super.key,
    required this.title,
    this.showBackButton = true,
    this.backgroundIcon = Icons.menu_book_outlined,
  });

  final String title;
  final bool showBackButton;

  /// No longer drawn; kept so existing call sites compile unchanged.
  final IconData backgroundIcon;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return AppPageHeader(
      title: strings.t(title),
      showBackButton: showBackButton,
    );
  }
}
