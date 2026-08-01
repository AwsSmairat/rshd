import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';

class QuizScoreHelper {
  QuizScoreHelper._();

  static double? parseScore(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }
    return double.tryParse(raw.trim());
  }

  static String formatScore(double score) {
    return '${score.toStringAsFixed(2)}%';
  }

  static String gradeLabel(double score) {
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

  static Color gradeColor(double score) {
    if (score >= 80) {
      return const Color(0xFF16A34A);
    }
    if (score >= 60) {
      return AppColors.darkGold;
    }
    return const Color(0xFF991B1B);
  }

  static String encouragement(double score) {
    if (score >= 80) {
      return 'استمر على هذا الأداء الرائع!';
    }
    if (score >= 60) {
      return 'أداء جيد، واصل التقدم!';
    }
    return 'راجع المادة وحاول مرة أخرى.';
  }

  static double normalizedProgress(double score) {
    return (score.clamp(0, 100)) / 100;
  }
}

class QuizDateHelper {
  QuizDateHelper._();

  static String formatDate(String? raw) {
    final parsed = _parse(raw);
    if (parsed == null) {
      return '—';
    }
    return DateFormat('yyyy/MM/dd', 'ar').format(parsed);
  }

  static String formatTime(String? raw) {
    final parsed = _parse(raw);
    if (parsed == null) {
      return '—';
    }
    return DateFormat('h:mm a', 'ar').format(parsed);
  }

  static String formatDateLong(String? raw) {
    final parsed = _parse(raw);
    if (parsed == null) {
      return '—';
    }
    return DateFormat('d MMMM yyyy', 'ar').format(parsed);
  }

  static DateTime? _parse(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }
    return DateTime.tryParse(raw)?.toLocal();
  }
}
