import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Opens the birth-date sheet and returns the chosen date, or null if the
/// student cancelled.
Future<DateTime?> showBirthDatePickerSheet(
  BuildContext context, {
  DateTime? initial,
}) {
  return showModalBottomSheet<DateTime>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => BirthDatePickerSheet(initial: initial),
  );
}

/// Picks a birth date with three wheels (day, month by name, year), the way
/// iOS does: one flick per part instead of paging through a calendar
/// month by month back to the birth year.
class BirthDatePickerSheet extends StatefulWidget {
  const BirthDatePickerSheet({super.key, this.initial, this.today});

  final DateTime? initial;

  /// For tests; defaults to now.
  final DateTime? today;

  static const firstYear = 1950;

  @override
  State<BirthDatePickerSheet> createState() => _BirthDatePickerSheetState();
}

class _BirthDatePickerSheetState extends State<BirthDatePickerSheet> {
  late final DateTime _today;
  late int _year;
  late int _month;
  late int _day;

  late final FixedExtentScrollController _dayController;
  late final FixedExtentScrollController _monthController;
  late final FixedExtentScrollController _yearController;

  @override
  void initState() {
    super.initState();
    final now = widget.today ?? DateTime.now();
    _today = DateTime(now.year, now.month, now.day);
    final start = _clampToRange(widget.initial ?? DateTime(_today.year - 18));
    _year = start.year;
    _month = start.month;
    _day = start.day;
    _dayController = FixedExtentScrollController(initialItem: _day - 1);
    _monthController = FixedExtentScrollController(initialItem: _month - 1);
    _yearController = FixedExtentScrollController(
      initialItem: _year - BirthDatePickerSheet.firstYear,
    );
  }

  @override
  void dispose() {
    _dayController.dispose();
    _monthController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  DateTime _clampToRange(DateTime date) {
    final first = DateTime(BirthDatePickerSheet.firstYear);
    if (date.isBefore(first)) return first;
    if (date.isAfter(_today)) return _today;
    return date;
  }

  int _daysIn(int year, int month) => DateUtils.getDaysInMonth(year, month);

  int get _lastMonth => _year == _today.year ? _today.month : 12;

  int get _lastDay {
    final days = _daysIn(_year, _month);
    return _year == _today.year && _month == _today.month ? _today.day : days;
  }

  DateTime get _selected => DateTime(_year, _month, _day);

  /// Keeps the day and month valid after another wheel moved (31 → 30 in
  /// April, nothing after today), moving those wheels to match.
  void _normalize() {
    if (_month > _lastMonth) {
      _month = _lastMonth;
      _jump(_monthController, _month - 1);
    }
    if (_day > _lastDay) {
      _day = _lastDay;
      _jump(_dayController, _day - 1);
    }
  }

  void _jump(FixedExtentScrollController controller, int item) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (controller.hasClients && controller.selectedItem != item) {
        controller.animateToItem(
          item,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  int _age(DateTime birth) {
    var age = _today.year - birth.year;
    if (_today.month < birth.month ||
        (_today.month == birth.month && _today.day < birth.day)) {
      age--;
    }
    return age;
  }

  String _ageLabel(AppStrings strings, int age) {
    if (strings.isEnglish) {
      return age == 1 ? '1 year old' : '$age years old';
    }
    if (age == 1) return 'العمر سنة واحدة';
    if (age == 2) return 'العمر سنتان';
    if (age >= 3 && age <= 10) return 'العمر $age سنوات';
    return 'العمر $age سنة';
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final colors = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selected = _selected;
    final years = _today.year - BirthDatePickerSheet.firstYear + 1;

    return Container(
      decoration: BoxDecoration(
        color: colors.cardWhite,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.paddingOf(context).bottom + 12,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 5,
            decoration: BoxDecoration(
              color: colors.textMuted.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
            child: Row(
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    foregroundColor: colors.textMuted,
                    minimumSize: const Size(64, 44),
                  ),
                  child: Text(strings.t('إلغاء')),
                ),
                Expanded(
                  child: Text(
                    strings.t('تاريخ الميلاد'),
                    textAlign: TextAlign.center,
                    style: AppTextStyles.titleOf(context).copyWith(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: colors.text,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, selected),
                  style: TextButton.styleFrom(
                    foregroundColor: isDark ? colors.accent : colors.primary,
                    minimumSize: const Size(64, 44),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  child: Text(strings.t('تم')),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // What will be saved, in words, with the age it means.
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: colors.accent.withValues(alpha: isDark ? 0.14 : 0.1),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Icon(Icons.cake_outlined, color: colors.darkGold, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    formatBirthDate(strings, selected),
                    style: AppTextStyles.subtitleOf(context).copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: colors.text,
                    ),
                  ),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: Text(
                    _ageLabel(strings, _age(selected)),
                    key: ValueKey(_age(selected)),
                    style: AppTextStyles.bodyOf(context).copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: colors.darkGold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 216,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: _Wheel(
                      label: strings.isEnglish ? 'Day' : 'اليوم',
                      controller: _dayController,
                      count: _lastDay,
                      itemText: (i) => '${i + 1}',
                      onChanged: (i) => setState(() => _day = i + 1),
                    ),
                  ),
                  Expanded(
                    flex: 4,
                    child: _Wheel(
                      label: strings.isEnglish ? 'Month' : 'الشهر',
                      controller: _monthController,
                      count: _lastMonth,
                      itemText: (i) => strings.monthName(i + 1),
                      onChanged: (i) => setState(() {
                        _month = i + 1;
                        _normalize();
                      }),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: _Wheel(
                      label: strings.isEnglish ? 'Year' : 'السنة',
                      controller: _yearController,
                      count: years,
                      itemText: (i) => '${BirthDatePickerSheet.firstYear + i}',
                      onChanged: (i) => setState(() {
                        _year = BirthDatePickerSheet.firstYear + i;
                        _normalize();
                      }),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "21 أبريل 2004" / "21 April 2004", with Western digits like the rest of
/// the app.
String formatBirthDate(AppStrings strings, DateTime date) =>
    '${date.day} ${strings.monthName(date.month)} ${date.year}';

class _Wheel extends StatelessWidget {
  const _Wheel({
    required this.label,
    required this.controller,
    required this.count,
    required this.itemText,
    required this.onChanged,
  });

  final String label;
  final FixedExtentScrollController controller;
  final int count;
  final String Function(int index) itemText;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Semantics(
      label: label,
      child: CupertinoPicker.builder(
        scrollController: controller,
        itemExtent: 44,
        diameterRatio: 1.4,
        squeeze: 1.1,
        useMagnifier: true,
        magnification: 1.08,
        selectionOverlay: Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: isDark ? 0.2 : 0.06),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onSelectedItemChanged: onChanged,
        childCount: count,
        itemBuilder: (context, index) => Center(
          child: Text(
            itemText(index),
            style: AppTextStyles.bodyOf(context).copyWith(
              fontSize: 19,
              fontWeight: FontWeight.w600,
              color: colors.text,
            ),
          ),
        ),
      ),
    );
  }
}
