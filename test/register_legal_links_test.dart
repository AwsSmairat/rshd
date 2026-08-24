import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:rshd/core/router/app_router.dart';
import 'package:rshd/features/auth/presentation/widgets/register_legal_links.dart';

const _termsLabel = 'شروط الاستخدام';
const _privacyLabel = 'سياسة الخصوصية';

void main() {
  testWidgets('register legal links open privacy and terms routes', (
    tester,
  ) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: RegisterLegalLinks()),
        ),
        GoRoute(
          path: AppRoutes.privacyPolicy,
          builder: (_, _) => const Text('privacy-page'),
        ),
        GoRoute(
          path: AppRoutes.termsAndConditions,
          builder: (_, _) => const Text('terms-page'),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(find.byType(RegisterLegalLinks), findsOneWidget);
    final legalText = _legalPlainText(tester);
    expect(legalText, contains(_termsLabel));
    expect(legalText, contains(_privacyLabel));

    _tapLegalSpan(tester, _privacyLabel);
    await tester.pumpAndSettle();
    expect(find.text('privacy-page'), findsOneWidget);

    router.go('/');
    await tester.pumpAndSettle();

    _tapLegalSpan(tester, _termsLabel);
    await tester.pumpAndSettle();
    expect(find.text('terms-page'), findsOneWidget);
  });
}

String _legalPlainText(WidgetTester tester) {
  final richText = tester.widget<RichText>(
    find.descendant(
      of: find.byType(RegisterLegalLinks),
      matching: find.byType(RichText),
    ),
  );

  return richText.text.toPlainText();
}

void _tapLegalSpan(WidgetTester tester, String label) {
  final richText = tester.widget<RichText>(
    find.descendant(
      of: find.byType(RegisterLegalLinks),
      matching: find.byType(RichText),
    ),
  );

  var tapped = false;
  void visit(InlineSpan span) {
    if (span is TextSpan && span.text == label) {
      final recognizer = span.recognizer;
      if (recognizer is TapGestureRecognizer) {
        recognizer.onTap?.call();
        tapped = true;
      }
    }
    if (span is TextSpan) {
      for (final child in span.children ?? const <InlineSpan>[]) {
        visit(child);
      }
    }
  }

  visit(richText.text);
  expect(tapped, isTrue, reason: 'missing tap target for $label');
}
