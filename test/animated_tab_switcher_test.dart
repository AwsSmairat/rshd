import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rshd/core/navigation/student_shell.dart';

double _opacityOf(WidgetTester tester, String label) {
  final opacity = tester.widget<AnimatedOpacity>(
    find.ancestor(of: find.text(label), matching: find.byType(AnimatedOpacity)),
  );
  return opacity.opacity;
}

/// Effective painted opacity of the tab, read from the render tree so a
/// frozen fade-out animation is caught, not just the target value.
double _paintedOpacity(WidgetTester tester, String label) {
  final render = tester.renderObject<RenderAnimatedOpacity>(
    find
        .ancestor(of: find.text(label), matching: find.byType(FadeTransition))
        .first, // nearest: the tab's own fade, not the route's
  );
  return render.opacity.value;
}

void main() {
  Widget host(int index) => MaterialApp(
    home: AnimatedTabSwitcher(
      currentIndex: index,
      children: const [Text('home'), Text('subjects'), Text('account')],
    ),
  );

  testWidgets('leaving a later tab fades it out completely', (tester) async {
    await tester.pumpWidget(host(2));
    await tester.pumpAndSettle();
    expect(_opacityOf(tester, 'account'), 1);

    // Back to an earlier tab: the account tab sits above it in the stack and
    // must not stay painted.
    await tester.pumpWidget(host(0));
    await tester.pumpAndSettle();

    expect(_opacityOf(tester, 'home'), 1);
    expect(_paintedOpacity(tester, 'account'), 0);
    expect(_paintedOpacity(tester, 'home'), 1);
  });
}
