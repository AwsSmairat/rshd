import '../data/models/subject_model.dart';

class SubjectSection {
  const SubjectSection({
    required this.categoryKey,
    required this.title,
    required this.subjects,
  });

  final String categoryKey;
  final String title;
  final List<SubjectModel> subjects;
}

class SubjectGroupingHelper {
  SubjectGroupingHelper._();

  // TODO: Replace local grouping with backend department field later.

  static const sectionTitles = {
    'medicine': 'الطب',
    'it': 'تكنولوجيا المعلومات',
    'engineering': 'الهندسة',
    'general': 'مواد أخرى',
  };

  static const _order = ['medicine', 'it', 'engineering', 'general'];

  static const _medicineKeywords = [
    'طب',
    'تشريح',
    'كيمياء حيوية',
    'حيوية',
    'medical',
    'anatomy',
  ];

  static const _itKeywords = [
    'برمجة',
    'تطبيقات',
    'قواعد البيانات',
    'أمن المعلومات',
    'flutter',
    'dart',
    'sql',
    'تقنية',
  ];

  static const _engineeringKeywords = [
    'هندسة',
    'رسم هندسي',
    'دوائر',
    'ميكانيكا',
    'كهرباء',
  ];

  static String resolveCategoryKey(SubjectModel subject) {
    final backendCategory = subject.category.trim();
    if (backendCategory.isNotEmpty &&
        sectionTitles.containsKey(backendCategory)) {
      return backendCategory;
    }

    final searchableText = '${subject.title} ${subject.description ?? ''}'
        .toLowerCase();

    if (_containsAny(searchableText, _medicineKeywords)) {
      return 'medicine';
    }
    if (_containsAny(searchableText, _itKeywords)) {
      return 'it';
    }
    if (_containsAny(searchableText, _engineeringKeywords)) {
      return 'engineering';
    }

    return 'general';
  }

  static List<SubjectSection> groupSubjects(List<SubjectModel> subjects) {
    final grouped = <String, List<SubjectModel>>{};

    for (final subject in subjects) {
      final key = resolveCategoryKey(subject);
      grouped.putIfAbsent(key, () => []).add(subject);
    }

    final sections = <SubjectSection>[];
    for (final key in _order) {
      final items = grouped.remove(key);
      if (items == null || items.isEmpty) {
        continue;
      }
      sections.add(
        SubjectSection(
          categoryKey: key,
          title: sectionTitles[key] ?? key,
          subjects: items,
        ),
      );
    }

    for (final entry in grouped.entries) {
      if (entry.value.isEmpty) {
        continue;
      }
      sections.add(
        SubjectSection(
          categoryKey: entry.key,
          title: sectionTitles[entry.key] ?? entry.key,
          subjects: entry.value,
        ),
      );
    }

    return sections;
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
