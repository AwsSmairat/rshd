import 'package:flutter/material.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../data/models/notification_model.dart';

/// What a notification is about; drives its icon, colour and filter.
enum NotificationKind { course, task, announcement, message, other }

NotificationKind notificationKindOf(NotificationModel n) {
  return switch (n.effectiveType) {
    'subject_activated' || 'activation_request' => NotificationKind.course,
    'assignment_created' ||
    'new_assignment' ||
    'assignment_reminder' ||
    'assignment_submitted' ||
    'quiz_created' ||
    'new_quiz' ||
    'quiz_available' ||
    'grade_published' ||
    'new_grade' => NotificationKind.task,
    'announcement' => NotificationKind.announcement,
    'student_message' || 'instructor_reply' => NotificationKind.message,
    _ => NotificationKind.other,
  };
}

/// Icon and colour for a notification, specific to its exact type.
(IconData, Color) notificationGlyph(NotificationModel n) {
  return switch (n.effectiveType) {
    'subject_activated' => (Icons.school_rounded, const Color(0xFF15803D)),
    'activation_request' => (
      Icons.hourglass_top_rounded,
      const Color(0xFFB45309),
    ),
    'assignment_created' || 'new_assignment' || 'assignment_reminder' => (
      Icons.assignment_rounded,
      const Color(0xFFB8862B),
    ),
    'assignment_submitted' => (Icons.task_alt_rounded, const Color(0xFF15803D)),
    'quiz_created' ||
    'new_quiz' ||
    'quiz_available' => (Icons.quiz_rounded, const Color(0xFF6D28D9)),
    'grade_published' ||
    'new_grade' => (Icons.workspace_premium_rounded, const Color(0xFFB8862B)),
    'announcement' => (Icons.campaign_rounded, const Color(0xFF1D4E89)),
    'student_message' ||
    'instructor_reply' => (Icons.forum_rounded, const Color(0xFF0F766E)),
    _ => (Icons.notifications_rounded, const Color(0xFF0B1F3A)),
  };
}

/// "Now", "5m ago", "3h ago", "Yesterday", or the date.
String relativeNotificationTime(AppStrings strings, DateTime? at) {
  if (at == null) return '';
  final now = DateTime.now();
  final diff = now.difference(at);
  if (diff.inMinutes < 1) return strings.timeNow;
  if (diff.inMinutes < 60) return strings.minutesAgo(diff.inMinutes);
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(at.year, at.month, at.day);
  if (day == today) return strings.hoursAgo(diff.inHours);
  if (today.difference(day).inDays == 1) return strings.groupYesterday;
  // The year only when it is not this year.
  return at.year == now.year
      ? '${at.day}/${at.month}'
      : '${at.day}/${at.month}/${at.year}';
}

/// One notification as a row inside a grouped card: a coloured icon tile,
/// title, message and time. Unread rows carry a gold dot and a faint wash.
class NotificationTile extends StatelessWidget {
  const NotificationTile({
    super.key,
    required this.notification,
    required this.onTap,
    this.showDivider = true,
  });

  final NotificationModel notification;
  final VoidCallback onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final colors = AppColors.of(context);
    final (icon, tone) = notificationGlyph(notification);
    final unread = !notification.isRead;
    final createdAt = DateTime.tryParse(
      notification.createdAt ?? '',
    )?.toLocal();
    final body = notification.body?.trim() ?? '';

    return Material(
      color: unread
          ? colors.accent.withValues(alpha: 0.07)
          : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          tone.withValues(alpha: 0.18),
                          tone.withValues(alpha: 0.08),
                        ],
                      ),
                    ),
                    child: Icon(icon, color: tone, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                strings.t(notification.title),
                                style: AppTextStyles.bodyOf(context).copyWith(
                                  fontSize: 15,
                                  fontWeight: unread
                                      ? FontWeight.w800
                                      : FontWeight.w700,
                                  color: colors.text,
                                  height: 1.3,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              relativeNotificationTime(strings, createdAt),
                              style: AppTextStyles.bodyOf(context).copyWith(
                                fontSize: 11.5,
                                fontWeight: unread
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: unread
                                    ? colors.darkGold
                                    : colors.textMuted,
                              ),
                            ),
                            if (unread) ...[
                              const SizedBox(width: 6),
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: colors.accent,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (body.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            strings.t(body),
                            style: AppTextStyles.bodyOf(context).copyWith(
                              fontSize: 13,
                              height: 1.5,
                              color: colors.textMuted,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (showDivider)
                Padding(
                  // Inset to the text column, like grouped lists on iOS.
                  padding: const EdgeInsetsDirectional.only(start: 56),
                  child: Divider(
                    height: 1,
                    thickness: 1,
                    color: colors.primary.withValues(alpha: 0.06),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
