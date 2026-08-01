import 'package:flutter/material.dart';

class AssignmentFileHelper {
  AssignmentFileHelper._();

  static const maxBytes = 10 * 1024 * 1024;
  static const allowedExtensions = [
    'pdf',
    'doc',
    'docx',
    'jpg',
    'jpeg',
    'png',
    'zip',
  ];

  static String? validate({
    required String? path,
    required String? name,
    int? size,
  }) {
    if (path == null || path.isEmpty) {
      return null;
    }

    final bytes = size ?? 0;
    if (bytes > maxBytes) {
      return 'حجم الملف يجب ألا يتجاوز 10MB.';
    }

    final extension = _extension(name ?? path);
    if (!allowedExtensions.contains(extension)) {
      return 'نوع الملف غير مدعوم.';
    }

    return null;
  }

  static String formatSize(int? bytes) {
    if (bytes == null || bytes <= 0) {
      return '—';
    }
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  static IconData iconFor({
    String? mimeType,
    String? fileName,
  }) {
    final mime = mimeType?.toLowerCase() ?? '';
    final ext = _extension(fileName);

    if (mime.contains('pdf') || ext == 'pdf') {
      return Icons.picture_as_pdf_outlined;
    }
    if (mime.contains('word') || ext == 'doc' || ext == 'docx') {
      return Icons.description_outlined;
    }
    if (mime.startsWith('image/') ||
        ext == 'jpg' ||
        ext == 'jpeg' ||
        ext == 'png') {
      return Icons.image_outlined;
    }
    if (mime.contains('zip') || ext == 'zip') {
      return Icons.folder_zip_outlined;
    }
    return Icons.insert_drive_file_outlined;
  }

  static String _extension(String? value) {
    if (value == null || value.isEmpty) {
      return '';
    }
    final dot = value.lastIndexOf('.');
    if (dot == -1 || dot == value.length - 1) {
      return '';
    }
    return value.substring(dot + 1).toLowerCase();
  }
}

class AssignmentGradeHelper {
  AssignmentGradeHelper._();

  static String? evaluationLabel(String? grade) {
    final score = double.tryParse(grade ?? '');
    if (score == null) {
      return null;
    }
    if (score >= 90) {
      return 'ممتاز';
    }
    if (score >= 80) {
      return 'جيد جداً';
    }
    if (score >= 70) {
      return 'جيد';
    }
    if (score >= 60) {
      return 'مقبول';
    }
    return 'بحاجة إلى تحسين';
  }
}
