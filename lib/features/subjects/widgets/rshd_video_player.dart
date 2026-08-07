import 'dart:async';

import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Network video player with Chewie controls and signed URL refresh support.
class RshdVideoPlayer extends StatefulWidget {
  const RshdVideoPlayer({
    super.key,
    required this.playbackUrl,
    this.expiresAt,
    this.initialPositionSeconds = 0,
    this.onPositionChanged,
    this.onPlaybackStateChanged,
    this.onRefreshPlayback,
  });

  final String playbackUrl;
  final DateTime? expiresAt;
  final int initialPositionSeconds;
  final ValueChanged<Duration>? onPositionChanged;
  final ValueChanged<bool>? onPlaybackStateChanged;
  final Future<String?> Function()? onRefreshPlayback;

  @override
  State<RshdVideoPlayer> createState() => _RshdVideoPlayerState();
}

class _RshdVideoPlayerState extends State<RshdVideoPlayer> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  Timer? _refreshTimer;
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _errorMessage;
  String _activePlaybackUrl = '';

  @override
  void initState() {
    super.initState();
    _activePlaybackUrl = widget.playbackUrl;
    _initializePlayer();
    _scheduleRefreshTimer();
  }

  @override
  void didUpdateWidget(covariant RshdVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.playbackUrl != widget.playbackUrl &&
        widget.playbackUrl.isNotEmpty &&
        widget.playbackUrl != _activePlaybackUrl) {
      _activePlaybackUrl = widget.playbackUrl;
      _reloadPlayer(preservePosition: true);
    }

    if (oldWidget.expiresAt != widget.expiresAt) {
      _scheduleRefreshTimer();
    }
  }

  Future<void> _initializePlayer() async {
    final uri = Uri.tryParse(_activePlaybackUrl);
    if (uri == null || !uri.hasScheme) {
      _setError('تعذر تشغيل الفيديو، يرجى المحاولة لاحقاً');
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

      _chewieController = ChewieController(
        videoPlayerController: controller,
        autoPlay: false,
        looping: false,
        allowFullScreen: true,
        allowMuting: true,
        allowPlaybackSpeedChanging: true,
        aspectRatio: controller.value.aspectRatio > 0
            ? controller.value.aspectRatio
            : 16 / 9,
        materialProgressColors: ChewieProgressColors(
          playedColor: AppColors.secondary,
          handleColor: AppColors.secondary,
          bufferedColor: AppColors.textMuted.withValues(alpha: 0.35),
          backgroundColor: AppColors.textMuted.withValues(alpha: 0.15),
        ),
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'تعذر تشغيل الفيديو، يرجى المحاولة لاحقاً',
                textAlign: TextAlign.center,
                style: AppTextStyles.body,
              ),
            ),
          );
        },
      );

      setState(() {
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (_) {
      await controller.dispose();
      _videoController = null;

      final refreshed = await _refreshPlaybackAndRetry();
      if (!refreshed) {
        _setError('تعذر تشغيل الفيديو، يرجى المحاولة لاحقاً');
      }
    }
  }

  Future<void> _reloadPlayer({required bool preservePosition}) async {
    final currentPosition = preservePosition
        ? (_videoController?.value.position ?? Duration.zero)
        : Duration.zero;
    final wasPlaying = _videoController?.value.isPlaying ?? false;

    _videoController?.removeListener(_onVideoTick);
    _chewieController?.dispose();
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
      final refreshedUrl = await widget.onRefreshPlayback!.call();
      if (refreshedUrl == null || refreshedUrl.trim().isEmpty) {
        return false;
      }

      _activePlaybackUrl = refreshedUrl;
      await _reloadPlayer(preservePosition: true);
      return true;
    } finally {
      _isRefreshing = false;
    }
  }

  void _scheduleRefreshTimer() {
    _refreshTimer?.cancel();

    final expiry = widget.expiresAt;
    if (expiry == null || widget.onRefreshPlayback == null) {
      return;
    }

    final refreshAt = expiry.subtract(const Duration(seconds: 60));
    final delay = refreshAt.difference(DateTime.now());

    if (delay.isNegative) {
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

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _videoController?.removeListener(_onVideoTick);
    _chewieController?.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        width: double.infinity,
        height: 220,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 12),
            Text(
              'جاري تجهيز الفيديو...',
              style: AppTextStyles.body.copyWith(color: AppColors.textMuted),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null || _chewieController == null) {
      return Container(
        width: double.infinity,
        height: 220,
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        alignment: Alignment.center,
        padding: const EdgeInsets.all(16),
        child: Text(
          _errorMessage ?? 'تعذر تشغيل الفيديو، يرجى المحاولة لاحقاً',
          textAlign: TextAlign.center,
          style: AppTextStyles.body.copyWith(color: AppColors.error),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: AspectRatio(
        aspectRatio: _videoController!.value.aspectRatio > 0
            ? _videoController!.value.aspectRatio
            : 16 / 9,
        child: Chewie(controller: _chewieController!),
      ),
    );
  }
}
