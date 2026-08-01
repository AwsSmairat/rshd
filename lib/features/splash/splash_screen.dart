import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/platform/platform_settings_controller.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../auth/presentation/auth_controller.dart';
import '../home/home_controller.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  static const _letters = ['R', 'S', 'H', 'D'];

  late final AnimationController _introController;
  late final AnimationController _zoomController;

  late final List<CurvedAnimation> _letterAnimations;
  late final CurvedAnimation _zoomCurve;

  String? _destinationRoute;
  bool _zoomStarted = false;
  bool _navigated = false;
  bool _homePreloadStarted = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(splashAnimationCompletedProvider.notifier).state = false;
      _bootstrapApp();
    });

    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _zoomController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 620),
    );

    _letterAnimations = List.generate(_letters.length, (index) {
      final start = index * 0.2;
      return CurvedAnimation(
        parent: _introController,
        curve: Interval(start, start + 0.2, curve: Curves.easeOutCubic),
      );
    });

    _zoomCurve = CurvedAnimation(
      parent: _zoomController,
      curve: Curves.easeInCubic,
    );

    _introController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _maybeStartZoom();
      }
    });

    _zoomController.addListener(_onZoomProgress);

    _zoomController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _finishSplash();
      }
    });

    _introController.forward();
  }

  void _bootstrapApp() {
    final settingsState = ref.read(platformSettingsProvider);

    void startAuthIfReady() {
      final settings = ref.read(platformSettingsProvider).value;
      if (settings?.maintenanceMode != true) {
        ref.read(authControllerProvider.notifier).bootstrap();
        return;
      }

      if (_introController.isCompleted) {
        _maybeStartZoom();
      }
    }

    if (settingsState.hasValue) {
      startAuthIfReady();
      return;
    }

    ref.read(platformSettingsProvider.future).then((_) {
      if (mounted) {
        startAuthIfReady();
      }
    });
  }

  @override
  void dispose() {
    _zoomController.removeListener(_onZoomProgress);
    _introController.dispose();
    _zoomController.dispose();
    super.dispose();
  }

  String? _resolveDestinationRoute(AuthState authState) {
    final platformSettings = ref.read(platformSettingsProvider).value;
    if (platformSettings?.maintenanceMode == true) {
      return AppRoutes.maintenance;
    }

    switch (authState.status) {
      case AuthStatus.authenticated:
        final user = authState.user;
        if (user != null && !user.isStudent) {
          return AppRoutes.login;
        }
        if (user != null && !user.isEmailVerified) {
          return '${AppRoutes.verifyEmail}?email=${Uri.encodeComponent(user.email)}';
        }
        return AppRoutes.home;
      case AuthStatus.unauthenticated:
      case AuthStatus.error:
        final pendingEmail = authState.pendingVerificationEmail;
        if (pendingEmail != null) {
          return '${AppRoutes.verifyEmail}?email=${Uri.encodeComponent(pendingEmail)}';
        }
        return AppRoutes.login;
      case AuthStatus.initial:
      case AuthStatus.loading:
      case AuthStatus.authenticating:
        return null;
    }
  }

  void _preloadHomeIfNeeded(AuthState authState) {
    final route = _resolveDestinationRoute(authState);
    if (route != AppRoutes.home || _homePreloadStarted) {
      return;
    }

    _homePreloadStarted = true;
    ref.read(homeControllerProvider.notifier).load(
          fallbackStudentName: authState.user?.name,
        );
  }

  void _maybeStartZoom() {
    if (_zoomStarted || !mounted || !_introController.isCompleted) {
      return;
    }

    final platformState = ref.read(platformSettingsProvider);
    if (platformState.isLoading) {
      return;
    }

    final authState = ref.read(authControllerProvider);
    final route = _resolveDestinationRoute(authState);
    if (route == null) {
      return;
    }

    _preloadHomeIfNeeded(authState);

    setState(() {
      _destinationRoute = route;
      _zoomStarted = true;
    });
    _zoomController.forward(from: 0);
  }

  void _onZoomProgress() {
    if (!_zoomStarted || _navigated || _destinationRoute == null) {
      return;
    }

    if (_zoomController.value >= 0.82) {
      _finishSplash();
    }
  }

  void _finishSplash() {
    final route = _destinationRoute;
    if (route == null || !mounted || _navigated) {
      return;
    }

    _navigated = true;
    ref.read(splashAnimationCompletedProvider.notifier).state = true;

    setState(() {});

    context.go(route);
  }

  Widget _buildLetter(int index) {
    final progress = _letterAnimations[index].value;

    return Opacity(
      opacity: progress,
      child: Transform.translate(
        offset: Offset(0, 14 * (1 - progress)),
        child: Transform.scale(
          scale: 0.85 + 0.15 * progress,
          child: Text(
            _letters[index],
            style: const TextStyle(
              fontSize: 56,
              fontWeight: FontWeight.w800,
              letterSpacing: 6,
              color: AppColors.accent,
              shadows: [
                Shadow(
                  color: Color(0x33061526),
                  blurRadius: 18,
                  offset: Offset(0, 6),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_navigated) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: SizedBox.shrink(),
      );
    }

    ref.listen(authControllerProvider, (previous, next) {
      _preloadHomeIfNeeded(next);
      _maybeStartZoom();
    });

    ref.listen(platformSettingsProvider, (previous, next) {
      if (next.hasValue) {
        _maybeStartZoom();
      }
    });

    final size = MediaQuery.sizeOf(context);
    final targetScale = (size.longestSide / 55).clamp(12.0, 20.0);

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: AnimatedBuilder(
        animation: Listenable.merge([_introController, _zoomController]),
        builder: (context, _) {
          final zoom = _zoomCurve.value;
          final scale = 1.0 + (targetScale - 1.0) * zoom;
          final splashOpacity = (1.0 - zoom).clamp(0.0, 1.0);
          final appPreviewOpacity = zoom.clamp(0.0, 1.0);
          final wordOpacity = zoom < 0.55
              ? 1.0
              : (1.0 - (zoom - 0.55) / 0.27).clamp(0.0, 1.0);
          final holdProgress =
              ((_introController.value - 0.8) / 0.2).clamp(0.0, 1.0);
          final waitingForAuth =
              _introController.isCompleted && !_zoomStarted;

          return ClipRect(
            child: Stack(
              fit: StackFit.expand,
              children: [
                IgnorePointer(
                  child: Opacity(
                    opacity: appPreviewOpacity,
                    child: const ColoredBox(color: AppColors.background),
                  ),
                ),
                IgnorePointer(
                  child: Opacity(
                    opacity: splashOpacity,
                    child: DecoratedBox(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topRight,
                          end: Alignment.bottomLeft,
                          colors: [
                            AppColors.primary,
                            AppColors.secondaryNavy,
                            Color(0xFF061526),
                          ],
                        ),
                      ),
                      child: Stack(
                        children: [
                          Align(
                            alignment: const Alignment(0, 0.28),
                            child: Opacity(
                              opacity: holdProgress,
                              child: const Text(
                                'منصة تعليمية ذكية',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xB3F6F1E7),
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ),
                          ),
                          Align(
                            alignment: const Alignment(0, 0.78),
                            child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 250),
                              opacity: waitingForAuth ? 1.0 : 0.0,
                              child: const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.accent,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                IgnorePointer(
                  child: Opacity(
                    opacity: wordOpacity,
                    child: Center(
                      child: Transform.scale(
                        scale: scale,
                        child: Directionality(
                          textDirection: TextDirection.ltr,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: List.generate(
                              _letters.length,
                              _buildLetter,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
