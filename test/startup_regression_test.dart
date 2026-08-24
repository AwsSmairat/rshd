import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rshd/core/platform/platform_settings.dart';
import 'package:rshd/core/platform/platform_settings_controller.dart';
import 'package:rshd/core/startup/startup_coordinator.dart';
import 'package:rshd/core/startup/startup_timing.dart';
import 'package:rshd/features/auth/data/auth_repository.dart';
import 'package:rshd/features/auth/presentation/auth_controller.dart';
import 'package:rshd/core/device/device_service.dart';
import 'package:rshd/core/network/api_client.dart';
import 'package:rshd/core/storage/secure_storage_service.dart';

class _ImmediateUnauthenticatedRepository extends AuthRepository {
  _ImmediateUnauthenticatedRepository()
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

class _TestPlatformSettingsController extends PlatformSettingsController {
  @override
  Future<PlatformSettings> build() async => PlatformSettings.fallback;
}

ProviderContainer _container(AuthRepository repository) {
  return ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(repository),
      platformSettingsProvider.overrideWith(
        _TestPlatformSettingsController.new,
      ),
    ],
  );
}

void main() {
  setUp(StartupTiming.resetForTests);

  test('auth bootstrap starts only once', () async {
    final container = _container(_ImmediateUnauthenticatedRepository());
    addTearDown(container.dispose);

    final coordinator = container.read(startupCoordinatorProvider.notifier);
    await coordinator.ensureAuthBootstrapStarted();
    await coordinator.ensureAuthBootstrapStarted();

    expect(
      container.read(startupCoordinatorProvider).authBootstrapStarted,
      isTrue,
    );
    expect(
      container.read(authControllerProvider).status,
      AuthStatus.unauthenticated,
    );
  });

  test('startup decision becomes ready when auth finishes', () async {
    final container = _container(_ImmediateUnauthenticatedRepository());
    addTearDown(container.dispose);

    await container
        .read(startupCoordinatorProvider.notifier)
        .ensureAuthBootstrapStarted();

    final startup = container.read(startupCoordinatorProvider);
    expect(startup.startupDecisionReady, isTrue);
    expect(startup.destinationRoute, '/onboarding');
  });

  test('animation finished with ready auth enables navigation state', () async {
    final container = _container(_ImmediateUnauthenticatedRepository());
    addTearDown(container.dispose);

    await container
        .read(startupCoordinatorProvider.notifier)
        .ensureAuthBootstrapStarted();
    container.read(startupCoordinatorProvider.notifier).markAnimationFinished();

    final startup = container.read(startupCoordinatorProvider);
    expect(startup.shouldNavigate, isTrue);
  });

  test(
    'auth ready before animation does not mark navigation until animation finishes',
    () async {
      final container = _container(_ImmediateUnauthenticatedRepository());
      addTearDown(container.dispose);

      await container
          .read(startupCoordinatorProvider.notifier)
          .ensureAuthBootstrapStarted();

      expect(
        container.read(startupCoordinatorProvider).shouldNavigate,
        isFalse,
      );

      container
          .read(startupCoordinatorProvider.notifier)
          .markAnimationFinished();

      expect(container.read(startupCoordinatorProvider).shouldNavigate, isTrue);
    },
  );

  test('markNavigationRequested happens once', () async {
    final container = _container(_ImmediateUnauthenticatedRepository());
    addTearDown(container.dispose);

    final coordinator = container.read(startupCoordinatorProvider.notifier);
    await coordinator.ensureAuthBootstrapStarted();
    coordinator.markAnimationFinished();
    coordinator.markNavigationRequested('/login');
    coordinator.markNavigationRequested('/login');

    expect(
      container.read(startupCoordinatorProvider).navigationRequested,
      isTrue,
    );
  });
}
