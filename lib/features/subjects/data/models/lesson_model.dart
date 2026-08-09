import '../../../assignments/data/models/assignment_model.dart';
import '../../../quizzes/data/models/quiz_model.dart';
import 'lesson_file_model.dart';
import 'video_model.dart';

class LessonModel {
  const LessonModel({
    required this.id,
    required this.subjectId,
    required this.title,
    this.description,
    this.order = 0,
    this.status = 'active',
    this.videos = const [],
    this.files = const [],
    this.assignments = const [],
    this.quizzes = const [],
    this.videosCount = 0,
    this.filesCount = 0,
    this.assignmentsCount = 0,
    this.quizzesCount = 0,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final int subjectId;
  final String title;
  final String? description;
  final int order;
  final String status;
  final List<VideoModel> videos;
  final List<LessonFileModel> files;
  final List<AssignmentModel> assignments;
  final List<QuizModel> quizzes;
  final int videosCount;
  final int filesCount;
  final int assignmentsCount;
  final int quizzesCount;
  final String? createdAt;
  final String? updatedAt;

  factory LessonModel.fromJson(Map<String, dynamic> json) {
    final videosJson = json['videos'];
    final filesJson = json['files'];
    final assignmentsJson = json['assignments'];
    final quizzesJson = json['quizzes'];

    final videos = videosJson is List
        ? videosJson
              .whereType<Map>()
              .map(
                (item) => VideoModel.fromJson(Map<String, dynamic>.from(item)),
              )
              .toList()
        : const <VideoModel>[];

    final files = filesJson is List
        ? filesJson
              .whereType<Map>()
              .map(
                (item) =>
                    LessonFileModel.fromJson(Map<String, dynamic>.from(item)),
              )
              .toList()
        : const <LessonFileModel>[];

    final assignments = assignmentsJson is List
        ? assignmentsJson
              .whereType<Map>()
              .map(
                (item) =>
                    AssignmentModel.fromJson(Map<String, dynamic>.from(item)),
              )
              .toList()
        : const <AssignmentModel>[];

    final quizzes = quizzesJson is List
        ? quizzesJson
              .whereType<Map>()
              .map(
                (item) => QuizModel.fromJson(Map<String, dynamic>.from(item)),
              )
              .toList()
        : const <QuizModel>[];

    return LessonModel(
      id: _asInt(json['id']),
      subjectId: _asInt(json['subject_id']),
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      order: _asInt(json['order']),
      status: json['status']?.toString() ?? 'active',
      videos: videos,
      files: files,
      assignments: assignments,
      quizzes: quizzes,
      videosCount: videos.isNotEmpty
          ? videos.length
          : _asInt(json['videos_count']),
      filesCount: files.isNotEmpty ? files.length : _asInt(json['files_count']),
      assignmentsCount: assignments.isNotEmpty
          ? assignments.length
          : _asInt(json['assignments_count']),
      quizzesCount: quizzes.isNotEmpty
          ? quizzes.length
          : _asInt(json['quizzes_count']),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  bool get isActive => status == 'active';

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
