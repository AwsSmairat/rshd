import 'package:flutter/material.dart';

class TermsSectionData {
  const TermsSectionData({
    required this.id,
    required this.title,
    required this.icon,
    this.paragraphs = const [],
    this.bulletPoints = const [],
    this.subsections = const [],
  });

  final String id;
  final String title;
  final IconData icon;
  final List<String> paragraphs;
  final List<String> bulletPoints;
  final List<TermsSubsection> subsections;
}

class TermsSubsection {
  const TermsSubsection({required this.title, required this.items});

  final String title;
  final List<String> items;
}

class TermsDocument {
  const TermsDocument({
    required this.title,
    required this.subtitle,
    required this.version,
    required this.lastUpdated,
    required this.sections,
    required this.source,
    this.requiresAcceptance = false,
    this.acceptedVersion,
  });

  final String title;
  final String subtitle;
  final String version;
  final String lastUpdated;
  final List<TermsSectionData> sections;
  final TermsSource source;
  final bool requiresAcceptance;
  final String? acceptedVersion;

  bool get isLocal => source == TermsSource.local;
}

enum TermsSource { remote, local, cached }

enum TermsLoadStatus { initial, loading, loaded, error, offline }

class TermsAcceptanceStatus {
  const TermsAcceptanceStatus({
    required this.currentVersion,
    required this.requiresAcceptance,
    this.acceptedVersion,
    this.acceptedAt,
  });

  final String currentVersion;
  final bool requiresAcceptance;
  final String? acceptedVersion;
  final String? acceptedAt;
}
