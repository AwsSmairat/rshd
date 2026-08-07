import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/models/video_model.dart';
import '../services/video_progress_tracker.dart';
import '../widgets/rshd_video_player.dart';
import 'subjects_controller.dart';

/// Secure playback via temporary signed URLs from backend.
class VideoDetailsScreen extends ConsumerStatefulWidget {
  const VideoDetailsScreen({
    super.key,
    required this.videoId,
  });

  final int videoId;

  @override
  ConsumerState<VideoDetailsScreen> createState() => _VideoDetailsScreenState();
}

class _VideoDetailsScreenState extends ConsumerState<VideoDetailsScreen> {
  VideoProgressTracker? _progressTracker;
  int? _trackerVideoId;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(videoDetailsControllerProvider(widget.videoId).notifier)
          .load(widget.videoId);
    });
  }

  @override
  void dispose() {
    _progressTracker?.dispose();
    super.dispose();
  }

  void _handleUnauthorized(String? message) {
    if (message != null && message.contains('انتهت الجلسة') && mounted) {
      ref.read(authControllerProvider.notifier).logout();
      context.go(AppRoutes.login);
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _ensureProgressTracker(VideoModel video) {
    if (_trackerVideoId == video.id && _progressTracker != null) {
      return;
    }

    _progressTracker?.dispose();
    _trackerVideoId = video.id;

    final durationSeconds = video.durationSeconds > 0 ? video.durationSeconds : 1;

    _progressTracker = VideoProgressTracker(
      durationSeconds: durationSeconds,
      onSync: ({
        required int currentPositionSeconds,
        required int durationSeconds,
        bool showSuccessMessage = false,
      }) {
        return ref
            .read(videoDetailsControllerProvider(widget.videoId).notifier)
            .syncProgress(
              videoId: widget.videoId,
              currentPositionSeconds: currentPositionSeconds,
              durationSeconds: durationSeconds,
              showSuccessMessage: showSuccessMessage,
            );
      },
    );
  }

  void _onPositionChanged(Duration position) {
    _progressTracker?.updatePosition(position, isPlaying: _isPlaying);
    if (mounted) {
      setState(() {});
    }
  }

  void _onPlaybackStateChanged(bool isPlaying) {
    _isPlaying = isPlaying;
    final seconds = _progressTracker?.currentPositionSeconds ?? 0;
    _progressTracker?.updatePosition(
      Duration(seconds: seconds),
      isPlaying: isPlaying,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(videoDetailsControllerProvider(widget.videoId));

    ref.listen(videoDetailsControllerProvider(widget.videoId), (prev, next) {
      _handleUnauthorized(next.errorMessage);

      if (next.progressMessage != null &&
          next.progressMessage != prev?.progressMessage) {
        _showSnackBar(next.progressMessage!);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(state.video?.title ?? 'تفاصيل الفيديو'),
      ),
      body: _buildBody(state),
    );
  }

  Widget _buildBody(VideoDetailsState state) {
    switch (state.status) {
      case FeatureLoadStatus.initial:
      case FeatureLoadStatus.loading:
        return const LoadingWidget(message: 'جاري تحميل الفيديو...');
      case FeatureLoadStatus.error:
        return ErrorView(
          message: state.errorMessage ?? 'تعذر تحميل الفيديو',
          onRetry: () => ref
              .read(videoDetailsControllerProvider(widget.videoId).notifier)
              .load(widget.videoId),
        );
      case FeatureLoadStatus.empty:
      case FeatureLoadStatus.loaded:
        final video = state.video;
        if (video == null) {
          return const ErrorView(message: 'المحتوى غير موجود');
        }

        _ensureProgressTracker(video);

        final savedProgress = video.progress;
        final livePercentage = _progressTracker?.completionPercentage ??
            savedProgress?.completionPercentage ??
            0;
        final livePosition = _progressTracker?.currentPositionSeconds ??
            savedProgress?.currentPosition ??
            0;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildPlayerSection(video),
            const SizedBox(height: 16),
            Text(video.title, style: AppTextStyles.title),
            const SizedBox(height: 12),
            _InfoRow(label: 'المدة', value: video.formattedDuration),
            _InfoRow(label: 'الحالة', value: video.statusLabel),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'تقدم المشاهدة',
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'النسبة: $livePercentage%',
                    style: AppTextStyles.body,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    livePosition > 0
                        ? 'الموضع الحالي: $livePosition ثانية'
                        : 'لا يوجد تقدم محفوظ بعد',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
    }
  }

  Widget _buildPlayerSection(VideoModel video) {
    final playback = video.playback;
    final playbackUrl = playback?.url.trim() ?? '';

    if (playbackUrl.isEmpty) {
      return _MessageBox(
        message: video.isLocked
            ? 'هذا الفيديو مقفل. يرجى تفعيل المادة للمشاهدة.'
            : 'رابط التشغيل غير متوفر حالياً',
      );
    }

    if (video.status != 'ready') {
      return _MessageBox(message: 'الفيديو غير جاهز للمشاهدة حالياً');
    }

    final savedPosition = video.progress?.currentPosition ?? 0;

    return RshdVideoPlayer(
      playbackUrl: playbackUrl,
      expiresAt: playback?.expiresAt,
      initialPositionSeconds: savedPosition,
      onPositionChanged: _onPositionChanged,
      onPlaybackStateChanged: _onPlaybackStateChanged,
      onRefreshPlayback: () => ref
          .read(videoDetailsControllerProvider(widget.videoId).notifier)
          .refreshPlayback(widget.videoId),
    );
  }
}

class _MessageBox extends StatelessWidget {
  const _MessageBox({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      alignment: Alignment.center,
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: AppTextStyles.body.copyWith(color: AppColors.textMuted),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: AppTextStyles.body.copyWith(
              color: AppColors.textMuted,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.body,
            ),
          ),
        ],
      ),
    );
  }
}
