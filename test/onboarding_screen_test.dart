import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rshd/features/onboarding/presentation/onboarding_screen.dart';

void main() {
  Future<void> pumpOnboarding(
    WidgetTester tester, {
    Size size = const Size(390, 844),
    double textScaleFactor = 1,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = GoRouter(
      initialLocation: '/onboarding',
      routes: [
        GoRoute(
          path: '/onboarding',
          builder: (context, state) => const OnboardingScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) =>
              const Scaffold(body: Text('Login destination')),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScaleFactor)),
          child: child!,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('page one renders the real responsive Flutter UI', (
    tester,
  ) async {
    await pumpOnboarding(tester);

    expect(find.text('تعلّم بطريقة أذكى'), findsOneWidget);
    expect(
      find.text('دروسك، ملفاتك ومتابعة تقدّمك في مكان واحد.'),
      findsOneWidget,
    );
    expect(find.text('LEARN | ACHIEVE | GROW'), findsOneWidget);
    expect(find.text('تخطي'), findsOneWidget);
    expect(find.text('التالي'), findsOneWidget);
    expect(find.byType(Image), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('page one has no overflow on small iPhone with scaled text', (
    tester,
  ) async {
    await pumpOnboarding(
      tester,
      size: const Size(320, 568),
      textScaleFactor: 1.3,
    );

    expect(find.text('تعلّم بطريقة أذكى'), findsOneWidget);
    expect(find.text('التالي'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('next advances the PageView with a smooth transition', (
    tester,
  ) async {
    await pumpOnboarding(tester);

    await tester.tap(find.text('التالي'));
    await tester.pumpAndSettle();

    final secondIndicator = tester.widget<AnimatedContainer>(
      find.byKey(const ValueKey('onboarding-indicator-1')),
    );
    final decoration = secondIndicator.decoration! as BoxDecoration;
    expect(decoration.color, isNot(Colors.transparent));
  });

  testWidgets('skip navigates to login', (tester) async {
    await pumpOnboarding(tester);

    await tester.tap(find.text('تخطي'));
    await tester.pumpAndSettle();

    expect(find.text('Login destination'), findsOneWidget);
  });
}
