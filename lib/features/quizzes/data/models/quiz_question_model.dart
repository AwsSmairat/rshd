import 'quiz_answer_model.dart';

class QuizQuestionModel {
  const QuizQuestionModel({
    required this.id,
    required this.quizId,
    required this.questionText,
    this.questionType = 'mcq',
    this.points = 1,
    this.answers = const [],
  });

  final int id;
  final int quizId;
  final String questionText;
  final String questionType;
  final int points;
  final List<QuizAnswerModel> answers;

  bool get isTrueFalse => questionType == 'true_false';

  factory QuizQuestionModel.fromJson(Map<String, dynamic> json) {
    final questionId = _asInt(json['id']);
    final answersJson = json['answers'];
    final answers = <QuizAnswerModel>[];

    if (answersJson is List) {
      for (final item in answersJson) {
        if (item is Map<String, dynamic>) {
          try {
            answers.add(QuizAnswerModel.fromJson(item, questionId: questionId));
          } catch (_) {}
        } else if (item is Map) {
          try {
            answers.add(
              QuizAnswerModel.fromJson(
                Map<String, dynamic>.from(item),
                questionId: questionId,
              ),
            );
          } catch (_) {}
        }
      }
    }

    return QuizQuestionModel(
      id: questionId,
      quizId: _asInt(json['quiz_id']),
      questionText: json['question_text']?.toString() ?? '',
      questionType: json['question_type']?.toString() ?? 'mcq',
      points: _asInt(json['points'], 1),
      answers: answers,
    );
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
