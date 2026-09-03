import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rshd/core/platform/platform_settings.dart';
import 'package:rshd/core/platform/platform_settings_controller.dart';
import 'package:rshd/core/router/app_router.dart';
import 'package:rshd/core/startup/startup_route_resolver.dart';
import 'package:rshd/features/auth/presentation/auth_controller.dart';

void main() {
  group('ResolvedPlatformSettings', () {
    test('error async value falls back without throwing', () {
      final value = AsyncValue<PlatformSettings>.error(
        Exception('offline'),
        StackTrace.empty,
      );

      expect(() => value.resolved, returnsNormally);
      expect(
        value.resolved.platformName,
        PlatformSettings.fallback.platformName,
      );
      expect(value.resolved.maintenanceMode, isFalse);
    });

    test('loading async value falls back without throwing', () {
      const value = AsyncValue<PlatformSettings>.loading();

      expect(value.resolved, PlatformSettings.fallback);
    });

    test('data async value keeps loaded settings', () {
      final settings = PlatformSettings(
        platformName: 'Staging',
        maintenanceMode: true,
        maintenanceMessage: 'Down',
        studentRegistrationEnabled: false,
        paymentInstructions: '',
        assignmentMaxFileSizeMb: 10,
        assignmentAllowedFileTypes: const ['pdf'],
        currencySymbol: 'د.أ',
        contact: PlatformSettings.fallback.contact,
      );

      expect(AsyncValue.data(settings).resolved, settings);
    });
  });

  group('offline splash destination', () {
    test('unauthenticated user still leaves splash when settings fail', () {
      final route = resolveStartupRoute(
        authState: const AuthState(status: AuthStatus.unauthenticated),
        platformSettings: AsyncValue<PlatformSettings>.error(
          Exception('offline'),
          StackTrace.empty,
        ).resolved,
      );

      expect(route, AppRoutes.onboarding);
    });
  });
}
