import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../controllers/pdf_editor_controller.dart';

class TextSettingsSheet extends StatefulWidget {
  const TextSettingsSheet({
    super.key,
    required this.settings,
    required this.onChanged,
  });

  final TextSettings settings;
  final ValueChanged<TextSettings> onChanged;

  static const colors = [
    Color(0xFF111827),
    Color(0xFF234E70),
    Color(0xFFB42318),
    Color(0xFF067647),
    Color(0xFFD6B56D),
  ];

  static const fontSizes = <(String, double)>[
    ('12', 0.020),
    ('16', 0.027),
    ('20', 0.034),
    ('24', 0.040),
  ];

  @override
  State<TextSettingsSheet> createState() => _TextSettingsSheetState();
}

class _TextSettingsSheetState extends State<TextSettingsSheet> {
  late TextSettings _settings;

  @override
  void initState() {
    super.initState();
    _settings = widget.settings;
  }

  void _apply(TextSettings next) {
    setState(() => _settings = next);
    widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.of(context).cardWhite,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.of(context).textMuted.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'إعدادات النص',
              style: AppTextStyles.subtitleOf(
                context,
              ).copyWith(color: AppColors.of(context).primary),
              textAlign: TextAlign.right,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.end,
              children: TextSettingsSheet.colors.map((color) {
                final selected = color.toARGB32() == _settings.color.toARGB32();
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _apply(_settings.copyWith(color: color)),
                    customBorder: const CircleBorder(),
                    child: Container(
                      width: 36,
                      height: 36,
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selected
                              ? AppColors.of(context).accent
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.end,
              children: TextSettingsSheet.fontSizes.map((preset) {
                final selected =
                    (_settings.fontSize - preset.$2).abs() < 0.0005;
                return ChoiceChip(
                  label: Text(preset.$1),
                  selected: selected,
                  onSelected: (_) =>
                      _apply(_settings.copyWith(fontSize: preset.$2)),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

void showTextSettingsSheet(
  BuildContext context, {
  required TextSettings settings,
  required ValueChanged<TextSettings> onChanged,
}) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) {
      return TextSettingsSheet(settings: settings, onChanged: onChanged);
    },
  );
}
