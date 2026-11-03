import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';

import '../../../core/preferences/app_display_preferences.dart';
import '../../../core/router/app_router.dart';
import '../../../core/security/screen_protection_provider.dart';
import '../../../core/theme/app_text_styles.dart';
import '../playback/floating_playback_controller.dart';
import 'rshd_embed_video_player.dart';
import '../../../core/l10n/app_strings.dart';

const _gold = Color(0xFFD6B56D);

/// Sizes the size button steps through, as a share of the widest allowed.
const _sizeSteps = [0.0, 0.5, 1.0];

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

    void open() {
      playback.restore();
      context.push(AppRoutes.videoDetails(session.videoId));
    }

    final Widget mini;
    if (session.usesEmbed) {
      mini = _MiniPlayer(
        title: session.title,
        aspectRatio: 16 / 9,
        offset: session.offset,
        width: playback.miniWidth,
        onOffset: playback.updateOffset,
        onWidth: playback.updateMiniWidth,
        onClose: playback.close,
        onOpen: open,
        // The web player takes its own taps, so the controls stay on top.
        interactiveVideo: true,
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
      mini = _MiniPlayer(
        title: session.title,
        aspectRatio: controller.value.aspectRatio,
        offset: session.offset,
        width: playback.miniWidth,
        onOffset: playback.updateOffset,
        onWidth: playback.updateMiniWidth,
        onClose: playback.close,
        onOpen: open,
        controller: controller,
        onTogglePlay: playback.toggleNativePlayPause,
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

/// A floating video the student can move, pin to either side and resize:
/// pinch it, drag its corner, or tap the size button.
class _MiniPlayer extends StatefulWidget {
  const _MiniPlayer({
    required this.title,
    required this.aspectRatio,
    required this.offset,
    required this.width,
    required this.onOffset,
    required this.onWidth,
    required this.onClose,
    required this.onOpen,
    required this.child,
    this.controller,
    this.onTogglePlay,
    this.interactiveVideo = false,
  });

  final String title;
  final double aspectRatio;
  final Offset offset;
  final double? width;
  final ValueChanged<Offset> onOffset;
  final ValueChanged<double> onWidth;
  final VoidCallback onClose;
  final VoidCallback onOpen;
  final Widget child;
  final VideoPlayerController? controller;
  final VoidCallback? onTogglePlay;
  final bool interactiveVideo;

  @override
  State<_MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends State<_MiniPlayer>
    with SingleTickerProviderStateMixin {
  static const _edgeGap = 12.0;

  late final AnimationController _snap = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
  );
  Animation<Offset>? _snapAnimation;

  // While a gesture runs the position and size live here, and are handed to
  // the controller when it ends, so the rest of the app does not rebuild on
  // every frame.
  Offset? _offset;
  double? _width;
  double _gestureStartWidth = 0;
  bool _resizing = false;

  bool _controlsVisible = true;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    _snap.addListener(() {
      final animation = _snapAnimation;
      if (animation != null) {
        setState(() => _offset = animation.value);
      }
    });
    _scheduleHide();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _snap.dispose();
    super.dispose();
  }

  void _scheduleHide() {
    _hideTimer?.cancel();
    // The web player always shows its controls; there is nothing to reveal.
    if (widget.interactiveVideo) {
      return;
    }
    _hideTimer = Timer(const Duration(seconds: 3), () {
      final playing = widget.controller?.value.isPlaying ?? true;
      if (mounted && playing) {
        setState(() => _controlsVisible = false);
      }
    });
  }

  void _showControls() {
    setState(() => _controlsVisible = true);
    _scheduleHide();
  }

  void _toggleControls() {
    if (_controlsVisible) {
      _hideTimer?.cancel();
      setState(() => _controlsVisible = false);
    } else {
      _showControls();
    }
  }

  EdgeInsets _safeArea(MediaQueryData media) {
    return media.padding + const EdgeInsets.all(_edgeGap);
  }

  double _availableWidth(MediaQueryData media) {
    final safe = _safeArea(media);
    return media.size.width - safe.horizontal;
  }

  double _defaultWidth(MediaQueryData media) {
    // Larger on tablets, where there is room to keep watching comfortably.
    return media.size.shortestSide >= 600 ? 320 : 220;
  }

  double _resolvedWidth(MediaQueryData media) {
    return clampFloatingWidth(
      _width ?? widget.width ?? _defaultWidth(media),
      available: _availableWidth(media),
    );
  }

  Size _sizeFor(double width) {
    return floatingMiniPlayerSize(widget.aspectRatio, width: width);
  }

  Offset _clamp(Offset offset, Size size, MediaQueryData media) {
    return clampFloatingOffset(
      offset: offset,
      screenSize: media.size,
      playerSize: size,
      padding: _safeArea(media),
    );
  }

  Offset _resolvedOffset(MediaQueryData media, Size size) {
    final stored = _offset ?? widget.offset;
    if (stored == Offset.zero) {
      return defaultFloatingOffset(
        screenSize: media.size,
        playerSize: size,
        padding: media.padding,
      );
    }
    return _clamp(stored, size, media);
  }

  void _onScaleStart(ScaleStartDetails details) {
    final media = MediaQuery.of(context);
    _snap.stop();
    _gestureStartWidth = _resolvedWidth(media);
    _offset = _resolvedOffset(media, _sizeFor(_gestureStartWidth));
    _width = _gestureStartWidth;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    final media = MediaQuery.of(context);
    final oldSize = _sizeFor(_width!);
    var offset = _offset! + details.focalPointDelta;

    if (details.pointerCount > 1) {
      // Pinch: grow or shrink around the middle of the player.
      final width = clampFloatingWidth(
        _gestureStartWidth * details.scale,
        available: _availableWidth(media),
      );
      final newSize = _sizeFor(width);
      offset += Offset(
        (oldSize.width - newSize.width) / 2,
        (oldSize.height - newSize.height) / 2,
      );
      _width = width;
    }

    setState(() => _offset = _clamp(offset, _sizeFor(_width!), media));
  }

  void _onScaleEnd(ScaleEndDetails details) {
    if (_gestureStartWidth != _width) {
      HapticFeedback.selectionClick();
    }
    _settle();
  }

  void _onCornerDrag(DragUpdateDetails details) {
    final media = MediaQuery.of(context);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final start = _resolvedWidth(media);
    final size = _sizeFor(start);
    final offset = _offset ?? _resolvedOffset(media, size);
    // The handle sits on the inner bottom corner and pulls that corner.
    final grow = rtl ? -details.delta.dx : details.delta.dx;
    final width = clampFloatingWidth(
      start + grow,
      available: _availableWidth(media),
    );
    final shift = rtl ? Offset(start - width, 0) : Offset.zero;
    setState(() {
      _resizing = true;
      _width = width;
      _offset = _clamp(offset + shift, _sizeFor(width), media);
    });
  }

  void _onCornerEnd(DragEndDetails details) {
    setState(() => _resizing = false);
    HapticFeedback.selectionClick();
    _settle();
  }

  /// The single-tap way to resize: small, medium, large, and round again.
  void _cycleSize() {
    final media = MediaQuery.of(context);
    final available = _availableWidth(media);
    final maxWidth = clampFloatingWidth(
      floatingMiniPlayerMaxWidth,
      available: available,
    );
    final steps = [
      for (final share in _sizeSteps)
        floatingMiniPlayerMinWidth +
            (maxWidth - floatingMiniPlayerMinWidth) * share,
    ];
    final current = _resolvedWidth(media);
    final next = steps.firstWhere(
      (step) => step > current + 1,
      orElse: () => steps.first,
    );
    final size = _sizeFor(current);
    _offset = _resolvedOffset(media, size);
    _width = next;
    HapticFeedback.selectionClick();
    _showControls();
    _settle();
  }

  /// Pins the player to the nearer side and hands the result on.
  void _settle() {
    final media = MediaQuery.of(context);
    final width = _resolvedWidth(media);
    final size = _sizeFor(width);
    final from = _resolvedOffset(media, size);
    final safe = _safeArea(media);
    final left = safe.left;
    final right = media.size.width - safe.right - size.width;
    final centre = from.dx + size.width / 2;
    final target = _clamp(
      Offset(centre < media.size.width / 2 ? left : right, from.dy),
      size,
      media,
    );

    widget.onWidth(width);
    _snapAnimation = Tween(
      begin: from,
      end: target,
    ).animate(CurvedAnimation(parent: _snap, curve: Curves.easeOutBack));
    _snap.forward(from: 0).whenComplete(() {
      if (!mounted) {
        return;
      }
      widget.onOffset(target);
      _width = null;
      _offset = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final width = _resolvedWidth(media);
    final size = _sizeFor(width);
    final offset = _resolvedOffset(media, size);
    final strings = AppStrings.of(context);
    final compact = width < 220;

    final controls = AnimatedOpacity(
      opacity: _controlsVisible || widget.interactiveVideo ? 1 : 0,
      duration: const Duration(milliseconds: 180),
      child: IgnorePointer(
        ignoring: !_controlsVisible && !widget.interactiveVideo,
        child: _MiniControls(
          title: strings.t(widget.title),
          compact: compact,
          controller: widget.controller,
          interactiveVideo: widget.interactiveVideo,
          onClose: widget.onClose,
          onOpen: widget.onOpen,
          onCycleSize: _cycleSize,
          onTogglePlay: widget.onTogglePlay == null
              ? null
              : () {
                  widget.onTogglePlay!();
                  _showControls();
                },
          // The web player takes touches on the video, so the bar moves it.
          onBarScaleStart: widget.interactiveVideo ? _onScaleStart : null,
          onBarScaleUpdate: widget.interactiveVideo ? _onScaleUpdate : null,
          onBarScaleEnd: widget.interactiveVideo ? _onScaleEnd : null,
        ),
      ),
    );

    return Positioned(
      left: offset.dx,
      top: offset.dy,
      width: size.width,
      height: size.height,
      child: Semantics(
        container: true,
        label: strings.t('مشغل الفيديو العائم'),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _gold.withValues(alpha: _resizing ? 0.9 : 0.35),
              width: _resizing ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            // Above the navigator there is no page Material: give the text
            // its style and the buttons somewhere to draw their ink.
            child: Material(
              type: MaterialType.transparency,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  widget.child,
                  if (!widget.interactiveVideo)
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _toggleControls,
                      onDoubleTap: widget.onOpen,
                      onScaleStart: _onScaleStart,
                      onScaleUpdate: _onScaleUpdate,
                      onScaleEnd: _onScaleEnd,
                    ),
                  controls,
                  if (widget.controller != null)
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: _ProgressLine(controller: widget.controller!),
                    ),
                  PositionedDirectional(
                    end: 0,
                    bottom: 0,
                    child: _ResizeHandle(
                      onDrag: _onCornerDrag,
                      onEnd: _onCornerEnd,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniControls extends StatelessWidget {
  const _MiniControls({
    required this.title,
    required this.compact,
    required this.controller,
    required this.interactiveVideo,
    required this.onClose,
    required this.onOpen,
    required this.onCycleSize,
    this.onTogglePlay,
    this.onBarScaleStart,
    this.onBarScaleUpdate,
    this.onBarScaleEnd,
  });

  final String title;
  final bool compact;
  final VideoPlayerController? controller;
  final bool interactiveVideo;
  final VoidCallback onClose;
  final VoidCallback onOpen;
  final VoidCallback onCycleSize;
  final VoidCallback? onTogglePlay;
  final GestureScaleStartCallback? onBarScaleStart;
  final GestureScaleUpdateCallback? onBarScaleUpdate;
  final GestureScaleEndCallback? onBarScaleEnd;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    final topBar = Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.65),
            Colors.black.withValues(alpha: 0),
          ],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 14),
      child: Row(
        children: [
          _MiniButton(
            icon: Icons.close_rounded,
            tooltip: strings.t('إغلاق'),
            onPressed: onClose,
          ),
          Expanded(
            child: compact
                ? const SizedBox.shrink()
                : Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.captionOf(context).copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
          _MiniButton(
            icon: Icons.aspect_ratio_rounded,
            tooltip: strings.t('تغيير الحجم'),
            onPressed: onCycleSize,
          ),
          _MiniButton(
            icon: Icons.open_in_full_rounded,
            tooltip: strings.t('فتح صفحة الفيديو'),
            onPressed: onOpen,
          ),
        ],
      ),
    );

    return Stack(
      children: [
        if (!interactiveVideo)
          // A light shade so the white controls read on any frame.
          Positioned.fill(
            child: IgnorePointer(
              child: ColoredBox(color: Colors.black.withValues(alpha: 0.18)),
            ),
          ),
        Align(
          alignment: Alignment.topCenter,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onScaleStart: onBarScaleStart,
            onScaleUpdate: onBarScaleUpdate,
            onScaleEnd: onBarScaleEnd,
            child: topBar,
          ),
        ),
        if (controller != null && onTogglePlay != null)
          Center(
            child: ValueListenableBuilder<VideoPlayerValue>(
              valueListenable: controller!,
              builder: (context, value, _) => _PlayButton(
                playing: value.isPlaying,
                buffering: value.isBuffering,
                size: compact ? 44 : 54,
                onPressed: onTogglePlay!,
              ),
            ),
          ),
      ],
    );
  }
}

class _MiniButton extends StatelessWidget {
  const _MiniButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    // No tooltip: the mini player sits above the navigator, where there is
    // no overlay to show one in.
    return Semantics(
      button: true,
      label: tooltip,
      excludeSemantics: true,
      child: IconButton(
        onPressed: onPressed,
        color: Colors.white,
        iconSize: 19,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints.tightFor(width: 38, height: 38),
        icon: Icon(icon),
      ),
    );
  }
}

class _PlayButton extends StatelessWidget {
  const _PlayButton({
    required this.playing,
    required this.buffering,
    required this.size,
    required this.onPressed,
  });

  final bool playing;
  final bool buffering;
  final double size;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Material(
      color: Colors.black.withValues(alpha: 0.45),
      shape: CircleBorder(
        side: BorderSide(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox.square(
          dimension: size,
          child: buffering && playing
              ? const Padding(
                  padding: EdgeInsets.all(15),
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: Colors.white,
                  ),
                )
              : AnimatedSwitcher(
                  duration: const Duration(milliseconds: 160),
                  transitionBuilder: (child, animation) =>
                      ScaleTransition(scale: animation, child: child),
                  child: Icon(
                    playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    key: ValueKey(playing),
                    color: Colors.white,
                    size: size * 0.55,
                    semanticLabel: strings.t(playing ? 'إيقاف مؤقت' : 'تشغيل'),
                  ),
                ),
        ),
      ),
    );
  }
}

/// A thin gold line along the bottom that shows how far the video is.
class _ProgressLine extends StatelessWidget {
  const _ProgressLine({required this.controller});

  final VideoPlayerController controller;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final total = value.duration.inMilliseconds;
        final progress = total > 0
            ? (value.position.inMilliseconds / total).clamp(0.0, 1.0)
            : 0.0;
        return LinearProgressIndicator(
          value: progress,
          minHeight: 3,
          color: _gold,
          backgroundColor: Colors.white.withValues(alpha: 0.18),
        );
      },
    );
  }
}

/// Corner grip for resizing by dragging.
class _ResizeHandle extends StatelessWidget {
  const _ResizeHandle({required this.onDrag, required this.onEnd});

  final GestureDragUpdateCallback onDrag;
  final GestureDragEndCallback onEnd;

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return Semantics(
      label: AppStrings.of(context).t('اسحب لتغيير الحجم'),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanUpdate: onDrag,
        onPanEnd: onEnd,
        child: SizedBox.square(
          dimension: 40,
          child: Align(
            alignment: AlignmentDirectional.bottomEnd,
            child: Padding(
              padding: const EdgeInsets.all(5),
              child: Transform(
                alignment: Alignment.center,
                // Mirrored in RTL so the lines point into the corner.
                transform: Matrix4.diagonal3Values(rtl ? -1 : 1, 1, 1),
                child: const CustomPaint(
                  size: Size(14, 14),
                  painter: _GripPainter(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GripPainter extends CustomPainter {
  const _GripPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final w = size.width;
    final h = size.height;
    canvas.drawLine(Offset(w, h * 0.2), Offset(w * 0.2, h), paint);
    canvas.drawLine(Offset(w, h * 0.6), Offset(w * 0.6, h), paint);
  }

  @override
  bool shouldRepaint(_GripPainter oldDelegate) => false;
}
