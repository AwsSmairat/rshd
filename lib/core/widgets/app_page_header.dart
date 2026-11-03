import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'responsive_content.dart';

/// The app's page title block: an optional round back button, a large
/// title and a muted line under it. Light, on the page background — the
/// style shared by every redesigned screen.
class PageTitleBlock extends StatelessWidget {
  const PageTitleBlock({
    super.key,
    required this.title,
    this.subtitle,
    this.onBack,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final VoidCallback? onBack;

  /// Shown on the end side of the back-button row (e.g. a page action).
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (onBack != null || trailing != null) ...[
            Row(
              children: [
                if (onBack != null)
                  Material(
                    color: colors.cardWhite,
                    shape: CircleBorder(
                      side: BorderSide(
                        color: colors.primary.withValues(alpha: 0.06),
                      ),
                    ),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: onBack,
                      child: SizedBox(
                        width: 44,
                        height: 44,
                        child: Icon(
                          isRtl
                              ? Icons.arrow_forward_ios_rounded
                              : Icons.arrow_back_ios_new_rounded,
                          size: 17,
                          color: colors.primary,
                          semanticLabel: AppStrings.of(context).back,
                        ),
                      ),
                    ),
                  ),
                const Spacer(),
                ?trailing,
              ],
            ),
            const SizedBox(height: 14),
          ] else
            const SizedBox(height: 10),
          Text(
            title,
            style: AppTextStyles.titleOf(context).copyWith(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: colors.text,
              height: 1.2,
            ),
          ),
          if (subtitle != null && subtitle!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: AppTextStyles.bodyOf(
                context,
              ).copyWith(fontSize: 14, color: colors.textMuted, height: 1.4),
            ),
          ],
        ],
      ),
    );
  }
}

/// [PageTitleBlock] laid out as the top of a scrolling page: below the status
/// bar, within the page margins, with the back button shown whenever there is
/// a page to go back to.
class AppPageHeader extends StatelessWidget {
  const AppPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.showBackButton = true,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final bool showBackButton;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final canPop = showBackButton && Navigator.of(context).canPop();
    return SafeArea(
      bottom: false,
      child: ResponsiveContent(
        padding: null,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 18),
          child: PageTitleBlock(
            title: title,
            subtitle: subtitle,
            trailing: trailing,
            onBack: canPop ? () => Navigator.of(context).maybePop() : null,
          ),
        ),
      ),
    );
  }
}
