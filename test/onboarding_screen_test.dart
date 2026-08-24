import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rshd/core/constants/storage_keys.dart';
import 'package:rshd/core/network/api_client.dart';
import 'package:rshd/core/storage/secure_storage_service.dart';
import 'package:rshd/core/theme/app_colors.dart';
import 'package:rshd/features/onboarding/presentation/onboarding_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const secureStorageChannel = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );

  late Map<String, String> secureStore;

  setUp(() {
    secureStore = {};

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorageChannel, (
          MethodCall call,
        ) async {
          switch (call.method) {
            case 'write':
              final key = call.arguments['key'] as String;
              final value = call.arguments['value'] as String?;
              if (value == null) {
                secureStore.remove(key);
              } else {
                secureStore[key] = value;
              }
              return null;
            case 'read':
              final key = call.arguments['key'] as String;
              return secureStore[key];
            case 'delete':
              final key = call.arguments['key'] as String;
              secureStore.remove(key);
              return null;
            case 'deleteAll':
              secureStore.clear();
              return null;
            case 'containsKey':
              final key = call.arguments['key'] as String;
              return secureStore.containsKey(key);
            default:
              return null;
          }
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorageChannel, null);
  });

  Future<void> pumpOnboarding(
    WidgetTester tester, {
    Size size = const Size(390, 844),
    double textScaleFactor = 1,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final storage = SecureStorageService();

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
        GoRoute(
          path: '/register',
          builder: (context, state) =>
              const Scaffold(body: Text('Register destination')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [secureStorageProvider.overrideWithValue(storage)],
        child: MaterialApp.router(
          routerConfig: router,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(textScaleFactor)),
            child: child!,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> goToPage(WidgetTester tester, int pageIndex) async {
    for (var page = 0; page < pageIndex; page++) {
      await tester.tap(find.text('التالي'));
      await tester.pumpAndSettle();
    }
  }

  BoxDecoration indicatorDecoration(WidgetTester tester, int index) {
    final indicator = tester.widget<AnimatedContainer>(
      find.byKey(ValueKey('onboarding-indicator-$index')),
    );
    return indicator.decoration! as BoxDecoration;
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

    expect(indicatorDecoration(tester, 1).color, AppColors.accent);
    expect(indicatorDecoration(tester, 0).color, Colors.transparent);
  });

  testWidgets('skip navigates to login and saves onboarding completion', (
    tester,
  ) async {
    await pumpOnboarding(tester);

    await tester.tap(find.text('تخطي'));
    await tester.pumpAndSettle();

    expect(find.text('Login destination'), findsOneWidget);
    expect(secureStore[StorageKeys.onboardingCompleted], 'true');
  });

  testWidgets('page two renders title description and illustration asset', (
    tester,
  ) async {
    await pumpOnboarding(tester);
    await goToPage(tester, 1);

    expect(find.text('كل أدواتك للدراسة… بمكان واحد'), findsOneWidget);
    expect(
      find.text(
        'شاهد، اقرأ، ظلّل ودوّن ملاحظاتك، وكمّل تعلّمك بالطريقة اللي تناسبك.',
      ),
      findsOneWidget,
    );
    expect(find.text('LEARN | ACHIEVE | GROW'), findsOneWidget);
    expect(find.text('تخطي'), findsOneWidget);
    expect(find.text('التالي'), findsOneWidget);
    expect(find.byType(Image), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('page two uses RTL layout and active second indicator', (
    tester,
  ) async {
    await pumpOnboarding(tester);
    await goToPage(tester, 1);

    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Directionality &&
            widget.textDirection == TextDirection.rtl,
      ),
      findsWidgets,
    );
    expect(indicatorDecoration(tester, 1).color, AppColors.accent);
    expect(indicatorDecoration(tester, 0).color, Colors.transparent);
    expect(indicatorDecoration(tester, 2).color, Colors.transparent);
  });

  testWidgets('page two next advances to page three', (tester) async {
    await pumpOnboarding(tester);
    await goToPage(tester, 2);

    expect(indicatorDecoration(tester, 2).color, AppColors.accent);
    expect(find.text('ابدأ الآن'), findsOneWidget);
  });

  testWidgets('page two skip navigates to login', (tester) async {
    await pumpOnboarding(tester);
    await goToPage(tester, 1);

    await tester.tap(find.text('تخطي'));
    await tester.pumpAndSettle();

    expect(find.text('Login destination'), findsOneWidget);
  });

  testWidgets('swipe forward from page one to page two works', (tester) async {
    await pumpOnboarding(tester);

    await tester.drag(find.byType(PageView), const Offset(320, 0));
    await tester.pumpAndSettle();

    expect(find.text('كل أدواتك للدراسة… بمكان واحد'), findsOneWidget);
    expect(indicatorDecoration(tester, 1).color, AppColors.accent);
  });

  testWidgets('swipe back from page two to page one works', (tester) async {
    await pumpOnboarding(tester);
    await goToPage(tester, 1);

    await tester.drag(find.byType(PageView), const Offset(-320, 0));
    await tester.pumpAndSettle();

    expect(find.text('تعلّم بطريقة أذكى'), findsOneWidget);
    expect(indicatorDecoration(tester, 0).color, AppColors.accent);
  });

  testWidgets('system back from page two returns to page one', (tester) async {
    await pumpOnboarding(tester);
    await goToPage(tester, 1);

    final handled = await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(handled, isTrue);
    expect(find.text('تعلّم بطريقة أذكى'), findsOneWidget);
    expect(indicatorDecoration(tester, 0).color, AppColors.accent);
  });

  testWidgets('page two has no network images', (tester) async {
    await pumpOnboarding(tester);
    await goToPage(tester, 1);

    expect(
      find.byWidgetPredicate(
        (widget) => widget is Image && widget.image is NetworkImage,
      ),
      findsNothing,
    );
  });

  testWidgets('page two has no overflow on small screen with large text', (
    tester,
  ) async {
    await pumpOnboarding(
      tester,
      size: const Size(320, 568),
      textScaleFactor: 1.3,
    );
    await goToPage(tester, 1);

    expect(find.text('كل أدواتك للدراسة… بمكان واحد'), findsOneWidget);
    expect(find.text('التالي'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('page state persists after swipe forward and back', (
    tester,
  ) async {
    await pumpOnboarding(tester);

    await tester.drag(find.byType(PageView), const Offset(320, 0));
    await tester.pumpAndSettle();
    expect(find.text('كل أدواتك للدراسة… بمكان واحد'), findsOneWidget);

    await tester.drag(find.byType(PageView), const Offset(-320, 0));
    await tester.pumpAndSettle();
    expect(find.text('تعلّم بطريقة أذكى'), findsOneWidget);

    await tester.tap(find.text('التالي'));
    await tester.pumpAndSettle();
    expect(find.text('كل أدواتك للدراسة… بمكان واحد'), findsOneWidget);
    expect(indicatorDecoration(tester, 1).color, AppColors.accent);
  });

  testWidgets('page three renders title description and illustration', (
    tester,
  ) async {
    await pumpOnboarding(tester);
    await goToPage(tester, 2);

    expect(find.text('تقدّمك قدامك… وهدفك أقرب'), findsOneWidget);
    expect(
      find.text('تابع إنجازك، اختباراتك ودرجاتك، وخليك دائمًا عارف وين وصلت.'),
      findsOneWidget,
    );
    expect(find.text('LEARN | ACHIEVE | GROW'), findsOneWidget);
    expect(find.text('ابدأ الآن'), findsOneWidget);
    expect(find.text('تسجيل الدخول'), findsOneWidget);
    expect(find.byType(Image), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('page three third indicator active and first two inactive', (
    tester,
  ) async {
    await pumpOnboarding(tester);
    await goToPage(tester, 2);

    expect(indicatorDecoration(tester, 2).color, AppColors.accent);
    expect(indicatorDecoration(tester, 0).color, Colors.transparent);
    expect(indicatorDecoration(tester, 1).color, Colors.transparent);
  });

  testWidgets('page three start saves completion and navigates to register', (
    tester,
  ) async {
    await pumpOnboarding(tester);
    await goToPage(tester, 2);

    await tester.tap(find.text('ابدأ الآن'));
    await tester.pumpAndSettle();

    expect(find.text('Register destination'), findsOneWidget);
    expect(secureStore[StorageKeys.onboardingCompleted], 'true');
  });

  testWidgets('page three login saves completion and navigates to login', (
    tester,
  ) async {
    await pumpOnboarding(tester);
    await goToPage(tester, 2);

    await tester.tap(find.text('تسجيل الدخول'));
    await tester.pumpAndSettle();

    expect(find.text('Login destination'), findsOneWidget);
    expect(secureStore[StorageKeys.onboardingCompleted], 'true');
  });

  testWidgets('system back from page three returns to page two', (
    tester,
  ) async {
    await pumpOnboarding(tester);
    await goToPage(tester, 2);

    final handled = await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(handled, isTrue);
    expect(find.text('كل أدواتك للدراسة… بمكان واحد'), findsOneWidget);
    expect(indicatorDecoration(tester, 1).color, AppColors.accent);
  });

  testWidgets('swipe back from page three to page two works', (tester) async {
    await pumpOnboarding(tester);
    await goToPage(tester, 2);

    await tester.drag(find.byType(PageView), const Offset(-320, 0));
    await tester.pumpAndSettle();

    expect(find.text('كل أدواتك للدراسة… بمكان واحد'), findsOneWidget);
    expect(indicatorDecoration(tester, 1).color, AppColors.accent);
  });

  testWidgets('page three skip saves completion and navigates to login', (
    tester,
  ) async {
    await pumpOnboarding(tester);
    await goToPage(tester, 2);

    await tester.tap(find.text('تخطي'));
    await tester.pumpAndSettle();

    expect(find.text('Login destination'), findsOneWidget);
    expect(secureStore[StorageKeys.onboardingCompleted], 'true');
  });

  testWidgets('page three uses RTL layout', (tester) async {
    await pumpOnboarding(tester);
    await goToPage(tester, 2);

    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Directionality &&
            widget.textDirection == TextDirection.rtl,
      ),
      findsWidgets,
    );
  });

  testWidgets('page three has no network images', (tester) async {
    await pumpOnboarding(tester);
    await goToPage(tester, 2);

    expect(
      find.byWidgetPredicate(
        (widget) => widget is Image && widget.image is NetworkImage,
      ),
      findsNothing,
    );
  });

  testWidgets('page three has no overflow on small screen with large text', (
    tester,
  ) async {
    await pumpOnboarding(
      tester,
      size: const Size(320, 568),
      textScaleFactor: 1.3,
    );
    await goToPage(tester, 2);

    expect(find.text('تقدّمك قدامك… وهدفك أقرب'), findsOneWidget);
    expect(find.text('ابدأ الآن'), findsOneWidget);
    expect(find.text('تسجيل الدخول'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reaching page three alone does not save onboarding completion', (
    tester,
  ) async {
    await pumpOnboarding(tester);
    await goToPage(tester, 2);

    expect(find.text('ابدأ الآن'), findsOneWidget);
    expect(secureStore.containsKey(StorageKeys.onboardingCompleted), isFalse);
  });
}
