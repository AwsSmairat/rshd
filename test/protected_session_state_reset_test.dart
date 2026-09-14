import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rshd/core/device/device_service.dart';
import 'package:rshd/core/network/api_client.dart';
import 'package:rshd/core/security/protected_session_state_reset.dart';
import 'package:rshd/core/storage/secure_storage_service.dart';
import 'package:rshd/features/announcements/presentation/announcements_controller.dart';
import 'package:rshd/features/assignments/presentation/assignments_controller.dart';
import 'package:rshd/features/auth/data/auth_repository.dart';
import 'package:rshd/features/auth/presentation/auth_controller.dart';
import 'package:rshd/features/grades/presentation/grades_controller.dart';
import 'package:rshd/features/help/presentation/help_center_controller.dart';
import 'package:rshd/features/help/presentation/technical_support_controller.dart';
import 'package:rshd/features/home/home_controller.dart';
import 'package:rshd/features/notifications/presentation/notifications_controller.dart';
import 'package:rshd/features/profile/presentation/profile_controller.dart';
import 'package:rshd/features/quizzes/presentation/quizzes_controller.dart';
import 'package:rshd/features/settings/presentation/student_settings_controller.dart';
import 'package:rshd/features/subjects/presentation/subjects_controller.dart';

class _FakeAuthRepository extends AuthRepository {
  _FakeAuthRepository()
    : super(
        apiClient: ApiClient(secureStorage: SecureStorageService()),
        secureStorage: SecureStorageService(),
        deviceService: DeviceService(secureStorage: SecureStorageService()),
      );

  @override
  Future<void> clearLocalSession() async {}
}

void main() {
  test('ending a session recreates persistent protected providers', () async {
    final repository = _FakeAuthRepository();

    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    // Activate the app-level session boundary listener.
    container.read(protectedSessionStateResetProvider);

    final before = <Object>[
      container.read(homeControllerProvider.notifier),
      container.read(gradesListControllerProvider.notifier),
      container.read(assignmentsListControllerProvider.notifier),
      container.read(announcementsListControllerProvider.notifier),
      container.read(profileControllerProvider.notifier),
      container.read(subjectsListControllerProvider.notifier),
      container.read(quizzesListControllerProvider.notifier),
      container.read(notificationsListControllerProvider.notifier),
      container.read(studentSettingsControllerProvider.notifier),
      container.read(technicalSupportControllerProvider.notifier),
      container.read(helpCenterControllerProvider.notifier),
    ];

    await container.read(authControllerProvider.notifier).invalidateSession();
    await Future<void>.delayed(Duration.zero);

    final after = <Object>[
      container.read(homeControllerProvider.notifier),
      container.read(gradesListControllerProvider.notifier),
      container.read(assignmentsListControllerProvider.notifier),
      container.read(announcementsListControllerProvider.notifier),
      container.read(profileControllerProvider.notifier),
      container.read(subjectsListControllerProvider.notifier),
      container.read(quizzesListControllerProvider.notifier),
      container.read(notificationsListControllerProvider.notifier),
      container.read(studentSettingsControllerProvider.notifier),
      container.read(technicalSupportControllerProvider.notifier),
      container.read(helpCenterControllerProvider.notifier),
    ];

    expect(after.length, before.length);

    for (var index = 0; index < before.length; index++) {
      expect(
        identical(before[index], after[index]),
        isFalse,
        reason: 'protected provider at index $index was not recreated',
      );
    }
  });
}
