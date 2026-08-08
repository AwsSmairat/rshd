import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/announcements/data/models/announcement_model.dart';
import '../../features/announcements/presentation/announcement_details_screen.dart';
import '../../features/announcements/presentation/announcements_screen.dart';
import '../../features/assignments/presentation/assignment_details_screen.dart';
import '../../features/assignments/presentation/assignments_screen.dart';
import '../../features/assignments/presentation/submit_assignment_screen.dart';
import '../../core/platform/platform_settings_controller.dart';
import '../../features/auth/presentation/auth_controller.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/password_reset_verification_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/reset_password_screen.dart';
import '../../features/auth/presentation/verify_email_screen.dart';
import '../../features/grades/presentation/grade_details_screen.dart';
import '../../features/grades/presentation/grades_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/maintenance/maintenance_screen.dart';
import '../../features/legal/terms/presentation/terms_acceptance_gate_controller.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/contact/presentation/contact_us_screen.dart';
import '../../features/help/presentation/help_center_screen.dart';
import '../../features/help/presentation/technical_support_screen.dart';
import '../../features/legal/terms/presentation/terms_acceptance_screen.dart';
import '../../features/legal/terms/presentation/terms_and_conditions_screen.dart';
import '../../features/legal/privacy/presentation/delete_account_screen.dart';
import '../../features/legal/privacy/presentation/privacy_policy_screen.dart';
import '../../features/settings/presentation/student_settings_screen.dart';
import '../../features/quizzes/presentation/quiz_attempt_screen.dart';
import '../../features/quizzes/presentation/quiz_details_screen.dart';
import '../../features/quizzes/presentation/quiz_result_screen.dart';
import '../../features/quizzes/presentation/quizzes_screen.dart';
import '../../features/subjects/data/models/subject_model.dart';
import '../../features/subjects/presentation/file_details_screen.dart';
import '../../features/subjects/presentation/lesson_details_screen.dart';
import '../../features/subjects/presentation/my_subjects_screen.dart';
import '../../features/subjects/presentation/pdf_viewer_screen.dart';
import '../../features/subjects/presentation/subject_details_screen.dart';
import '../../features/subjects/presentation/video_details_screen.dart';
import '../../core/security/protected_content_scope.dart';

class AppRoutes {
  AppRoutes._();

  static const splash = '/splash';
  static const login = '/login';
  static const register = '/register';
  static const verifyEmail = '/verify-email';
  static const forgotPassword = '/forgot-password';
  static const passwordResetVerify = '/password-reset/verify';
  static const passwordResetNew = '/password-reset/new';
  static const home = '/home';
  static const subjects = '/subjects';

  static String subjectsByCategory(String category) =>
      '/subjects?category=$category';

  static String subjectDetails(int id) => '/subjects/$id';

  static String lessonDetails(int id) => '/lessons/$id';

  static String videoDetails(int id) => '/videos/$id';

  static String fileDetails(int id) => '/files/$id';

  static String filePdfViewer(int id) => '/files/$id/pdf';

  static const assignments = '/assignments';

  static String assignmentDetails(int id) => '/assignments/$id';

  static String submitAssignment(int id) => '/assignments/$id/submit';

  static const quizzes = '/quizzes';

  static String quizDetails(int id) => '/quizzes/$id';

  static String quizAttempt(int id) => '/quizzes/$id/attempt';

  static String quizResult(int id) => '/quizzes/$id/result';

  static const grades = '/grades';

  static String gradeDetails(int id) => '/grades/$id';

  static const notifications = '/notifications';

  static const announcements = '/announcements';

  static String announcementDetails(int id) => '/announcements/$id';

  static const profile = '/profile';

  static const privacyPolicy = '/privacy-policy';

  static const deleteAccount = '/delete-account';

  static const termsAndConditions = '/terms-and-conditions';

  static const termsAcceptance = '/terms-acceptance';

  static const helpCenter = '/help-center';

  static const technicalSupport = '/technical-support';

  static const contactUs = '/contact-us';

  static const maintenance = '/maintenance';
}

/// Set by the splash screen once its RSHD reveal animation has finished, so
/// the router doesn't redirect away from /splash mid-animation.
final splashAnimationCompletedProvider = StateProvider<bool>((ref) => false);

final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});

class RouterNotifier extends ChangeNotifier {
  RouterNotifier(this.ref) {
    ref.listen(authControllerProvider, (_, next) => notifyListeners());
    ref.listen(platformSettingsProvider, (_, next) => notifyListeners());
    ref.listen(termsAcceptanceGateProvider, (_, next) => notifyListeners());
  }

  final Ref ref;
}

Widget _protectedContent({
  required String scopeId,
  required Widget child,
}) {
  return ProtectedContentScope(
    scopeId: scopeId,
    child: child,
  );
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: notifier,
    redirect: (context, state) {
      final authState = ref.read(authControllerProvider);
      final location = state.matchedLocation;
      final platformSettings = ref.read(platformSettingsProvider).value;

      final isSplash = location == AppRoutes.splash;
      final isMaintenance = location == AppRoutes.maintenance;
      final isLogin = location == AppRoutes.login;
      final isRegister = location == AppRoutes.register;
      final isVerifyEmail = location.startsWith(AppRoutes.verifyEmail);
      final isForgotPassword = location.startsWith(AppRoutes.forgotPassword);
      final isPasswordResetVerify =
          location.startsWith(AppRoutes.passwordResetVerify);
      final isPasswordResetNew =
          location.startsWith(AppRoutes.passwordResetNew);
      final isPasswordResetRoute =
          isForgotPassword || isPasswordResetVerify || isPasswordResetNew;
      final isAuthRoute =
          isLogin || isRegister || isVerifyEmail || isPasswordResetRoute;

      if (platformSettings?.maintenanceMode == true &&
          !isMaintenance &&
          !isSplash) {
        return AppRoutes.maintenance;
      }

      if (platformSettings?.maintenanceMode != true && isMaintenance) {
        return AppRoutes.splash;
      }

      // Keep the splash on screen until its animation completes; the splash
      // screen navigates itself to the resolved destination.
      if (isSplash && !ref.read(splashAnimationCompletedProvider)) {
        return null;
      }

      if (authState.status == AuthStatus.initial) {
        if (isAuthRoute) {
          return null;
        }
        return isSplash ? null : AppRoutes.splash;
      }

      if (authState.status == AuthStatus.loading && isSplash) {
        return null;
      }

      if (authState.status == AuthStatus.loading && isAuthRoute) {
        return null;
      }

      if (authState.status == AuthStatus.loading && !isSplash) {
        return null;
      }

      if (authState.status == AuthStatus.authenticating && isVerifyEmail) {
        return null;
      }

      if (authState.status == AuthStatus.authenticated) {
        final user = authState.user;
        if (user != null && !user.isStudent) {
          return AppRoutes.login;
        }
        if (user != null && !user.isEmailVerified) {
          return '${AppRoutes.verifyEmail}?email=${Uri.encodeComponent(user.email)}';
        }

        final termsGate = ref.read(termsAcceptanceGateProvider);
        final isTermsAcceptance = location == AppRoutes.termsAcceptance;
        final isTermsPage = location == AppRoutes.termsAndConditions;
        final isPrivacyPage = location == AppRoutes.privacyPolicy;

        if (termsGate.requiresAcceptance &&
            !isTermsAcceptance &&
            !isTermsPage &&
            !isPrivacyPage) {
          return AppRoutes.termsAcceptance;
        }

        if (isAuthRoute || isSplash) {
          return AppRoutes.home;
        }
        return null;
      }

      if (authState.status == AuthStatus.unauthenticated ||
          authState.status == AuthStatus.error) {
        if (isVerifyEmail) {
          return null;
        }
        if (platformSettings?.studentRegistrationEnabled == false && isRegister) {
          return AppRoutes.login;
        }
        if (!isAuthRoute && !isSplash && !isMaintenance) {
          if (authState.pendingVerificationEmail != null) {
            return '${AppRoutes.verifyEmail}?email=${Uri.encodeComponent(authState.pendingVerificationEmail!)}';
          }
          return AppRoutes.login;
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.maintenance,
        builder: (context, state) => const MaintenanceScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) {
          final email = state.uri.queryParameters['email'];
          return LoginScreen(initialEmail: email);
        },
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) {
          final email = state.uri.queryParameters['email'];
          return ForgotPasswordScreen(initialEmail: email);
        },
      ),
      GoRoute(
        path: AppRoutes.passwordResetVerify,
        builder: (context, state) {
          final email = state.uri.queryParameters['email'] ?? '';
          return PasswordResetVerificationScreen(email: email);
        },
      ),
      GoRoute(
        path: AppRoutes.passwordResetNew,
        builder: (context, state) {
          final email = state.uri.queryParameters['email'] ?? '';
          return ResetPasswordScreen(email: email);
        },
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.verifyEmail,
        builder: (context, state) {
          final email = state.uri.queryParameters['email'] ?? '';
          return VerifyEmailScreen(email: email);
        },
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.subjects,
        builder: (context, state) {
          final category = state.uri.queryParameters['category'];
          return MySubjectsScreen(category: category);
        },
      ),
      GoRoute(
        path: '/subjects/:id',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          final subject = state.extra is SubjectModel
              ? state.extra! as SubjectModel
              : null;

          return _protectedContent(
            scopeId: 'subject:$id',
            child: SubjectDetailsScreen(
              subjectId: id,
              subject: subject,
            ),
          );
        },
      ),
      GoRoute(
        path: '/lessons/:id',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return _protectedContent(
            scopeId: 'lesson:$id',
            child: LessonDetailsScreen(lessonId: id),
          );
        },
      ),
      GoRoute(
        path: '/videos/:id',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return _protectedContent(
            scopeId: 'video:$id',
            child: VideoDetailsScreen(videoId: id),
          );
        },
      ),
      GoRoute(
        path: '/files/:id/pdf',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          final extra = state.extra is Map<String, dynamic>
              ? state.extra! as Map<String, dynamic>
              : state.extra is Map
                  ? Map<String, dynamic>.from(state.extra! as Map)
                  : const <String, dynamic>{};

          return _protectedContent(
            scopeId: 'pdf:$id',
            child: PdfViewerScreen(
              fileId: id,
              title: extra['title']?.toString() ?? 'ملف PDF',
              courseTitle: extra['courseTitle']?.toString(),
            ),
          );
        },
      ),
      GoRoute(
        path: '/files/:id',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return _protectedContent(
            scopeId: 'file:$id',
            child: FileDetailsScreen(fileId: id),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.assignments,
        builder: (context, state) => const AssignmentsScreen(),
      ),
      GoRoute(
        path: '/assignments/:id/submit',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return SubmitAssignmentScreen(assignmentId: id);
        },
      ),
      GoRoute(
        path: '/assignments/:id',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return AssignmentDetailsScreen(assignmentId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.quizzes,
        builder: (context, state) => const QuizzesScreen(),
      ),
      GoRoute(
        path: '/quizzes/:id/attempt',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return _protectedContent(
            scopeId: 'quiz_attempt:$id',
            child: QuizAttemptScreen(quizId: id),
          );
        },
      ),
      GoRoute(
        path: '/quizzes/:id/result',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          final extra = state.extra is Map<String, dynamic>
              ? state.extra! as Map<String, dynamic>
              : state.extra is Map
                  ? Map<String, dynamic>.from(state.extra! as Map)
                  : const <String, dynamic>{};

          return QuizResultScreen(
            quizId: id,
            score: extra['score']?.toString() ?? '0',
            questionsCount: int.tryParse(
                  extra['questionsCount']?.toString() ?? '',
                ) ??
                0,
            submittedAt: extra['submittedAt']?.toString() ?? '',
            quizTitle: extra['quizTitle']?.toString() ?? 'الاختبار',
          );
        },
      ),
      GoRoute(
        path: '/quizzes/:id',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return QuizDetailsScreen(quizId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.grades,
        builder: (context, state) => const GradesScreen(),
      ),
      GoRoute(
        path: '/grades/:id',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return GradeDetailsScreen(gradeId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.notifications,
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: AppRoutes.announcements,
        builder: (context, state) => const AnnouncementsScreen(),
      ),
      GoRoute(
        path: '/announcements/:id',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          final announcement = state.extra is AnnouncementModel
              ? state.extra! as AnnouncementModel
              : null;
          return AnnouncementDetailsScreen(
            announcementId: id,
            initialAnnouncement: announcement,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (context, state) => const StudentSettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.helpCenter,
        builder: (context, state) => const HelpCenterScreen(),
      ),
      GoRoute(
        path: AppRoutes.technicalSupport,
        builder: (context, state) => const TechnicalSupportScreen(),
      ),
      GoRoute(
        path: AppRoutes.contactUs,
        builder: (context, state) => const ContactUsScreen(),
      ),
      GoRoute(
        path: AppRoutes.privacyPolicy,
        builder: (context, state) => const PrivacyPolicyPage(),
      ),
      GoRoute(
        path: AppRoutes.termsAcceptance,
        builder: (context, state) => const TermsAcceptanceScreen(),
      ),
      GoRoute(
        path: AppRoutes.termsAndConditions,
        builder: (context, state) => const TermsAndConditionsPage(),
      ),
      GoRoute(
        path: AppRoutes.deleteAccount,
        builder: (context, state) => const DeleteAccountScreen(),
      ),
    ],
  );
});
