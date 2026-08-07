import '../privacy/data/privacy_policy_model.dart';
import '../terms/data/terms_and_conditions_model.dart';
import 'legal_icon_mapper.dart';

class LegalDocumentParser {
  LegalDocumentParser._();

  static String formatLastUpdated(String? raw) {
    if (raw == null || raw.isEmpty) {
      return '';
    }

    final parsed = DateTime.tryParse(raw);
    if (parsed == null) {
      return raw;
    }

    final y = parsed.year.toString().padLeft(4, '0');
    final m = parsed.month.toString().padLeft(2, '0');
    final d = parsed.day.toString().padLeft(2, '0');

    return '$y/$m/$d';
  }

  static PrivacyPolicyDocument parsePrivacyPolicy(
    Map<String, dynamic> data, {
    required PrivacyPolicySource source,
  }) {
    return PrivacyPolicyDocument(
      title: data['title']?.toString() ?? 'سياسة الخصوصية',
      subtitle: data['subtitle']?.toString() ?? '',
      lastUpdated: formatLastUpdated(data['last_updated']?.toString()),
      version: data['version']?.toString() ?? '1.0',
      sections: _parsePrivacySections(data['sections']),
      source: source,
    );
  }

  static TermsDocument parseTerms(
    Map<String, dynamic> data, {
    required TermsSource source,
    bool requiresAcceptance = false,
    String? acceptedVersion,
  }) {
    return TermsDocument(
      title: data['title']?.toString() ?? 'الشروط والأحكام',
      subtitle: data['subtitle']?.toString() ?? '',
      version: data['version']?.toString() ?? '1.0',
      lastUpdated: formatLastUpdated(data['last_updated']?.toString()),
      sections: _parseTermsSections(data['sections']),
      source: source,
      requiresAcceptance: requiresAcceptance,
      acceptedVersion: acceptedVersion,
    );
  }

  static List<PrivacyPolicySectionData> _parsePrivacySections(dynamic raw) {
    if (raw is! List) {
      return const [];
    }

    return raw
        .whereType<Map>()
        .map((section) {
          final map = Map<String, dynamic>.from(section);
          return PrivacyPolicySectionData(
            id: map['id']?.toString() ?? '',
            title: map['title']?.toString() ?? '',
            icon: LegalIconMapper.resolve(map['icon']?.toString()),
            paragraphs: _stringList(map['paragraphs']),
            bulletPoints: _stringList(map['bullet_points']),
            subsections: _parsePrivacySubsections(map['subsections']),
          );
        })
        .where((section) => section.id.isNotEmpty)
        .toList();
  }

  static List<TermsSectionData> _parseTermsSections(dynamic raw) {
    if (raw is! List) {
      return const [];
    }

    return raw
        .whereType<Map>()
        .map((section) {
          final map = Map<String, dynamic>.from(section);
          return TermsSectionData(
            id: map['id']?.toString() ?? '',
            title: map['title']?.toString() ?? '',
            icon: LegalIconMapper.resolve(map['icon']?.toString()),
            paragraphs: _stringList(map['paragraphs']),
            bulletPoints: _stringList(map['bullet_points']),
            subsections: _parseTermsSubsections(map['subsections']),
          );
        })
        .where((section) => section.id.isNotEmpty)
        .toList();
  }

  static List<PrivacyPolicySubsection> _parsePrivacySubsections(dynamic raw) {
    if (raw is! List) {
      return const [];
    }

    return raw.whereType<Map>().map((item) {
      final map = Map<String, dynamic>.from(item);
      return PrivacyPolicySubsection(
        title: map['title']?.toString() ?? '',
        items: _stringList(map['items']),
      );
    }).toList();
  }

  static List<TermsSubsection> _parseTermsSubsections(dynamic raw) {
    if (raw is! List) {
      return const [];
    }

    return raw.whereType<Map>().map((item) {
      final map = Map<String, dynamic>.from(item);
      return TermsSubsection(
        title: map['title']?.toString() ?? '',
        items: _stringList(map['items']),
      );
    }).toList();
  }

  static List<String> _stringList(dynamic raw) {
    if (raw is! List) {
      return const [];
    }

    return raw.map((item) => item.toString()).where((item) => item.isNotEmpty).toList();
  }
}
