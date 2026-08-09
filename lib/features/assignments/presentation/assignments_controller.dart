import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../subjects/presentation/subjects_controller.dart';
import '../data/assignments_repository.dart';
import '../data/models/assignment_model.dart';
import '../data/models/assignment_submission_model.dart';

class AssignmentsListState {
  const AssignmentsListState({
    this.status = FeatureLoadStatus.initial,
    this.assignments = const [],
    this.errorMessage,
  });

  final FeatureLoadStatus status;
  final List<AssignmentModel> assignments;
  final String? errorMessage;

  AssignmentsListState copyWith({
    FeatureLoadStatus? status,
    List<AssignmentModel>? assignments,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AssignmentsListState(
      status: status ?? this.status,
      assignments: assignments ?? this.assignments,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class AssignmentDetailsState {
  const AssignmentDetailsState({
    this.status = FeatureLoadStatus.initial,
    this.assignment,
    this.errorMessage,
  });

  final FeatureLoadStatus status;
  final AssignmentModel? assignment;
  final String? errorMessage;

  AssignmentDetailsState copyWith({
    FeatureLoadStatus? status,
    AssignmentModel? assignment,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AssignmentDetailsState(
      status: status ?? this.status,
      assignment: assignment ?? this.assignment,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

enum AssignmentSubmitStatus { initial, submitting, success, error }

class AssignmentSubmitState {
  const AssignmentSubmitState({
    this.status = AssignmentSubmitStatus.initial,
    this.submission,
    this.errorMessage,
  });

  final AssignmentSubmitStatus status;
  final AssignmentSubmissionModel? submission;
  final String? errorMessage;

  AssignmentSubmitState copyWith({
    AssignmentSubmitStatus? status,
    AssignmentSubmissionModel? submission,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AssignmentSubmitState(
      status: status ?? this.status,
      submission: submission ?? this.submission,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

String mapAssignmentError(ApiException error) {
  if (error.isForbidden) {
    return 'لا تملك صلاحية الوصول إلى هذا الواجب';
  }
  if (error.isUnauthorized) {
    return 'انتهت الجلسة. يرجى تسجيل الدخول مجدداً.';
  }
  if (error.statusCode == 404) {
    return 'الواجب غير موجود';
  }
  if (error.statusCode == null && error.message.contains('اتصال')) {
    return 'تعذر الاتصال بالسيرفر';
  }
  return error.message;
}

String mapAssignmentSubmitError(ApiException error) {
  if (error.isForbidden) {
    return 'لا تملك صلاحية الوصول إلى هذا الواجب';
  }
  if (error.isValidationError) {
    final fieldErrors = error.fieldErrors;
    if (fieldErrors.isNotEmpty) {
      return fieldErrors.join('\n');
    }
  }
  if (error.statusCode == null && error.message.contains('اتصال')) {
    return 'تعذر الاتصال بالسيرفر';
  }
  return error.message.isNotEmpty ? error.message : 'تعذر تسليم الواجب';
}

class AssignmentsListController extends StateNotifier<AssignmentsListState> {
  AssignmentsListController(this._repository)
    : super(const AssignmentsListState());

  final AssignmentsRepository _repository;

  Future<void> load({bool refresh = false}) async {
    if (state.status == FeatureLoadStatus.loading && !refresh) {
      return;
    }

    state = state.copyWith(status: FeatureLoadStatus.loading, clearError: true);

    try {
      final assignments = await _repository.getAssignments();
      state = AssignmentsListState(
        status: assignments.isEmpty
            ? FeatureLoadStatus.empty
            : FeatureLoadStatus.loaded,
        assignments: assignments,
      );
    } on ApiException catch (error) {
      state = AssignmentsListState(
        status: FeatureLoadStatus.error,
        errorMessage: mapAssignmentError(error),
      );
    } catch (_) {
      state = const AssignmentsListState(
        status: FeatureLoadStatus.error,
        errorMessage: 'تعذر الاتصال بالسيرفر',
      );
    }
  }

  AssignmentModel? findById(int id) {
    for (final assignment in state.assignments) {
      if (assignment.id == id) {
        return assignment;
      }
    }
    return null;
  }

  void upsertAssignment(AssignmentModel assignment) {
    final updated = [...state.assignments];
    final index = updated.indexWhere((item) => item.id == assignment.id);
    if (index >= 0) {
      updated[index] = assignment;
    } else {
      updated.add(assignment);
    }

    state = state.copyWith(
      status: updated.isEmpty
          ? FeatureLoadStatus.empty
          : FeatureLoadStatus.loaded,
      assignments: updated,
    );
  }
}

class AssignmentDetailsController
    extends StateNotifier<AssignmentDetailsState> {
  AssignmentDetailsController(this._repository)
    : super(const AssignmentDetailsState());

  final AssignmentsRepository _repository;

  Future<void> load(int assignmentId, {AssignmentModel? cached}) async {
    if (cached != null) {
      state = AssignmentDetailsState(
        status: FeatureLoadStatus.loaded,
        assignment: cached,
      );
    } else {
      state = state.copyWith(
        status: FeatureLoadStatus.loading,
        clearError: true,
      );
    }

    try {
      final assignment = await _repository.getAssignmentDetails(assignmentId);
      state = AssignmentDetailsState(
        status: FeatureLoadStatus.loaded,
        assignment: assignment,
      );
    } on ApiException catch (error) {
      state = AssignmentDetailsState(
        status: FeatureLoadStatus.error,
        errorMessage: mapAssignmentError(error),
      );
    } catch (_) {
      state = const AssignmentDetailsState(
        status: FeatureLoadStatus.error,
        errorMessage: 'تعذر الاتصال بالسيرفر',
      );
    }
  }

  void setAssignment(AssignmentModel assignment) {
    state = AssignmentDetailsState(
      status: FeatureLoadStatus.loaded,
      assignment: assignment,
    );
  }
}

class AssignmentSubmitController extends StateNotifier<AssignmentSubmitState> {
  AssignmentSubmitController(this._repository)
    : super(const AssignmentSubmitState());

  final AssignmentsRepository _repository;

  Future<AssignmentSubmissionModel?> submit({
    required int assignmentId,
    String? answerText,
    String? filePath,
    String? fileName,
  }) async {
    state = state.copyWith(
      status: AssignmentSubmitStatus.submitting,
      clearError: true,
    );

    try {
      final submission = await _repository.submitAssignment(
        assignmentId: assignmentId,
        answerText: answerText,
        filePath: filePath,
        fileName: fileName,
      );

      state = AssignmentSubmitState(
        status: AssignmentSubmitStatus.success,
        submission: submission,
      );
      return submission;
    } on ApiException catch (error) {
      state = AssignmentSubmitState(
        status: AssignmentSubmitStatus.error,
        errorMessage: mapAssignmentSubmitError(error),
      );
    } catch (_) {
      state = const AssignmentSubmitState(
        status: AssignmentSubmitStatus.error,
        errorMessage: 'تعذر تسليم الواجب',
      );
    }
    return null;
  }

  void reset() {
    state = const AssignmentSubmitState();
  }
}

final assignmentsListControllerProvider =
    StateNotifierProvider<AssignmentsListController, AssignmentsListState>((
      ref,
    ) {
      return AssignmentsListController(
        ref.watch(assignmentsRepositoryProvider),
      );
    });

final assignmentDetailsControllerProvider = StateNotifierProvider.autoDispose
    .family<AssignmentDetailsController, AssignmentDetailsState, int>((
      ref,
      assignmentId,
    ) {
      return AssignmentDetailsController(
        ref.watch(assignmentsRepositoryProvider),
      );
    });

final assignmentSubmitControllerProvider = StateNotifierProvider.autoDispose
    .family<AssignmentSubmitController, AssignmentSubmitState, int>((
      ref,
      assignmentId,
    ) {
      return AssignmentSubmitController(
        ref.watch(assignmentsRepositoryProvider),
      );
    });
