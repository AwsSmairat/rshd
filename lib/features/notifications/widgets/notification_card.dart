import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/liquid_glass_surface.dart';
import '../data/models/notification_model.dart';
import 'notification_type_icon.dart';
import '../../../core/l10n/app_strings.dart';

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
      tintColor: isUnread ? AppColors.of(context).accent : null,
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
                      child: Text(AppStrings.of(context).t(notification.title),
                        style: AppTextStyles.titleOf(context).copyWith(
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
                        decoration: BoxDecoration(
                          color: AppColors.of(context).accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(AppStrings.of(context).t(notification.shortBody),
                  style: AppTextStyles.bodyOf(context).copyWith(
                    color: AppColors.of(context).textMuted,
                    fontSize: 13,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      AppStrings.of(context).t(notification.typeLabel),
                      style: AppTextStyles.bodyOf(
                        context,
                      ).copyWith(fontSize: 12),
                    ),
                    const SizedBox(width: 8),
                    Text(AppStrings.of(context).t('•'),
                      style: AppTextStyles.bodyOf(
                        context,
                      ).copyWith(color: AppColors.of(context).textMuted),
                    ),
                    const SizedBox(width: 8),
                    Text(AppStrings.of(context).t(isUnread ? 'غير مقروء' : 'مقروء'),
                      style: AppTextStyles.bodyOf(context).copyWith(
                        fontSize: 12,
                        color: isUnread
                            ? AppColors.of(context).primary
                            : AppColors.of(context).textMuted,
                      ),
                    ),
                    if (notification.createdAt != null &&
                        notification.createdAt!.isNotEmpty) ...[
                      const Spacer(),
                      Text(AppStrings.of(context).t(_formatDate(context, notification.createdAt!)),
                        style: AppTextStyles.bodyOf(context).copyWith(
                          fontSize: 11,
                          color: AppColors.of(context).textMuted,
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

  String _formatDate(BuildContext context, String raw) {
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) {
      return raw;
    }
    return DateFormat('yyyy/MM/dd', AppStrings.of(context).dateLocale).format(parsed.toLocal());
  }
}
