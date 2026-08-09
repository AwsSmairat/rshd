import 'package:flutter_test/flutter_test.dart';
import 'package:rshd/core/platform/platform_settings.dart';
import 'package:rshd/core/router/app_router.dart';
import 'package:rshd/core/startup/startup_route_resolver.dart';
import 'package:rshd/features/auth/data/models/user_model.dart';
import 'package:rshd/features/auth/presentation/auth_controller.dart';

UserModel _student({bool verified = true}) {
  return UserModel(
    id: 1,
    name: 'Student',
    email: 'student@test.com',
    role: 'student',
    status: 'active',
    isEmailVerified: verified,
  );
}

PlatformSettings _maintenanceSettings() {
  return PlatformSettings(
    platformName: 'RSHD',
    maintenanceMode: true,
    maintenanceMessage: 'Maintenance',
    studentRegistrationEnabled: true,
    paymentInstructions: '',
    assignmentMaxFileSizeMb: 10,
    assignmentAllowedFileTypes: const ['pdf'],
    currencySymbol: 'د.أ',
    contact: PlatformSettings.fallback.contact,
  );
}

void main() {
  group('resolveStartupRoute', () {
    test('maintenance mode routes to maintenance', () {
      final route = resolveStartupRoute(
        authState: AuthState(
          status: AuthStatus.authenticated,
          user: _student(),
        ),
        platformSettings: _maintenanceSettings(),
      );

      expect(route, AppRoutes.maintenance);
    });

    test('authenticated student routes to home', () {
      final route = resolveStartupRoute(
        authState: AuthState(
          status: AuthStatus.authenticated,
          user: _student(),
        ),
        platformSettings: PlatformSettings.fallback,
      );

      expect(route, AppRoutes.home);
    });

    test('unverified student routes to verify email', () {
      final route = resolveStartupRoute(
        authState: AuthState(
          status: AuthStatus.authenticated,
          user: _student(verified: false),
        ),
        platformSettings: PlatformSettings.fallback,
      );

      expect(route, startsWith(AppRoutes.verifyEmail));
    });

    test('unauthenticated routes to login', () {
      final route = resolveStartupRoute(
        authState: const AuthState(status: AuthStatus.unauthenticated),
        platformSettings: PlatformSettings.fallback,
      );

      expect(route, AppRoutes.login);
    });

    test('loading auth returns null destination', () {
      final route = resolveStartupRoute(
        authState: const AuthState(status: AuthStatus.loading),
        platformSettings: PlatformSettings.fallback,
      );

      expect(route, isNull);
    });

    test('invalid session routes to login', () {
      final route = resolveStartupRoute(
        authState: const AuthState(status: AuthStatus.unauthenticated),
        platformSettings: PlatformSettings.fallback,
      );

      expect(route, AppRoutes.login);
    });
  });

  group('isStartupAuthDecisionReady', () {
    test('returns false while loading', () {
      expect(
        isStartupAuthDecisionReady(const AuthState(status: AuthStatus.loading)),
        isFalse,
      );
    });

    test('returns true when unauthenticated', () {
      expect(
        isStartupAuthDecisionReady(
          const AuthState(status: AuthStatus.unauthenticated),
        ),
        isTrue,
      );
    });

    test('returns true when authenticated', () {
      expect(
        isStartupAuthDecisionReady(
          AuthState(status: AuthStatus.authenticated, user: _student()),
        ),
        isTrue,
      );
    });
  });
}
