import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/security/sensitive_data_redactor.dart';
import '../../../core/security/screen_protection_provider.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/models/video_model.dart';
import '../data/subjects_repository.dart';
import '../services/video_progress_tracker.dart';
import '../utils/playback_refresh_scheduler.dart';

const floatingMiniPlayerWidth = 196.0;

/// Smallest and largest mini player widths the student can pick.
const floatingMiniPlayerMinWidth = 160.0;
const floatingMiniPlayerMaxWidth = 560.0;

Size floatingMiniPlayerSize(
  double videoAspectRatio, {
  double width = floatingMiniPlayerWidth,
}) {
  final ratio = videoAspectRatio > 0 ? videoAspectRatio : 16 / 9;
  return Size(width, width / ratio);
}

/// Keeps a chosen width inside the limits and inside the screen.
double clampFloatingWidth(double width, {required double available}) {
  final maxWidth = available
      .clamp(floatingMiniPlayerMinWidth, floatingMiniPlayerMaxWidth)
      .toDouble();
  return width.clamp(floatingMiniPlayerMinWidth, maxWidth).toDouble();
}

Offset clampFloatingOffset({
  required Offset offset,
  required Size screenSize,
  required Size playerSize,
  required EdgeInsets padding,
}) {
  // Keep clear of the safe area on every side, the bottom home indicator
  // included; a player too big to fit stays pinned to the top-left inset.
  final maxX = screenSize.width - playerSize.width - padding.right;
  final maxY = screenSize.height - playerSize.height - padding.bottom;
  return Offset(
    offset.dx.clamp(padding.left, maxX < padding.left ? padding.left : maxX),
    offset.dy.clamp(padding.top, maxY < padding.top ? padding.top : maxY),
  );
}

Offset defaultFloatingOffset({
  required Size screenSize,
  required Size playerSize,
  required EdgeInsets padding,
}) {
  return clampFloatingOffset(
    offset: Offset(
      padding.left + 12,
      screenSize.height - playerSize.height - padding.bottom - 24,
    ),
    screenSize: screenSize,
    playerSize: playerSize,
    padding: padding,
  );
}

@immutable
class FloatingPlaybackSession {
  const FloatingPlaybackSession({
    required this.videoId,
    required this.title,
    required this.playbackUrl,
    required this.usesEmbed,
    this.expiresAt,
    this.durationSeconds = 0,
    this.minimized = false,
    this.offset = Offset.zero,
  });

  final int videoId;
  final String title;
  final String playbackUrl;
  final bool usesEmbed;
  final DateTime? expiresAt;
  final int durationSeconds;
  final bool minimized;
  final Offset offset;

  FloatingPlaybackSession copyWith({
    String? playbackUrl,
    DateTime? expiresAt,
    bool? minimized,
    Offset? offset,
  }) {
    return FloatingPlaybackSession(
      videoId: videoId,
      title: title,
      playbackUrl: playbackUrl ?? this.playbackUrl,
      usesEmbed: usesEmbed,
      expiresAt: expiresAt ?? this.expiresAt,
      durationSeconds: durationSeconds,
      minimized: minimized ?? this.minimized,
      offset: offset ?? this.offset,
    );
  }
}

class FloatingPlaybackController extends ChangeNotifier {
  FloatingPlaybackController({required SubjectsRepository repository})
    : _repository = repository;

  final SubjectsRepository _repository;
  final GlobalKey embedPlayerKey = GlobalKey();

  FloatingPlaybackSession? _session;
  VideoPlayerController? _nativeController;
  bool _ownsNative = false;
  VideoProgressTracker? _progressTracker;
  Timer? _refreshTimer;
  bool _isRefreshing = false;

  /// Width the student gave the mini player; kept for the next video too.
  double? _miniWidth;
  double? get miniWidth => _miniWidth;

  void updateMiniWidth(double width) {
    if (_miniWidth == width) {
      return;
    }
    _miniWidth = width;
    notifyListeners();
  }

  FloatingPlaybackSession? get session => _session;
  VideoPlayerController? get nativeController => _nativeController;
  bool get isMinimized => _session?.minimized == true;

  VideoPlayerController? controllerFor(int videoId) {
    if (_session?.videoId != videoId || _session?.usesEmbed == true) {
      return null;
    }
    return _nativeController;
  }

  void attachNative({
    required int videoId,
    required String title,
    required String playbackUrl,
    required VideoPlayerController controller,
    DateTime? expiresAt,
    int durationSeconds = 0,
  }) {
    if (_session?.videoId != videoId) {
      _disposeOwnedNative();
      _stopProgressTracking(flush: true);
    }

    _nativeController?.removeListener(_onNativeTick);
    _nativeController = controller;
    _ownsNative = false;
    _session = FloatingPlaybackSession(
      videoId: videoId,
      title: title,
      playbackUrl: playbackUrl,
      usesEmbed: false,
      expiresAt: expiresAt,
      durationSeconds: durationSeconds,
      minimized: false,
      offset: _session?.videoId == videoId ? _session!.offset : Offset.zero,
    );
    _scheduleRefreshTimer();
    notifyListeners();
  }

  void attachEmbed({
    required int videoId,
    required String title,
    required String playbackUrl,
    DateTime? expiresAt,
    int durationSeconds = 0,
    bool minimized = true,
  }) {
    if (_session?.videoId == videoId && _session?.usesEmbed == true) {
      _session = _session!.copyWith(
        playbackUrl: playbackUrl,
        expiresAt: expiresAt,
        minimized: minimized,
      );
      notifyListeners();
      return;
    }

    close();
    _session = FloatingPlaybackSession(
      videoId: videoId,
      title: title,
      playbackUrl: playbackUrl,
      usesEmbed: true,
      expiresAt: expiresAt,
      durationSeconds: durationSeconds,
      minimized: minimized,
    );
    notifyListeners();
  }

  void playerDetached({required bool keepPlaying}) {
    final session = _session;
    if (session == null || session.usesEmbed) {
      return;
    }

    if (session.minimized) {
      _ownsNative = _nativeController != null;
      return;
    }

    if (keepPlaying && _nativeController != null) {
      minimizeNative();
      return;
    }

    _ownsNative = _nativeController != null;
    close();
  }

  /// Shows the in-app mini player while this controller still owns native playback.
  void minimizeNative() {
    final session = _session;
    if (session == null ||
        session.usesEmbed ||
        _nativeController == null ||
        !_nativeController!.value.isInitialized) {
      return;
    }

    _ownsNative = true;
    if (!session.minimized) {
      _session = session.copyWith(minimized: true);
      _bindNativeListener();
      _startProgressTracking();
      notifyListeners();
    }
  }

  void detachNativeWithoutDispose() {
    _nativeController?.removeListener(_onNativeTick);
    _nativeController = null;
    _ownsNative = false;
  }

  void restore() {
    final session = _session;
    if (session == null || !session.minimized) {
      return;
    }

    _stopProgressTracking(flush: true);
    _nativeController?.removeListener(_onNativeTick);
    _ownsNative = false;
    _session = session.copyWith(minimized: false);
    notifyListeners();
  }

  void updateOffset(Offset offset) {
    final session = _session;
    if (session == null) {
      return;
    }
    _session = session.copyWith(offset: offset);
    notifyListeners();
  }

  Future<void> toggleNativePlayPause() async {
    final controller = _nativeController;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }
    if (controller.value.isPlaying) {
      await controller.pause();
    } else {
      await controller.play();
    }
    notifyListeners();
  }

  void pauseForProtection() {
    final controller = _nativeController;
    if (controller != null &&
        controller.value.isInitialized &&
        controller.value.isPlaying) {
      unawaited(controller.pause());
    }
    notifyListeners();
  }

  Future<VideoPlaybackModel?> refreshPlayback() async {
    final session = _session;
    if (session == null || _isRefreshing) {
      return null;
    }

    _isRefreshing = true;
    try {
      final playback = await _repository.refreshVideoPlayback(session.videoId);
      _session = session.copyWith(
        playbackUrl: playback.url,
        expiresAt: playback.expiresAt,
      );
      _scheduleRefreshTimer();
      notifyListeners();
      // While the mini player owns the video it must move onto the new link
      // itself; the old one stops loading once it lapses.
      if (_ownsNative && session.minimized && !session.usesEmbed) {
        await _swapNativeTo(playback.url);
      }
      return playback;
    } on ApiException catch (error) {
      debugPrint(
        'Floating playback refresh failed: ${SensitiveDataRedactor.redactString(error.message)}',
      );
      return null;
    } catch (error) {
      debugPrint(
        'Floating playback refresh failed: ${SensitiveDataRedactor.redactString(error.toString())}',
      );
      return null;
    } finally {
      _isRefreshing = false;
    }
  }

  /// Moves the mini player's video onto [url] without a visible break: the
  /// new player gets ready at the same spot while the old one keeps playing,
  /// then replaces it. The old player is kept if the new link fails to open.
  Future<void> _swapNativeTo(String url) async {
    final old = _nativeController;
    final uri = Uri.tryParse(url.trim());
    if (old == null || !old.value.isInitialized || uri == null) {
      return;
    }
    if (!uri.hasScheme) {
      return;
    }

    final next = VideoPlayerController.networkUrl(uri);
    try {
      await next.initialize();
      await next.seekTo(old.value.position);
    } catch (_) {
      await next.dispose();
      return;
    }
    if (_nativeController != old || !_ownsNative) {
      await next.dispose();
      return;
    }

    final wasPlaying = old.value.isPlaying;
    await old.pause();
    // Catch up with what played while the new player was getting ready.
    await next.seekTo(old.value.position);
    await next.setPlaybackSpeed(old.value.playbackSpeed);
    await next.setVolume(old.value.volume);

    old.removeListener(_onNativeTick);
    _nativeController = next;
    _bindNativeListener();
    if (wasPlaying) {
      await next.play();
    }
    notifyListeners();

    // The old player is off screen after this frame.
    await WidgetsBinding.instance.endOfFrame;
    await old.dispose();
  }

  void close() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
    _stopProgressTracking(flush: true);
    _disposeOwnedNative();
    _nativeController = null;
    _ownsNative = false;
    _session = null;
    notifyListeners();
  }

  void _bindNativeListener() {
    _nativeController?.removeListener(_onNativeTick);
    _nativeController?.addListener(_onNativeTick);
  }

  bool _lastPlaying = false;

  void _onNativeTick() {
    final controller = _nativeController;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }
    // Timers stop while the app is in the background, so the link can lapse
    // unnoticed; the player then fails to load the next part.
    if (controller.value.hasError && _ownsNative && !_isRefreshing) {
      unawaited(refreshPlayback());
      return;
    }
    _progressTracker?.updatePosition(
      controller.value.position,
      isPlaying: controller.value.isPlaying,
    );
    final playing = controller.value.isPlaying;
    if (playing != _lastPlaying) {
      _lastPlaying = playing;
      notifyListeners();
    }
  }

  void _startProgressTracking() {
    final session = _session;
    if (session == null || session.usesEmbed) {
      return;
    }

    _progressTracker?.dispose();
    final durationSeconds = session.durationSeconds > 0
        ? session.durationSeconds
        : 1;
    _progressTracker = VideoProgressTracker(
      durationSeconds: durationSeconds,
      onSync:
          ({
            required int currentPositionSeconds,
            required int durationSeconds,
            bool showSuccessMessage = false,
          }) {
            return _syncProgress(
              videoId: session.videoId,
              currentPositionSeconds: currentPositionSeconds,
              durationSeconds: durationSeconds,
            );
          },
    );

    final position = _nativeController?.value.position ?? Duration.zero;
    _progressTracker?.updatePosition(
      position,
      isPlaying: _nativeController?.value.isPlaying ?? false,
    );
  }

  void _stopProgressTracking({required bool flush}) {
    if (flush) {
      unawaited(_progressTracker?.flush());
    }
    _progressTracker?.dispose();
    _progressTracker = null;
  }

  Future<void> _syncProgress({
    required int videoId,
    required int currentPositionSeconds,
    required int durationSeconds,
  }) async {
    if (currentPositionSeconds <= 0) {
      return;
    }

    final completionPercentage = durationSeconds > 0
        ? ((currentPositionSeconds / durationSeconds) * 100)
              .clamp(0, 100)
              .round()
        : 0;

    try {
      await _repository.updateVideoProgress(
        videoId,
        watchedSeconds: currentPositionSeconds,
        currentPosition: currentPositionSeconds,
        completionPercentage: completionPercentage,
      );
    } catch (error) {
      debugPrint(
        'Floating playback progress failed: ${SensitiveDataRedactor.redactString(error.toString())}',
      );
    }
  }

  void _scheduleRefreshTimer() {
    _refreshTimer?.cancel();
    final expiry = _session?.expiresAt;
    final delay = playbackRefreshDelay(expiry);
    if (delay == null) {
      return;
    }
    if (delay == Duration.zero) {
      unawaited(refreshPlayback());
      return;
    }
    _refreshTimer = Timer(delay, () => unawaited(refreshPlayback()));
  }

  void _disposeOwnedNative() {
    _nativeController?.removeListener(_onNativeTick);
    if (_ownsNative) {
      unawaited(_nativeController?.dispose());
    }
    _nativeController = null;
    _ownsNative = false;
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _progressTracker?.dispose();
    if (_ownsNative) {
      _nativeController?.dispose();
    }
    super.dispose();
  }
}

final floatingPlaybackControllerProvider =
    ChangeNotifierProvider<FloatingPlaybackController>((ref) {
      final controller = FloatingPlaybackController(
        repository: ref.watch(subjectsRepositoryProvider),
      );

      ref.listen<AuthState>(authControllerProvider, (previous, next) {
        if (next.status == AuthStatus.unauthenticated) {
          controller.close();
        }
      });

      ref.listen<bool>(shouldHideProtectedContentProvider, (previous, next) {
        if (next) {
          controller.pauseForProtection();
        }
      });

      ref.onDispose(controller.dispose);
      return controller;
    });
