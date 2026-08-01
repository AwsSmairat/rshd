import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/api_response.dart';
import 'models/quiz_attempt_model.dart';
import 'models/quiz_model.dart';
import 'models/quiz_question_model.dart';

class QuizzesRepository {
  QuizzesRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<List<QuizModel>> getQuizzes() async {
    return _fetchList(ApiEndpoints.quizzes, QuizModel.fromJson);
  }

  Future<QuizModel?> findQuizById(int quizId) async {
    final quizzes = await getQuizzes();
    for (final quiz in quizzes) {
      if (quiz.id == quizId) {
        return quiz;
      }
    }
    return null;
  }

  Future<QuizStartResult> startQuiz(int quizId) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.startQuiz(quizId),
    );

    final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
      Map<String, dynamic>.from(response.data as Map),
      (json) => Map<String, dynamic>.from(json as Map),
    );

    if (!apiResponse.success || apiResponse.data == null) {
      throw ApiException(
        message: apiResponse.message ?? 'تعذر بدء الاختبار',
        errors: apiResponse.errors,
      );
    }

    final data = apiResponse.data!;
    final quizJson = data['quiz'];
    if (quizJson is! Map) {
      throw ApiException(message: 'تعذر بدء الاختبار');
    }

    return QuizStartResult(
      attemptId: _asInt(data['attempt_id']),
      quiz: QuizModel.fromJson(Map<String, dynamic>.from(quizJson)),
    );
  }

  Future<QuizAttemptModel> submitQuiz({
    required int quizId,
    required List<QuizQuestionModel> questions,
    required Map<int, int> selectedAnswers,
  }) async {
    final answers = questions
        .map(
          (question) => {
            'question_id': question.id,
            'answer_id': selectedAnswers[question.id],
          },
        )
        .toList();

    final response = await _apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.submitQuiz(quizId),
      data: {'answers': answers},
    );

    final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
      Map<String, dynamic>.from(response.data as Map),
      (json) => Map<String, dynamic>.from(json as Map),
    );

    if (!apiResponse.success || apiResponse.data == null) {
      throw ApiException(
        message: apiResponse.message ?? 'تعذر تسليم الاختبار',
        errors: apiResponse.errors,
      );
    }

    return QuizAttemptModel.fromJson(apiResponse.data!);
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

  static int _asInt(dynamic value, [int fallback = 0]) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse('$value') ?? fallback;
  }
}

final quizzesRepositoryProvider = Provider<QuizzesRepository>((ref) {
  return QuizzesRepository(apiClient: ref.watch(apiClientProvider));
});
