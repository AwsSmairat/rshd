import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rshd/core/theme/app_theme.dart';
import 'package:rshd/core/widgets/password_requirements.dart';
import 'package:rshd/features/settings/presentation/change_password_screen.dart';

Future<void> _pump(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        theme: AppTheme.light,
        home: const Directionality(
          textDirection: TextDirection.rtl,
          child: ChangePasswordScreen(),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows the password checklist under the new password', (
    tester,
  ) async {
    await _pump(tester);

    expect(find.byType(PasswordRequirementsChecklist), findsOneWidget);
  });

  testWidgets('a weak new password is warned about and not sent', (
    tester,
  ) async {
    await _pump(tester);

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Current@2026');
    await tester.enterText(fields.at(1), 'abcdefgh1');
    await tester.enterText(fields.at(2), 'abcdefgh1');
    await tester.pumpAndSettle();

    await tester.tap(find.text('حفظ كلمة المرور'));
    await tester.pumpAndSettle();

    // Under the field, and as a warning bar.
    expect(
      find.textContaining('كلمة المرور يجب أن تحتوي على:'),
      findsNWidgets(2),
    );
  });

  testWidgets('a mismatched confirmation is warned about', (tester) async {
    await _pump(tester);

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Current@2026');
    await tester.enterText(fields.at(1), 'Rshd@2026x');
    await tester.enterText(fields.at(2), 'Rshd@2026y');
    await tester.pumpAndSettle();

    await tester.tap(find.text('حفظ كلمة المرور'));
    await tester.pumpAndSettle();

    expect(find.text('كلمتا المرور غير متطابقتين'), findsNWidgets(2));
  });
}
