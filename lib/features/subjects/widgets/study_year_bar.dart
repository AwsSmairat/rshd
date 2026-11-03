import 'package:flutter/material.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/widgets/pill_choice_bar.dart';

/// Horizontal chips to filter medicine courses by study year (1–6);
/// `null` means all years.
class StudyYearBar extends StatelessWidget {
  const StudyYearBar({
    super.key,
    required this.selected,
    required this.onChanged,
    this.years = 6,
  });

  final int? selected;
  final ValueChanged<int?> onChanged;
  final int years;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return PillChoiceBar<int?>(
      selected: selected,
      onChanged: onChanged,
      choices: [
        PillChoice<int?>(null, strings.allYears),
        for (var y = 1; y <= years; y++)
          PillChoice<int?>(y, strings.studyYearLabel(y)),
      ],
    );
  }
}
