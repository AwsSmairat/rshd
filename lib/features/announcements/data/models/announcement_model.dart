import '../../../../core/config/app_config.dart';

class AnnouncementModel {
  const AnnouncementModel({
    required this.id,
    required this.title,
    this.body,
    this.type = 'general',
    this.imageUrl,
    this.subjectId,
    this.subjectTitle,
    this.createdAt,
  });

  final int id;
  final String title;
  final String? body;
  final String type;
  final String? imageUrl;
  final int? subjectId;
  final String? subjectTitle;
  final String? createdAt;

  bool get hasCarouselImage =>
      imageUrl != null && imageUrl!.trim().isNotEmpty;

  String? get resolvedImageUrl {
    final value = imageUrl?.trim();
    if (value == null || value.isEmpty) {
      return null;
    }
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }
    return '${AppConfig.appOrigin}$value';
  }

  String get typeLabel {
    switch (type) {
      case 'general':
        return 'إعلان عام';
      case 'subject':
        return 'إعلان مادة';
      case 'important':
        return 'مهم';
      default:
        return 'إعلان';
    }
  }

  String get shortBody {
    final text = body ?? '';
    if (text.length <= 90) {
      return text;
    }
    return '${text.substring(0, 90)}...';
  }

  factory AnnouncementModel.fromJson(Map<String, dynamic> json) {
    return AnnouncementModel(
      id: _asInt(json['id']),
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString(),
      type: json['type']?.toString() ?? 'general',
      imageUrl: json['image_url']?.toString(),
      subjectId: _nullableInt(json['subject_id']),
      subjectTitle: json['subject_title']?.toString(),
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

  static int? _nullableInt(dynamic value) {
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
