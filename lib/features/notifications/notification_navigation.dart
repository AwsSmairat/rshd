import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:rshd/core/router/app_router.dart';
import 'package:rshd/features/notifications/data/models/notification_model.dart';
import 'package:rshd/features/notifications/widgets/notification_message_sheet.dart';

class NotificationNavigation {
  NotificationNavigation._();

  static void open(BuildContext context, NotificationModel notification) {
    if (notification.isMessageNotification) {
      _openMessage(context, notification);
      return;
    }

    switch (notification.effectiveType) {
      case 'subject_activated':
        _openSubject(context, notification);
        return;
      case 'announcement':
        _openAnnouncement(context, notification);
        return;
      case 'assignment_created':
      case 'new_assignment':
      case 'assignment_reminder':
        _openAssignment(context, notification);
        return;
      case 'quiz_created':
      case 'new_quiz':
      case 'quiz_available':
        _openQuiz(context, notification);
        return;
      case 'grade_published':
      case 'new_grade':
        _openGrade(context, notification);
        return;
      case 'instructor_reply':
      case 'student_message':
        _openMessage(context, notification);
        return;
      default:
        _openFallback(context, notification);
    }
  }

  static void _openSubject(
    BuildContext context,
    NotificationModel notification,
  ) {
    final subjectId = notification.subjectId;
    if (subjectId != null) {
      context.push(AppRoutes.subjectDetails(subjectId));
      return;
    }
    context.push(AppRoutes.subjects);
  }

  static void _openAnnouncement(
    BuildContext context,
    NotificationModel notification,
  ) {
    final announcementId = notification.announcementId;
    if (announcementId != null) {
      context.push(AppRoutes.announcementDetails(announcementId));
      return;
    }
    context.push(AppRoutes.announcements);
  }

  static void _openAssignment(
    BuildContext context,
    NotificationModel notification,
  ) {
    final assignmentId = notification.assignmentId;
    if (assignmentId != null) {
      context.push(AppRoutes.assignmentDetails(assignmentId));
      return;
    }
    context.push(AppRoutes.assignments);
  }

  static void _openQuiz(BuildContext context, NotificationModel notification) {
    final quizId = notification.quizId;
    if (quizId != null) {
      context.push(AppRoutes.quizDetails(quizId));
      return;
    }
    context.push(AppRoutes.quizzes);
  }

  static void _openGrade(BuildContext context, NotificationModel notification) {
    final gradeId = notification.gradeId;
    if (gradeId != null) {
      context.push(AppRoutes.gradeDetails(gradeId));
      return;
    }
    if (notification.quizId != null) {
      context.push(AppRoutes.quizDetails(notification.quizId!));
      return;
    }
    context.push(AppRoutes.grades);
  }

  static void _openFallback(
    BuildContext context,
    NotificationModel notification,
  ) {
    if (notification.isMessageNotification) {
      _openMessage(context, notification);
      return;
    }

    if (notification.subjectId != null) {
      context.push(AppRoutes.subjectDetails(notification.subjectId!));
      return;
    }
    if (notification.announcementId != null) {
      context.push(AppRoutes.announcementDetails(notification.announcementId!));
      return;
    }
    context.push(AppRoutes.announcements);
  }

  static void _openMessage(
    BuildContext context,
    NotificationModel notification,
  ) {
    showNotificationMessageSheet(context: context, notification: notification);
  }
}
