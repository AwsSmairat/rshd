import 'package:flutter/material.dart';

class AssignmentIconHelper {
  AssignmentIconHelper._();

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
      'physiology',
    ])) {
      return Icons.menu_book_outlined;
    }

    if (_matches(haystack, const [
      'كيمياء',
      'enzyme',
      'enzymes',
      'chemistry',
      'biochem',
    ])) {
      return Icons.science_outlined;
    }

    if (_matches(haystack, const [
      'برمجة',
      'flutter',
      'dart',
      'code',
      'programming',
      'تطبيق',
      'software',
      'واجهات',
    ])) {
      return Icons.code_rounded;
    }

    if (_matches(haystack, const [
      'مشروع',
      'project',
    ])) {
      return Icons.folder_special_outlined;
    }

    if (_matches(haystack, const [
      'مراجعة',
      'review',
      'general',
    ])) {
      return Icons.fact_check_outlined;
    }

    return Icons.assignment_outlined;
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
