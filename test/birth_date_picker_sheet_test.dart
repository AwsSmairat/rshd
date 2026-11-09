import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rshd/core/theme/app_theme.dart';
import 'package:rshd/features/settings/widgets/birth_date_picker_sheet.dart';

void main() {
  Future<DateTime?> open(WidgetTester tester, {DateTime? initial}) async {
    DateTime? result;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () async {
                    result = await showBirthDatePickerSheet(
                      context,
                      initial: initial,
                    );
                  },
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return result;
  }

  testWidgets('shows the current date in words with the age', (tester) async {
    await open(tester, initial: DateTime(2004, 4, 21));

    expect(find.text('21 أبريل 2004'), findsOneWidget);
    expect(find.textContaining('العمر'), findsOneWidget);
    expect(find.byType(CupertinoPicker), findsNWidgets(3));
  });

  testWidgets('تم returns the chosen date; إلغاء returns nothing', (
    tester,
  ) async {
    DateTime? picked;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                picked = await showBirthDatePickerSheet(
                  context,
                  initial: DateTime(2004, 4, 21),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('تم'));
    await tester.pumpAndSettle();
    expect(picked, DateTime(2004, 4, 21));

    picked = null;
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('إلغاء'));
    await tester.pumpAndSettle();
    expect(picked, isNull);
  });

  testWidgets('February has no 30th or 31st', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: BirthDatePickerSheet(
            initial: DateTime(2003, 2, 10),
            today: DateTime(2026, 11, 9),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final dayWheel = tester.widget<CupertinoPicker>(
      find.byType(CupertinoPicker).first,
    );
    expect(dayWheel.childDelegate.estimatedChildCount, 28);
  });
}
