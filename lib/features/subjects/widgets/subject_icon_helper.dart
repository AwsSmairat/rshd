import 'package:flutter/material.dart';

import '../data/models/subject_model.dart';
import 'subject_grouping_helper.dart';

class SubjectIconHelper {
  SubjectIconHelper._();

  static IconData iconForSubject(SubjectModel subject) {
    final text = '${subject.title} ${subject.description ?? ''}'.toLowerCase();

    if (_containsAny(text, ['تشريح', 'anatomy'])) {
      return Icons.menu_book_outlined;
    }
    if (_containsAny(text, ['كيمياء', 'chemistry', 'حيوية'])) {
      return Icons.science_outlined;
    }
    if (_containsAny(text, ['برمجة', 'flutter', 'dart', 'تطبيقات'])) {
      return Icons.code;
    }
    if (_containsAny(text, ['قواعد البيانات', 'sql', 'database'])) {
      return Icons.storage_outlined;
    }
    if (_containsAny(text, ['أمن', 'security'])) {
      return Icons.security_outlined;
    }
    if (_containsAny(text, ['هندسة', 'رسم', 'دوائر', 'ميكانيك', 'كهرب'])) {
      return Icons.architecture_outlined;
    }

    final category = SubjectGroupingHelper.resolveCategoryKey(subject);
    switch (category) {
      case 'medicine':
        return Icons.medical_services_outlined;
      case 'it':
        return Icons.terminal_outlined;
      case 'engineering':
        return Icons.engineering_outlined;
      default:
        return Icons.menu_book_outlined;
    }
  }

  static bool _containsAny(String text, List<String> keywords) {
    for (final keyword in keywords) {
      if (text.contains(keyword.toLowerCase())) {
        return true;
      }
    }
    return false;
  }
}
