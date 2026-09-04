import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/startup/startup_coordinator.dart';
import '../../core/theme/app_colors.dart';
import '../../core/l10n/app_strings.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  static const _letters = ['R', 'S', 'H', 'D'];
  static const _introDuration = Duration(milliseconds: 1200);
  static const _zoomDuration = Duration(milliseconds: 420);
  static const _navigateAtZoomProgress = 0.78;

  late final AnimationController _introController;
  late final AnimationController _zoomController;

  late final List<CurvedAnimation> _letterAnimations;
  late final CurvedAnimation _zoomCurve;

  bool _zoomStarted = false;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(splashAnimationCompletedProvider.notifier).state = false;
      ref
          .read(startupCoordinatorProvider.notifier)
          .ensureAuthBootstrapStarted();
    });

    _introController = AnimationController(
      vsync: this,
      duration: _introDuration,
    );

    _zoomController = AnimationController(vsync: this, duration: _zoomDuration);

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
        ref.read(startupCoordinatorProvider.notifier).markAnimationFinished();
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

  @override
  void dispose() {
    _zoomController.removeListener(_onZoomProgress);
    _introController.dispose();
    _zoomController.dispose();
    super.dispose();
  }

  void _maybeStartZoom() {
    if (_zoomStarted || !mounted || !_introController.isCompleted) {
      return;
    }

    final startup = ref.read(startupCoordinatorProvider);
    if (!startup.startupDecisionReady || startup.destinationRoute == null) {
      return;
    }

    setState(() {
      _zoomStarted = true;
    });
    _zoomController.forward(from: 0);
  }

  void _onZoomProgress() {
    if (!_zoomStarted || _navigated) {
      return;
    }

    if (_zoomController.value >= _navigateAtZoomProgress) {
      _finishSplash();
    }
  }

  void _finishSplash() {
    if (!mounted || _navigated) {
      return;
    }

    final startup = ref.read(startupCoordinatorProvider);
    final route = startup.destinationRoute;
    if (route == null || !startup.animationFinished) {
      return;
    }

    _navigated = true;
    ref
        .read(startupCoordinatorProvider.notifier)
        .markNavigationRequested(route);
    ref.read(splashAnimationCompletedProvider.notifier).state = true;

    context.go(route);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref
            .read(startupCoordinatorProvider.notifier)
            .markDestinationFirstFrame();
      }
    });
  }

  void _tryNavigateWhenReady() {
    if (_navigated) {
      return;
    }

    final startup = ref.read(startupCoordinatorProvider);

    if (!startup.animationFinished) {
      if (_introController.isCompleted) {
        ref.read(startupCoordinatorProvider.notifier).markAnimationFinished();
      } else {
        return;
      }
    }

    if (!startup.startupDecisionReady) {
      return;
    }

    if (_zoomStarted) {
      _finishSplash();
      return;
    }

    _maybeStartZoom();
  }

  Widget _buildLetter(int index) {
    final progress = _letterAnimations[index].value;

    return Opacity(
      opacity: progress,
      child: Transform.translate(
        offset: Offset(0, 14 * (1 - progress)),
        child: Transform.scale(
          scale: 0.85 + 0.15 * progress,
          child: Text(AppStrings.of(context).t(_letters[index]),
            style: TextStyle(
              fontSize: 56,
              fontWeight: FontWeight.w800,
              letterSpacing: 6,
              color: AppColors.of(context).accent,
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
      return Scaffold(
        backgroundColor: AppColors.of(context).background,
        body: SizedBox.shrink(),
      );
    }

    ref.listen(startupCoordinatorProvider, (previous, next) {
      _tryNavigateWhenReady();
    });

    final startup = ref.watch(startupCoordinatorProvider);
    final waitingForAuth =
        _introController.isCompleted && !startup.startupDecisionReady;

    final size = MediaQuery.sizeOf(context);
    final targetScale = (size.longestSide / 55).clamp(12.0, 20.0);

    return Scaffold(
      backgroundColor: AppColors.of(context).primary,
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
          final holdProgress = ((_introController.value - 0.8) / 0.2).clamp(
            0.0,
            1.0,
          );

          return ClipRect(
            child: Stack(
              fit: StackFit.expand,
              children: [
                IgnorePointer(
                  child: Opacity(
                    opacity: appPreviewOpacity,
                    child: ColoredBox(color: AppColors.of(context).background),
                  ),
                ),
                IgnorePointer(
                  child: Opacity(
                    opacity: splashOpacity,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topRight,
                          end: Alignment.bottomLeft,
                          colors: [
                            AppColors.of(context).primary,
                            AppColors.of(context).secondaryNavy,
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
                              child: Text(AppStrings.of(context).t('منصة تعليمية ذكية'),
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
                              child: SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.of(context).accent,
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
