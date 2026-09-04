import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/liquid_glass_surface.dart';
import '../data/models/notification_model.dart';
import '../../../core/l10n/app_strings.dart';

Future<void> showNotificationMessageSheet({
  required BuildContext context,
  required NotificationModel notification,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _NotificationMessageSheet(notification: notification),
  );
}

class _NotificationMessageSheet extends StatelessWidget {
  const _NotificationMessageSheet({required this.notification});

  final NotificationModel notification;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final isReply = notification.effectiveType == 'instructor_reply';
    final senderName =
        notification.data['instructor_name']?.toString() ??
        notification.data['student_name']?.toString() ??
        _extractNameFromTitle(notification.title);
    final subjectTitle =
        notification.data['subject_title']?.toString() ??
        _extractSubjectFromTitle(notification.title);
    final message = notification.body?.trim().isNotEmpty == true
        ? notification.body!.trim()
        : 'لا يوجد محتوى للرسالة.';

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, bottomInset + 16),
      child: LiquidGlassSurface(
        borderRadius: BorderRadius.circular(24),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.of(context).accent.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    isReply ? Icons.reply_rounded : Icons.mail_outline,
                    color: AppColors.of(context).darkGold,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(AppStrings.of(context).t(isReply ? 'رد من المدرّس' : 'رسالة'),
                        style: AppTextStyles.bodyOf(context).copyWith(
                          fontSize: 12,
                          color: AppColors.of(context).darkGold,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(AppStrings.of(context).t(senderName),
                        style: AppTextStyles.subtitleOf(
                          context,
                        ).copyWith(fontWeight: FontWeight.w800, fontSize: 17),
                      ),
                      if (subjectTitle.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(AppStrings.of(context).t(subjectTitle),
                          style: AppTextStyles.bodyOf(context).copyWith(
                            fontSize: 13,
                            color: AppColors.of(context).textMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.of(context).background,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE8DFCF)),
              ),
              child: Text(AppStrings.of(context).t(message),
                style: AppTextStyles.bodyOf(
                  context,
                ).copyWith(fontSize: 15, height: 1.7),
                textAlign: TextAlign.right,
              ),
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.of(context).primary,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(AppStrings.of(context).t('إغلاق')),
            ),
          ],
        ),
      ),
    );
  }

  String _extractNameFromTitle(String title) {
    if (title.startsWith('رد من ')) {
      final parts = title.split(' — ');
      if (parts.isNotEmpty) {
        return parts.first.replaceFirst('رد من ', '').trim();
      }
    }

    if (title.startsWith('رسالة من ')) {
      final parts = title.split(' — ');
      if (parts.isNotEmpty) {
        return parts.first.replaceFirst('رسالة من ', '').trim();
      }
    }

    return title;
  }

  String _extractSubjectFromTitle(String title) {
    final parts = title.split(' — ');
    if (parts.length > 1) {
      return parts.last.trim();
    }
    return '';
  }
}
