import '../../../auth/data/models/user_model.dart';
import '../../../../core/config/app_config.dart';

class SubjectModel {
  const SubjectModel({
    required this.id,
    required this.title,
    this.description,
    this.category = '',
    this.coverImage,
    this.status = 'active',
    this.price,
    this.enrollmentStatus = 'none',
    this.progressPercent,
    this.instructor,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final String title;
  final String? description;
  final String category;
  final String? coverImage;
  final String status;
  final String? price;

  /// none | pending | active
  final String enrollmentStatus;
  final double? progressPercent;
  final UserModel? instructor;
  final String? createdAt;
  final String? updatedAt;

  bool get isEnrollmentActive => enrollmentStatus == 'active';
  bool get isEnrollmentPending => enrollmentStatus == 'pending';
  bool get canRequestPurchase => enrollmentStatus == 'none';

  bool get hasCoverImage =>
      coverImage != null && coverImage!.trim().isNotEmpty;

  String? get resolvedCoverImageUrl {
    final value = coverImage?.trim();
    if (value == null || value.isEmpty) {
      return null;
    }
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }
    final path = value.startsWith('/') ? value : '/$value';
    if (path.startsWith('/storage/')) {
      return '${AppConfig.appOrigin}$path';
    }
    return '${AppConfig.appOrigin}/storage$path';
  }

  SubjectModel copyWith({
    int? id,
    String? title,
    String? description,
    String? category,
    String? coverImage,
    String? status,
    String? price,
    String? enrollmentStatus,
    double? progressPercent,
    UserModel? instructor,
    String? createdAt,
    String? updatedAt,
  }) {
    return SubjectModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      coverImage: coverImage ?? this.coverImage,
      status: status ?? this.status,
      price: price ?? this.price,
      enrollmentStatus: enrollmentStatus ?? this.enrollmentStatus,
      progressPercent: progressPercent ?? this.progressPercent,
      instructor: instructor ?? this.instructor,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory SubjectModel.fromJson(Map<String, dynamic> json) {
    UserModel? instructor;
    final instructorJson = json['instructor'];
    if (instructorJson is Map<String, dynamic>) {
      try {
        instructor = UserModel.fromJson(instructorJson);
      } catch (_) {
        instructor = null;
      }
    }

    return SubjectModel(
      id: _asInt(json['id']),
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      category: json['category']?.toString() ?? '',
      coverImage: json['cover_image']?.toString(),
      status: json['status']?.toString() ?? 'active',
      price: json['price']?.toString(),
      enrollmentStatus: json['enrollment_status']?.toString() ?? 'none',
      progressPercent: _asDouble(json['progress_percent']) ??
          (_enrollmentIsActive(json['enrollment_status']) ? 0 : null),
      instructor: instructor,
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  String get categoryLabel => categoryLabels[category] ?? category;

  static const categoryLabels = {
    'medicine': 'طب',
    'it': 'تقنية',
    'engineering': 'هندسة',
    'general': 'عام',
  };

  static const departmentSectionTitles = {
    'medicine': 'الطب',
    'it': 'تكنولوجيا المعلومات',
    'engineering': 'الهندسة',
    'general': 'مواد عامة',
  };

  static const departmentOrder = [
    'medicine',
    'it',
    'engineering',
    'general',
  ];

  String get departmentSectionTitle =>
      departmentSectionTitles[category] ?? categoryLabel;

  static int _asInt(dynamic value, [int fallback = 0]) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse('$value') ?? fallback;
  }

  static double? _asDouble(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is double) {
      return value;
    }
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse('$value');
  }

  static bool _enrollmentIsActive(dynamic value) =>
      value?.toString() == 'active';
}
