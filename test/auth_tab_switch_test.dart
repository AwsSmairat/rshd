import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:rshd/core/l10n/app_locale_controller.dart';
import 'package:rshd/core/l10n/app_strings.dart';
import 'package:rshd/core/network/api_client.dart';
import 'package:rshd/core/router/app_router.dart';
import 'package:rshd/features/auth/data/auth_repository.dart';
import 'package:rshd/features/auth/presentation/login_screen.dart';
import 'package:rshd/features/auth/presentation/widgets/auth_mode_tabs.dart';
import 'package:rshd/features/auth/presentation/widgets/auth_primary_button.dart';
import 'package:rshd/core/network/api_exception.dart';
import 'package:rshd/core/theme/app_colors.dart';
import 'package:rshd/features/auth/presentation/widgets/auth_form_parts.dart';
import 'package:rshd/features/auth/presentation/widgets/register_form.dart';
import 'package:rshd/features/auth/presentation/widgets/sign_in_form.dart';
import 'package:rshd/core/platform/platform_settings.dart';
import 'package:rshd/core/platform/platform_settings_controller.dart';
import 'package:rshd/core/storage/secure_storage_service.dart';

/// Repository that records calls instead of reaching the network, so the
/// register/login paths can be exercised without creating real accounts.
/// Fails every login with a server-style message, so the error banner renders
/// exactly as it does when the backend is unreachable.
class _FailingAuthRepository implements AuthRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<LoginOutcome> login({
    required String email,
    required String password,
  }) async {
    throw ApiException(
      message: 'لا يوجد اتصال بالسيرفر. تحقق من الاتصال وحاول مرة أخرى.',
      statusCode: 503,
    );
  }
}

class _RecordingAuthRepository implements AuthRepository {
  final List<String> calls = [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<LoginOutcome> login({
    required String email,
    required String password,
  }) async {
    calls.add('login:$email');
    throw UnimplementedError('not exercised');
  }
}

/// Secure storage stub: no remembered email, no platform channels.
class _EmptySecureStorage implements SecureStorageService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<String?> getToken() async => null;

  @override
  Future<String?> getRememberedEmail() async => null;

  @override
  Future<void> saveRememberMe({required bool enabled, String? email}) async {}
}

/// Serves local defaults so the widget tests never hit the network.
class _FakePlatformSettings extends PlatformSettingsController {
  @override
  Future<PlatformSettings> build() async => PlatformSettings.fallback;
}

Widget _harness({
  AuthTab initialTab = AuthTab.signIn,
  String locale = appLocaleArabic,
  Brightness brightness = Brightness.light,
  AuthRepository? repository,
}) {
  final router = GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(
        path: '/login',
        builder: (_, _) => LoginScreen(initialTab: initialTab),
      ),
      GoRoute(path: '/home', builder: (_, _) => const Text('home-page')),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (_, _) => const Text('forgot-page'),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(
        repository ?? _RecordingAuthRepository(),
      ),
      secureStorageProvider.overrideWithValue(_EmptySecureStorage()),
      platformSettingsProvider.overrideWith(_FakePlatformSettings.new),
    ],
    child: Directionality(
      textDirection: locale == appLocaleEnglish
          ? TextDirection.ltr
          : TextDirection.rtl,
      child: AppStringsScope(
        strings: AppStrings(locale),
        child: MaterialApp.router(
          theme: ThemeData(brightness: brightness),
          routerConfig: router,
        ),
      ),
    ),
  );
}

/// Sizes the surface, pumps the screen and settles its entrance animation.
Future<void> _pumpAuth(
  WidgetTester tester, {
  AuthTab initialTab = AuthTab.signIn,
  String locale = appLocaleArabic,
  Brightness brightness = Brightness.light,
  Size size = const Size(400, 900),
  double keyboardInset = 0,
  AuthRepository? repository,
}) async {
  _useSurface(tester, size, keyboardInset: keyboardInset);
  await tester.pumpWidget(
    _harness(
      initialTab: initialTab,
      locale: locale,
      brightness: brightness,
      repository: repository,
    ),
  );
  await tester.pumpAndSettle();
}

/// Tall enough that both forms fit without driving the panel's inner scroll,
/// so validator assertions are about the rules rather than about scrolling.
const _tallPhone = Size(400, 1500);

/// Resizes the actual render surface, not just [MediaQuery].
///
/// The page no longer scrolls, so anything laid out past the default 800x600
/// test surface would be unreachable by `tap()` even though the widget exists.
void _useSurface(WidgetTester tester, Size size, {double keyboardInset = 0}) {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = size;
  tester.view.viewInsets = FakeViewPadding(bottom: keyboardInset);
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('auth screen opens on the sign-in form', (tester) async {
    await _pumpAuth(tester);

    expect(find.byType(SignInForm), findsOneWidget);
    expect(find.byType(RegisterForm), findsNothing);
  });

  testWidgets('tapping create-account swaps the form without navigating', (
    tester,
  ) async {
    await _pumpAuth(tester);

    final router = GoRouter.of(tester.element(find.byType(LoginScreen)));
    final locationBefore = router.routerDelegate.currentConfiguration.uri
        .toString();

    await tester.tap(find.text('إنشاء حساب').first);
    await tester.pumpAndSettle();

    expect(find.byType(RegisterForm), findsOneWidget);
    expect(find.byType(SignInForm), findsNothing);

    // The whole point of the merge: still the same route, same screen.
    expect(
      router.routerDelegate.currentConfiguration.uri.toString(),
      locationBefore,
    );
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('switching back restores the sign-in fields', (tester) async {
    await _pumpAuth(tester);

    await tester.tap(find.text('إنشاء حساب').first);
    await tester.pumpAndSettle();
    expect(find.byType(RegisterForm), findsOneWidget);

    await tester.tap(find.text('تسجيل الدخول').first);
    await tester.pumpAndSettle();

    expect(find.byType(SignInForm), findsOneWidget);
    expect(find.text('تذكرني'), findsOneWidget);
    expect(find.text('نسيت كلمة المرور؟'), findsOneWidget);
  });

  testWidgets('register tab can be preselected for /register deep links', (
    tester,
  ) async {
    await _pumpAuth(tester, initialTab: AuthTab.register);

    expect(find.byType(RegisterForm), findsOneWidget);
    expect(find.byType(SignInForm), findsNothing);
  });

  testWidgets('register form keeps every required field and validator', (
    tester,
  ) async {
    await _pumpAuth(tester, initialTab: AuthTab.register, size: _tallPhone);

    // Submitting empty must surface the original validators, not navigate.
    // The register form is tall, so bring the button into view before tapping.
    final submit = find.byType(AuthPrimaryButton);
    await tester.ensureVisible(submit);
    await tester.pumpAndSettle();
    await tester.tap(submit);
    await tester.pumpAndSettle();
    // Let the button's failure-shake timer expire before the test ends.
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('الاسم مطلوب'), findsOneWidget);
    expect(find.text('البريد الإلكتروني مطلوب'), findsOneWidget);
    expect(find.text('كلمة المرور 8 أحرف على الأقل'), findsOneWidget);
    expect(find.byType(RegisterForm), findsOneWidget);
  });

  testWidgets('phone number is mandatory on the register form', (tester) async {
    await _pumpAuth(tester, initialTab: AuthTab.register);

    final submit = find.byType(AuthPrimaryButton);
    await tester.ensureVisible(submit);
    await tester.pumpAndSettle();
    await tester.tap(submit);
    await tester.pumpAndSettle();
    // Let the button's failure-shake timer expire before the test ends.
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('رقم الهاتف مطلوب'), findsOneWidget);
  });

  testWidgets('date of birth is mandatory on the register form', (
    tester,
  ) async {
    await _pumpAuth(tester, initialTab: AuthTab.register, size: _tallPhone);

    final submit = find.byType(AuthPrimaryButton);
    await tester.ensureVisible(submit);
    await tester.pumpAndSettle();
    await tester.tap(submit);
    await tester.pumpAndSettle();
    // Let the button's failure-shake timer expire before the test ends.
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('تاريخ الميلاد مطلوب'), findsOneWidget);
  });

  testWidgets('register form no longer offers Google or Apple sign-in', (
    tester,
  ) async {
    await _pumpAuth(tester);

    expect(find.textContaining('Google'), findsNothing);
    expect(find.textContaining('Apple'), findsNothing);
    expect(find.text('أو'), findsNothing);
    expect(find.textContaining('ليس لديك حساب'), findsNothing);
  });

  testWidgets('sign-in validation errors do not leak into the register form', (
    tester,
  ) async {
    await _pumpAuth(tester, size: _tallPhone);

    final signInSubmit = find.byType(AuthPrimaryButton);
    await tester.ensureVisible(signInSubmit);
    await tester.pumpAndSettle();
    await tester.tap(signInSubmit);
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('البريد الإلكتروني مطلوب'), findsOneWidget);

    await tester.tap(find.text('إنشاء حساب').first);
    await tester.pumpAndSettle();

    // A fresh register form: no inherited validation messages.
    expect(find.text('كلمة المرور مطلوبة'), findsNothing);
    expect(find.text('الاسم مطلوب'), findsNothing);
  });

  testWidgets('password visibility toggle flips obscuring', (tester) async {
    await _pumpAuth(tester);

    EditableText passwordField() =>
        tester.widget<EditableText>(find.byType(EditableText).last);

    expect(passwordField().obscureText, isTrue);

    final eye = find.byIcon(Icons.visibility_off_outlined).first;
    await tester.ensureVisible(eye);
    await tester.pumpAndSettle();
    await tester.tap(eye);
    await tester.pumpAndSettle();

    expect(passwordField().obscureText, isFalse);
  });

  testWidgets('renders without overflow in English and in dark mode', (
    tester,
  ) async {
    for (final locale in [appLocaleArabic, appLocaleEnglish]) {
      for (final brightness in [Brightness.light, Brightness.dark]) {
        for (final tab in AuthTab.values) {
          await _pumpAuth(
            tester,
            initialTab: tab,
            locale: locale,
            brightness: brightness,
          );

          expect(
            tester.takeException(),
            isNull,
            reason: 'overflow in $locale/$brightness/$tab',
          );
        }
      }
    }
  });

  testWidgets('hero logo does not move when the keyboard opens', (
    tester,
  ) async {
    await _pumpAuth(tester);

    final logo = find.byType(Image).first;
    final before = tester.getRect(logo);

    // Same screen, keyboard up: the band, the logo and the headline must be
    // pinned — the keyboard is absorbed by scrolling, not by resizing.
    await _pumpAuth(tester, keyboardInset: 336);

    expect(tester.getRect(find.byType(Image).first), before);
  });

  testWidgets('hero logo does not move when switching tabs', (tester) async {
    await _pumpAuth(tester);

    final before = tester.getRect(find.byType(Image).first);

    await tester.tap(find.text('إنشاء حساب').first);
    await tester.pumpAndSettle();

    expect(tester.getRect(find.byType(Image).first), before);
  });

  testWidgets('field geometry is unchanged by focus', (tester) async {
    await _pumpAuth(tester);

    final emailField = find.byType(EditableText).first;
    final before = tester.getRect(emailField);

    await tester.tap(emailField);
    await tester.pumpAndSettle();

    final after = tester.getRect(find.byType(EditableText).first);

    // Focusing may scroll the field above the keyboard — that is wanted — but
    // it must not reflow the tile: same width, same horizontal edges, same
    // height. A border that thickened on focus used to shift both by 0.5pt.
    expect(after.size, before.size);
    expect(after.left, before.left);
    expect(after.right, before.right);
  });

  testWidgets('rejected sign-in turns the button red, then recovers', (
    tester,
  ) async {
    await _pumpAuth(tester);

    AuthButtonState buttonState() =>
        tester.widget<AuthPrimaryButton>(find.byType(AuthPrimaryButton)).state;

    expect(buttonState(), AuthButtonState.idle);

    // Empty form: validation rejects it, so the button must flash failure.
    final submit = find.byType(AuthPrimaryButton);
    await tester.ensureVisible(submit);
    await tester.pumpAndSettle();
    await tester.tap(submit);
    await tester.pump();

    expect(buttonState(), AuthButtonState.failure);

    // ...and settle back on its own, so the form stays usable.
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(buttonState(), AuthButtonState.idle);
  });

  testWidgets('failure state paints the pill with the error colour', (
    tester,
  ) async {
    await _pumpAuth(tester);

    final submit = find.byType(AuthPrimaryButton);
    await tester.ensureVisible(submit);
    await tester.pumpAndSettle();
    await tester.tap(submit);
    await tester.pumpAndSettle();

    final pill = tester
        .widgetList<AnimatedContainer>(
          find.descendant(
            of: find.byType(AuthPrimaryButton),
            matching: find.byType(AnimatedContainer),
          ),
        )
        .first;
    final decoration = pill.decoration! as BoxDecoration;

    expect(decoration.color, AppColors.light.error);

    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('submit button stays fully visible when an error banner shows', (
    tester,
  ) async {
    await _pumpAuth(tester, repository: _FailingAuthRepository());

    await tester.enterText(
      find.byType(EditableText).first,
      'student@rshd.test',
    );
    await tester.enterText(find.byType(EditableText).last, 'password123');
    await tester.pumpAndSettle();

    await tester.tap(find.byType(AuthPrimaryButton));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    // The banner must actually be showing, otherwise this proves nothing.
    expect(find.byType(AuthErrorBanner), findsOneWidget);

    // The glass panel clips its contents, so the button has to fit inside the
    // panel's own box — comparing against the screen would pass even when the
    // panel cuts the button in half, which is the bug this guards.
    final glass = tester.getRect(find.byType(BackdropFilter));
    final button = tester.getRect(find.byType(AuthPrimaryButton));

    expect(
      button.bottom,
      lessThanOrEqualTo(glass.bottom),
      reason: 'submit button is clipped by the glass panel',
    );
    expect(button.top, greaterThanOrEqualTo(glass.top));
    expect(button.height, greaterThanOrEqualTo(56));
  });

  testWidgets('greeting sits inside the panel and follows the tab', (
    tester,
  ) async {
    await _pumpAuth(tester);

    final glass = find.byType(BackdropFilter);
    Finder inPanel(String text) => find.descendant(
      of: glass,
      matching: find.textContaining(text, findRichText: true),
    );

    expect(inPanel('بعودتك'), findsOneWidget);
    expect(inPanel('مرحباً بك في'), findsNothing);

    await tester.tap(find.text('إنشاء حساب').first);
    await tester.pumpAndSettle();

    expect(inPanel('بعودتك'), findsNothing);
    expect(inPanel('مرحباً بك في'), findsOneWidget);
    expect(inPanel('أنشئ حسابك'), findsOneWidget);
  });

  testWidgets('register card opens to full height with nothing scrolled', (
    tester,
  ) async {
    // iPhone 17 Pro Max logical size, with its safe-area insets.
    tester.view.padding = const FakeViewPadding(top: 59, bottom: 34);
    await _pumpAuth(
      tester,
      initialTab: AuthTab.register,
      size: const Size(440, 956),
    );

    // The panel's own scroll view has nothing left to scroll: every field and
    // the submit button are on screen at once.
    final inner = tester.state<ScrollableState>(
      find
          .descendant(
            of: find.byType(BackdropFilter),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(inner.position.maxScrollExtent, 0);

    final glass = tester.getRect(find.byType(BackdropFilter));
    final button = tester.getRect(find.byType(AuthPrimaryButton));
    expect(button.bottom, lessThanOrEqualTo(glass.bottom));
    expect(glass.top, greaterThanOrEqualTo(0));
  });

  testWidgets('compact phone height still lays out both forms', (tester) async {
    for (final tab in AuthTab.values) {
      await _pumpAuth(tester, initialTab: tab, size: const Size(320, 568));
      expect(tester.takeException(), isNull, reason: 'overflow on small phone');
    }
  });
}
