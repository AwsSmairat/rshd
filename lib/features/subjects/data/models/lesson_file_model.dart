import 'package:flutter/material.dart';

class LessonFileModel {
  const LessonFileModel({
    required this.id,
    required this.lessonId,
    required this.title,
    this.fileType = 'other',
    this.fileUrl,
    this.fileSize = 0,
    this.isLocked = false,
    this.requiresSignedDownload = false,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final int lessonId;
  final String title;
  final String fileType;
  final String? fileUrl;
  final int fileSize;
  final bool isLocked;
  final bool requiresSignedDownload;
  final String? createdAt;
  final String? updatedAt;

  bool get canOpen =>
      !isLocked &&
      (requiresSignedDownload || (fileUrl?.trim().isNotEmpty ?? false));

  factory LessonFileModel.fromJson(Map<String, dynamic> json) {
    return LessonFileModel(
      id: _asInt(json['id']),
      lessonId: _asInt(json['lesson_id']),
      title: json['title']?.toString() ?? '',
      fileType: json['file_type']?.toString() ?? 'other',
      fileUrl: json['file_url']?.toString(),
      fileSize: _asInt(json['file_size']),
      isLocked: json['is_locked'] == true || json['is_locked'] == 1,
      requiresSignedDownload:
          json['requires_signed_download'] == true ||
          json['requires_signed_download'] == 1,
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  String get fileTypeLabel {
    switch (fileType) {
      case 'pdf':
        return 'PDF';
      case 'ppt':
        return 'PPT';
      case 'doc':
        return 'DOC';
      case 'image':
        return 'صورة';
      default:
        return 'ملف';
    }
  }

  IconData get fileIcon {
    switch (fileType) {
      case 'pdf':
        return Icons.picture_as_pdf_outlined;
      case 'ppt':
        return Icons.slideshow_outlined;
      case 'doc':
        return Icons.description_outlined;
      case 'image':
        return Icons.image_outlined;
      default:
        return Icons.insert_drive_file_outlined;
    }
  }

  String get formattedSize => formatFileSize(fileSize);

  static String formatFileSize(int bytes) {
    if (bytes <= 0) {
      return '—';
    }

    if (bytes < 1024) {
      return '$bytes بايت';
    }
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
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
}
