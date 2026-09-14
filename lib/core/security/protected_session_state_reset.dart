import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/announcements/presentation/announcements_controller.dart';
import '../../features/assignments/presentation/assignments_controller.dart';
import '../../features/auth/presentation/auth_controller.dart';
import '../../features/grades/presentation/grades_controller.dart';
import '../../features/help/presentation/help_center_controller.dart';
import '../../features/help/presentation/technical_support_controller.dart';
import '../../features/home/home_controller.dart';
import '../../features/legal/terms/data/terms_and_conditions_repository.dart';
import '../../features/notifications/presentation/notifications_controller.dart';
import '../../features/profile/presentation/profile_controller.dart';
import '../../features/quizzes/presentation/quizzes_controller.dart';
import '../../features/settings/presentation/student_settings_controller.dart';
import '../../features/subjects/presentation/subjects_controller.dart';

final protectedSessionStateResetProvider = Provider<void>((ref) {
  ref.listen<AuthState>(authControllerProvider, (previous, next) {
    final becameUnauthenticated =
        next.status == AuthStatus.unauthenticated &&
        previous?.status != AuthStatus.unauthenticated;

    final startedAuthenticatedSession =
        next.status == AuthStatus.authenticated &&
        (previous?.status != AuthStatus.authenticated ||
            previous?.user?.id != next.user?.id);

    if (!becameUnauthenticated && !startedAuthenticatedSession) {
      return;
    }

    _invalidateProtectedSessionState(ref);
  });
});

void _invalidateProtectedSessionState(Ref ref) {
  ref.invalidate(homeControllerProvider);
  ref.invalidate(gradesListControllerProvider);
  ref.invalidate(assignmentsListControllerProvider);
  ref.invalidate(announcementsListControllerProvider);
  ref.invalidate(profileControllerProvider);
  ref.invalidate(subjectsListControllerProvider);
  ref.invalidate(quizzesListControllerProvider);
  ref.invalidate(notificationsListControllerProvider);
  ref.invalidate(studentSettingsControllerProvider);
  ref.invalidate(technicalSupportControllerProvider);
  ref.invalidate(helpCenterControllerProvider);

  // User-specific acceptance status must never survive into another session.
  ref.invalidate(termsAcceptanceStatusProvider);
}
