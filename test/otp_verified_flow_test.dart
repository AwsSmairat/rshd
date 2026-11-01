import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:rshd/core/l10n/app_locale_controller.dart';
import 'package:rshd/core/l10n/app_strings.dart';
import 'package:rshd/core/network/api_client.dart';
import 'package:rshd/core/network/api_exception.dart';
import 'package:rshd/core/platform/platform_settings.dart';
import 'package:rshd/core/platform/platform_settings_controller.dart';
import 'package:rshd/core/router/app_router.dart';
import 'package:rshd/core/storage/secure_storage_service.dart';
import 'package:rshd/features/auth/data/auth_repository.dart';
import 'package:rshd/features/auth/data/models/user_model.dart';
import 'package:rshd/features/auth/presentation/verify_email_screen.dart';
import 'package:rshd/features/auth/presentation/widgets/otp_input_row.dart';

/// The one code the fake backend accepts.
const _correctCode = '482913';
const _email = 'student-pending@staging.rshd.test';

/// Mimics the real endpoint: the right code returns a session, anything else
/// is rejected the way Laravel rejects it.
class _CodeCheckingRepository implements AuthRepository {
  int verifyCalls = 0;
  String? lastCode;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<AuthSession> verifyEmail({
    required String email,
    required String code,
  }) async {
    verifyCalls++;
    lastCode = code;

    if (code != _correctCode) {
      throw ApiException(
        message: 'رمز التحقق غير صحيح.',
        statusCode: 422,
        errors: const {
          'code': ['رمز التحقق غير صحيح.'],
        },
      );
    }

    return const AuthSession(
      token: 'test-token',
      user: UserModel(
        id: 5,
        name: 'Pending Student',
        email: _email,
        role: 'student',
        status: 'active',
        isEmailVerified: true,
      ),
    );
  }
}

class _EmptySecureStorage implements SecureStorageService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<String?> getToken() async => null;

  @override
  Future<void> saveToken(String token) async {}
}

class _FakePlatformSettings extends PlatformSettingsController {
  @override
  Future<PlatformSettings> build() async => PlatformSettings.fallback;
}

Future<void> _pumpVerifyScreen(
  WidgetTester tester,
  _CodeCheckingRepository repository,
) async {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = const Size(420, 1000);
  addTearDown(tester.view.reset);

  final router = GoRouter(
    initialLocation: '/verify',
    routes: [
      GoRoute(
        path: '/verify',
        builder: (_, _) => const VerifyEmailScreen(email: _email),
      ),
      GoRoute(path: AppRoutes.home, builder: (_, _) => const Text('home-page')),
      GoRoute(
        path: AppRoutes.login,
        builder: (_, _) => const Text('login-page'),
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(repository),
        secureStorageProvider.overrideWithValue(_EmptySecureStorage()),
        platformSettingsProvider.overrideWith(_FakePlatformSettings.new),
      ],
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

/// Types one digit per cell, exactly as a person would.
Future<void> _enterCode(WidgetTester tester, String code) async {
  final cells = find.byType(TextField);
  for (var i = 0; i < code.length; i++) {
    await tester.enterText(cells.at(i), code[i]);
    await tester.pump();
  }
}

void main() {
  testWidgets('a correct code turns all six cells green with a check', (
    tester,
  ) async {
    final repository = _CodeCheckingRepository();
    await _pumpVerifyScreen(tester, repository);

    // Scoped to the row: the success button grows a check of its own, which
    // would otherwise be counted here.
    final cellChecks = find.descendant(
      of: find.byType(OtpInputRow),
      matching: find.byIcon(Icons.check_rounded),
    );

    // Before: six editable cells, no checks anywhere.
    expect(find.byType(TextField), findsNWidgets(6));
    expect(cellChecks, findsNothing);

    await _enterCode(tester, _correctCode);
    await tester.pump();

    // The screen really called the backend with what was typed.
    expect(repository.verifyCalls, 1);
    expect(repository.lastCode, _correctCode);

    // Let the success state land, but stop short of the 620ms route change
    // so the verified row is still on screen.
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      cellChecks,
      findsNWidgets(6),
      reason: 'every cell should carry a check once the code is accepted',
    );
    expect(
      find.byType(TextField),
      findsNothing,
      reason: 'verified cells replace the editable ones',
    );

    // And the cells are actually green, not merely checked.
    final cell = tester.widget<Container>(
      find
          .descendant(
            of: find.byType(OtpInputRow),
            matching: find.byType(Container),
          )
          .first,
    );
    final decoration = cell.decoration! as BoxDecoration;
    expect(decoration.border!.top.color, const Color(0xFF17865A));

    // Finally it hands off to the app. The 620ms pause before the route
    // change is a plain Future.delayed, so time has to be advanced for it —
    // pumpAndSettle alone would return first.
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();
    expect(find.text('home-page'), findsOneWidget);
  });

  testWidgets('a wrong code leaves the cells editable and shows the error', (
    tester,
  ) async {
    final repository = _CodeCheckingRepository();
    await _pumpVerifyScreen(tester, repository);

    await _enterCode(tester, '000000');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(repository.lastCode, '000000');
    expect(
      find.descendant(
        of: find.byType(OtpInputRow),
        matching: find.byIcon(Icons.check_rounded),
      ),
      findsNothing,
    );
    expect(find.byType(TextField), findsNWidgets(6));
    expect(find.textContaining('غير صحيح'), findsWidgets);

    // Let the button's failure-shake timer expire before the test ends.
    await tester.pump(const Duration(seconds: 1));
  });
}
