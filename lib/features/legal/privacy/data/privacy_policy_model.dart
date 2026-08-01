import 'package:flutter/material.dart';

class PrivacyPolicySectionData {
  const PrivacyPolicySectionData({
    required this.id,
    required this.title,
    required this.icon,
    required this.paragraphs,
    this.bulletPoints = const [],
    this.subsections = const [],
  });

  final String id;
  final String title;
  final IconData icon;
  final List<String> paragraphs;
  final List<String> bulletPoints;
  final List<PrivacyPolicySubsection> subsections;
}

class PrivacyPolicySubsection {
  const PrivacyPolicySubsection({
    required this.title,
    required this.items,
  });

  final String title;
  final List<String> items;
}

class PrivacyPolicyDocument {
  const PrivacyPolicyDocument({
    required this.title,
    required this.subtitle,
    required this.lastUpdated,
    required this.version,
    required this.sections,
    required this.source,
  });

  final String title;
  final String subtitle;
  final String lastUpdated;
  final String version;
  final List<PrivacyPolicySectionData> sections;
  final PrivacyPolicySource source;

  bool get isLocal => source == PrivacyPolicySource.local;
}

enum PrivacyPolicySource { remote, local, cached }

enum PrivacyPolicyLoadStatus { initial, loading, loaded, error, offline }
