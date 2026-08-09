import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rshd/core/device/device_service.dart';
import 'package:rshd/core/network/api_client.dart';
import 'package:rshd/core/platform/platform_settings.dart';
import 'package:rshd/core/platform/platform_settings_controller.dart';
import 'package:rshd/core/storage/secure_storage_service.dart';
import 'package:rshd/features/auth/data/auth_repository.dart';
import 'package:rshd/features/auth/presentation/auth_controller.dart';
import 'package:rshd/features/splash/splash_screen.dart';

class TestAuthRepository extends AuthRepository {
  TestAuthRepository()
    : super(
        apiClient: ApiClient(secureStorage: SecureStorageService()),
        secureStorage: SecureStorageService(),
        deviceService: DeviceService(secureStorage: SecureStorageService()),
      );

  @override
  Future<void> purgeLegacyRememberedPassword() async {}

  @override
  Future<bool> hasToken() async => false;
}

class TestPlatformSettingsController extends PlatformSettingsController {
  @override
  Future<PlatformSettings> build() async => PlatformSettings.fallback;
}

void main() {
  testWidgets('Splash screen shows animated RSHD letters', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          platformSettingsProvider.overrideWith(
            TestPlatformSettingsController.new,
          ),
          authControllerProvider.overrideWith(
            (ref) => AuthController(TestAuthRepository()),
          ),
        ],
        child: const MaterialApp(home: SplashScreen()),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1250));

    expect(find.text('R'), findsOneWidget);
    expect(find.text('S'), findsOneWidget);
    expect(find.text('H'), findsOneWidget);
    expect(find.text('D'), findsOneWidget);
  });
}
