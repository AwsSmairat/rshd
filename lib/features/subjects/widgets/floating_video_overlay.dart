import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';

import '../../../core/preferences/app_display_preferences.dart';
import '../../../core/router/app_router.dart';
import '../../../core/security/screen_protection_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../playback/floating_playback_controller.dart';
import 'rshd_embed_video_player.dart';
import '../../../core/l10n/app_strings.dart';

class FloatingVideoOverlay extends ConsumerWidget {
  const FloatingVideoOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playback = ref.watch(floatingPlaybackControllerProvider);
    final session = playback.session;
    if (session == null || !session.minimized) {
      return const SizedBox.shrink();
    }

    final hideContent = ref.watch(shouldHideProtectedContentProvider);
    if (hideContent) {
      return const SizedBox.shrink();
    }

    final display = ref.watch(appDisplayPreferencesProvider);

    final Widget mini;
    if (session.usesEmbed) {
      mini = _DraggableMiniPlayer(
        title: session.title,
        aspectRatio: 16 / 9,
        offset: session.offset,
        onOffset: playback.updateOffset,
        onClose: playback.close,
        onOpen: () {
          playback.restore();
          context.push(AppRoutes.videoDetails(session.videoId));
        },
        child: RshdEmbedVideoPlayer(
          key: playback.embedPlayerKey,
          playbackUrl: session.playbackUrl,
          expiresAt: session.expiresAt,
          blockPlayback: hideContent,
          autoPlay: display.autoPlayVideo,
          rememberPosition: display.saveWatchPosition,
          quality: display.videoQuality,
          onRefreshPlayback: playback.refreshPlayback,
        ),
      );
    } else {
      final controller = playback.nativeController;
      if (controller == null || !controller.value.isInitialized) {
        return const SizedBox.shrink();
      }
      mini = _DraggableMiniPlayer(
        title: session.title,
        aspectRatio: controller.value.aspectRatio,
        offset: session.offset,
        onOffset: playback.updateOffset,
        onClose: playback.close,
        onOpen: () {
          playback.restore();
          context.push(AppRoutes.videoDetails(session.videoId));
        },
        onTogglePlay: playback.toggleNativePlayPause,
        isPlaying: controller.value.isPlaying,
        child: ColoredBox(color: Colors.black, child: VideoPlayer(controller)),
      );
    }

    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.none,
      children: [mini],
    );
  }
}

class _DraggableMiniPlayer extends StatelessWidget {
  const _DraggableMiniPlayer({
    required this.title,
    required this.aspectRatio,
    required this.offset,
    required this.onOffset,
    required this.onClose,
    required this.onOpen,
    required this.child,
    this.onTogglePlay,
    this.isPlaying = true,
  });

  final String title;
  final double aspectRatio;
  final Offset offset;
  final ValueChanged<Offset> onOffset;
  final VoidCallback onClose;
  final VoidCallback onOpen;
  final VoidCallback? onTogglePlay;
  final bool isPlaying;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final videoSize = floatingMiniPlayerSize(aspectRatio);
    final playerSize = Size(
      videoSize.width,
      videoSize.height + floatingMiniPlayerBarHeight,
    );
    final resolved = offset == Offset.zero
        ? defaultFloatingOffset(
            screenSize: media.size,
            playerSize: playerSize,
            padding: media.padding,
          )
        : clampFloatingOffset(
            offset: offset,
            screenSize: media.size,
            playerSize: playerSize,
            padding: media.padding,
          );

    return Positioned(
      left: resolved.dx,
      top: resolved.dy,
      width: playerSize.width,
      height: playerSize.height,
      child: Material(
        elevation: 12,
        color: AppColors.of(context).secondaryNavy,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: GestureDetector(
          onPanUpdate: (details) {
            onOffset(
              clampFloatingOffset(
                offset: resolved + details.delta,
                screenSize: media.size,
                playerSize: playerSize,
                padding: media.padding,
              ),
            );
          },
          child: Column(
            children: [
              SizedBox(
                height: floatingMiniPlayerBarHeight,
                child: Row(
                  children: [
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      onPressed: onClose,
                      icon: Icon(
                        Icons.close,
                        size: 18,
                        color: AppColors.of(context).white,
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: onOpen,
                        child: Text(AppStrings.of(context).t(title),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.captionOf(context).copyWith(
                            color: AppColors.of(context).white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    if (onTogglePlay != null)
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        onPressed: onTogglePlay,
                        icon: Icon(
                          isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          size: 20,
                          color: AppColors.of(context).accent,
                        ),
                      ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      onPressed: onOpen,
                      icon: Icon(
                        Icons.open_in_full_rounded,
                        size: 16,
                        color: AppColors.of(context).white,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: videoSize.width,
                height: videoSize.height,
                child: child,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
