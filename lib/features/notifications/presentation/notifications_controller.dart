import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../subjects/presentation/subjects_controller.dart';
import '../data/models/notification_model.dart';
import '../data/notifications_repository.dart';

class NotificationsListState {
  const NotificationsListState({
    this.status = FeatureLoadStatus.initial,
    this.notifications = const [],
    this.errorMessage,
  });

  final FeatureLoadStatus status;
  final List<NotificationModel> notifications;
  final String? errorMessage;

  int get unreadCount =>
      notifications.where((notification) => !notification.isRead).length;

  NotificationsListState copyWith({
    FeatureLoadStatus? status,
    List<NotificationModel>? notifications,
    String? errorMessage,
    bool clearError = false,
  }) {
    return NotificationsListState(
      status: status ?? this.status,
      notifications: notifications ?? this.notifications,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

String mapNotificationsError(ApiException error) {
  if (error.isForbidden) {
    return 'لا تملك صلاحية الوصول إلى هذا الإشعار';
  }
  if (error.isUnauthorized) {
    return 'انتهت الجلسة. يرجى تسجيل الدخول مجدداً.';
  }
  if (error.statusCode == null && error.message.contains('اتصال')) {
    return 'تعذر الاتصال بالسيرفر';
  }
  return error.message;
}

String mapMarkAsReadError(ApiException error) {
  if (error.isForbidden) {
    return 'لا تملك صلاحية الوصول إلى هذا الإشعار';
  }
  if (error.statusCode == null && error.message.contains('اتصال')) {
    return 'تعذر الاتصال بالسيرفر';
  }
  return error.message.isNotEmpty ? error.message : 'تعذر تحديث حالة الإشعار';
}

class NotificationsListController
    extends StateNotifier<NotificationsListState> {
  NotificationsListController(this._repository)
    : super(const NotificationsListState());

  final NotificationsRepository _repository;

  Future<void> load({bool refresh = false}) async {
    if (state.status == FeatureLoadStatus.loading && !refresh) {
      return;
    }

    state = state.copyWith(status: FeatureLoadStatus.loading, clearError: true);

    try {
      final notifications = await _repository.getNotifications();

      if (!mounted) {
        return;
      }

      state = NotificationsListState(
        status: notifications.isEmpty
            ? FeatureLoadStatus.empty
            : FeatureLoadStatus.loaded,
        notifications: notifications,
      );
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }

      state = NotificationsListState(
        status: FeatureLoadStatus.error,
        errorMessage: mapNotificationsError(error),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      state = const NotificationsListState(
        status: FeatureLoadStatus.error,
        errorMessage: 'تعذر الاتصال بالسيرفر',
      );
    }
  }

  NotificationModel? findById(int id) {
    for (final notification in state.notifications) {
      if (notification.id == id) {
        return notification;
      }
    }
    return null;
  }

  /// Marks every unread notification as read. The API has no bulk call, so
  /// each one is sent in parallel; whatever succeeds is applied, and the
  /// result says whether all of them did.
  Future<bool> markAllAsRead() async {
    final unread = state.notifications.where((n) => !n.isRead).toList();
    if (unread.isEmpty) return true;

    final results = await Future.wait(
      unread.map((n) async {
        try {
          return await _repository.markAsRead(n.id);
        } catch (_) {
          return null;
        }
      }),
    );
    if (!mounted) return false;

    final updated = {
      for (final n in results.whereType<NotificationModel>()) n.id: n,
    };
    state = state.copyWith(
      notifications: [for (final n in state.notifications) updated[n.id] ?? n],
    );
    return updated.length == unread.length;
  }

  Future<bool> markAsRead(int notificationId) async {
    try {
      final updated = await _repository.markAsRead(notificationId);

      if (!mounted) {
        return false;
      }

      final updatedList = state.notifications
          .map(
            (notification) =>
                notification.id == notificationId ? updated : notification,
          )
          .toList();

      state = state.copyWith(
        status: updatedList.isEmpty
            ? FeatureLoadStatus.empty
            : FeatureLoadStatus.loaded,
        notifications: updatedList,
      );
      return true;
    } on ApiException catch (error) {
      if (!mounted) {
        return false;
      }

      state = state.copyWith(errorMessage: mapMarkAsReadError(error));
      return false;
    } catch (_) {
      if (!mounted) {
        return false;
      }

      state = state.copyWith(errorMessage: 'تعذر تحديث حالة الإشعار');
      return false;
    }
  }

  void updateNotification(NotificationModel notification) {
    final updatedList = state.notifications
        .map((item) => item.id == notification.id ? notification : item)
        .toList();

    state = state.copyWith(notifications: updatedList);
  }
}

final notificationsListControllerProvider =
    StateNotifierProvider<NotificationsListController, NotificationsListState>((
      ref,
    ) {
      return NotificationsListController(
        ref.watch(notificationsRepositoryProvider),
      );
    });
