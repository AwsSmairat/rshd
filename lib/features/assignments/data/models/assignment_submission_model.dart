class AssignmentSubmissionModel {
  const AssignmentSubmissionModel({
    required this.id,
    required this.assignmentId,
    this.studentId,
    this.answerText,
    this.fileUrl,
    this.originalFileName,
    this.fileSize,
    this.fileMimeType,
    this.grade,
    this.feedback,
    this.submittedAt,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final int assignmentId;
  final int? studentId;
  final String? answerText;
  final String? fileUrl;
  final String? originalFileName;
  final int? fileSize;
  final String? fileMimeType;
  final String? grade;
  final String? feedback;
  final String? submittedAt;
  final String? createdAt;
  final String? updatedAt;

  bool get hasFile => fileUrl != null && fileUrl!.trim().isNotEmpty;

  factory AssignmentSubmissionModel.fromJson(Map<String, dynamic> json) {
    return AssignmentSubmissionModel(
      id: _asInt(json['id']),
      assignmentId: _asInt(json['assignment_id']),
      studentId: _asNullableInt(json['student_id']),
      answerText: json['answer_text']?.toString(),
      fileUrl: json['file_url']?.toString(),
      originalFileName: json['original_file_name']?.toString(),
      fileSize: _asNullableInt(json['file_size']),
      fileMimeType: json['file_mime_type']?.toString(),
      grade: json['grade']?.toString(),
      feedback: json['feedback']?.toString(),
      submittedAt: json['submitted_at']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
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
