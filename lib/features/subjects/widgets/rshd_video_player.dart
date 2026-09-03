import 'dart:async';

import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../data/models/video_model.dart';
import '../utils/playback_refresh_scheduler.dart';

/// Network video player with Chewie controls and signed URL refresh support.
class RshdVideoPlayer extends StatefulWidget {
  const RshdVideoPlayer({
    super.key,
    required this.playbackUrl,
    this.expiresAt,
    this.initialPositionSeconds = 0,
    this.autoPlay = false,
    this.blockPlayback = false,
    this.existingController,
    this.onControllerReady,
    this.onWillReplaceController,
    this.onPlayerDetached,
    this.onRequestFloating,
    this.onHandoffFloating,
    this.onPositionChanged,
    this.onPlaybackStateChanged,
    this.onRefreshPlayback,
  });

  final String playbackUrl;
  final DateTime? expiresAt;
  final int initialPositionSeconds;
  final bool autoPlay;
  final bool blockPlayback;
  final VideoPlayerController? existingController;
  final ValueChanged<VideoPlayerController>? onControllerReady;
  final VoidCallback? onWillReplaceController;
  final void Function({required bool keepPlaying})? onPlayerDetached;
  final VoidCallback? onRequestFloating;
  final VoidCallback? onHandoffFloating;
  final ValueChanged<Duration>? onPositionChanged;
  final ValueChanged<bool>? onPlaybackStateChanged;
  final Future<VideoPlaybackModel?> Function()? onRefreshPlayback;

  @override
  State<RshdVideoPlayer> createState() => RshdVideoPlayerState();
}

class RshdVideoPlayerState extends State<RshdVideoPlayer> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  Timer? _refreshTimer;
  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _floatOnDispose = false;
  bool _handedOff = false;
  String? _errorMessage;
  String _activePlaybackUrl = '';
  DateTime? _activeExpiresAt;

  static const _playbackErrorMessage =
      'تعذّر تشغيل الفيديو. أعد المحاولة أو حدّث الصفحة.';

  @override
  void initState() {
    super.initState();
    _activePlaybackUrl = widget.playbackUrl;
    _activeExpiresAt = widget.expiresAt;
    final existing = widget.existingController;
    if (existing != null && existing.value.isInitialized) {
      _videoController = existing;
      existing.addListener(_onVideoTick);
      if (widget.autoPlay && !existing.value.isPlaying) {
        unawaited(existing.play());
      }
      unawaited(_attachChewie(existing));
      widget.onControllerReady?.call(existing);
    } else {
      _initializePlayer();
    }
    _scheduleRefreshTimer();
  }

  @override
  void didUpdateWidget(covariant RshdVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.blockPlayback && !oldWidget.blockPlayback) {
      _pauseForProtection();
    }

    if (oldWidget.playbackUrl != widget.playbackUrl &&
        widget.playbackUrl.isNotEmpty &&
        widget.playbackUrl != _activePlaybackUrl) {
      _activePlaybackUrl = widget.playbackUrl;
      _reloadPlayer(preservePosition: true);
    }

    if (oldWidget.expiresAt != widget.expiresAt) {
      _activeExpiresAt = widget.expiresAt;
      _scheduleRefreshTimer();
    }
  }

  Future<void> _initializePlayer() async {
    final uri = Uri.tryParse(_activePlaybackUrl);
    if (uri == null || !uri.hasScheme) {
      _setError(_playbackErrorMessage);
      return;
    }

    final controller = VideoPlayerController.networkUrl(uri);
    _videoController = controller;

    try {
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }

      final resumeSeconds = widget.initialPositionSeconds;
      if (resumeSeconds > 0) {
        await controller.seekTo(Duration(seconds: resumeSeconds));
      }

      controller.addListener(_onVideoTick);
      if (widget.autoPlay && !controller.value.isPlaying) {
        await controller.play();
      }
      await _attachChewie(controller);
      widget.onControllerReady?.call(controller);
    } catch (_) {
      await controller.dispose();
      _videoController = null;

      final refreshed = await _refreshPlaybackAndRetry();
      if (!refreshed) {
        _setError(_playbackErrorMessage);
      }
    }
  }

  Future<void> _attachChewie(VideoPlayerController controller) async {
    if (!mounted) {
      return;
    }

    _chewieController?.dispose();
    _chewieController = ChewieController(
      videoPlayerController: controller,
      autoPlay: widget.autoPlay || controller.value.isPlaying,
      looping: false,
      allowFullScreen: true,
      allowMuting: true,
      allowPlaybackSpeedChanging: true,
      aspectRatio: controller.value.aspectRatio > 0
          ? controller.value.aspectRatio
          : 16 / 9,
      materialProgressColors: ChewieProgressColors(
        playedColor: AppColors.of(context).accent,
        handleColor: AppColors.of(context).accent,
        bufferedColor: AppColors.of(context).textMuted.withValues(alpha: 0.35),
        backgroundColor: AppColors.of(
          context,
        ).textMuted.withValues(alpha: 0.15),
      ),
      errorBuilder: (context, errorMessage) {
        return _buildStatePanel(
          icon: Icons.play_disabled_rounded,
          title: 'تعذّر التشغيل',
          message: _playbackErrorMessage,
          showRetry: true,
        );
      },
    );

    setState(() {
      _isLoading = false;
      _errorMessage = null;
    });
  }

  Future<void> _reloadPlayer({required bool preservePosition}) async {
    final currentPosition = preservePosition
        ? (_videoController?.value.position ?? Duration.zero)
        : Duration.zero;
    final wasPlaying = _videoController?.value.isPlaying ?? false;

    _videoController?.removeListener(_onVideoTick);
    _chewieController?.dispose();
    widget.onWillReplaceController?.call();
    await _videoController?.dispose();
    _chewieController = null;
    _videoController = null;

    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    await _initializePlayer();

    if (!mounted || _videoController == null) {
      return;
    }

    if (currentPosition > Duration.zero) {
      await _videoController!.seekTo(currentPosition);
    }

    if (wasPlaying) {
      await _videoController!.play();
    }
  }

  Future<bool> _refreshPlaybackAndRetry() async {
    if (_isRefreshing || widget.onRefreshPlayback == null) {
      return false;
    }

    _isRefreshing = true;

    try {
      final refreshedPlayback = await widget.onRefreshPlayback!.call();
      final refreshedUrl = refreshedPlayback?.url ?? '';
      if (refreshedUrl.trim().isEmpty) {
        return false;
      }

      _activePlaybackUrl = refreshedUrl;
      _activeExpiresAt = refreshedPlayback?.expiresAt ?? widget.expiresAt;
      await _reloadPlayer(preservePosition: true);
      _scheduleRefreshTimer();
      return true;
    } finally {
      _isRefreshing = false;
    }
  }

  Future<void> _retryPlayback() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final refreshed = await _refreshPlaybackAndRetry();
    if (!refreshed && mounted) {
      await _reloadPlayer(preservePosition: false);
    }
  }

  void _scheduleRefreshTimer() {
    _refreshTimer?.cancel();

    final expiry = _activeExpiresAt ?? widget.expiresAt;
    if (expiry == null || widget.onRefreshPlayback == null) {
      return;
    }

    final delay = playbackRefreshDelay(expiry);
    if (delay == null) {
      return;
    }

    if (delay == Duration.zero) {
      unawaited(_refreshPlaybackAndRetry());
      return;
    }

    _refreshTimer = Timer(delay, () {
      unawaited(_refreshPlaybackAndRetry());
    });
  }

  void _setError(String message) {
    if (!mounted) {
      return;
    }
    setState(() {
      _isLoading = false;
      _errorMessage = message;
    });
  }

  void _onVideoTick() {
    final controller = _videoController;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    widget.onPositionChanged?.call(controller.value.position);
    widget.onPlaybackStateChanged?.call(controller.value.isPlaying);
  }

  void _pauseForProtection() {
    final controller = _videoController;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }
    if (controller.value.isPlaying) {
      unawaited(controller.pause());
      widget.onPlaybackStateChanged?.call(false);
    }
  }

  /// Hands the playing video to the in-app mini player and leaves this screen.
  Future<bool> startFloating() async {
    if (_handedOff ||
        widget.blockPlayback ||
        widget.onRequestFloating == null) {
      return false;
    }

    final controller = _videoController;
    if (controller == null || !controller.value.isInitialized) {
      return false;
    }

    _floatOnDispose = true;

    final chewie = _chewieController;
    if (chewie != null && chewie.isFullScreen) {
      chewie.exitFullScreen();
      await Future<void>.delayed(const Duration(milliseconds: 350));
    }

    if (!controller.value.isPlaying) {
      await controller.play();
    }

    if (!mounted) {
      return false;
    }

    _chewieController?.dispose();
    _chewieController = null;
    setState(() => _handedOff = true);
    await WidgetsBinding.instance.endOfFrame;

    widget.onHandoffFloating?.call();
    widget.onRequestFloating!();
    return true;
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _videoController?.removeListener(_onVideoTick);
    _chewieController?.dispose();
    _chewieController = null;
    final controller = _videoController;
    final keepPlaying =
        controller != null &&
        controller.value.isInitialized &&
        !widget.blockPlayback &&
        (_handedOff || _floatOnDispose || controller.value.isPlaying);
    _videoController = null;
    widget.onPlayerDetached?.call(keepPlaying: keepPlaying);
    super.dispose();
  }

  Widget _buildStatePanel({
    required IconData icon,
    required String title,
    required String message,
    bool showRetry = false,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact =
            constraints.hasBoundedHeight && constraints.maxHeight < 220;

        return Container(
          width: double.infinity,
          height: constraints.hasBoundedHeight ? constraints.maxHeight : null,
          padding: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: compact ? 10 : 14,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.of(context).cardWhite,
                AppColors.of(context).error.withValues(alpha: 0.06),
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: compact ? 40 : 48,
                height: compact ? 40 : 48,
                decoration: BoxDecoration(
                  color: AppColors.of(context).error.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: compact ? 20 : 24,
                  color: AppColors.of(context).error,
                ),
              ),
              SizedBox(height: compact ? 6 : 8),
              Text(
                title,
                style: AppTextStyles.subtitleOf(context).copyWith(
                  color: AppColors.of(context).primary,
                  fontWeight: FontWeight.w700,
                  fontSize: compact ? 14 : 15,
                ),
              ),
              SizedBox(height: compact ? 4 : 6),
              Text(
                message,
                textAlign: TextAlign.center,
                maxLines: compact ? 2 : 3,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.captionOf(context).copyWith(
                  color: AppColors.of(context).textMuted,
                  height: 1.3,
                  fontSize: compact ? 11 : 12,
                ),
              ),
              if (showRetry) ...[
                SizedBox(height: compact ? 8 : 10),
                OutlinedButton.icon(
                  onPressed: _isRefreshing ? null : _retryPlayback,
                  icon: _isRefreshing
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(Icons.refresh_rounded, size: compact ? 15 : 17),
                  label: Text(
                    _isRefreshing ? 'جاري التحديث...' : 'إعادة المحاولة',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.of(context).secondary,
                    side: BorderSide(
                      color: AppColors.of(
                        context,
                      ).secondary.withValues(alpha: 0.35),
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: compact ? 12 : 16,
                      vertical: compact ? 6 : 8,
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_handedOff) {
      return const ColoredBox(color: Colors.black);
    }

    if (_isLoading) {
      return Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              AppColors.of(context).primary,
              AppColors.of(context).secondaryNavy,
            ],
          ),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.of(context).accent),
            const SizedBox(height: 12),
            Text(
              'جاري تجهيز الفيديو...',
              style: AppTextStyles.bodyOf(
                context,
              ).copyWith(color: AppColors.of(context).white),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null || _chewieController == null) {
      return _buildStatePanel(
        icon: Icons.play_disabled_rounded,
        title: 'تعذّر التشغيل',
        message: _errorMessage ?? _playbackErrorMessage,
        showRetry: true,
      );
    }

    return ColoredBox(
      color: Colors.black,
      child: Chewie(controller: _chewieController!),
    );
  }
}
