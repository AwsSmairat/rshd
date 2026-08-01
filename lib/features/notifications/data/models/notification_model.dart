class NotificationModel {
  const NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    this.body,
    this.type = 'other',
    this.data = const {},
    this.isRead = false,
    this.createdAt,
  });

  final int id;
  final int userId;
  final String title;
  final String? body;
  final String type;
  final Map<String, dynamic> data;
  final bool isRead;
  final String? createdAt;

  int? get subjectId => _dataInt('subject_id');
  int? get assignmentId => _dataInt('assignment_id');
  int? get quizId => _dataInt('quiz_id');
  int? get gradeId => _dataInt('grade_id');
  int? get announcementId => _dataInt('announcement_id');
  int? get inReplyToId => _dataInt('in_reply_to_id');
  int? get instructorId => _dataInt('instructor_id');

  bool get isMessageNotification {
    if (type == 'instructor_reply' || type == 'student_message') {
      return true;
    }

    if (inReplyToId != null) {
      return true;
    }

    if (instructorId != null && title.startsWith('رد من')) {
      return true;
    }

    return false;
  }

  String get effectiveType {
    if (type != 'other' && type.isNotEmpty) {
      return type;
    }

    if (inReplyToId != null || (instructorId != null && title.startsWith('رد من'))) {
      return 'instructor_reply';
    }

    return type;
  }

  String get typeLabel {
    switch (effectiveType) {
      case 'subject_activated':
        return 'تفعيل مادة';
      case 'activation_request':
        return 'طلب تفعيل';
      case 'assignment_created':
      case 'new_assignment':
        return 'واجب جديد';
      case 'quiz_created':
      case 'new_quiz':
      case 'quiz_available':
        return 'اختبار جديد';
      case 'grade_published':
      case 'new_grade':
        return 'درجة منشورة';
      case 'assignment_submitted':
        return 'تسليم واجب';
      case 'announcement':
        return 'إعلان';
      case 'student_message':
        return 'رسالة للمدرّس';
      case 'instructor_reply':
        return 'رد من المدرّس';
      case 'custom':
        return 'إشعار مخصص';
      case 'assignment_reminder':
        return 'تذكير واجب';
      default:
        return 'إشعار';
    }
  }

  String get shortBody {
    final text = body ?? '';
    if (text.length <= 100) {
      return text;
    }
    return '${text.substring(0, 100)}...';
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: _asInt(json['id']),
      userId: _asInt(json['user_id']),
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString(),
      type: json['type']?.toString() ?? 'other',
      data: _parseData(json['data']),
      isRead: _asBool(json['is_read']),
      createdAt: json['created_at']?.toString(),
    );
  }

  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      id: id,
      userId: userId,
      title: title,
      body: body,
      type: type,
      data: data,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
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

  static bool _asBool(dynamic value) {
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }
    if (value is String) {
      return value == '1' || value.toLowerCase() == 'true';
    }
    return false;
  }

  static Map<String, dynamic> _parseData(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return const {};
  }

  int? _dataInt(String key) {
    final value = data[key];
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse('$value');
  }
}
