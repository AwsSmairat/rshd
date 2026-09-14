import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rshd/core/platform/platform_settings.dart';
import 'package:rshd/core/platform/platform_settings_controller.dart';
import 'package:rshd/core/startup/startup_coordinator.dart';
import 'package:rshd/core/startup/startup_timing.dart';
import 'package:rshd/features/auth/data/auth_repository.dart';
import 'package:rshd/features/auth/data/models/user_model.dart';
import 'package:rshd/features/auth/presentation/auth_controller.dart';
import 'package:rshd/core/device/device_service.dart';
import 'package:rshd/core/network/api_client.dart';
import 'package:rshd/core/network/api_exception.dart';
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

class _BootstrapFailureRepository extends AuthRepository {
  _BootstrapFailureRepository(this.error)
    : super(
        apiClient: ApiClient(secureStorage: SecureStorageService()),
        secureStorage: SecureStorageService(),
        deviceService: DeviceService(secureStorage: SecureStorageService()),
      );

  final Object error;

  int clearLocalSessionCalls = 0;
  int logoutCalls = 0;

  @override
  Future<void> purgeLegacyRememberedPassword() async {}

  @override
  Future<bool> hasToken() async => true;

  @override
  Future<UserModel?> getCachedUser() async => null;

  @override
  Future<UserModel> me() => Future<UserModel>.error(error);

  @override
  Future<void> clearLocalSession() async {
    clearLocalSessionCalls++;
  }

  @override
  Future<void> logout() async {
    logoutCalls++;
  }
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
  test('transient bootstrap API failure preserves local session', () async {
    final repository = _BootstrapFailureRepository(
      ApiException(
        message: 'لا يوجد اتصال بالسيرفر. تحقق من الاتصال وحاول مرة أخرى.',
      ),
    );

    final container = _container(repository);
    addTearDown(container.dispose);

    await container.read(authControllerProvider.notifier).bootstrap();

    final auth = container.read(authControllerProvider);

    expect(auth.status, AuthStatus.unauthenticated);
    expect(auth.errorMessage, contains('اتصال'));
    expect(repository.clearLocalSessionCalls, 0);
    expect(repository.logoutCalls, 0);
  });

  test('server failure during bootstrap preserves local session', () async {
    final repository = _BootstrapFailureRepository(
      ApiException(
        message: 'خطأ في السيرفر. يرجى المحاولة لاحقاً.',
        statusCode: 500,
      ),
    );

    final container = _container(repository);
    addTearDown(container.dispose);

    await container.read(authControllerProvider.notifier).bootstrap();

    expect(
      container.read(authControllerProvider).status,
      AuthStatus.unauthenticated,
    );
    expect(repository.clearLocalSessionCalls, 0);
    expect(repository.logoutCalls, 0);
  });

  test('unauthorized bootstrap response clears local session', () async {
    final repository = _BootstrapFailureRepository(
      ApiException(message: 'غير مصرح. يرجى تسجيل الدخول.', statusCode: 401),
    );

    final container = _container(repository);
    addTearDown(container.dispose);

    await container.read(authControllerProvider.notifier).bootstrap();

    expect(
      container.read(authControllerProvider).status,
      AuthStatus.unauthenticated,
    );
    expect(repository.clearLocalSessionCalls, 1);
    expect(repository.logoutCalls, 0);
  });

  test('forbidden bootstrap response clears local session', () async {
    final repository = _BootstrapFailureRepository(
      ApiException(
        message: 'الحساب غير مسموح له باستخدام التطبيق.',
        statusCode: 403,
      ),
    );

    final container = _container(repository);
    addTearDown(container.dispose);

    await container.read(authControllerProvider.notifier).bootstrap();

    expect(
      container.read(authControllerProvider).status,
      AuthStatus.unauthenticated,
    );
    expect(repository.clearLocalSessionCalls, 1);
    expect(repository.logoutCalls, 0);
  });
}
