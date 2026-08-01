class QuizAnswerModel {
  const QuizAnswerModel({
    required this.id,
    required this.questionId,
    required this.answerText,
  });

  final int id;
  final int questionId;
  final String answerText;

  factory QuizAnswerModel.fromJson(Map<String, dynamic> json, {int? questionId}) {
    return QuizAnswerModel(
      id: _asInt(json['id']),
      questionId: _asInt(json['question_id'] ?? questionId),
      answerText: json['answer_text']?.toString() ?? '',
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
