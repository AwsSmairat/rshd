import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rshd/core/navigation/student_shell.dart';

/// A tab page with a button that opens a detail page over the shell.
class _Page extends StatelessWidget {
  const _Page(this.name);
  final String name;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('page:$name'),
          TextButton(
            onPressed: () => context.push('/detail'),
            child: Text('open-from-$name'),
          ),
        ],
      ),
    ),
  );
}

GoRouter _router() => GoRouter(
  initialLocation: '/home',
  routes: [
    StatefulShellRoute(
      builder: (context, state, shell) => StudentShell(navigationShell: shell),
      navigatorContainerBuilder: (context, shell, children) =>
          AnimatedTabSwitcher(
            currentIndex: shell.currentIndex,
            children: children,
          ),
      branches: [
        for (final name in [
          'home',
          'subjects',
          'assignments',
          'quizzes',
          'profile',
        ])
          StatefulShellBranch(
            routes: [GoRoute(path: '/$name', builder: (_, _) => _Page(name))],
          ),
      ],
    ),
    GoRoute(
      path: '/detail',
      builder: (context, _) => Scaffold(
        body: Center(
          child: TextButton(
            onPressed: () => context.pop(),
            child: const Text('back'),
          ),
        ),
      ),
    ),
  ],
);

/// The page that is actually visible: active tabs are fully opaque.
bool _visible(WidgetTester tester, String name) {
  final finder = find.text('page:$name', skipOffstage: false);
  if (finder.evaluate().isEmpty) return false;
  final fades = tester.renderObjectList<RenderObject>(
    find.ancestor(of: finder, matching: find.byType(FadeTransition)),
  );
  // ignore: avoid_dynamic_calls
  return fades.every((r) => (r as dynamic).opacity.value == 1.0);
}

void main() {
  Future<void> tapTab(WidgetTester tester, String label) async {
    await tester.tap(find.bySemanticsLabel(label));
    await tester.pumpAndSettle();
  }

  testWidgets('tapping the bar moves between tabs and back', (tester) async {
    tester.view.physicalSize = const Size(1290, 2796);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: _router())),
    );
    await tester.pumpAndSettle();
    expect(_visible(tester, 'home'), isTrue);

    const labels = {
      'home': 'الرئيسية',
      'subjects': 'موادي',
      'assignments': 'واجباتي',
      'quizzes': 'اختباراتي',
      'profile': 'حسابي',
    };
    for (final step in [
      'subjects',
      'home',
      'profile',
      'home',
      'assignments',
      'subjects',
      'quizzes',
      'home',
      'profile',
      'quizzes',
    ]) {
      await tapTab(tester, labels[step]!);
      for (final other in labels.keys) {
        expect(
          _visible(tester, other),
          other == step,
          reason: 'after tapping $step, $other visible?',
        );
      }
    }
  });

  testWidgets('a page opened from a tab returns to that tab', (tester) async {
    tester.view.physicalSize = const Size(1290, 2796);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: _router())),
    );
    await tester.pumpAndSettle();

    await tapTab(tester, 'موادي');
    await tester.tap(find.text('open-from-subjects'));
    await tester.pumpAndSettle();
    expect(find.text('back'), findsOneWidget);

    await tester.tap(find.text('back'));
    await tester.pumpAndSettle();
    expect(_visible(tester, 'subjects'), isTrue);

    // And the bar still works afterwards.
    await tapTab(tester, 'الرئيسية');
    expect(_visible(tester, 'home'), isTrue);
    expect(_visible(tester, 'subjects'), isFalse);
  });
}
