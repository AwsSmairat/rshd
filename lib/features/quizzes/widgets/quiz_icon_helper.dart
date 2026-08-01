import 'package:flutter/material.dart';

class QuizIconHelper {
  QuizIconHelper._();

  /// Default quizzes branding icon (avoids the question-mark look of [Icons.quiz_outlined]).
  static const IconData sectionIcon = Icons.edit_note_rounded;

  static IconData iconFor({
    required String title,
    String? subjectTitle,
  }) {
    final haystack = _normalize('$title ${subjectTitle ?? ''}');

    if (_matches(haystack, const [
      'تشريح',
      'anatomy',
      'طب',
      'medicine',
    ])) {
      return Icons.menu_book_outlined;
    }

    if (_matches(haystack, const [
      'كيمياء',
      'chemistry',
      'biochem',
      'حيوية',
      'enzyme',
    ])) {
      return Icons.science_outlined;
    }

    if (_matches(haystack, const [
      'flutter',
      'dart',
      'برمجة',
      'code',
      'programming',
      'تطبيق',
    ])) {
      return Icons.code_rounded;
    }

    if (_matches(haystack, const [
      'widget',
      'widgets',
      'واجهات',
      'ui',
    ])) {
      return Icons.dashboard_customize_outlined;
    }

    if (_matches(haystack, const [
      'sql',
      'database',
      'قواعد بيانات',
      'db',
    ])) {
      return Icons.storage_outlined;
    }

    if (_matches(haystack, const [
      'أمن',
      'security',
      'cyber',
    ])) {
      return Icons.security_outlined;
    }

    return sectionIcon;
  }

  static String _normalize(String value) {
    return value.toLowerCase().trim();
  }

  static bool _matches(String haystack, List<String> needles) {
    for (final needle in needles) {
      if (haystack.contains(needle.toLowerCase())) {
        return true;
      }
    }
    return false;
  }
}
