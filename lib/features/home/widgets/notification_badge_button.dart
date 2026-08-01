import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';

class NotificationBadgeButton extends StatelessWidget {
  const NotificationBadgeButton({
    super.key,
    required this.unreadCount,
    this.iconColor,
  });

  final int unreadCount;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'الإشعارات',
      onPressed: () => context.push(AppRoutes.notifications),
      icon: Badge(
        isLabelVisible: unreadCount > 0,
        label: Text(
          unreadCount > 9 ? '9+' : '$unreadCount',
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: AppColors.accent,
        textColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: Icon(
          Icons.notifications_outlined,
          color: iconColor ?? AppColors.primary,
          size: 22,
        ),
      ),
    );
  }
}
