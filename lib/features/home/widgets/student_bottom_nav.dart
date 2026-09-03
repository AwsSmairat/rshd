import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';

/// TODO: Create shared app shell with bottom navigation later.
class StudentBottomNav extends StatelessWidget {
  const StudentBottomNav({super.key});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = _indexForLocation(location);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.of(context).primary,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.of(context).primary.withValues(alpha: 0.28),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          _NavItem(
            label: 'موادي',
            icon: Icons.menu_book_outlined,
            isActive: currentIndex == 0,
            onTap: () => _navigate(context, AppRoutes.subjects, 0),
          ),
          _NavItem(
            label: 'واجباتي',
            icon: Icons.assignment_outlined,
            isActive: currentIndex == 1,
            onTap: () => _navigate(context, AppRoutes.assignments, 1),
          ),
          _HomeNavItem(
            isActive: currentIndex == 2,
            onTap: () => _navigate(context, AppRoutes.home, 2),
          ),
          _NavItem(
            label: 'درجاتي',
            icon: Icons.star_outline,
            isActive: currentIndex == 3,
            onTap: () => _navigate(context, AppRoutes.grades, 3),
          ),
          _NavItem(
            label: 'المزيد',
            icon: Icons.person_outline,
            isActive: currentIndex == 4,
            onTap: () => _navigate(context, AppRoutes.profile, 4),
          ),
        ],
      ),
    );
  }

  int _indexForLocation(String location) {
    if (location.startsWith(AppRoutes.subjects)) {
      return 0;
    }
    if (location.startsWith(AppRoutes.assignments)) {
      return 1;
    }
    if (location == AppRoutes.home) {
      return 2;
    }
    if (location.startsWith(AppRoutes.grades)) {
      return 3;
    }
    if (location.startsWith(AppRoutes.profile)) {
      return 4;
    }
    return 2;
  }

  void _navigate(BuildContext context, String route, int index) {
    if (index == 2) {
      context.go(AppRoutes.home);
      return;
    }
    context.push(route);
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 22,
                color: isActive
                    ? AppColors.of(context).accent
                    : AppColors.of(context).white.withValues(alpha: 0.75),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isActive
                      ? AppColors.of(context).accent
                      : AppColors.of(context).white.withValues(alpha: 0.75),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeNavItem extends StatelessWidget {
  const _HomeNavItem({required this.isActive, required this.onTap});

  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Transform.translate(
        offset: const Offset(0, -18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: isActive
                        ? [
                            AppColors.of(context).accent,
                            AppColors.of(context).darkGold,
                          ]
                        : [
                            AppColors.of(
                              context,
                            ).accent.withValues(alpha: 0.85),
                            AppColors.of(
                              context,
                            ).darkGold.withValues(alpha: 0.85),
                          ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.of(
                        context,
                      ).darkGold.withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.home_rounded,
                  color: AppColors.of(context).primary,
                  size: 28,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'الرئيسية',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: isActive
                      ? AppColors.of(context).accent
                      : AppColors.of(context).white.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
