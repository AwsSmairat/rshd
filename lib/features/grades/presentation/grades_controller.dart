import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/async_load_guard.dart';
import '../../subjects/presentation/subjects_controller.dart';
import '../data/grades_repository.dart';
import '../data/models/grade_model.dart';

class GradesListState {
  const GradesListState({
    this.status = FeatureLoadStatus.initial,
    this.grades = const [],
    this.errorMessage,
  });

  final FeatureLoadStatus status;
  final List<GradeModel> grades;
  final String? errorMessage;

  int get count => grades.length;

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

  GradesListState copyWith({
    FeatureLoadStatus? status,
    List<GradeModel>? grades,
    String? errorMessage,
    bool clearError = false,
  }) {
    return GradesListState(
      status: status ?? this.status,
      grades: grades ?? this.grades,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class GradeDetailsState {
  const GradeDetailsState({
    this.status = FeatureLoadStatus.initial,
    this.grade,
    this.errorMessage,
  });

  final FeatureLoadStatus status;
  final GradeModel? grade;
  final String? errorMessage;

  GradeDetailsState copyWith({
    FeatureLoadStatus? status,
    GradeModel? grade,
    String? errorMessage,
    bool clearError = false,
  }) {
    return GradeDetailsState(
      status: status ?? this.status,
      grade: grade ?? this.grade,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

String mapGradesError(ApiException error) {
  if (error.isForbidden) {
    return 'لا تملك صلاحية الوصول إلى هذه الدرجات';
  }
  if (error.isUnauthorized) {
    return 'انتهت الجلسة. يرجى تسجيل الدخول مجدداً.';
  }
  if (error.statusCode == null && error.message.contains('اتصال')) {
    return 'تعذر الاتصال بالسيرفر';
  }
  return error.message;
}

class GradesListController extends StateNotifier<GradesListState> {
  GradesListController(this._repository) : super(const GradesListState());

  final GradesRepository _repository;

  Future<void> load({bool refresh = false}) async {
    if (state.status == FeatureLoadStatus.loading && !refresh) {
      return;
    }

    state = state.copyWith(status: FeatureLoadStatus.loading, clearError: true);

    try {
      final grades = await _repository.getGrades();
      state = GradesListState(
        status: grades.isEmpty
            ? FeatureLoadStatus.empty
            : FeatureLoadStatus.loaded,
        grades: grades,
      );
    } on ApiException catch (error) {
      state = GradesListState(
        status: FeatureLoadStatus.error,
        errorMessage: mapGradesError(error),
      );
    } catch (_) {
      state = const GradesListState(
        status: FeatureLoadStatus.error,
        errorMessage: 'تعذر الاتصال بالسيرفر',
      );
    }
  }

  GradeModel? findById(int id) {
    for (final grade in state.grades) {
      if (grade.id == id) {
        return grade;
      }
    }
    return null;
  }
}

class GradeDetailsController extends StateNotifier<GradeDetailsState>
    with AsyncLoadGuard {
  GradeDetailsController(this._repository) : super(const GradeDetailsState());

  final GradesRepository _repository;

  Future<void> load(int gradeId, {GradeModel? cached}) async {
    if (cached != null) {
      state = GradeDetailsState(
        status: FeatureLoadStatus.loaded,
        grade: cached,
      );
      return;
    }

    final generation = beginLoad();

    state = state.copyWith(status: FeatureLoadStatus.loading, clearError: true);

    try {
      final grade = await _repository.findGradeById(gradeId);
      if (!isCurrentLoad(generation)) {
        return;
      }

      if (grade == null) {
        state = const GradeDetailsState(
          status: FeatureLoadStatus.error,
          errorMessage: 'الدرجة غير موجودة',
        );
        return;
      }

      state = GradeDetailsState(status: FeatureLoadStatus.loaded, grade: grade);
    } on ApiException catch (error) {
      if (!isCurrentLoad(generation)) {
        return;
      }
      state = GradeDetailsState(
        status: FeatureLoadStatus.error,
        errorMessage: mapGradesError(error),
      );
    } catch (_) {
      if (!isCurrentLoad(generation)) {
        return;
      }
      state = const GradeDetailsState(
        status: FeatureLoadStatus.error,
        errorMessage: 'تعذر الاتصال بالسيرفر',
      );
    }
  }
}

final gradesListControllerProvider =
    StateNotifierProvider<GradesListController, GradesListState>((ref) {
      return GradesListController(ref.watch(gradesRepositoryProvider));
    });

final gradeDetailsControllerProvider = StateNotifierProvider.autoDispose
    .family<GradeDetailsController, GradeDetailsState, int>((ref, gradeId) {
      return GradeDetailsController(ref.watch(gradesRepositoryProvider));
    });
