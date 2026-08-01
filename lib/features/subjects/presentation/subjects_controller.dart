import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../data/models/lesson_file_model.dart';
import '../data/models/lesson_model.dart';
import '../data/models/subject_model.dart';
import '../data/models/video_model.dart';
import '../data/subjects_repository.dart';

enum FeatureLoadStatus {
  initial,
  loading,
  loaded,
  empty,
  error,
}

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

String mapContentError(ApiException error, {bool subjectContext = false, bool fileContext = false}) {
  if (error.isForbidden) {
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

    state = state.copyWith(
      status: FeatureLoadStatus.loading,
      clearError: true,
    );

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
      final subjects = state.subjects.map((subject) {
        if (subject.id != subjectId) {
          return subject;
        }
        return subject.copyWith(enrollmentStatus: updated.enrollmentStatus);
      }).toList(growable: false);

      state = state.copyWith(
        status: subjects.isEmpty
            ? FeatureLoadStatus.empty
            : FeatureLoadStatus.loaded,
        subjects: subjects,
        clearError: true,
      );
      return null;
    } on ApiException catch (error) {
      return mapSubjectsError(error);
    } catch (_) {
      return 'تعذر إرسال طلب الشراء';
    }
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

class SubjectLessonsController extends StateNotifier<LessonsListState> {
  SubjectLessonsController(this._repository) : super(const LessonsListState());

  final SubjectsRepository _repository;

  Future<void> load(int subjectId, {bool refresh = false}) async {
    if (state.status == FeatureLoadStatus.loading && !refresh) {
      return;
    }

    state = state.copyWith(
      status: FeatureLoadStatus.loading,
      clearError: true,
    );

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

class LessonDetailsController extends StateNotifier<LessonDetailsState> {
  LessonDetailsController(this._repository) : super(const LessonDetailsState());

  final SubjectsRepository _repository;

  Future<void> load(int lessonId) async {
    state = state.copyWith(
      status: FeatureLoadStatus.loading,
      clearError: true,
    );

    try {
      final lesson = await _repository.getLessonDetails(lessonId);
      state = LessonDetailsState(
        status: FeatureLoadStatus.loaded,
        lesson: lesson,
      );
    } on ApiException catch (error) {
      state = LessonDetailsState(
        status: FeatureLoadStatus.error,
        errorMessage: mapContentError(error),
      );
    } catch (_) {
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
      state = VideoDetailsState(
        status: FeatureLoadStatus.loaded,
        video: video,
      );
    } on ApiException catch (error) {
      state = VideoDetailsState(
        status: FeatureLoadStatus.error,
        errorMessage: mapContentError(error),
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
        progressMessage:
            showSuccessMessage ? 'تم حفظ تقدم المشاهدة' : state.progressMessage,
        video: VideoModel(
          id: currentVideo.id,
          lessonId: currentVideo.lessonId,
          title: currentVideo.title,
          videoUrl: currentVideo.videoUrl,
          durationSeconds: currentVideo.durationSeconds,
          status: currentVideo.status,
          storageProvider: currentVideo.storageProvider,
          progress: progress,
          createdAt: currentVideo.createdAt,
          updatedAt: currentVideo.updatedAt,
        ),
      );
    } on ApiException catch (error) {
      if (kDebugMode) {
        debugPrint('Video progress sync failed: ${error.message}');
      }
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Video progress sync failed: $error');
      }
    }
  }
}

class FileDetailsController extends StateNotifier<FileDetailsState> {
  FileDetailsController(this._repository) : super(const FileDetailsState());

  final SubjectsRepository _repository;

  Future<void> load(int fileId) async {
    state = state.copyWith(
      status: FeatureLoadStatus.loading,
      clearError: true,
    );

    try {
      final file = await _repository.getFileDetails(fileId);
      state = FileDetailsState(
        status: FeatureLoadStatus.loaded,
        file: file,
      );
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
