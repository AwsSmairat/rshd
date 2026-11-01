import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rshd/features/auth/presentation/widgets/birth_date_sheet.dart';

void main() {
  testWidgets('sheet uses wheels capped at the minimum-age date', (
    tester,
  ) async {
    final latest = DateTime(2008, 11, 1);
    DateTime? result;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () async => result = await showBirthDateSheet(
                  context,
                  initial: latest,
                  earliest: DateTime(1926),
                  latest: latest,
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // Wheels, not the calendar grid.
    final picker = tester.widget<CupertinoDatePicker>(
      find.byType(CupertinoDatePicker),
    );
    expect(picker.maximumDate, latest);
    expect(picker.mode, CupertinoDatePickerMode.date);
    expect(find.byType(CalendarDatePicker), findsNothing);

    // Live read-out shows the age.
    expect(find.textContaining('العمر 18 سنة'), findsOneWidget);

    await tester.tap(find.text('تأكيد'));
    await tester.pumpAndSettle();
    expect(result, latest);
  });
}
