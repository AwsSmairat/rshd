import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/api_response.dart';
import 'models/assignment_model.dart';
import 'models/assignment_submission_model.dart';

class AssignmentsRepository {
  AssignmentsRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<List<AssignmentModel>> getAssignments() async {
    return _fetchList(
      ApiEndpoints.assignments,
      AssignmentModel.fromJson,
    );
  }

  Future<AssignmentModel> getAssignmentDetails(int assignmentId) async {
    final assignments = await getAssignments();
    for (final assignment in assignments) {
      if (assignment.id == assignmentId) {
        return assignment;
      }
    }

    throw ApiException(
      message: 'الواجب غير موجود',
      statusCode: 404,
    );
  }

  Future<AssignmentSubmissionModel> submitAssignment({
    required int assignmentId,
    String? answerText,
    String? filePath,
    String? fileName,
  }) async {
    final formData = FormData();
    final trimmedAnswer = answerText?.trim();

    if (trimmedAnswer != null && trimmedAnswer.isNotEmpty) {
      formData.fields.add(MapEntry('answer_text', trimmedAnswer));
    }

    if (filePath != null && filePath.isNotEmpty) {
      formData.files.add(
        MapEntry(
          'file',
          await MultipartFile.fromFile(
            filePath,
            filename: fileName,
          ),
        ),
      );
    }

    final response = await _apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.submitAssignment(assignmentId),
      data: formData,
    );

    final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
      Map<String, dynamic>.from(response.data as Map),
      (json) => Map<String, dynamic>.from(json as Map),
    );

    if (!apiResponse.success || apiResponse.data == null) {
      throw ApiException(
        message: apiResponse.message ?? 'تعذر تسليم الواجب',
        errors: apiResponse.errors,
      );
    }

    return AssignmentSubmissionModel.fromJson(apiResponse.data!);
  }

  Future<List<T>> _fetchList<T>(
    String path,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
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

final assignmentsRepositoryProvider = Provider<AssignmentsRepository>((ref) {
  return AssignmentsRepository(apiClient: ref.watch(apiClientProvider));
});
