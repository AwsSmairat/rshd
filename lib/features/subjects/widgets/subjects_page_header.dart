import 'package:flutter/material.dart';

import '../../../core/widgets/app_page_header.dart';

/// Kept for existing call sites; the page title block now lives in core.
class SubjectsPageHeader extends StatelessWidget {
  const SubjectsPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.onBack,
  });

  final String title;
  final String? subtitle;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) =>
      PageTitleBlock(title: title, subtitle: subtitle, onBack: onBack);
}
