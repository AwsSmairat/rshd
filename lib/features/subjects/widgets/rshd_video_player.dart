import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Network video player with Chewie controls.
///
/// TODO: Add dynamic watermark with student name and phone.
/// TODO: Add screenshot/recording protection where supported.
class RshdVideoPlayer extends StatefulWidget {
  const RshdVideoPlayer({
    super.key,
    required this.videoUrl,
    this.onPositionChanged,
    this.onPlaybackStateChanged,
  });

  final String videoUrl;
  final ValueChanged<Duration>? onPositionChanged;
  final ValueChanged<bool>? onPlaybackStateChanged;

  @override
  State<RshdVideoPlayer> createState() => _RshdVideoPlayerState();
}

class _RshdVideoPlayerState extends State<RshdVideoPlayer> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    final uri = Uri.tryParse(widget.videoUrl);
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

      setState(() => _isLoading = false);
    } catch (_) {
      await controller.dispose();
      _videoController = null;
      _setError('تعذر تشغيل الفيديو، يرجى المحاولة لاحقاً');
    }
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
