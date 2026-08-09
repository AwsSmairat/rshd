import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/async_load_guard.dart';
import '../../../core/security/sensitive_data_redactor.dart';
import '../data/models/lesson_file_model.dart';
import '../data/models/lesson_model.dart';
import '../data/models/subject_model.dart';
import '../data/models/video_model.dart';
import '../data/subjects_repository.dart';

enum FeatureLoadStatus { initial, loading, loaded, empty, error }

class SubjectsListState {
  const SubjectsListState({
    this.status = FeatureLoadStatus.initial,
    this.subjects = const [],
    this.errorMessage,
  });

  final FeatureLoadStatus status;
  final List<SubjectModel> subjects;
  final String? errorMessage;

  SubjectsListState copyWith({
    FeatureLoadStatus? status,
    List<SubjectModel>? subjects,
    String? errorMessage,
    bool clearError = false,
  }) {
    return SubjectsListState(
      status: status ?? this.status,
      subjects: subjects ?? this.subjects,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class LessonsListState {
  const LessonsListState({
    this.status = FeatureLoadStatus.initial,
    this.lessons = const [],
    this.errorMessage,
  });

  final FeatureLoadStatus status;
  final List<LessonModel> lessons;
  final String? errorMessage;

  LessonsListState copyWith({
    FeatureLoadStatus? status,
    List<LessonModel>? lessons,
    String? errorMessage,
    bool clearError = false,
  }) {
    return LessonsListState(
      status: status ?? this.status,
      lessons: lessons ?? this.lessons,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class LessonDetailsState {
  const LessonDetailsState({
    this.status = FeatureLoadStatus.initial,
    this.lesson,
    this.errorMessage,
  });

  final FeatureLoadStatus status;
  final LessonModel? lesson;
  final String? errorMessage;

  LessonDetailsState copyWith({
    FeatureLoadStatus? status,
    LessonModel? lesson,
    String? errorMessage,
    bool clearError = false,
  }) {
    return LessonDetailsState(
      status: status ?? this.status,
      lesson: lesson ?? this.lesson,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

String mapSubjectsError(ApiException error) {
  return mapContentError(error, subjectContext: true);
}

String mapContentError(
  ApiException error, {
  bool subjectContext = false,
  bool fileContext = false,
  bool videoContext = false,
}) {
  if (error.isForbidden) {
    if (videoContext) {
      return 'انتهت صلاحية الوصول إلى هذه المادة أو لا تملك صلاحية مشاهدة هذا الفيديو.';
    }
    if (subjectContext) {
      return 'لا تملك صلاحية الوصول إلى هذه المادة';
    }
    if (fileContext) {
      return 'لا تملك صلاحية الوصول إلى هذا الملف';
    }
    return 'لا تملك صلاحية الوصول إلى هذا المحتوى';
  }
  if (error.statusCode == 404) {
    return fileContext ? 'الملف غير موجود' : 'المحتوى غير موجود';
  }
  if (error.isUnauthorized) {
    return 'انتهت الجلسة. يرجى تسجيل الدخول مجدداً.';
  }
  if (error.statusCode == null && error.message.contains('اتصال')) {
    return 'تعذر الاتصال بالسيرفر';
  }
  return error.message;
}

class SubjectsListController extends StateNotifier<SubjectsListState> {
  SubjectsListController(this._repository) : super(const SubjectsListState());

  final SubjectsRepository _repository;

  Future<void> load({bool refresh = false, String? category}) async {
    if (state.status == FeatureLoadStatus.loading && !refresh) {
      return;
    }

    state = state.copyWith(status: FeatureLoadStatus.loading, clearError: true);

    try {
      final subjects = (category != null && category.isNotEmpty)
          ? await _repository.getSubjectsCatalog(category: category)
          : await _repository.getMySubjects();
      state = SubjectsListState(
        status: subjects.isEmpty
            ? FeatureLoadStatus.empty
            : FeatureLoadStatus.loaded,
        subjects: subjects,
      );
    } on ApiException catch (error) {
      state = SubjectsListState(
        status: FeatureLoadStatus.error,
        errorMessage: mapSubjectsError(error),
      );
    } catch (_) {
      state = const SubjectsListState(
        status: FeatureLoadStatus.error,
        errorMessage: 'تعذر الاتصال بالسيرفر',
      );
    }
  }

  Future<String?> requestPurchase(int subjectId) async {
    try {
      final updated = await _repository.requestPurchase(subjectId);
      syncEnrollmentStatus(subjectId, updated.enrollmentStatus);
      return null;
    } on ApiException catch (error) {
      return mapSubjectsError(error);
    } catch (_) {
      return 'تعذر إرسال طلب الشراء';
    }
  }

  void syncEnrollmentStatus(int subjectId, String enrollmentStatus) {
    if (!state.subjects.any((subject) => subject.id == subjectId)) {
      return;
    }

    final subjects = state.subjects
        .map((subject) {
          if (subject.id != subjectId) {
            return subject;
          }
          return subject.copyWith(enrollmentStatus: enrollmentStatus);
        })
        .toList(growable: false);

    state = state.copyWith(
      status: subjects.isEmpty
          ? FeatureLoadStatus.empty
          : FeatureLoadStatus.loaded,
      subjects: subjects,
      clearError: true,
    );
  }

  void syncSubjectProgress(SubjectModel subject) {
    if (!state.subjects.any((entry) => entry.id == subject.id)) {
      return;
    }

    final subjects = state.subjects
        .map((entry) {
          if (entry.id != subject.id) {
            return entry;
          }

          return entry.copyWith(progressPercent: subject.progressPercent);
        })
        .toList(growable: false);

    state = state.copyWith(subjects: subjects);
  }

  SubjectModel? findSubjectById(int id) {
    for (final subject in state.subjects) {
      if (subject.id == id) {
        return subject;
      }
    }
    return null;
  }
}

class SubjectDetailsState {
  const SubjectDetailsState({
    this.status = FeatureLoadStatus.initial,
    this.subject,
    this.errorMessage,
  });

  final FeatureLoadStatus status;
  final SubjectModel? subject;
  final String? errorMessage;

  SubjectDetailsState copyWith({
    FeatureLoadStatus? status,
    SubjectModel? subject,
    String? errorMessage,
    bool clearError = false,
  }) {
    return SubjectDetailsState(
      status: status ?? this.status,
      subject: subject ?? this.subject,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class SubjectDetailsController extends StateNotifier<SubjectDetailsState> {
  SubjectDetailsController(this._repository)
    : super(const SubjectDetailsState());

  final SubjectsRepository _repository;

  Future<void> load(
    int subjectId, {
    SubjectModel? initial,
    SubjectModel? cached,
    bool refresh = false,
  }) async {
    if (!refresh) {
      final existing = initial ?? cached ?? state.subject;
      if (existing != null && existing.id == subjectId) {
        state = SubjectDetailsState(
          status: FeatureLoadStatus.loaded,
          subject: existing,
        );
        return;
      }
    }

    if (state.status == FeatureLoadStatus.loading && !refresh) {
      return;
    }

    state = state.copyWith(status: FeatureLoadStatus.loading, clearError: true);

    try {
      final subject = await _repository.findSubjectById(subjectId);
      if (subject == null) {
        state = const SubjectDetailsState(
          status: FeatureLoadStatus.error,
          errorMessage: 'المادة غير موجودة',
        );
        return;
      }

      state = SubjectDetailsState(
        status: FeatureLoadStatus.loaded,
        subject: subject,
      );
    } on ApiException catch (error) {
      state = SubjectDetailsState(
        status: FeatureLoadStatus.error,
        errorMessage: mapSubjectsError(error),
      );
    } catch (_) {
      state = const SubjectDetailsState(
        status: FeatureLoadStatus.error,
        errorMessage: 'تعذر الاتصال بالسيرفر',
      );
    }
  }

  void updateSubject(SubjectModel subject) {
    state = state.copyWith(subject: subject);
  }
}

class SubjectLessonsController extends StateNotifier<LessonsListState> {
  SubjectLessonsController(this._repository) : super(const LessonsListState());

  final SubjectsRepository _repository;

  Future<void> load(int subjectId, {bool refresh = false}) async {
    if (state.status == FeatureLoadStatus.loading && !refresh) {
      return;
    }

    state = state.copyWith(status: FeatureLoadStatus.loading, clearError: true);

    try {
      final lessons = await _repository.getSubjectLessons(subjectId);
      state = LessonsListState(
        status: lessons.isEmpty
            ? FeatureLoadStatus.empty
            : FeatureLoadStatus.loaded,
        lessons: lessons,
      );
    } on ApiException catch (error) {
      state = LessonsListState(
        status: FeatureLoadStatus.error,
        errorMessage: mapSubjectsError(error),
      );
    } catch (_) {
      state = const LessonsListState(
        status: FeatureLoadStatus.error,
        errorMessage: 'تعذر الاتصال بالسيرفر',
      );
    }
  }
}

class LessonDetailsController extends StateNotifier<LessonDetailsState>
    with AsyncLoadGuard {
  LessonDetailsController(this._repository) : super(const LessonDetailsState());

  final SubjectsRepository _repository;

  Future<void> load(int lessonId) async {
    final generation = beginLoad();

    state = state.copyWith(status: FeatureLoadStatus.loading, clearError: true);

    try {
      final lesson = await _repository.getLessonDetails(lessonId);
      if (!isCurrentLoad(generation)) {
        return;
      }
      state = LessonDetailsState(
        status: FeatureLoadStatus.loaded,
        lesson: lesson,
      );
    } on ApiException catch (error) {
      if (!isCurrentLoad(generation)) {
        return;
      }
      state = LessonDetailsState(
        status: FeatureLoadStatus.error,
        errorMessage: mapContentError(error),
      );
    } catch (_) {
      if (!isCurrentLoad(generation)) {
        return;
      }
      state = const LessonDetailsState(
        status: FeatureLoadStatus.error,
        errorMessage: 'تعذر الاتصال بالسيرفر',
      );
    }
  }
}

final subjectsListControllerProvider =
    StateNotifierProvider<SubjectsListController, SubjectsListState>((ref) {
      return SubjectsListController(ref.watch(subjectsRepositoryProvider));
    });

final subjectDetailsControllerProvider = StateNotifierProvider.autoDispose
    .family<SubjectDetailsController, SubjectDetailsState, int>((
      ref,
      subjectId,
    ) {
      return SubjectDetailsController(ref.watch(subjectsRepositoryProvider));
    });

final subjectLessonsControllerProvider = StateNotifierProvider.autoDispose
    .family<SubjectLessonsController, LessonsListState, int>((ref, subjectId) {
      return SubjectLessonsController(ref.watch(subjectsRepositoryProvider));
    });

final lessonDetailsControllerProvider = StateNotifierProvider.autoDispose
    .family<LessonDetailsController, LessonDetailsState, int>((ref, lessonId) {
      return LessonDetailsController(ref.watch(subjectsRepositoryProvider));
    });

class VideoDetailsState {
  const VideoDetailsState({
    this.status = FeatureLoadStatus.initial,
    this.video,
    this.errorMessage,
    this.progressMessage,
  });

  final FeatureLoadStatus status;
  final VideoModel? video;
  final String? errorMessage;
  final String? progressMessage;

  VideoDetailsState copyWith({
    FeatureLoadStatus? status,
    VideoModel? video,
    String? errorMessage,
    bool clearError = false,
    String? progressMessage,
    bool clearProgressFeedback = false,
  }) {
    return VideoDetailsState(
      status: status ?? this.status,
      video: video ?? this.video,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      progressMessage: clearProgressFeedback
          ? null
          : (progressMessage ?? this.progressMessage),
    );
  }
}

class FileDetailsState {
  const FileDetailsState({
    this.status = FeatureLoadStatus.initial,
    this.file,
    this.errorMessage,
  });

  final FeatureLoadStatus status;
  final LessonFileModel? file;
  final String? errorMessage;

  FileDetailsState copyWith({
    FeatureLoadStatus? status,
    LessonFileModel? file,
    String? errorMessage,
    bool clearError = false,
  }) {
    return FileDetailsState(
      status: status ?? this.status,
      file: file ?? this.file,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class VideoDetailsController extends StateNotifier<VideoDetailsState> {
  VideoDetailsController(this._repository) : super(const VideoDetailsState());

  final SubjectsRepository _repository;

  Future<void> load(int videoId) async {
    state = state.copyWith(
      status: FeatureLoadStatus.loading,
      clearError: true,
      clearProgressFeedback: true,
    );

    try {
      final video = await _repository.getVideoDetails(videoId);
      state = VideoDetailsState(status: FeatureLoadStatus.loaded, video: video);
    } on ApiException catch (error) {
      state = VideoDetailsState(
        status: FeatureLoadStatus.error,
        errorMessage: mapContentError(error, videoContext: true),
      );
    } catch (_) {
      state = const VideoDetailsState(
        status: FeatureLoadStatus.error,
        errorMessage: 'تعذر الاتصال بالسيرفر',
      );
    }
  }

  Future<void> syncProgress({
    required int videoId,
    required int currentPositionSeconds,
    required int durationSeconds,
    bool showSuccessMessage = false,
  }) async {
    if (currentPositionSeconds <= 0) {
      return;
    }

    final completionPercentage = durationSeconds > 0
        ? ((currentPositionSeconds / durationSeconds) * 100)
              .clamp(0, 100)
              .round()
        : 0;

    try {
      final progress = await _repository.updateVideoProgress(
        videoId,
        watchedSeconds: currentPositionSeconds,
        currentPosition: currentPositionSeconds,
        completionPercentage: completionPercentage,
        replayCount: 0,
      );

      final currentVideo = state.video;
      if (currentVideo == null) {
        return;
      }

      state = state.copyWith(
        progressMessage: showSuccessMessage
            ? 'تم حفظ تقدم المشاهدة'
            : state.progressMessage,
        video: currentVideo.copyWith(progress: progress),
      );
    } on ApiException catch (error) {
      if (kDebugMode) {
        debugPrint(
          'Video progress sync failed: ${SensitiveDataRedactor.redactString(error.message)}',
        );
      }
    } catch (error) {
      if (kDebugMode) {
        debugPrint(
          'Video progress sync failed: ${SensitiveDataRedactor.redactString(error.toString())}',
        );
      }
    }
  }

  Future<VideoPlaybackModel?> refreshPlayback(int videoId) async {
    try {
      final playback = await _repository.refreshVideoPlayback(videoId);
      final currentVideo = state.video;

      if (currentVideo != null) {
        state = state.copyWith(
          video: currentVideo.copyWith(playback: playback),
        );
      }

      return playback;
    } on ApiException catch (error) {
      if (error.isForbidden || error.isUnauthorized) {
        state = state.copyWith(
          errorMessage: mapContentError(error, videoContext: true),
        );
      } else if (kDebugMode) {
        debugPrint(
          'Video playback refresh failed: ${SensitiveDataRedactor.redactString(error.message)}',
        );
      }
      return null;
    } catch (error) {
      if (kDebugMode) {
        debugPrint(
          'Video playback refresh failed: ${SensitiveDataRedactor.redactString(error.toString())}',
        );
      }
      return null;
    }
  }
}

class FileDetailsController extends StateNotifier<FileDetailsState> {
  FileDetailsController(this._repository) : super(const FileDetailsState());

  final SubjectsRepository _repository;

  Future<void> load(int fileId) async {
    state = state.copyWith(status: FeatureLoadStatus.loading, clearError: true);

    try {
      final file = await _repository.getFileDetails(fileId);
      state = FileDetailsState(status: FeatureLoadStatus.loaded, file: file);
    } on ApiException catch (error) {
      state = FileDetailsState(
        status: FeatureLoadStatus.error,
        errorMessage: mapContentError(error, fileContext: true),
      );
    } catch (_) {
      state = const FileDetailsState(
        status: FeatureLoadStatus.error,
        errorMessage: 'تعذر الاتصال بالسيرفر',
      );
    }
  }
}

final videoDetailsControllerProvider = StateNotifierProvider.autoDispose
    .family<VideoDetailsController, VideoDetailsState, int>((ref, videoId) {
      return VideoDetailsController(ref.watch(subjectsRepositoryProvider));
    });

final fileDetailsControllerProvider = StateNotifierProvider.autoDispose
    .family<FileDetailsController, FileDetailsState, int>((ref, fileId) {
      return FileDetailsController(ref.watch(subjectsRepositoryProvider));
    });
