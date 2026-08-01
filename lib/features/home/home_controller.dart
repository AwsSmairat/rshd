import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_exception.dart';
import '../announcements/data/announcements_repository.dart';
import '../announcements/data/models/announcement_model.dart';
import '../assignments/data/assignments_repository.dart';
import '../assignments/data/models/assignment_model.dart';
import '../grades/data/models/grade_model.dart';
import '../notifications/data/models/notification_model.dart';
import '../profile/data/models/profile_model.dart';
import '../quizzes/data/models/quiz_model.dart';
import '../subjects/data/models/subject_model.dart';
import '../grades/data/grades_repository.dart';
import '../notifications/data/notifications_repository.dart';
import '../profile/data/profile_repository.dart';
import '../quizzes/data/quizzes_repository.dart';
import '../subjects/data/subjects_repository.dart';
import 'home_dashboard_model.dart';

enum HomeLoadStatus {
  initial,
  loading,
  loaded,
  refreshing,
  error,
}

class HomeState {
  const HomeState({
    this.status = HomeLoadStatus.initial,
    this.dashboard,
    this.errorMessage,
  });

  final HomeLoadStatus status;
  final HomeDashboardModel? dashboard;
  final String? errorMessage;

  HomeState copyWith({
    HomeLoadStatus? status,
    HomeDashboardModel? dashboard,
    String? errorMessage,
    bool clearError = false,
    bool clearDashboard = false,
  }) {
    return HomeState(
      status: status ?? this.status,
      dashboard: clearDashboard ? null : (dashboard ?? this.dashboard),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class _SectionResult<T> {
  const _SectionResult({
    this.data,
    this.failed = false,
    this.unauthorized = false,
  });

  final T? data;
  final bool failed;
  final bool unauthorized;
}

class HomeController extends StateNotifier<HomeState> {
  HomeController({
    required ProfileRepository profileRepository,
    required SubjectsRepository subjectsRepository,
    required AssignmentsRepository assignmentsRepository,
    required QuizzesRepository quizzesRepository,
    required GradesRepository gradesRepository,
    required NotificationsRepository notificationsRepository,
    required AnnouncementsRepository announcementsRepository,
  })  : _profileRepository = profileRepository,
        _subjectsRepository = subjectsRepository,
        _assignmentsRepository = assignmentsRepository,
        _quizzesRepository = quizzesRepository,
        _gradesRepository = gradesRepository,
        _notificationsRepository = notificationsRepository,
        _announcementsRepository = announcementsRepository,
        super(const HomeState());

  final ProfileRepository _profileRepository;
  final SubjectsRepository _subjectsRepository;
  final AssignmentsRepository _assignmentsRepository;
  final QuizzesRepository _quizzesRepository;
  final GradesRepository _gradesRepository;
  final NotificationsRepository _notificationsRepository;
  final AnnouncementsRepository _announcementsRepository;

  Future<void> load({
    bool refresh = false,
    String? fallbackStudentName,
  }) async {
    if (state.status == HomeLoadStatus.loading && !refresh) {
      return;
    }

    state = state.copyWith(
      status: refresh ? HomeLoadStatus.refreshing : HomeLoadStatus.loading,
      clearError: true,
    );

    try {
      final previousDashboard = state.dashboard;

      final profileFuture = _loadSection<ProfileModel>(
        () => _profileRepository.getProfile(),
      );
      final subjectsFuture = _loadSection<List<SubjectModel>>(
        () => _subjectsRepository.getMySubjects(),
      );
      final catalogFuture = _loadSection<List<SubjectModel>>(
        () => _subjectsRepository.getSubjectsCatalog(),
      );
      final assignmentsFuture = _loadSection<List<AssignmentModel>>(
        () => _assignmentsRepository.getAssignments(),
      );
      final quizzesFuture = _loadSection<List<QuizModel>>(
        () => _quizzesRepository.getQuizzes(),
      );
      final gradesFuture = _loadSection<List<GradeModel>>(
        () => _gradesRepository.getGrades(),
      );
      final notificationsFuture = _loadSection<List<NotificationModel>>(
        () => _notificationsRepository.getNotifications(),
      );
      final announcementsFuture = _loadSection<List<AnnouncementModel>>(
        () => _announcementsRepository.getAnnouncements(),
      );

      final results = await Future.wait([
        profileFuture,
        subjectsFuture,
        catalogFuture,
        assignmentsFuture,
        quizzesFuture,
        gradesFuture,
        notificationsFuture,
        announcementsFuture,
      ]);

      for (final result in results) {
        if (result.unauthorized) {
          state = const HomeState(
            status: HomeLoadStatus.error,
            errorMessage: 'انتهت الجلسة. يرجى تسجيل الدخول مجدداً.',
          );
          return;
        }
      }

      final profileResult = results[0] as _SectionResult<ProfileModel>;
      final subjectsResult = results[1] as _SectionResult<List<SubjectModel>>;
      final catalogResult = results[2] as _SectionResult<List<SubjectModel>>;
      final assignmentsResult =
          results[3] as _SectionResult<List<AssignmentModel>>;
      final quizzesResult = results[4] as _SectionResult<List<QuizModel>>;
      final gradesResult = results[5] as _SectionResult<List<GradeModel>>;
      final notificationsResult =
          results[6] as _SectionResult<List<NotificationModel>>;
      final announcementsResult =
          results[7] as _SectionResult<List<AnnouncementModel>>;
      final studentName = profileResult.data?.name ?? fallbackStudentName;

      final allFailed = results.every((result) => result.failed);
      if (allFailed || studentName == null || studentName.isEmpty) {
        state = const HomeState(
          status: HomeLoadStatus.error,
          errorMessage: 'تعذر تحميل الصفحة الرئيسية',
        );
        return;
      }

      final notifications = notificationsResult.data ?? const [];
      final unreadCount =
          notifications.where((notification) => !notification.isRead).length;

      state = HomeState(
        status: HomeLoadStatus.loaded,
        dashboard: HomeDashboardModel(
          studentName: studentName,
          subjects: subjectsResult.failed
              ? (previousDashboard?.subjects ?? const [])
              : (subjectsResult.data ?? const []),
          catalogSubjects: catalogResult.failed
              ? (previousDashboard?.catalogSubjects ?? const [])
              : (catalogResult.data ?? const []),
          assignments: assignmentsResult.failed
              ? (previousDashboard?.assignments ?? const [])
              : (assignmentsResult.data ?? const []),
          quizzes: quizzesResult.failed
              ? (previousDashboard?.quizzes ?? const [])
              : (quizzesResult.data ?? const []),
          grades: gradesResult.failed
              ? (previousDashboard?.grades ?? const [])
              : (gradesResult.data ?? const []),
          unreadNotificationsCount: unreadCount,
          notificationsLoadFailed: notificationsResult.failed,
          announcements: announcementsResult.failed
              ? (previousDashboard?.announcements ?? const [])
              : (announcementsResult.data ?? const []),
          announcementsLoadFailed: announcementsResult.failed,
        ),
      );
    } on ApiException catch (error) {
      state = HomeState(
        status: HomeLoadStatus.error,
        errorMessage: error.isUnauthorized
            ? 'انتهت الجلسة. يرجى تسجيل الدخول مجدداً.'
            : (error.statusCode == null && error.message.contains('اتصال')
                ? 'تعذر الاتصال بالسيرفر'
                : 'تعذر تحميل الصفحة الرئيسية'),
      );
    } catch (_) {
      state = const HomeState(
        status: HomeLoadStatus.error,
        errorMessage: 'تعذر الاتصال بالسيرفر',
      );
    }
  }

  Future<_SectionResult<T>> _loadSection<T>(Future<T> Function() loader) async {
    try {
      final data = await loader();
      return _SectionResult(data: data);
    } on ApiException catch (error) {
      if (error.isUnauthorized) {
        return const _SectionResult(unauthorized: true);
      }
      return _SectionResult(
        failed: true,
        data: null,
      );
    } catch (_) {
      return const _SectionResult(failed: true);
    }
  }
}

final homeControllerProvider =
    StateNotifierProvider<HomeController, HomeState>((ref) {
  return HomeController(
    profileRepository: ref.watch(profileRepositoryProvider),
    subjectsRepository: ref.watch(subjectsRepositoryProvider),
    assignmentsRepository: ref.watch(assignmentsRepositoryProvider),
    quizzesRepository: ref.watch(quizzesRepositoryProvider),
    gradesRepository: ref.watch(gradesRepositoryProvider),
    notificationsRepository: ref.watch(notificationsRepositoryProvider),
    announcementsRepository: ref.watch(announcementsRepositoryProvider),
  );
});
