import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_colors.dart';

/// Hairline colour for dividers and card edges in both themes.
Color _hairline(BuildContext context) {
  final colors = AppColors.of(context);
  return Theme.of(context).brightness == Brightness.dark
      ? colors.white.withValues(alpha: 0.08)
      : colors.primary.withValues(alpha: 0.07);
}

/// Accent colours that tell settings groups apart at a glance.
class SettingsAccents {
  SettingsAccents._();

  static const account = Color(0xFF1D4E89);
  static const security = Color(0xFFB45309);
  static const preferences = Color(0xFF0F766E);
  static const notifications = Color(0xFF6D28D9);
  static const privacy = Color(0xFF1D4E89);
  static const support = Color(0xFF15803D);
}

/// A settings group as one card: a coloured icon badge and title in the
/// card's own header, then its rows. Calm surface, soft shadow, no clutter.
class SettingsSectionCard extends StatelessWidget {
  const SettingsSectionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
    this.trailing,
    this.footer,
    this.accent,
  });

  final String title;
  final IconData icon;
  final Widget child;

  /// Small action on the end of the header (e.g. "Edit").
  final Widget? trailing;

  /// Muted note at the bottom of the card.
  final String? footer;

  /// Colour of the header badge; navy by default.
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tone = accent ?? (isDark ? colors.accent : colors.primary);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.cardWhite,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _hairline(context)),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: const Color(0xFF0B1F3A).withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 12, 10),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [tone, Color.lerp(tone, Colors.black, 0.25)!],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: tone.withValues(alpha: 0.28),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(icon, size: 19, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      AppStrings.of(context).t(title),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: colors.text,
                      ),
                    ),
                  ),
                  ?trailing,
                ],
              ),
            ),
            child,
            if (footer != null)
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(16, 4, 16, 14),
                child: Text(
                  footer!,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.5,
                    color: colors.textMuted.withValues(alpha: 0.9),
                  ),
                ),
              )
            else
              const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }
}

/// Soft round badge holding a row's icon.
class _IconTile extends StatelessWidget {
  const _IconTile({required this.icon, this.color});

  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tint = color ?? (isDark ? colors.accent : colors.primary);

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: tint.withValues(alpha: isDark ? 0.16 : 0.08),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 18, color: tint),
    );
  }
}

/// Divider inset past the icon badge, so rows read as one continuous list.
class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 66, end: 16),
      child: Divider(height: 1, thickness: 1, color: _hairline(context)),
    );
  }
}

class SettingsItemTile extends StatelessWidget {
  const SettingsItemTile({
    super.key,
    required this.icon,
    required this.label,
    this.value,
    this.subtitle,
    this.onTap,
    this.showDivider = true,
    this.valueColor,
    this.iconColor,
    this.labelColor,
  });

  final IconData icon;
  final String label;
  final String? value;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool showDivider;
  final Color? valueColor;
  final Color? iconColor;
  final Color? labelColor;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final strings = AppStrings.of(context);
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    final content = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 60),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(16, 10, 14, 10),
        child: Row(
          children: [
            _IconTile(icon: icon, color: iconColor),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    strings.t(label),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                      color: labelColor ?? colors.text,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      strings.t(subtitle!),
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.35,
                        color: colors.textMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (value != null) ...[
              const SizedBox(width: 8),
              // Values sit in a soft pill so they read as data, not labels.
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: (valueColor ?? colors.textMuted).withValues(
                      alpha: 0.08,
                    ),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    strings.t(value!),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: valueColor ?? colors.text.withValues(alpha: 0.75),
                    ),
                  ),
                ),
              ),
            ],
            if (onTap != null) ...[
              const SizedBox(width: 6),
              Icon(
                isRtl
                    ? Icons.chevron_left_rounded
                    : Icons.chevron_right_rounded,
                size: 22,
                color: colors.textMuted.withValues(alpha: 0.55),
              ),
            ],
          ],
        ),
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (onTap == null)
          content
        else
          Material(
            color: Colors.transparent,
            child: InkWell(onTap: onTap, child: content),
          ),
        if (showDivider) const _RowDivider(),
      ],
    );
  }
}

/// The app's toggle: a rounded track that fills navy (gold in dark mode),
/// with a white knob that carries a check mark when on.
class RshdSwitch extends StatelessWidget {
  const RshdSwitch({super.key, required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final on = isDark ? colors.accent : colors.primary;
    const duration = Duration(milliseconds: 220);

    return Semantics(
      toggled: value,
      enabled: onChanged != null,
      child: GestureDetector(
        onTap: onChanged == null
            ? null
            : () {
                HapticFeedback.selectionClick();
                onChanged!(!value);
              },
        child: AnimatedContainer(
          duration: duration,
          curve: Curves.easeOutCubic,
          width: 52,
          height: 31,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: value
                ? on
                : colors.textMuted.withValues(alpha: isDark ? 0.35 : 0.22),
          ),
          child: AnimatedAlign(
            duration: duration,
            curve: Curves.easeOutBack,
            alignment: value
                ? AlignmentDirectional.centerEnd
                : AlignmentDirectional.centerStart,
            child: Container(
              width: 25,
              height: 25,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: AnimatedOpacity(
                duration: duration,
                opacity: value ? 1 : 0,
                child: Icon(Icons.check_rounded, size: 15, color: on),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SettingsSwitchTile extends StatelessWidget {
  const SettingsSwitchTile({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.icon,
    this.subtitle,
    this.showDivider = true,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  /// Optional; rows without one indent their text to line up with rows that
  /// have one, so a mixed list keeps a single text edge.
  final IconData? icon;
  final String? subtitle;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final strings = AppStrings.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            // The whole row toggles, not just the switch.
            onTap: () {
              HapticFeedback.selectionClick();
              onChanged(!value);
            },
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 60),
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 8),
                child: Row(
                  children: [
                    if (icon != null)
                      _IconTile(icon: icon!)
                    else
                      const SizedBox(width: 36),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            strings.t(label),
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              height: 1.3,
                              color: colors.text,
                            ),
                          ),
                          if (subtitle != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              strings.t(subtitle!),
                              style: TextStyle(
                                fontSize: 12.5,
                                height: 1.35,
                                color: colors.textMuted,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    RshdSwitch(value: value, onChanged: onChanged),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (showDivider) const _RowDivider(),
      ],
    );
  }
}

/// A setting chosen in place: its label above a segmented control whose
/// highlight slides to the picked option. Replaces opening a list for short
/// choices (theme, language, text size, quality).
class SettingsSegmentedRow<T> extends StatelessWidget {
  const SettingsSegmentedRow({
    super.key,
    required this.icon,
    required this.label,
    required this.options,
    required this.value,
    required this.onChanged,
    this.showDivider = true,
  });

  final IconData icon;
  final String label;
  final List<SettingsPickerOption<T>> options;
  final T value;
  final ValueChanged<T> onChanged;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final strings = AppStrings.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selected = options.indexWhere((o) => o.value == value);
    final count = options.length;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  _IconTile(icon: icon),
                  const SizedBox(width: 14),
                  Text(
                    strings.t(label),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: colors.text,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                height: 44,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: colors.textMuted.withValues(
                    alpha: isDark ? 0.18 : 0.09,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Stack(
                  children: [
                    if (selected >= 0)
                      AnimatedAlign(
                        duration: const Duration(milliseconds: 260),
                        curve: Curves.easeOutCubic,
                        alignment: AlignmentDirectional(
                          count == 1 ? 0 : -1 + 2 * selected / (count - 1),
                          0,
                        ),
                        child: FractionallySizedBox(
                          widthFactor: 1 / count,
                          heightFactor: 1,
                          child: Container(
                            decoration: BoxDecoration(
                              color: isDark ? colors.accent : colors.cardWhite,
                              borderRadius: BorderRadius.circular(11),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    Row(
                      children: [
                        for (var i = 0; i < count; i++)
                          Expanded(
                            child: Semantics(
                              button: true,
                              selected: i == selected,
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () {
                                  if (i == selected) return;
                                  HapticFeedback.selectionClick();
                                  onChanged(options[i].value);
                                },
                                child: Center(
                                  child: AnimatedDefaultTextStyle(
                                    duration: const Duration(milliseconds: 200),
                                    style: TextStyle(
                                      fontFamily: DefaultTextStyle.of(
                                        context,
                                      ).style.fontFamily,
                                      fontSize: 13,
                                      fontWeight: i == selected
                                          ? FontWeight.w800
                                          : FontWeight.w600,
                                      color: i == selected
                                          ? (isDark
                                                ? const Color(0xFF0B1F3A)
                                                : colors.primary)
                                          : colors.textMuted,
                                    ),
                                    child: Text(
                                      strings.t(options[i].label),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (showDivider) const _RowDivider(),
      ],
    );
  }
}

/// A row that reveals more rows beneath it, inside the same card.
///
/// Used where a section would otherwise be a long wall of toggles: the summary
/// stays visible, the detail is one tap away.
class SettingsExpandableRow extends StatefulWidget {
  const SettingsExpandableRow({
    super.key,
    required this.icon,
    required this.label,
    required this.children,
    this.value,
  });

  final IconData icon;
  final String label;
  final String? value;
  final List<Widget> children;

  @override
  State<SettingsExpandableRow> createState() => _SettingsExpandableRowState();
}

class _SettingsExpandableRowState extends State<SettingsExpandableRow> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final strings = AppStrings.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 56),
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(14, 10, 12, 10),
                child: Row(
                  children: [
                    _IconTile(icon: widget.icon),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        strings.t(widget.label),
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: colors.text,
                        ),
                      ),
                    ),
                    if (widget.value != null)
                      Text(
                        widget.value!,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                          color: colors.textMuted,
                        ),
                      ),
                    const SizedBox(width: 4),
                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      child: Icon(
                        Icons.expand_more_rounded,
                        size: 22,
                        color: colors.textMuted.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: _expanded
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [const _RowDivider(), ...widget.children],
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}

class SettingsPickerOption<T> {
  const SettingsPickerOption({required this.value, required this.label});

  final T value;
  final String label;
}

/// Bottom-sheet single choice, in the same ivory sheet language as the rest of
/// the redesigned app.
Future<T?> showSettingsOptionPicker<T>({
  required BuildContext context,
  required String title,
  required List<SettingsPickerOption<T>> options,
  required T current,
}) {
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) {
      final colors = AppColors.of(context);
      final strings = AppStrings.of(context);
      final isDark = Theme.of(context).brightness == Brightness.dark;
      final bottomInset = MediaQuery.paddingOf(context).bottom;

      return Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.75,
        ),
        decoration: BoxDecoration(
          color: isDark ? colors.secondaryNavy : const Color(0xFFFBF8F2),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.fromLTRB(16, 10, 16, 14 + bottomInset),
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
            const SizedBox(height: 16),
            Text(
              strings.t(title),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: colors.primary,
              ),
            ),
            const SizedBox(height: 14),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final option in options)
                      _PickerOptionRow(
                        label: strings.t(option.label),
                        selected: option.value == current,
                        onTap: () => Navigator.pop(context, option.value),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _PickerOptionRow extends StatelessWidget {
  const _PickerOptionRow({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected
            ? colors.accent.withValues(alpha: isDark ? 0.16 : 0.14)
            : (isDark
                  ? colors.white.withValues(alpha: 0.05)
                  : colors.white.withValues(alpha: 0.8)),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 54,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? colors.accent : _hairline(context),
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: colors.text,
                    ),
                  ),
                ),
                AnimatedOpacity(
                  opacity: selected ? 1 : 0,
                  duration: const Duration(milliseconds: 150),
                  child: Icon(
                    Icons.check_circle_rounded,
                    size: 22,
                    color: colors.darkGold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
