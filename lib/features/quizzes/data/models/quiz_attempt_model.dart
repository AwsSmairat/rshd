class QuizAttemptModel {
  const QuizAttemptModel({
    required this.id,
    required this.quizId,
    this.studentId,
    this.score,
    this.startedAt,
    this.submittedAt,
    this.questionsCount,
  });

  final int id;
  final int quizId;
  final int? studentId;
  final String? score;
  final String? startedAt;
  final String? submittedAt;
  final int? questionsCount;

  bool get isSubmitted => submittedAt != null && submittedAt!.isNotEmpty;

  factory QuizAttemptModel.fromJson(Map<String, dynamic> json) {
    return QuizAttemptModel(
      id: _asInt(json['attempt_id'] ?? json['id']),
      quizId: _asInt(json['quiz_id']),
      studentId: _asNullableInt(json['student_id']),
      score: json['score']?.toString(),
      startedAt: json['started_at']?.toString(),
      submittedAt: json['submitted_at']?.toString(),
      questionsCount: _asNullableInt(json['questions_count']),
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

  static int? _asNullableInt(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse('$value');
  }
}
