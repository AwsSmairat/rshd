import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rshd/features/legal/shared/legal_document_parser.dart';
import 'package:rshd/features/legal/shared/legal_icon_mapper.dart';
import 'package:rshd/features/legal/privacy/data/privacy_policy_content.dart';
import 'package:rshd/features/legal/privacy/data/privacy_policy_model.dart';
import 'package:rshd/features/legal/terms/data/terms_and_conditions_content.dart';
import 'package:rshd/features/legal/terms/data/terms_and_conditions_model.dart';

void main() {
  group('LegalDocumentParser', () {
    test('parses privacy policy sections from API payload', () {
      final document = LegalDocumentParser.parsePrivacyPolicy({
        'title': 'سياسة الخصوصية',
        'subtitle': 'وصف',
        'version': '1.0',
        'last_updated': '2026-07-31T10:00:00.000000Z',
        'sections': [
          {
            'id': 'introduction',
            'title': 'مقدمة',
            'icon': 'info_outline',
            'paragraphs': ['نص'],
            'bullet_points': ['نقطة'],
            'subsections': [],
          },
        ],
      }, source: PrivacyPolicySource.remote);

      expect(document.title, 'سياسة الخصوصية');
      expect(document.version, '1.0');
      expect(document.lastUpdated, '2026/07/31');
      expect(document.sections, hasLength(1));
      expect(document.sections.first.icon, Icons.info_outline);
    });

    test('parses terms payload with acceptance flags', () {
      final document = LegalDocumentParser.parseTerms(
        {
          'title': 'الشروط',
          'subtitle': 'وصف',
          'version': '2.0',
          'last_updated': '2026-08-01T00:00:00.000000Z',
          'requires_acceptance': true,
          'sections': [
            {
              'id': 'intro',
              'title': 'مقدمة',
              'icon': 'handshake_outlined',
              'paragraphs': ['نص'],
              'bullet_points': [],
              'subsections': [],
            },
          ],
        },
        source: TermsSource.remote,
        requiresAcceptance: true,
        acceptedVersion: '1.0',
      );

      expect(document.version, '2.0');
      expect(document.requiresAcceptance, isTrue);
      expect(document.acceptedVersion, '1.0');
    });
  });

  group('LegalIconMapper', () {
    test('falls back to article icon for unknown names', () {
      expect(LegalIconMapper.resolve('unknown_icon'), Icons.article_outlined);
    });
  });

  group('Local fallback documents', () {
    test('privacy local document remains available', () {
      final doc = PrivacyPolicyContent.buildLocalDocument();
      expect(doc.source, PrivacyPolicySource.local);
      expect(doc.sections, isNotEmpty);
    });

    test('terms local document supports acceptance flags', () {
      final doc = TermsAndConditionsContent.buildLocalDocument(
        requiresAcceptance: true,
        acceptedVersion: '1.0',
      );
      expect(doc.requiresAcceptance, isTrue);
      expect(doc.acceptedVersion, '1.0');
    });
  });
}
