import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/widgets/responsive_content.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/models/video_model.dart';
import '../services/video_progress_tracker.dart';
import '../widgets/rshd_embed_video_player.dart';
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
  Timer? _statusPollTimer;

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
    _statusPollTimer?.cancel();
    _progressTracker?.dispose();
    super.dispose();
  }

  void _syncStatusPolling(VideoModel? video) {
    _statusPollTimer?.cancel();

    if (video == null || !video.isPendingPlayback) {
      return;
    }

    _statusPollTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (!mounted) {
        return;
      }

      ref
          .read(videoDetailsControllerProvider(widget.videoId).notifier)
          .load(widget.videoId);
    });
  }

  Future<void> _reloadVideo() {
    return ref
        .read(videoDetailsControllerProvider(widget.videoId).notifier)
        .load(widget.videoId);
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

    final durationSeconds =
        video.durationSeconds > 0 ? video.durationSeconds : 1;

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
      backgroundColor: AppColors.background,
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
          onRetry: _reloadVideo,
        );
      case FeatureLoadStatus.empty:
      case FeatureLoadStatus.loaded:
        final video = state.video;
        if (video == null) {
          return const ErrorView(message: 'المحتوى غير موجود');
        }

        _ensureProgressTracker(video);
        _syncStatusPolling(video);

        final savedProgress = video.progress;
        final livePercentage = _progressTracker?.completionPercentage ??
            savedProgress?.completionPercentage ??
            0;
        final livePosition = _progressTracker?.currentPositionSeconds ??
            savedProgress?.currentPosition ??
            0;

        return RefreshIndicator(
          color: AppColors.accent,
          backgroundColor: AppColors.cardWhite,
          onRefresh: _reloadVideo,
          edgeOffset: MediaQuery.paddingOf(context).top + kToolbarHeight,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              _VideoDetailsHero(title: video.title),
              ResponsiveSliverContent(
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildPlayerSection(video),
                    const SizedBox(height: 20),
                    _VideoInfoSection(video: video),
                    const SizedBox(height: 16),
                    _ProgressSection(
                      percentage: livePercentage,
                      positionSeconds: livePosition,
                      durationLabel: video.formattedDuration,
                    ),
                    const SizedBox(height: 24),
                  ]),
                ),
              ),
            ],
          ),
        );
    }
  }

  Widget _buildPlayerSection(VideoModel video) {
    final playback = video.playback;
    final playbackUrl = playback?.url.trim() ?? '';
    final showsVideoPlayer =
        playbackUrl.isNotEmpty && video.status == 'ready';
    final content =
        _buildPlayerContent(video, playbackUrl, playback?.expiresAt);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.glassShadow.withValues(alpha: 0.14),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: showsVideoPlayer
            ? AspectRatio(aspectRatio: 16 / 9, child: content)
            : content,
      ),
    );
  }

  Widget _buildPlayerContent(
    VideoModel video,
    String playbackUrl,
    DateTime? expiresAt,
  ) {
    if (playbackUrl.isEmpty) {
      return _PlayerPlaceholder(
        icon: video.isLocked
            ? Icons.lock_outline_rounded
            : Icons.hourglass_top_rounded,
        title: video.isLocked ? 'فيديو مقفل' : _pendingTitle(video.status),
        message: video.isLocked
            ? 'فعّل المادة لمشاهدة هذا الفيديو.'
            : video.pendingPlaybackMessage,
        tone: video.isLocked ? _PlaceholderTone.locked : _PlaceholderTone.pending,
        onRetry: video.isPendingPlayback ? _reloadVideo : null,
      );
    }

    if (video.status != 'ready') {
      return _PlayerPlaceholder(
        icon: Icons.info_outline_rounded,
        title: 'غير جاهز',
        message: 'الفيديو غير جاهز للمشاهدة حالياً.',
        tone: _PlaceholderTone.pending,
        onRetry: _reloadVideo,
      );
    }

    final savedPosition = video.progress?.currentPosition ?? 0;
    final playback = video.playback;

    if (playback?.isEmbed ?? false) {
      return RshdEmbedVideoPlayer(
        playbackUrl: playbackUrl,
        expiresAt: expiresAt,
        onRefreshPlayback: () => ref
            .read(videoDetailsControllerProvider(widget.videoId).notifier)
            .refreshPlayback(widget.videoId),
      );
    }

    return RshdVideoPlayer(
      playbackUrl: playbackUrl,
      expiresAt: expiresAt,
      initialPositionSeconds: savedPosition,
      onPositionChanged: _onPositionChanged,
      onPlaybackStateChanged: _onPlaybackStateChanged,
      onRefreshPlayback: () => ref
          .read(videoDetailsControllerProvider(widget.videoId).notifier)
          .refreshPlayback(widget.videoId),
    );
  }

  String _pendingTitle(String status) {
    return switch (status) {
      'uploading' => 'جاري الرفع',
      'processing' => 'قيد المعالجة',
      'failed' => 'فشل التجهيز',
      _ => 'بانتظار التشغيل',
    };
  }
}

class _VideoDetailsHero extends StatelessWidget {
  const _VideoDetailsHero({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    final barHeight = kToolbarHeight + topInset;

    return SliverAppBar(
      expandedHeight: barHeight,
      collapsedHeight: barHeight,
      toolbarHeight: kToolbarHeight,
      pinned: true,
      stretch: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.white,
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 16,
        ),
      ),
      flexibleSpace: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerRight,
            end: Alignment.centerLeft,
            colors: [
              AppColors.primary,
              AppColors.secondaryNavy,
            ],
          ),
        ),
      ),
    );
  }
}

enum _PlaceholderTone { pending, locked, error }

class _PlayerPlaceholder extends StatelessWidget {
  const _PlayerPlaceholder({
    required this.icon,
    required this.title,
    required this.message,
    required this.tone,
    this.onRetry,
  });

  final IconData icon;
  final String title;
  final String message;
  final _PlaceholderTone tone;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final Color accent = switch (tone) {
      _PlaceholderTone.error => AppColors.error,
      _PlaceholderTone.locked => AppColors.secondary,
      _PlaceholderTone.pending => AppColors.darkGold,
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.cardWhite,
            accent.withValues(alpha: 0.07),
          ],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 24, color: accent),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: AppTextStyles.subtitle.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textMuted,
              height: 1.35,
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('تحديث'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.secondary,
                side: BorderSide(color: AppColors.secondary.withValues(alpha: 0.35)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _VideoInfoSection extends StatelessWidget {
  const _VideoInfoSection({required this.video});

  final VideoModel video;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeading(
            icon: Icons.info_outline_rounded,
            title: 'معلومات الفيديو',
          ),
          const SizedBox(height: 14),
          Text(
            video.title,
            style: AppTextStyles.title.copyWith(
              fontSize: 22,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _StatusChip(label: video.statusLabel, status: video.status),
              _InfoPill(
                icon: Icons.schedule_rounded,
                label: video.formattedDuration,
                caption: 'المدة',
              ),
              if (video.isFree)
                const _InfoPill(
                  icon: Icons.visibility_outlined,
                  label: 'مجاني',
                  caption: 'الوصول',
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProgressSection extends StatelessWidget {
  const _ProgressSection({
    required this.percentage,
    required this.positionSeconds,
    required this.durationLabel,
  });

  final int percentage;
  final int positionSeconds;
  final String durationLabel;

  @override
  Widget build(BuildContext context) {
    final progress = (percentage.clamp(0, 100)) / 100;

    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: _SectionHeading(
                  icon: Icons.auto_graph_rounded,
                  title: 'تقدم المشاهدة',
                ),
              ),
              _ProgressBadge(percentage: percentage),
            ],
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 10,
              value: progress > 0 ? progress : null,
              backgroundColor: AppColors.background,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  positionSeconds > 0
                      ? 'توقفت عند $positionSeconds ثانية'
                      : 'لم تبدأ المشاهدة بعد',
                  style: AppTextStyles.caption,
                ),
              ),
              Text(
                'من $durationLabel',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SurfaceCard extends StatelessWidget {
  const _SurfaceCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.white,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.glassShadow.withValues(alpha: 0.07),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.icon,
    required this.title,
  });

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: AppColors.darkGold),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: AppTextStyles.body.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }
}

class _ProgressBadge extends StatelessWidget {
  const _ProgressBadge({required this.percentage});

  final int percentage;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$percentage%',
        style: AppTextStyles.caption.copyWith(
          color: AppColors.secondary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.status,
  });

  final String label;
  final String status;

  @override
  Widget build(BuildContext context) {
    final Color color = switch (status) {
      'ready' => const Color(0xFF067647),
      'processing' => const Color(0xFFB54708),
      'uploading' => const Color(0xFF175CD3),
      'failed' => AppColors.error,
      _ => AppColors.textMuted,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 7),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({
    required this.icon,
    required this.label,
    required this.caption,
  });

  final IconData icon;
  final String label;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.secondary),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                caption,
                style: AppTextStyles.caption.copyWith(fontSize: 10),
              ),
              Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
