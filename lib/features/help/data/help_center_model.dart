class TeacherContactModel {
  const TeacherContactModel({
    required this.subjectId,
    required this.subjectTitle,
    required this.instructorId,
    required this.instructorName,
    this.contactEmail,
    required this.contactViaSupport,
  });

  final int subjectId;
  final String subjectTitle;
  final int? instructorId;
  final String instructorName;
  final String? contactEmail;
  final bool contactViaSupport;

  factory TeacherContactModel.fromJson(Map<String, dynamic> json) {
    return TeacherContactModel(
      subjectId: _asInt(json['subject_id']),
      subjectTitle: json['subject_title']?.toString() ?? '',
      instructorId: json['instructor_id'] == null
          ? null
          : _asInt(json['instructor_id']),
      instructorName: json['instructor_name']?.toString() ?? '—',
      contactEmail: json['contact_email']?.toString(),
      contactViaSupport: json['contact_via_support'] == true,
    );
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }
}

class HelpCenterContactsModel {
  const HelpCenterContactsModel({
    required this.supportEmail,
    required this.supportPhone,
    required this.teachers,
  });

  final String supportEmail;
  final String supportPhone;
  final List<TeacherContactModel> teachers;

  factory HelpCenterContactsModel.fromJson(Map<String, dynamic> json) {
    final teachers = (json['teachers'] as List? ?? [])
        .whereType<Map>()
        .map(
          (item) =>
              TeacherContactModel.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();

    return HelpCenterContactsModel(
      supportEmail: json['support_email']?.toString() ?? '',
      supportPhone: json['support_phone']?.toString() ?? '',
      teachers: teachers,
    );
  }
}
