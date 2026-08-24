import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/auth_controller.dart';
import '../network/api_client.dart';
import '../platform/platform_settings.dart';
import '../platform/platform_settings_controller.dart';
import 'startup_route_resolver.dart';
import 'startup_timing.dart';

class StartupCoordinatorState {
  const StartupCoordinatorState({
    this.animationFinished = false,
    this.authBootstrapStarted = false,
    this.navigationRequested = false,
    this.destinationRoute,
  });

  final bool animationFinished;
  final bool authBootstrapStarted;
  final bool navigationRequested;
  final String? destinationRoute;

  bool get startupDecisionReady => destinationRoute != null;

  bool get shouldNavigate =>
      animationFinished && startupDecisionReady && !navigationRequested;

  StartupCoordinatorState copyWith({
    bool? animationFinished,
    bool? authBootstrapStarted,
    bool? navigationRequested,
    String? destinationRoute,
    bool clearDestinationRoute = false,
  }) {
    return StartupCoordinatorState(
      animationFinished: animationFinished ?? this.animationFinished,
      authBootstrapStarted: authBootstrapStarted ?? this.authBootstrapStarted,
      navigationRequested: navigationRequested ?? this.navigationRequested,
      destinationRoute: clearDestinationRoute
          ? null
          : (destinationRoute ?? this.destinationRoute),
    );
  }
}

class StartupCoordinator extends StateNotifier<StartupCoordinatorState> {
  StartupCoordinator(this.ref) : super(const StartupCoordinatorState()) {
    ref.listen(authControllerProvider, (_, next) {
      _updateDestinationFromAuth(next);
    });
    ref.listen(platformSettingsProvider, (_, next) {
      _updateDestinationFromAuth(ref.read(authControllerProvider));
    });
  }

  final Ref ref;
  bool _onboardingCompleted = false;

  Future<void> ensureAuthBootstrapStarted() async {
    if (state.authBootstrapStarted) {
      return;
    }

    state = state.copyWith(authBootstrapStarted: true);
    StartupTiming.mark('T5');
    _onboardingCompleted = await _readOnboardingCompleted();
    await ref.read(authControllerProvider.notifier).bootstrap();
    StartupTiming.mark('T6');
    _updateDestinationFromAuth(ref.read(authControllerProvider));
  }

  void markAnimationFinished() {
    if (state.animationFinished) {
      return;
    }
    StartupTiming.mark('T8');
    state = state.copyWith(animationFinished: true);
  }

  void markNavigationRequested(String route) {
    if (state.navigationRequested) {
      return;
    }
    StartupTiming.mark('T9');
    state = state.copyWith(navigationRequested: true, destinationRoute: route);
  }

  void markDestinationFirstFrame() {
    StartupTiming.mark('T11');
  }

  void _updateDestinationFromAuth(AuthState authState) {
    if (!isStartupAuthDecisionReady(authState)) {
      return;
    }

    final settings =
        ref.read(platformSettingsProvider).value ?? PlatformSettings.fallback;
    final route = resolveStartupRoute(
      authState: authState,
      platformSettings: settings,
      onboardingCompleted: _onboardingCompleted,
    );

    if (route == null) {
      return;
    }

    if (state.destinationRoute != route) {
      StartupTiming.mark('T7');
    }

    state = state.copyWith(destinationRoute: route);
  }

  Future<bool> _readOnboardingCompleted() async {
    try {
      return await ref.read(secureStorageProvider).isOnboardingCompleted();
    } catch (_) {
      return false;
    }
  }
}

final startupCoordinatorProvider =
    StateNotifierProvider<StartupCoordinator, StartupCoordinatorState>((ref) {
      return StartupCoordinator(ref);
    });
