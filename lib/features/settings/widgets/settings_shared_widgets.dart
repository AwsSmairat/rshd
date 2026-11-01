import 'package:flutter/material.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_colors.dart';

/// Hairline colour for dividers and card edges in both themes.
Color _hairline(BuildContext context) {
  final colors = AppColors.of(context);
  return Theme.of(context).brightness == Brightness.dark
      ? colors.white.withValues(alpha: 0.08)
      : colors.primary.withValues(alpha: 0.07);
}

/// A titled, always-open group of settings rows.
///
/// The label sits above the card (not inside it) so the card itself holds
/// nothing but rows — the inset-grouped pattern people already know from the
/// system Settings app. Sections never collapse: every control is visible at a
/// glance instead of hiding behind a tap.
class SettingsSectionCard extends StatelessWidget {
  const SettingsSectionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
    this.trailing,
    this.footer,
  });

  final String title;
  final IconData icon;
  final Widget child;

  /// Small action aligned with the section label (e.g. "Edit").
  final Widget? trailing;

  /// Muted note under the card.
  final String? footer;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(6, 0, 2, 8),
          child: Row(
            children: [
              Icon(icon, size: 16, color: colors.darkGold),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  AppStrings.of(context).t(title),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                    color: colors.textMuted,
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: isDark
                ? colors.cardWhite.withValues(alpha: 0.55)
                : colors.white.withValues(alpha: 0.82),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: _hairline(context)),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: colors.primary.withValues(alpha: 0.045),
                      blurRadius: 18,
                      spreadRadius: -4,
                      offset: const Offset(0, 8),
                    ),
                  ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: child,
          ),
        ),
        if (footer != null)
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(8, 8, 8, 0),
            child: Text(
              footer!,
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
                color: colors.textMuted.withValues(alpha: 0.9),
              ),
            ),
          ),
      ],
    );
  }
}

/// Gold-tinted square holding a row's icon.
class _IconTile extends StatelessWidget {
  const _IconTile({required this.icon, this.color});

  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final tint = color ?? colors.darkGold;

    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 18, color: tint),
    );
  }
}

/// Divider inset past the icon tile, so rows read as one continuous list.
class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 62),
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
      constraints: const BoxConstraints(minHeight: 56),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(14, 10, 12, 10),
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
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                      color: labelColor ?? colors.text,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      strings.t(subtitle!),
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.3,
                        color: colors.textMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (value != null) ...[
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  strings.t(value!),
                  textAlign: TextAlign.end,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    color: valueColor ?? colors.textMuted,
                  ),
                ),
              ),
            ],
            if (onTap != null) ...[
              const SizedBox(width: 4),
              Icon(
                isRtl
                    ? Icons.chevron_left_rounded
                    : Icons.chevron_right_rounded,
                size: 20,
                color: colors.textMuted.withValues(alpha: 0.6),
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
            // The whole row toggles, not just the small switch.
            onTap: () => onChanged(!value),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 56),
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(14, 8, 8, 8),
                child: Row(
                  children: [
                    if (icon != null)
                      _IconTile(icon: icon!)
                    else
                      const SizedBox(width: 34),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            strings.t(label),
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                              height: 1.3,
                              color: colors.text,
                            ),
                          ),
                          if (subtitle != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              strings.t(subtitle!),
                              style: TextStyle(
                                fontSize: 12,
                                height: 1.3,
                                color: colors.textMuted,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Switch.adaptive(
                      value: value,
                      onChanged: onChanged,
                      activeTrackColor: colors.darkGold,
                      // In dark mode the gold track is pale, so a white thumb
                      // would vanish into it.
                      activeThumbColor:
                          Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF0B1F3A)
                          : colors.white,
                      // Material's default "off" is a dark ring with a heavy
                      // outline; a soft track keeps off-state rows quiet.
                      inactiveThumbColor: colors.white,
                      inactiveTrackColor: colors.textMuted.withValues(
                        alpha: 0.28,
                      ),
                      trackOutlineColor: const WidgetStatePropertyAll(
                        Colors.transparent,
                      ),
                    ),
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
