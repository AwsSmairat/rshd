import '../../../../core/config/app_config.dart';
import 'assignment_submission_model.dart';

class AssignmentModel {
  const AssignmentModel({
    required this.id,
    required this.subjectId,
    this.lessonId,
    required this.title,
    this.description,
    this.attachmentUrl,
    this.originalFileName,
    this.fileSize,
    this.fileMimeType,
    this.dueDate,
    this.status = 'active',
    this.subjectTitle,
    this.lessonTitle,
    this.submission,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final int subjectId;
  final int? lessonId;
  final String title;
  final String? description;
  final String? attachmentUrl;
  final String? originalFileName;
  final int? fileSize;
  final String? fileMimeType;
  final String? dueDate;
  final String status;
  final String? subjectTitle;
  final String? lessonTitle;
  final AssignmentSubmissionModel? submission;
  final String? createdAt;
  final String? updatedAt;

  bool get isSubmitted => submission != null;

  bool get hasAttachment =>
      resolvedAttachmentUrl != null && resolvedAttachmentUrl!.isNotEmpty;

  String? get resolvedAttachmentUrl {
    final value = attachmentUrl?.trim();
    if (value == null || value.isEmpty) {
      return null;
    }

    if (value.startsWith('http://') || value.startsWith('https://')) {
      final uri = Uri.tryParse(value);
      final path = uri?.path;
      if (path != null && path.startsWith('/storage/')) {
        return '${AppConfig.appOrigin}$path';
      }
      return value;
    }

    final path = value.startsWith('/') ? value : '/$value';
    if (path.startsWith('/storage/')) {
      return '${AppConfig.appOrigin}$path';
    }

    return '${AppConfig.appOrigin}/storage$path';
  }

  bool get isOverdue {
    if (dueDate == null || dueDate!.isEmpty) {
      return false;
    }
    final parsed = DateTime.tryParse(dueDate!);
    if (parsed == null) {
      return false;
    }
    return parsed.isBefore(DateTime.now());
  }

  factory AssignmentModel.fromJson(Map<String, dynamic> json) {
    AssignmentSubmissionModel? submission;
    final submissionJson = json['submission'];
    if (submissionJson is Map<String, dynamic>) {
      try {
        submission = AssignmentSubmissionModel.fromJson(submissionJson);
      } catch (_) {
        submission = null;
      }
    } else {
      final submissions = json['submissions'];
      if (submissions is List && submissions.isNotEmpty) {
        final first = submissions.first;
        if (first is Map<String, dynamic>) {
          try {
            submission = AssignmentSubmissionModel.fromJson(first);
          } catch (_) {
            submission = null;
          }
        }
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

    return AssignmentModel(
      id: _asInt(json['id']),
      subjectId: _asInt(json['subject_id']),
      lessonId: _asNullableInt(json['lesson_id']),
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      attachmentUrl: json['attachment_url']?.toString(),
      originalFileName: json['original_file_name']?.toString(),
      fileSize: _asNullableInt(json['file_size']),
      fileMimeType: json['file_mime_type']?.toString(),
      dueDate: json['due_date']?.toString(),
      status: json['status']?.toString() ?? 'active',
      subjectTitle: subjectTitle,
      lessonTitle: lessonTitle,
      submission: submission,
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  AssignmentModel copyWith({
    AssignmentSubmissionModel? submission,
    bool clearSubmission = false,
  }) {
    return AssignmentModel(
      id: id,
      subjectId: subjectId,
      lessonId: lessonId,
      title: title,
      description: description,
      attachmentUrl: attachmentUrl,
      originalFileName: originalFileName,
      fileSize: fileSize,
      fileMimeType: fileMimeType,
      dueDate: dueDate,
      status: status,
      subjectTitle: subjectTitle,
      lessonTitle: lessonTitle,
      submission: clearSubmission ? null : (submission ?? this.submission),
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
