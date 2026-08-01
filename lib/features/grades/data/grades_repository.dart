import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/api_response.dart';
import 'models/grade_model.dart';

class GradesRepository {
  GradesRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<List<GradeModel>> getGrades() async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.grades,
    );

    final apiResponse = ApiResponse<List<dynamic>>.fromJson(
      Map<String, dynamic>.from(response.data as Map),
      (json) => json is List ? json : <dynamic>[],
    );

    if (!apiResponse.success) {
      throw ApiException(
        message: apiResponse.message ?? 'تعذر جلب الدرجات.',
        errors: apiResponse.errors,
      );
    }

    final rawList = apiResponse.data ?? [];
    if (rawList.isEmpty) {
      return [];
    }

    return rawList
        .whereType<Map>()
        .map((item) => GradeModel.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<GradeModel?> findGradeById(int gradeId) async {
    final grades = await getGrades();
    for (final grade in grades) {
      if (grade.id == gradeId) {
        return grade;
      }
    }
    return null;
  }
}

final gradesRepositoryProvider = Provider<GradesRepository>((ref) {
  return GradesRepository(apiClient: ref.watch(apiClientProvider));
});
