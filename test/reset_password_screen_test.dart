import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:rshd/core/l10n/app_locale_controller.dart';
import 'package:rshd/core/l10n/app_strings.dart';
import 'package:rshd/core/network/api_client.dart';
import 'package:rshd/core/router/app_router.dart';
import 'package:rshd/core/storage/secure_storage_service.dart';
import 'package:rshd/features/auth/presentation/reset_password_screen.dart';
import 'package:rshd/features/auth/presentation/widgets/auth_input_field.dart';
import 'package:rshd/features/auth/presentation/widgets/auth_page_scaffold.dart';
import 'package:rshd/features/auth/presentation/widgets/auth_primary_button.dart';
import 'package:rshd/features/auth/presentation/widgets/password_strength_indicator.dart';

const _email = 'student-pending@staging.rshd.test';

/// Supplies the reset session the screen guards on, so the form actually
/// renders instead of bouncing back to "forgot password".
class _SessionStorage implements SecureStorageService {
  _SessionStorage({this.session});

  final ({String email, String resetToken})? session;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<({String email, String resetToken})?>
  getPasswordResetSession() async => session;
}

Future<void> _pump(WidgetTester tester, SecureStorageService storage) async {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = const Size(420, 1100);
  addTearDown(tester.view.reset);

  final router = GoRouter(
    initialLocation: '/new',
    routes: [
      GoRoute(
        path: '/new',
        builder: (_, _) => const ResetPasswordScreen(email: _email),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (_, _) => const Text('forgot-page'),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (_, _) => const Text('login-page'),
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [secureStorageProvider.overrideWithValue(storage)],
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: AppStringsScope(
          strings: const AppStrings(appLocaleArabic),
          child: MaterialApp.router(routerConfig: router),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('new-password screen uses the shared auth page design', (
    tester,
  ) async {
    await _pump(
      tester,
      _SessionStorage(session: (email: _email, resetToken: 'tok')),
    );

    // Same shell as the other secondary auth pages.
    expect(find.byType(AuthPageScaffold), findsOneWidget);
    expect(find.text('كلمة مرور جديدة'), findsOneWidget);

    // Both fields are the new shared input, plus the strength meter.
    expect(find.byType(AuthInputField), findsNWidgets(2));
    expect(find.byType(PasswordStrengthIndicator), findsOneWidget);

    // Gold action pill, enabled once the reset token has loaded.
    final button = tester.widget<AuthPrimaryButton>(
      find.byType(AuthPrimaryButton),
    );
    expect(button.variant, AuthButtonVariant.gold);
    expect(button.onPressed, isNotNull);

    expect(find.text('العودة إلى تسجيل الدخول'), findsOneWidget);
  });

  testWidgets('validators still guard a weak or mismatched password', (
    tester,
  ) async {
    await _pump(
      tester,
      _SessionStorage(session: (email: _email, resetToken: 'tok')),
    );

    final fields = find.byType(EditableText);
    await tester.enterText(fields.first, 'short');
    await tester.enterText(fields.last, 'different');
    await tester.pumpAndSettle();

    await tester.tap(find.byType(AuthPrimaryButton));
    await tester.pumpAndSettle();

    expect(
      find.text('يجب أن تكون كلمة المرور 8 أحرف على الأقل'),
      findsOneWidget,
    );
    expect(find.text('كلمتا المرور غير متطابقتين'), findsOneWidget);

    // Let the button's failure-shake timer expire before the test ends.
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('a missing reset session bounces back to forgot password', (
    tester,
  ) async {
    await _pump(tester, _SessionStorage());

    expect(find.text('forgot-page'), findsOneWidget);
    expect(find.byType(AuthPageScaffold), findsNothing);
  });
}
