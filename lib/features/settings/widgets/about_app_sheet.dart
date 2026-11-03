import 'package:flutter/material.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// "About the app" as a bottom sheet: the RSHD mark, name and tagline, and
/// the exact version and build.
Future<void> showAboutAppSheet(
  BuildContext context, {
  required String platformName,
  required String version,
  required String buildNumber,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _AboutAppSheet(
      platformName: platformName,
      version: version,
      buildNumber: buildNumber,
    ),
  );
}

class _AboutAppSheet extends StatelessWidget {
  const _AboutAppSheet({
    required this.platformName,
    required this.version,
    required this.buildNumber,
  });

  final String platformName;
  final String version;
  final String buildNumber;

  static const _logoAsset = 'assets/images/rshd_logo_no_bg.png';

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final colors = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Center(
      heightFactor: 1,
      child: ConstrainedBox(
        // A sheet, not a full-width slab, on tablets.
        constraints: const BoxConstraints(maxWidth: 560),
        child: Container(
          decoration: BoxDecoration(
            color: colors.background,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.fromLTRB(20, 10, 20, bottom + 16),
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
              const SizedBox(height: 20),
              Center(
                child: Container(
                  width: 96,
                  height: 96,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark ? colors.cardWhite : Colors.white,
                    border: Border.all(
                      color: colors.accent.withValues(alpha: 0.55),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: colors.darkGold.withValues(alpha: 0.18),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Image.asset(_logoAsset, fit: BoxFit.contain),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                platformName,
                textAlign: TextAlign.center,
                style: AppTextStyles.titleOf(context).copyWith(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: colors.text,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                strings.aboutTagline,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyOf(
                  context,
                ).copyWith(fontSize: 14, color: colors.textMuted),
              ),
              const SizedBox(height: 12),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: colors.darkGold.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    strings.aboutVersion(version, buildNumber),
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: colors.darkGold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                strings.aboutCopyright(DateTime.now().year, platformName),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: colors.textMuted.withValues(alpha: 0.85),
                ),
              ),
              const SizedBox(height: 14),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(strings.ok),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
