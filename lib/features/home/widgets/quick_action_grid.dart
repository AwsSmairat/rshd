import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/layout/app_layout_metrics.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/liquid_glass_surface.dart';
import '../../../core/widgets/responsive_content.dart';
import '../../quizzes/widgets/quiz_icon_helper.dart';
import 'home_section_header.dart';

class QuickActionGrid extends StatelessWidget {
  const QuickActionGrid({super.key});

  static const _actions = [
    _QuickAction(
      label: 'المحاضرات',
      icon: Icons.smart_display_outlined,
      route: AppRoutes.subjects,
    ),
    _QuickAction(
      label: 'موادي',
      icon: Icons.menu_book_outlined,
      route: AppRoutes.subjects,
    ),
    _QuickAction(
      label: 'الواجبات',
      icon: Icons.assignment_outlined,
      route: AppRoutes.assignments,
    ),
    _QuickAction(
      label: 'الاختبارات',
      icon: QuizIconHelper.sectionIcon,
      route: AppRoutes.quizzes,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final metrics = AppLayoutMetrics.of(context);
    final crossAxisCount = metrics.quickActionColumns;
    final cellHeight = metrics.quickActionCellHeight;
    final spacing = metrics.isTablet ? 14.0 : 10.0;

    final rows = <Widget>[];
    for (var i = 0; i < _actions.length; i += crossAxisCount) {
      if (rows.isNotEmpty) {
        rows.add(SizedBox(height: spacing));
      }

      rows.add(
        Row(
          children: [
            for (var j = 0; j < crossAxisCount; j++) ...[
              if (j > 0) SizedBox(width: spacing),
              Expanded(
                child: i + j < _actions.length
                    ? SizedBox(
                        height: cellHeight,
                        child: _QuickActionTile(action: _actions[i + j]),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ],
        ),
      );
    }

    return ResponsiveContent(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const HomeSectionHeader(title: 'اختصارات سريعة'),
          const SizedBox(height: 8),
          ...rows,
        ],
      ),
    );
  }
}

class _QuickAction {
  const _QuickAction({
    required this.label,
    required this.icon,
    required this.route,
  });

  final String label;
  final IconData icon;
  final String route;
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({required this.action});

  final _QuickAction action;

  @override
  Widget build(BuildContext context) {
    final metrics = AppLayoutMetrics.of(context);

    return LiquidGlassSurface(
      borderRadius: BorderRadius.circular(18),
      padding: EdgeInsets.symmetric(
        horizontal: metrics.isTablet ? 12 : 8,
        vertical: metrics.isTablet ? 14 : 12,
      ),
      onTap: () {
        context.push(action.route);
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: metrics.quickActionIconContainerSize,
            height: metrics.quickActionIconContainerSize,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.45),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(
              action.icon,
              color: AppColors.of(context).primary,
              size: metrics.quickActionIconSize,
            ),
          ),
          SizedBox(height: metrics.isTablet ? 10 : 8),
          Text(
            action.label,
            style: AppTextStyles.bodyOf(context).copyWith(
              fontSize: metrics.quickActionLabelFontSize,
              height: 1.25,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
