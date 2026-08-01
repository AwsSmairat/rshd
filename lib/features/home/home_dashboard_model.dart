import '../announcements/data/models/announcement_model.dart';
import '../assignments/data/models/assignment_model.dart';
import '../grades/data/models/grade_model.dart';
import '../quizzes/data/models/quiz_model.dart';
import '../subjects/data/models/subject_model.dart';

/// Aggregated dashboard data from existing API responses.
///
/// TODO: Add /dashboard endpoint later for performance.
class HomeDashboardModel {
  const HomeDashboardModel({
    required this.studentName,
    this.subjects = const [],
    this.catalogSubjects = const [],
    this.assignments = const [],
    this.quizzes = const [],
    this.grades = const [],
    this.unreadNotificationsCount = 0,
    this.notificationsLoadFailed = false,
    this.announcements = const [],
    this.announcementsLoadFailed = false,
  });

  final String studentName;
  /// Activated/enrolled subjects for "موادي".
  final List<SubjectModel> subjects;
  /// All active catalog subjects for department cards counts.
  final List<SubjectModel> catalogSubjects;
  final List<AssignmentModel> assignments;
  final List<QuizModel> quizzes;
  final List<GradeModel> grades;
  final int unreadNotificationsCount;
  final bool notificationsLoadFailed;
  final List<AnnouncementModel> announcements;
  final bool announcementsLoadFailed;

  int get subjectsCount => subjects.length;

  int get unsubmittedAssignmentsCount =>
      assignments.where((assignment) => !assignment.isSubmitted).length;

  int get availableQuizzesCount =>
      quizzes.where((quiz) => quiz.isActive && !quiz.isCompleted).length;

  double? get averageGrade {
    final values = grades
        .map((grade) => grade.gradeValue)
        .whereType<double>()
        .toList();
    if (values.isEmpty) {
      return null;
    }
    return values.reduce((a, b) => a + b) / values.length;
  }

  double? get highestGrade {
    final values = grades
        .map((grade) => grade.gradeValue)
        .whereType<double>()
        .toList();
    if (values.isEmpty) {
      return null;
    }
    return values.reduce((a, b) => a > b ? a : b);
  }

  List<SubjectModel> get recentSubjects => subjects.take(3).toList();

  /// Activated subject with the highest progress for "continue learning".
  SubjectModel? get continueLearningSubject {
    if (subjects.isEmpty) {
      return null;
    }

    return subjects.reduce((best, current) {
      final bestProgress = resolvedProgressPercent(best);
      final currentProgress = resolvedProgressPercent(current);
      if (currentProgress > bestProgress) {
        return current;
      }
      return best;
    });
  }

  double resolvedProgressPercent(SubjectModel subject) {
    if (subject.progressPercent != null) {
      return subject.progressPercent!;
    }
    return progressPercentForSubject(subject.id);
  }

  double progressPercentForSubject(int subjectId) {
    for (final subject in subjects) {
      if (subject.id == subjectId && subject.progressPercent != null) {
        return subject.progressPercent!;
      }
    }

    final subjectAssignments =
        assignments.where((assignment) => assignment.subjectId == subjectId);
    final subjectQuizzes =
        quizzes.where((quiz) => quiz.subjectId == subjectId);
    final total = subjectAssignments.length + subjectQuizzes.length;
    if (total == 0) {
      return 0;
    }
    final completed = subjectAssignments.where((a) => a.isSubmitted).length +
        subjectQuizzes.where((q) => q.isCompleted).length;
    return (completed / total) * 100;
  }

  List<AssignmentModel> get upcomingAssignments {
    final sorted = [...assignments];
    sorted.sort((a, b) {
      if (a.isSubmitted != b.isSubmitted) {
        return a.isSubmitted ? 1 : -1;
      }
      final aDate = DateTime.tryParse(a.dueDate ?? '');
      final bDate = DateTime.tryParse(b.dueDate ?? '');
      if (aDate == null && bDate == null) {
        return 0;
      }
      if (aDate == null) {
        return 1;
      }
      if (bDate == null) {
        return -1;
      }
      return aDate.compareTo(bDate);
    });
    return sorted.take(3).toList();
  }

  List<QuizModel> get featuredQuizzes => quizzes.take(3).toList();

  List<GradeModel> get recentGrades => grades.take(2).toList();

  List<AnnouncementModel> get featuredAnnouncements =>
      announcements.take(3).toList();
}
