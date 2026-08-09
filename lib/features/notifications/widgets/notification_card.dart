import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/liquid_glass_surface.dart';
import '../data/models/notification_model.dart';
import 'notification_type_icon.dart';

class NotificationCard extends StatelessWidget {
  const NotificationCard({
    super.key,
    required this.notification,
    required this.onTap,
  });

  final NotificationModel notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isUnread = !notification.isRead;

    return LiquidGlassSurface(
      borderRadius: BorderRadius.circular(16),
      padding: const EdgeInsets.all(16),
      onTap: onTap,
      tintColor: isUnread ? AppColors.accent : null,
      tintOpacity: isUnread ? 0.14 : 0.08,
      borderOpacity: isUnread ? 0.62 : 0.5,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NotificationTypeIcon(type: notification.effectiveType),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        notification.title,
                        style: AppTextStyles.title.copyWith(
                          fontSize: 16,
                          fontWeight: isUnread
                              ? FontWeight.w800
                              : FontWeight.w600,
                        ),
                      ),
                    ),
                    if (isUnread)
                      Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsetsDirectional.only(start: 8),
                        decoration: const BoxDecoration(
                          color: AppColors.accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  notification.shortBody,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textMuted,
                    fontSize: 13,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      notification.typeLabel,
                      style: AppTextStyles.body.copyWith(fontSize: 12),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '•',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isUnread ? 'غير مقروء' : 'مقروء',
                      style: AppTextStyles.body.copyWith(
                        fontSize: 12,
                        color: isUnread
                            ? AppColors.primary
                            : AppColors.textMuted,
                      ),
                    ),
                    if (notification.createdAt != null &&
                        notification.createdAt!.isNotEmpty) ...[
                      const Spacer(),
                      Text(
                        _formatDate(notification.createdAt!),
                        style: AppTextStyles.body.copyWith(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String raw) {
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) {
      return raw;
    }
    return DateFormat('yyyy/MM/dd', 'ar').format(parsed.toLocal());
  }
}
