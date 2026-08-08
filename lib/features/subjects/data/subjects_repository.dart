import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/api_response.dart';
import 'models/file_download_model.dart';
import 'models/lesson_file_model.dart';
import 'models/lesson_model.dart';
import 'models/subject_model.dart';
import 'models/pdf_annotation_model.dart';
import 'models/video_model.dart';

class SubjectsRepository {
  SubjectsRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<List<SubjectModel>> getMySubjects() async {
    return _fetchList(
      ApiEndpoints.mySubjects,
      SubjectModel.fromJson,
      emptyMessage: 'لا توجد مواد مفعلة حالياً.',
    );
  }

  Future<SubjectModel?> findSubjectById(int subjectId) async {
    final mySubjects = await getMySubjects();
    for (final subject in mySubjects) {
      if (subject.id == subjectId) {
        return subject;
      }
    }

    final catalog = await getSubjectsCatalog();
    for (final subject in catalog) {
      if (subject.id == subjectId) {
        return subject;
      }
    }

    return null;
  }

  Future<List<SubjectModel>> getSubjectsCatalog({String? category}) async {
    final query = (category != null && category.isNotEmpty)
        ? '?category=${Uri.encodeQueryComponent(category)}'
        : '';

    return _fetchList(
      '${ApiEndpoints.subjectsCatalog}$query',
      SubjectModel.fromJson,
      emptyMessage: 'لا توجد مواد في هذا القسم حالياً.',
    );
  }

  Future<SubjectModel> requestPurchase(int subjectId) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.subjectPurchaseRequest(subjectId),
    );

    final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
      Map<String, dynamic>.from(response.data as Map),
      (json) => Map<String, dynamic>.from(json as Map),
    );

    if (!apiResponse.success || apiResponse.data == null) {
      throw ApiException(
        message: apiResponse.message ?? 'تعذر إرسال طلب الشراء.',
        errors: apiResponse.errors,
      );
    }

    final data = Map<String, dynamic>.from(apiResponse.data!);
    final subjectJson = data['subject'];
    if (subjectJson is! Map) {
      throw ApiException(message: 'استجابة غير متوقعة من السيرفر.');
    }

    return SubjectModel.fromJson(Map<String, dynamic>.from(subjectJson));
  }

  Future<SubjectModel> cancelPurchaseRequest(int subjectId) async {
    final response = await _apiClient.delete<Map<String, dynamic>>(
      ApiEndpoints.subjectPurchaseRequest(subjectId),
    );

    final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
      Map<String, dynamic>.from(response.data as Map),
      (json) => Map<String, dynamic>.from(json as Map),
    );

    if (!apiResponse.success || apiResponse.data == null) {
      throw ApiException(
        message: apiResponse.message ?? 'تعذر إلغاء طلب الشراء.',
        errors: apiResponse.errors,
      );
    }

    final data = Map<String, dynamic>.from(apiResponse.data!);
    final subjectJson = data['subject'];
    if (subjectJson is! Map) {
      throw ApiException(message: 'استجابة غير متوقعة من السيرفر.');
    }

    return SubjectModel.fromJson(Map<String, dynamic>.from(subjectJson));
  }

  Future<List<LessonModel>> getSubjectLessons(int subjectId) async {
    return _fetchList(
      ApiEndpoints.subjectLessons(subjectId),
      LessonModel.fromJson,
      emptyMessage: 'لا توجد دروس في هذه المادة.',
    );
  }

  Future<LessonModel> getLessonDetails(int lessonId) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.lessonDetails(lessonId),
    );

    final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
      Map<String, dynamic>.from(response.data as Map),
      (json) => Map<String, dynamic>.from(json as Map),
    );

    if (!apiResponse.success || apiResponse.data == null) {
      throw ApiException(
        message: apiResponse.message ?? 'تعذر جلب تفاصيل الدرس.',
        errors: apiResponse.errors,
      );
    }

    return LessonModel.fromJson(apiResponse.data!);
  }

  Future<VideoModel> getVideoDetails(int videoId) async {
    return _fetchEntity(
      ApiEndpoints.videoDetails(videoId),
      VideoModel.fromJson,
      emptyMessage: 'تعذر جلب تفاصيل الفيديو.',
    );
  }

  Future<VideoPlaybackModel> refreshVideoPlayback(int videoId) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.videoPlayback(videoId),
    );

    final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
      Map<String, dynamic>.from(response.data as Map),
      (json) => Map<String, dynamic>.from(json as Map),
    );

    if (!apiResponse.success || apiResponse.data == null) {
      throw ApiException(
        message: apiResponse.message ?? 'تعذر تجديد رابط التشغيل.',
        errors: apiResponse.errors,
      );
    }

    final playbackJson = apiResponse.data!['playback'];

    if (playbackJson is! Map) {
      throw ApiException(message: 'تعذر تجديد رابط التشغيل.');
    }

    return VideoPlaybackModel.fromJson(
      Map<String, dynamic>.from(playbackJson),
    );
  }

  Future<LessonFileModel> getFileDetails(int fileId) async {
    return _fetchEntity(
      ApiEndpoints.fileDetails(fileId),
      LessonFileModel.fromJson,
      emptyMessage: 'تعذر جلب تفاصيل الملف.',
    );
  }

  Future<FileDownloadModel> getFileDownloadUrl(int fileId) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.fileDownload(fileId),
    );

    final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
      Map<String, dynamic>.from(response.data as Map),
      (json) => Map<String, dynamic>.from(json as Map),
    );

    if (!apiResponse.success || apiResponse.data == null) {
      throw ApiException(
        message: apiResponse.message ?? 'غير مصرح لك بتنزيل هذا الملف.',
        errors: apiResponse.errors,
        statusCode: response.statusCode,
      );
    }

    return FileDownloadModel.fromJson(apiResponse.data!);
  }

  Future<VideoProgressModel> updateVideoProgress(
    int videoId, {
    required int watchedSeconds,
    required int currentPosition,
    required int completionPercentage,
    int replayCount = 0,
  }) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.videoProgress(videoId),
      data: {
        'watched_seconds': watchedSeconds,
        'current_position': currentPosition,
        'completion_percentage': completionPercentage,
        'replay_count': replayCount,
      },
    );

    final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
      Map<String, dynamic>.from(response.data as Map),
      (json) => Map<String, dynamic>.from(json as Map),
    );

    if (!apiResponse.success || apiResponse.data == null) {
      throw ApiException(
        message: apiResponse.message ?? 'تعذر تحديث تقدم المشاهدة.',
        errors: apiResponse.errors,
      );
    }

    return VideoProgressModel.fromJson(apiResponse.data!);
  }

  Future<PdfAnnotationModel> getFileAnnotations(int fileId) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.fileAnnotations(fileId),
    );

    final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
      Map<String, dynamic>.from(response.data as Map),
      (json) => Map<String, dynamic>.from(json as Map),
    );

    if (!apiResponse.success || apiResponse.data == null) {
      throw ApiException(
        message: apiResponse.message ?? 'تعذر تحميل الملاحظات.',
        errors: apiResponse.errors,
      );
    }

    final data = Map<String, dynamic>.from(apiResponse.data!);
    data['file_id'] ??= fileId;

    return PdfAnnotationModel.fromJson(data);
  }

  Future<PdfAnnotationModel> saveFileAnnotations(
    int fileId,
    Map<String, dynamic> annotationJson,
  ) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.fileAnnotations(fileId),
      data: {
        'annotation_json': annotationJson,
      },
    );

    final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
      Map<String, dynamic>.from(response.data as Map),
      (json) => Map<String, dynamic>.from(json as Map),
    );

    if (!apiResponse.success || apiResponse.data == null) {
      throw ApiException(
        message: apiResponse.message ?? 'تعذر حفظ الملاحظات.',
        errors: apiResponse.errors,
      );
    }

    final data = Map<String, dynamic>.from(apiResponse.data!);
    data['file_id'] ??= fileId;

    return PdfAnnotationModel.fromJson(data);
  }

  Future<T> _fetchEntity<T>(
    String path,
    T Function(Map<String, dynamic>) fromJson, {
    required String emptyMessage,
  }) async {
    final response = await _apiClient.get<Map<String, dynamic>>(path);

    final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
      Map<String, dynamic>.from(response.data as Map),
      (json) => Map<String, dynamic>.from(json as Map),
    );

    if (!apiResponse.success || apiResponse.data == null) {
      throw ApiException(
        message: apiResponse.message ?? emptyMessage,
        errors: apiResponse.errors,
      );
    }

    return fromJson(apiResponse.data!);
  }

  Future<List<T>> _fetchList<T>(
    String path,
    T Function(Map<String, dynamic>) fromJson, {
    required String emptyMessage,
  }) async {
    final response = await _apiClient.get<Map<String, dynamic>>(path);

    final apiResponse = ApiResponse<List<dynamic>>.fromJson(
      Map<String, dynamic>.from(response.data as Map),
      (json) => json is List ? json : <dynamic>[],
    );

    if (!apiResponse.success) {
      throw ApiException(
        message: apiResponse.message ?? 'تعذر جلب البيانات.',
        errors: apiResponse.errors,
      );
    }

    final rawList = apiResponse.data ?? [];
    if (rawList.isEmpty) {
      return [];
    }

    return rawList
        .whereType<Map>()
        .map((item) => fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }
}

final subjectsRepositoryProvider = Provider<SubjectsRepository>((ref) {
  return SubjectsRepository(apiClient: ref.watch(apiClientProvider));
});
