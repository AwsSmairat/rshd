import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rshd/features/notifications/data/models/notification_model.dart';
import 'package:rshd/features/notifications/data/notifications_repository.dart';
import 'package:rshd/features/notifications/presentation/notifications_controller.dart';
import 'package:rshd/features/notifications/presentation/notifications_screen.dart';

NotificationModel _n(int id, String type, {bool read = false}) =>
    NotificationModel(
      id: id,
      userId: 1,
      title: 't$id',
      type: type,
      isRead: read,
    );

class _FakeRepository implements NotificationsRepository {
  _FakeRepository(this.items, {this.failId});

  final List<NotificationModel> items;
  final int? failId;

  @override
  Future<List<NotificationModel>> getNotifications() async => items;

  @override
  Future<NotificationModel> markAsRead(int notificationId) async {
    if (notificationId == failId) throw Exception('offline');
    final n = items.firstWhere((e) => e.id == notificationId);
    return NotificationModel(
      id: n.id,
      userId: n.userId,
      title: n.title,
      type: n.type,
      isRead: true,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final items = [
    _n(1, 'subject_activated'),
    _n(2, 'announcement'),
    _n(3, 'new_quiz', read: true),
    _n(4, 'instructor_reply'),
  ];

  test('mark all as read clears every unread notification', () async {
    final container = ProviderContainer(
      overrides: [
        notificationsRepositoryProvider.overrideWithValue(
          _FakeRepository(items),
        ),
      ],
    );
    addTearDown(container.dispose);
    final controller = container.read(
      notificationsListControllerProvider.notifier,
    );
    await controller.load();
    expect(container.read(notificationsListControllerProvider).unreadCount, 3);

    expect(await controller.markAllAsRead(), isTrue);
    expect(container.read(notificationsListControllerProvider).unreadCount, 0);
  });

  test('a failed one stays unread and is reported', () async {
    final container = ProviderContainer(
      overrides: [
        notificationsRepositoryProvider.overrideWithValue(
          _FakeRepository(items, failId: 2),
        ),
      ],
    );
    addTearDown(container.dispose);
    final controller = container.read(
      notificationsListControllerProvider.notifier,
    );
    await controller.load();

    expect(await controller.markAllAsRead(), isFalse);
    final state = container.read(notificationsListControllerProvider);
    expect(state.unreadCount, 1);
    expect(state.notifications.firstWhere((n) => !n.isRead).id, 2);
  });

  test('filters sort notifications by what they are about', () {
    List<int> ids(NotificationFilter f) =>
        items.where(f.matches).map((n) => n.id).toList();

    expect(ids(NotificationFilter.all), [1, 2, 3, 4]);
    expect(ids(NotificationFilter.unread), [1, 2, 4]);
    expect(ids(NotificationFilter.courses), [1]);
    expect(ids(NotificationFilter.announcements), [2]);
    expect(ids(NotificationFilter.tasks), [3]);
    expect(ids(NotificationFilter.messages), [4]);
  });
}
