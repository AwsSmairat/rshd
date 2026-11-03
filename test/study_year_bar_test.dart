import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rshd/core/theme/app_theme.dart';
import 'package:rshd/features/subjects/widgets/study_year_bar.dart';

void main() {
  testWidgets('offers all years plus years one to six', (tester) async {
    int? picked = -1;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: StudyYearBar(selected: null, onChanged: (y) => picked = y),
        ),
      ),
    );

    expect(find.text('الكل'), findsOneWidget);
    expect(find.text('السنة الأولى'), findsOneWidget);
    await tester.tap(find.text('السنة الثانية'));
    await tester.pump();
    expect(picked, 2);

    await tester.scrollUntilVisible(
      find.text('السنة السادسة'),
      100,
      scrollable: find.byType(Scrollable),
    );
    await tester.pumpAndSettle();
    expect(find.text('السنة السادسة'), findsOneWidget);

    await tester.tap(find.text('السنة السادسة'));
    await tester.pump();
    expect(picked, 6);
  });
}
