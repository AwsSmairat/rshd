import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/preferences/app_display_preferences.dart';
import '../../../core/router/app_router.dart';
import '../../../core/security/screen_protection_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/widgets/responsive_content.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/models/video_model.dart';
import '../playback/floating_playback_controller.dart';
import '../services/video_progress_tracker.dart';
import '../widgets/floating_playback_launch_button.dart';
import '../widgets/rshd_embed_video_player.dart';
import '../widgets/rshd_video_player.dart';
import 'subjects_controller.dart';
import '../../../core/l10n/app_strings.dart';

/// Secure playback via temporary signed URLs from backend.
class VideoDetailsScreen extends ConsumerStatefulWidget {
  const VideoDetailsScreen({super.key, required this.videoId});

  final int videoId;

  @override
  ConsumerState<VideoDetailsScreen> createState() => _VideoDetailsScreenState();
}

class _VideoDetailsScreenState extends ConsumerState<VideoDetailsScreen> {
  final GlobalKey<RshdVideoPlayerState> _nativePlayerKey =
      GlobalKey<RshdVideoPlayerState>();
  FloatingPlaybackController? _floatingPlayback;
  VideoProgressTracker? _progressTracker;
  int? _trackerVideoId;
  bool _isPlaying = false;
  Timer? _statusPollTimer;
  VideoModel? _activeVideo;

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
  void didChangeDependencies() {
    super.didChangeDependencies();
    _floatingPlayback = ref.read(floatingPlaybackControllerProvider);
  }

  @override
  void dispose() {
    _statusPollTimer?.cancel();
    _progressTracker?.dispose();
    final video = _activeVideo;
    final playback = video?.playback;
    final floating = _floatingPlayback;
    if (floating != null &&
        video != null &&
        (playback?.usesEmbedPlayer ?? false) &&
        (playback?.url.trim().isNotEmpty ?? false) &&
        !floating.isMinimized) {
      floating.attachEmbed(
        videoId: video.id,
        title: video.title,
        playbackUrl: playback?.url ?? '',
        expiresAt: playback?.expiresAt,
        durationSeconds: video.durationSeconds,
        minimized: true,
      );
    }
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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(AppStrings.of(context).t(message))));
  }

  void _ensureProgressTracker(VideoModel video) {
    final savePosition = ref
        .read(appDisplayPreferencesProvider)
        .saveWatchPosition;
    if (!savePosition) {
      _progressTracker?.dispose();
      _progressTracker = null;
      _trackerVideoId = video.id;
      return;
    }

    if (_trackerVideoId == video.id && _progressTracker != null) {
      return;
    }

    _progressTracker?.dispose();
    _trackerVideoId = video.id;

    final durationSeconds = video.durationSeconds > 0
        ? video.durationSeconds
        : 1;
    final details = ref.read(
      videoDetailsControllerProvider(widget.videoId).notifier,
    );

    _progressTracker = VideoProgressTracker(
      durationSeconds: durationSeconds,
      onSync:
          ({
            required int currentPositionSeconds,
            required int durationSeconds,
            bool showSuccessMessage = false,
          }) {
            return details.syncProgress(
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

  void _floatAndLeave() {
    final video = _activeVideo;
    final playback = video?.playback;
    final floating = _floatingPlayback;
    if (floating != null &&
        video != null &&
        (playback?.usesEmbedPlayer ?? false) &&
        (playback?.url.trim().isNotEmpty ?? false)) {
      floating.attachEmbed(
        videoId: video.id,
        title: video.title,
        playbackUrl: playback?.url ?? '',
        expiresAt: playback?.expiresAt,
        durationSeconds: video.durationSeconds,
        minimized: true,
      );
    }

    if (!mounted) {
      return;
    }
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go(AppRoutes.home);
  }

  Future<void> _onFloatPressed() async {
    final native = _nativePlayerKey.currentState;
    if (native != null) {
      final started = await native.startFloating();
      if (!started && mounted) {
        _showSnackBar('انتظر تجهيز الفيديو ثم اضغط تشغيل عائم');
      }
      return;
    }

    _floatAndLeave();
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
      backgroundColor: AppColors.of(context).background,
      body: _buildBody(state),
    );
  }

  Widget _buildBody(VideoDetailsState state) {
    switch (state.status) {
      case FeatureLoadStatus.initial:
      case FeatureLoadStatus.loading:
        return LoadingWidget(message: AppStrings.of(context).t('جاري تحميل الفيديو...'));
      case FeatureLoadStatus.error:
        return ErrorView(
          message: state.errorMessage ?? 'تعذر تحميل الفيديو',
          onRetry: _reloadVideo,
        );
      case FeatureLoadStatus.empty:
      case FeatureLoadStatus.loaded:
        final video = state.video;
        if (video == null) {
          return ErrorView(message: AppStrings.of(context).t('المحتوى غير موجود'));
        }

        _ensureProgressTracker(video);
        _syncStatusPolling(video);
        _activeVideo = video;

        final savedProgress = video.progress;
        final livePercentage =
            _progressTracker?.completionPercentage ??
            savedProgress?.completionPercentage ??
            0;
        final livePosition =
            _progressTracker?.currentPositionSeconds ??
            savedProgress?.currentPosition ??
            0;
        final playbackUrl = video.playback?.url.trim() ?? '';
        final canFloat = playbackUrl.isNotEmpty && video.status == 'ready';

        return RefreshIndicator(
          color: AppColors.of(context).accent,
          backgroundColor: AppColors.of(context).cardWhite,
          onRefresh: _reloadVideo,
          edgeOffset: MediaQuery.paddingOf(context).top + kToolbarHeight,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              _VideoDetailsHero(
                title: video.title,
                onFloat: canFloat ? _onFloatPressed : null,
              ),
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
    final showsVideoPlayer = playbackUrl.isNotEmpty && video.status == 'ready';
    final content = _buildPlayerContent(
      video,
      playbackUrl,
      playback?.expiresAt,
    );

    final playerCard = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.of(context).glassShadow.withValues(alpha: 0.14),
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

    if (!showsVideoPlayer) {
      return playerCard;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        playerCard,
        FloatingPlaybackLaunchBar(onPressed: _onFloatPressed),
      ],
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
            : AppStrings.of(context).t(video.pendingPlaybackMessage),
        tone: video.isLocked
            ? _PlaceholderTone.locked
            : _PlaceholderTone.pending,
        onRetry: video.isPendingPlayback ? _reloadVideo : null,
      );
    }

    if (video.status != 'ready') {
      return _PlayerPlaceholder(
        icon: Icons.info_outline_rounded,
        title: AppStrings.of(context).t('غير جاهز'),
        message: AppStrings.of(context).t('الفيديو غير جاهز للمشاهدة حالياً.'),
        tone: _PlaceholderTone.pending,
        onRetry: _reloadVideo,
      );
    }

    final savedPosition = video.progress?.currentPosition ?? 0;
    final playback = video.playback;
    final blockPlayback = ref.watch(shouldHideProtectedContentProvider);
    final floating = ref.read(floatingPlaybackControllerProvider);
    final display = ref.watch(appDisplayPreferencesProvider);
    final resumeSeconds = display.saveWatchPosition ? savedPosition : 0;

    if (playback?.usesEmbedPlayer ?? false) {
      if (floating.session?.videoId == video.id &&
          floating.session?.usesEmbed == true &&
          floating.isMinimized) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) {
            return;
          }
          _floatingPlayback?.restore();
        });
      }
      return RshdEmbedVideoPlayer(
        playbackUrl: playbackUrl,
        expiresAt: expiresAt,
        blockPlayback: blockPlayback,
        autoPlay: display.autoPlayVideo,
        rememberPosition: display.saveWatchPosition,
        quality: display.videoQuality,
        onRequestFloating: _floatAndLeave,
        onRefreshPlayback: () => ref
            .read(videoDetailsControllerProvider(widget.videoId).notifier)
            .refreshPlayback(widget.videoId),
      );
    }

    return RshdVideoPlayer(
      key: _nativePlayerKey,
      playbackUrl: playbackUrl,
      expiresAt: expiresAt,
      initialPositionSeconds: resumeSeconds,
      autoPlay: display.autoPlayVideo,
      blockPlayback: blockPlayback,
      existingController: floating.controllerFor(video.id),
      onControllerReady: (controller) {
        _floatingPlayback?.attachNative(
          videoId: video.id,
          title: video.title,
          playbackUrl: playbackUrl,
          controller: controller,
          expiresAt: expiresAt,
          durationSeconds: video.durationSeconds,
        );
      },
      onWillReplaceController: () {
        _floatingPlayback?.detachNativeWithoutDispose();
      },
      onPlayerDetached: ({required bool keepPlaying}) {
        final current = _floatingPlayback;
        if (current == null || current.session?.videoId != video.id) {
          return;
        }
        current.playerDetached(keepPlaying: keepPlaying);
      },
      onHandoffFloating: () {
        _floatingPlayback?.minimizeNative();
      },
      onRequestFloating: _floatAndLeave,
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
  const _VideoDetailsHero({required this.title, this.onFloat});

  final String title;
  final VoidCallback? onFloat;

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
      backgroundColor: AppColors.of(context).primary,
      foregroundColor: AppColors.of(context).white,
      title: Text(AppStrings.of(context).t(title),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
      ),
      actions: [
        if (onFloat != null)
          IconButton(
            tooltip: AppStrings.of(context).t('تشغيل عائم'),
            onPressed: onFloat,
            icon: const Icon(Icons.picture_in_picture_alt_rounded),
          ),
      ],
      flexibleSpace: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerRight,
            end: Alignment.centerLeft,
            colors: [
              AppColors.of(context).primary,
              AppColors.of(context).secondaryNavy,
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
      _PlaceholderTone.error => AppColors.of(context).error,
      _PlaceholderTone.locked => AppColors.of(context).secondary,
      _PlaceholderTone.pending => AppColors.of(context).darkGold,
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.of(context).cardWhite,
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
          Text(AppStrings.of(context).t(title),
            style: AppTextStyles.subtitleOf(context).copyWith(
              color: AppColors.of(context).primary,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 4),
          Text(AppStrings.of(context).t(message),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.captionOf(
              context,
            ).copyWith(color: AppColors.of(context).textMuted, height: 1.35),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: Text(AppStrings.of(context).t('تحديث')),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.of(context).secondary,
                side: BorderSide(
                  color: AppColors.of(
                    context,
                  ).secondary.withValues(alpha: 0.35),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
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
          _SectionHeading(
            icon: Icons.info_outline_rounded,
            title: AppStrings.of(context).t('معلومات الفيديو'),
          ),
          const SizedBox(height: 14),
          Text(AppStrings.of(context).t(video.title),
            style: AppTextStyles.titleOf(
              context,
            ).copyWith(fontSize: 22, height: 1.25),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _StatusChip(label: AppStrings.of(context).t(video.statusLabel), status: video.status),
              _InfoPill(
                icon: Icons.schedule_rounded,
                label: video.formattedDuration,
                caption: 'المدة',
              ),
              if (video.isFree)
                _InfoPill(
                  icon: Icons.visibility_outlined,
                  label: AppStrings.of(context).t('مجاني'),
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
              Expanded(
                child: _SectionHeading(
                  icon: Icons.auto_graph_rounded,
                  title: AppStrings.of(context).t('تقدم المشاهدة'),
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
              backgroundColor: AppColors.of(context).background,
              color: AppColors.of(context).accent,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(AppStrings.of(context).t(positionSeconds > 0
                      ? 'توقفت عند $positionSeconds ثانية'
                      : 'لم تبدأ المشاهدة بعد'),
                  style: AppTextStyles.captionOf(context),
                ),
              ),
              Text(AppStrings.of(context).t('من $durationLabel'),
                style: AppTextStyles.captionOf(context).copyWith(
                  color: AppColors.of(context).secondary,
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
        color: AppColors.of(context).cardWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.of(context).white, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppColors.of(context).glassShadow.withValues(alpha: 0.07),
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
  const _SectionHeading({required this.icon, required this.title});

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
            color: AppColors.of(context).accent.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: AppColors.of(context).darkGold),
        ),
        const SizedBox(width: 10),
        Text(AppStrings.of(context).t(title),
          style: AppTextStyles.bodyOf(context).copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.of(context).primary,
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
        color: AppColors.of(context).background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(AppStrings.of(context).t('$percentage%'),
        style: AppTextStyles.captionOf(context).copyWith(
          color: AppColors.of(context).secondary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.status});

  final String label;
  final String status;

  @override
  Widget build(BuildContext context) {
    final Color color = switch (status) {
      'ready' => const Color(0xFF067647),
      'processing' => const Color(0xFFB54708),
      'uploading' => const Color(0xFF175CD3),
      'failed' => AppColors.of(context).error,
      _ => AppColors.of(context).textMuted,
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
          Text(AppStrings.of(context).t(label),
            style: AppTextStyles.captionOf(
              context,
            ).copyWith(color: color, fontWeight: FontWeight.w700),
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
        color: AppColors.of(context).background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.of(context).secondary),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppStrings.of(context).t(caption),
                style: AppTextStyles.captionOf(context).copyWith(fontSize: 10),
              ),
              Text(AppStrings.of(context).t(label),
                style: AppTextStyles.captionOf(context).copyWith(
                  color: AppColors.of(context).primary,
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
