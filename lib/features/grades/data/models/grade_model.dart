class GradeModel {
  const GradeModel({
    required this.id,
    required this.studentId,
    required this.subjectId,
    required this.sourceType,
    this.sourceId,
    required this.grade,
    this.notes,
    this.subjectTitle,
    this.sourceTitle,
    this.createdAt,
  });

  final int id;
  final int studentId;
  final int subjectId;
  final String sourceType;
  final int? sourceId;
  final String grade;
  final String? notes;
  final String? subjectTitle;
  final String? sourceTitle;
  final String? createdAt;

  double? get gradeValue => double.tryParse(grade);

  String get sourceTypeLabel {
    switch (sourceType) {
      case 'assignment':
        return 'واجب';
      case 'quiz':
        return 'اختبار';
      case 'manual':
        return 'درجة يدوية';
      default:
        return sourceType;
    }
  }

  String get displayTitle {
    if (sourceTitle != null && sourceTitle!.isNotEmpty) {
      return sourceTitle!;
    }
    return sourceTypeLabel;
  }

  factory GradeModel.fromJson(Map<String, dynamic> json) {
    String? subjectTitle;
    final subjectJson = json['subject'];
    if (subjectJson is Map<String, dynamic>) {
      subjectTitle = subjectJson['title']?.toString();
    } else if (subjectJson is Map) {
      subjectTitle = subjectJson['title']?.toString();
    }

    return GradeModel(
      id: _asInt(json['id']),
      studentId: _asInt(json['student_id']),
      subjectId: _asInt(json['subject_id']),
      sourceType: json['source_type']?.toString() ?? 'manual',
      sourceId: _asNullableInt(json['source_id']),
      grade: json['grade']?.toString() ?? '0',
      notes: json['notes']?.toString(),
      subjectTitle: subjectTitle ?? json['subject_title']?.toString(),
      sourceTitle: json['source_title']?.toString(),
      createdAt: json['created_at']?.toString(),
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
