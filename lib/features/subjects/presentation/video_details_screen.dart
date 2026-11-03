import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/widgets/rshd_refresh_indicator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/layout/app_layout_metrics.dart';
import '../../../core/preferences/app_display_preferences.dart';
import '../../../core/router/app_router.dart';
import '../../../core/security/screen_protection_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/widgets/responsive_content.dart';
import '../../home/home_controller.dart';
import '../data/models/video_model.dart';
import '../playback/floating_playback_controller.dart';
import '../services/video_progress_tracker.dart';
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
  HomeController? _home;
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
    _home = ref.read(homeControllerProvider.notifier);
  }

  @override
  void dispose() {
    _statusPollTimer?.cancel();
    final tracker = _progressTracker;
    _progressTracker = null;
    if (tracker != null) {
      // Once the last position is saved, refresh the home screen so the
      // subject's progress bar reflects what was just watched.
      final home = _home;
      unawaited(
        tracker.dispose().whenComplete(() {
          if (home != null && home.mounted) {
            home.load(refresh: true);
          }
        }),
      );
    }
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
          .load(widget.videoId, silent: true);
    });
  }

  Future<void> _reloadVideo() {
    return ref
        .read(videoDetailsControllerProvider(widget.videoId).notifier)
        .load(widget.videoId);
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

  void _onEmbedProgress(EmbedPlaybackProgress progress) {
    final tracker = _progressTracker;
    if (tracker == null) {
      return;
    }
    final reported = progress.duration.inSeconds;
    if (reported > 0 && reported != tracker.durationSeconds) {
      tracker.durationSeconds = reported;
    }
    _isPlaying = progress.isPlaying;
    // At the very end the player may stop a fraction short of the duration;
    // count a finished video as fully watched.
    final position = progress.ended && reported > 0
        ? Duration(seconds: reported)
        : progress.position;
    // `updatePosition` only arms the periodic save while playing, and a short
    // video can end before the first tick, so mark it started explicitly.
    tracker.updatePosition(
      position,
      isPlaying: progress.isPlaying || progress.ended,
    );
    if (progress.ended) {
      unawaited(tracker.flush(showSuccessMessage: true));
    }
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
        return LoadingWidget(
          message: AppStrings.of(context).t('جاري تحميل الفيديو...'),
        );
      case FeatureLoadStatus.error:
        return ErrorView(
          message: state.errorMessage ?? 'تعذر تحميل الفيديو',
          onRetry: _reloadVideo,
        );
      case FeatureLoadStatus.empty:
      case FeatureLoadStatus.loaded:
        final video = state.video;
        if (video == null) {
          return ErrorView(
            message: AppStrings.of(context).t('المحتوى غير موجود'),
          );
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

        return AnnotatedRegion<SystemUiOverlayStyle>(
          // Light status bar icons over the dark stage.
          value: SystemUiOverlayStyle.light,
          child: RshdRefreshIndicator(
            color: AppColors.of(context).accent,
            backgroundColor: AppColors.of(context).cardWhite,
            onRefresh: _reloadVideo,
            edgeOffset: MediaQuery.paddingOf(context).top,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                SliverToBoxAdapter(
                  child: _CinemaStage(
                    video: video,
                    player: _buildPlayerSection(video),
                    onBack: _goBack,
                    onFloat: canFloat ? _onFloatPressed : null,
                  ),
                ),
                ResponsiveSliverContent(
                  padding: AppLayoutMetrics.of(
                    context,
                  ).pagePadding(top: 20, bottom: 32),
                  sliver: SliverToBoxAdapter(
                    child: _WatchProgressCard(
                      percentage: livePercentage,
                      positionSeconds: livePosition,
                      durationSeconds: video.durationSeconds,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
    }
  }

  void _goBack() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }
    context.go(AppRoutes.home);
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

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: ColoredBox(
          color: Colors.black,
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: showsVideoPlayer ? content : Center(child: content),
          ),
        ),
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
        onProgress: _onEmbedProgress,
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
        // The player detaches while the tree is being torn down; providers
        // may only change once that is over.
        Future(() => current.playerDetached(keepPlaying: keepPlaying));
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

/// "1:02:44" or "12:05": the clock a player shows, without a leading zero hour.
String _clock(int totalSeconds) {
  final seconds = totalSeconds < 0 ? 0 : totalSeconds;
  final hours = seconds ~/ 3600;
  final minutes = (seconds % 3600) ~/ 60;
  final rest = (seconds % 60).toString().padLeft(2, '0');
  if (hours > 0) {
    return '$hours:${minutes.toString().padLeft(2, '0')}:$rest';
  }
  return '$minutes:$rest';
}

/// The stage stays navy in both themes: video reads best on a dark surround.
const _stageTop = Color(0xFF0B1F3A);
const _stageBottom = Color(0xFF12294A);

/// Dark, full-width top of the page: back, the player, then the title and
/// the facts about the video, like a cinema screen above the page.
class _CinemaStage extends StatelessWidget {
  const _CinemaStage({
    required this.video,
    required this.player,
    required this.onBack,
    this.onFloat,
  });

  final VideoModel video;
  final Widget player;
  final VoidCallback onBack;
  final VoidCallback? onFloat;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final metrics = AppLayoutMetrics.of(context);
    const gold = Color(0xFFD6B56D);

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_stageTop, _stageBottom],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: SafeArea(
        bottom: false,
        child: ResponsiveHeaderContent(
          padding: EdgeInsets.fromLTRB(
            metrics.horizontalPadding,
            8,
            metrics.horizontalPadding,
            26,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _StageIconButton(
                    // Same back glyph as the app's other page headers.
                    icon: Directionality.of(context) == TextDirection.rtl
                        ? Icons.arrow_forward_ios_rounded
                        : Icons.arrow_back_ios_new_rounded,
                    tooltip: strings.t('رجوع'),
                    onPressed: onBack,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      strings.t('محاضرة فيديو'),
                      style: AppTextStyles.captionOf(context).copyWith(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              player,
              const SizedBox(height: 20),
              Text(
                strings.t(video.title),
                style: AppTextStyles.titleOf(context).copyWith(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _StatusChip(
                    label: strings.t(video.statusLabel),
                    status: video.status,
                  ),
                  if (video.durationSeconds > 0)
                    _StageChip(
                      icon: Icons.schedule_rounded,
                      label: _clock(video.durationSeconds),
                    ),
                  if (video.isFree)
                    _StageChip(
                      icon: Icons.lock_open_rounded,
                      label: strings.t('مجاني'),
                    ),
                ],
              ),
              if (onFloat != null) ...[
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onFloat,
                    icon: const Icon(
                      Icons.picture_in_picture_alt_rounded,
                      size: 19,
                    ),
                    label: Text(strings.t('تابع المشاهدة أثناء التصفح')),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: gold,
                      side: BorderSide(color: gold.withValues(alpha: 0.45)),
                      backgroundColor: gold.withValues(alpha: 0.08),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      textStyle: AppTextStyles.bodyOf(
                        context,
                      ).copyWith(fontWeight: FontWeight.w800, fontSize: 14),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StageIconButton extends StatelessWidget {
  const _StageIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.1),
      shape: const CircleBorder(),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        color: Colors.white,
        iconSize: 18,
        constraints: const BoxConstraints.tightFor(width: 44, height: 44),
        icon: Icon(icon),
      ),
    );
  }
}

class _StageChip extends StatelessWidget {
  const _StageChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: Colors.white.withValues(alpha: 0.75)),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.captionOf(context).copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
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
    // Light tones that hold up on the navy stage.
    final Color color = switch (status) {
      'ready' => const Color(0xFF4ADE80),
      'processing' => const Color(0xFFFBBF24),
      'uploading' => const Color(0xFF60A5FA),
      'failed' => const Color(0xFFF87171),
      _ => Colors.white70,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.25)),
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
            style: AppTextStyles.captionOf(
              context,
            ).copyWith(color: color, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

enum _PlaceholderTone { pending, locked, error }

/// Shown in the player frame when there is nothing to play yet.
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
      _PlaceholderTone.error => const Color(0xFFF87171),
      _PlaceholderTone.locked => Colors.white,
      _PlaceholderTone.pending => const Color(0xFFD6B56D),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(color: accent.withValues(alpha: 0.25)),
            ),
            child: Icon(icon, size: 24, color: accent),
          ),
          const SizedBox(height: 12),
          Text(
            AppStrings.of(context).t(title),
            style: AppTextStyles.subtitleOf(context).copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            AppStrings.of(context).t(message),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.captionOf(
              context,
            ).copyWith(color: Colors.white.withValues(alpha: 0.7), height: 1.4),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: Text(AppStrings.of(context).t('تحديث')),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
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

/// Where the student is in this video: a ring with the share watched, the
/// spot they reached, and a bar from the start to the end.
class _WatchProgressCard extends StatelessWidget {
  const _WatchProgressCard({
    required this.percentage,
    required this.positionSeconds,
    required this.durationSeconds,
  });

  final int percentage;
  final int positionSeconds;
  final int durationSeconds;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final colors = AppColors.of(context);
    final percent = percentage.clamp(0, 100);
    final done = percent >= 100;
    final started = positionSeconds > 0;
    final remaining = (durationSeconds - positionSeconds).clamp(
      0,
      durationSeconds,
    );
    const green = Color(0xFF16A34A);
    final tone = done ? green : colors.accent;

    final headline = done
        ? strings.t('أكملت هذا الفيديو')
        : started
        ? strings.t('وصلت إلى ${_clock(positionSeconds)}')
        : strings.t('لم تبدأ المشاهدة بعد');
    final caption = done
        ? strings.t('يمكنك إعادة المشاهدة في أي وقت')
        : started && durationSeconds > 0
        ? strings.t('متبقٍ ${_clock(remaining)}')
        : strings.t('سيُحفظ تقدّمك تلقائياً أثناء المشاهدة');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.cardWhite,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.primary.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: colors.glassShadow.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox.square(
                dimension: 64,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(end: percent / 100),
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) => Stack(
                    fit: StackFit.expand,
                    children: [
                      CircularProgressIndicator(
                        value: value,
                        strokeWidth: 6,
                        strokeCap: StrokeCap.round,
                        color: tone,
                        backgroundColor: tone.withValues(alpha: 0.14),
                      ),
                      Center(
                        child: done
                            ? const Icon(
                                Icons.check_rounded,
                                color: green,
                                size: 28,
                              )
                            : Text(
                                '$percent%',
                                textDirection: TextDirection.ltr,
                                style: AppTextStyles.bodyOf(context).copyWith(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                  color: colors.text,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.t('تقدم المشاهدة'),
                      style: AppTextStyles.captionOf(context).copyWith(
                        color: colors.textMuted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      headline,
                      style: AppTextStyles.bodyOf(context).copyWith(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: colors.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      caption,
                      style: AppTextStyles.captionOf(
                        context,
                      ).copyWith(color: colors.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (durationSeconds > 0) ...[
            const SizedBox(height: 18),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: TweenAnimationBuilder<double>(
                tween: Tween(end: percent / 100),
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) => LinearProgressIndicator(
                  minHeight: 8,
                  // Always determinate: 0% is an empty track, not a spinner.
                  value: value,
                  color: tone,
                  backgroundColor: colors.background,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  _clock(positionSeconds),
                  textDirection: TextDirection.ltr,
                  style: _timeStyle(context, colors.text),
                ),
                const Spacer(),
                Text(
                  _clock(durationSeconds),
                  textDirection: TextDirection.ltr,
                  style: _timeStyle(context, colors.textMuted),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  TextStyle _timeStyle(BuildContext context, Color color) {
    return AppTextStyles.captionOf(context).copyWith(
      color: color,
      fontWeight: FontWeight.w700,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }
}
