import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import 'auth_primary_button.dart';

/// Opens a bottom sheet with day / month / year wheels and resolves to the
/// chosen date, or null if dismissed.
///
/// Wheels replace the calendar grid deliberately: a birth date is ~20 years
/// back, which on a month grid means paging through hundreds of months. Three
/// spinning columns get there in a couple of flicks, and the sheet can never
/// produce a date past [latest] (the minimum-age cut-off).
Future<DateTime?> showBirthDateSheet(
  BuildContext context, {
  required DateTime initial,
  required DateTime earliest,
  required DateTime latest,
}) {
  return showModalBottomSheet<DateTime>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) =>
        _BirthDateSheet(initial: initial, earliest: earliest, latest: latest),
  );
}

class _BirthDateSheet extends StatefulWidget {
  const _BirthDateSheet({
    required this.initial,
    required this.earliest,
    required this.latest,
  });

  final DateTime initial;
  final DateTime earliest;
  final DateTime latest;

  @override
  State<_BirthDateSheet> createState() => _BirthDateSheetState();
}

class _BirthDateSheetState extends State<_BirthDateSheet> {
  late DateTime _selected = widget.initial;

  int _ageOn(DateTime birthDate, DateTime today) {
    var age = today.year - birthDate.year;
    final hadBirthday =
        today.month > birthDate.month ||
        (today.month == birthDate.month && today.day >= birthDate.day);
    return hadBirthday ? age : age - 1;
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final strings = AppStrings.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final localizations = MaterialLocalizations.of(context);
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    final sheetColor = isDark ? colors.secondaryNavy : const Color(0xFFFBF8F2);
    final age = _ageOn(_selected, DateTime.now());

    return Container(
      decoration: BoxDecoration(
        color: sheetColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      padding: EdgeInsets.fromLTRB(22, 10, 22, 18 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.textMuted.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 18),

          Text(
            strings.birthDate,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 21,
              fontWeight: FontWeight.w700,
              color: colors.primary,
            ),
          ),
          const SizedBox(height: 14),

          // Live read-out, so the choice is legible without parsing wheels.
          Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 160),
              child: Container(
                key: ValueKey(_selected),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: colors.accent.withValues(alpha: isDark ? 0.14 : 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${_selected.day} ${localizations.formatMonthYear(_selected)}'
                  '  ·  ${strings.ageYears(age)}',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: colors.darkGold,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          SizedBox(
            height: 210,
            child: CupertinoTheme(
              data: CupertinoThemeData(
                brightness: isDark ? Brightness.dark : Brightness.light,
                textTheme: CupertinoTextThemeData(
                  dateTimePickerTextStyle: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w600,
                    color: colors.text,
                  ),
                ),
              ),
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                dateOrder: DatePickerDateOrder.dmy,
                initialDateTime: widget.initial,
                minimumDate: widget.earliest,
                maximumDate: widget.latest,
                itemExtent: 42,
                onDateTimeChanged: (value) => setState(() => _selected = value),
              ),
            ),
          ),
          const SizedBox(height: 14),

          AuthPrimaryButton(
            label: strings.confirm,
            onPressed: () => Navigator.of(
              context,
            ).pop(DateTime(_selected.year, _selected.month, _selected.day)),
          ),
        ],
      ),
    );
  }
}
