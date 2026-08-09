import 'quiz_attempt_model.dart';
import 'quiz_question_model.dart';

class QuizModel {
  const QuizModel({
    required this.id,
    required this.subjectId,
    this.lessonId,
    required this.title,
    this.description,
    this.durationMinutes,
    this.status = 'active',
    this.subjectTitle,
    this.lessonTitle,
    this.questionsCount,
    this.latestAttempt,
    this.questions = const [],
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final int subjectId;
  final int? lessonId;
  final String title;
  final String? description;
  final int? durationMinutes;
  final String status;
  final String? subjectTitle;
  final String? lessonTitle;
  final int? questionsCount;
  final QuizAttemptModel? latestAttempt;
  final List<QuizQuestionModel> questions;
  final String? createdAt;
  final String? updatedAt;

  bool get isActive => status == 'active';

  bool get isCompleted => latestAttempt?.isSubmitted ?? false;

  factory QuizModel.fromJson(Map<String, dynamic> json) {
    QuizAttemptModel? latestAttempt;
    final attemptJson = json['latest_attempt'];
    if (attemptJson is Map<String, dynamic>) {
      try {
        latestAttempt = QuizAttemptModel.fromJson(attemptJson);
      } catch (_) {
        latestAttempt = null;
      }
    }

    String? subjectTitle;
    final subjectJson = json['subject'];
    if (subjectJson is Map<String, dynamic>) {
      subjectTitle = subjectJson['title']?.toString();
    }

    String? lessonTitle;
    final lessonJson = json['lesson'];
    if (lessonJson is Map<String, dynamic>) {
      lessonTitle = lessonJson['title']?.toString();
    }

    final questions = <QuizQuestionModel>[];
    final questionsJson = json['questions'];
    if (questionsJson is List) {
      for (final item in questionsJson) {
        if (item is Map<String, dynamic>) {
          try {
            questions.add(QuizQuestionModel.fromJson(item));
          } catch (_) {}
        } else if (item is Map) {
          try {
            questions.add(
              QuizQuestionModel.fromJson(Map<String, dynamic>.from(item)),
            );
          } catch (_) {}
        }
      }
    }

    return QuizModel(
      id: _asInt(json['id']),
      subjectId: _asInt(json['subject_id']),
      lessonId: _asNullableInt(json['lesson_id']),
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      durationMinutes: _asNullableInt(json['duration_minutes']),
      status: json['status']?.toString() ?? 'active',
      subjectTitle: subjectTitle,
      lessonTitle: lessonTitle,
      questionsCount:
          _asNullableInt(json['questions_count']) ??
          (questions.isNotEmpty ? questions.length : null),
      latestAttempt: latestAttempt,
      questions: questions,
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  QuizModel copyWith({
    QuizAttemptModel? latestAttempt,
    List<QuizQuestionModel>? questions,
  }) {
    return QuizModel(
      id: id,
      subjectId: subjectId,
      lessonId: lessonId,
      title: title,
      description: description,
      durationMinutes: durationMinutes,
      status: status,
      subjectTitle: subjectTitle,
      lessonTitle: lessonTitle,
      questionsCount: questionsCount,
      latestAttempt: latestAttempt ?? this.latestAttempt,
      questions: questions ?? this.questions,
      createdAt: createdAt,
      updatedAt: updatedAt,
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

class QuizStartResult {
  const QuizStartResult({required this.attemptId, required this.quiz});

  final int attemptId;
  final QuizModel quiz;
}
