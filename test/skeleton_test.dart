import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rshd/core/theme/app_theme.dart';
import 'package:rshd/core/widgets/skeleton.dart';

void main() {
  Widget host({bool reduceMotion = false}) => MaterialApp(
    theme: AppTheme.light,
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: reduceMotion),
      child: const Scaffold(
        body: Skeleton(
          child: Column(
            children: [SkeletonBox(width: 120, height: 14), SkeletonListRow()],
          ),
        ),
      ),
    ),
  );

  Color boxColor(WidgetTester tester) {
    final box = tester.widget<Container>(
      find
          .descendant(
            of: find.byType(SkeletonBox).first,
            matching: find.byType(Container),
          )
          .first,
    );
    return (box.decoration! as BoxDecoration).color!;
  }

  testWidgets('screen readers hear one "loading", not the empty shapes', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(host(reduceMotion: true));

    expect(find.bySemanticsLabel('جاري التحميل'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('the shapes breathe while loading', (tester) async {
    await tester.pumpWidget(host());
    final first = boxColor(tester);
    await tester.pump(const Duration(milliseconds: 550));

    expect(boxColor(tester), isNot(first));
  });

  testWidgets('the shapes stay still when motion is reduced', (tester) async {
    await tester.pumpWidget(host(reduceMotion: true));
    final first = boxColor(tester);
    await tester.pump(const Duration(milliseconds: 550));

    expect(boxColor(tester), first);
    expect(tester.hasRunningAnimations, isFalse);
  });
}
