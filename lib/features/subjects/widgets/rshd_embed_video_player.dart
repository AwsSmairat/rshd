import 'dart:async';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../core/platform/webview_bootstrap.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../data/models/video_model.dart';
import '../utils/playback_refresh_scheduler.dart';
import '../utils/playback_url_preferences.dart';

/// Bunny Stream embed player (iframe.mediadelivery.net) for when CDN HLS is blocked.
class RshdEmbedVideoPlayer extends StatefulWidget {
  const RshdEmbedVideoPlayer({
    super.key,
    required this.playbackUrl,
    this.expiresAt,
    this.blockPlayback = false,
    this.autoPlay = false,
    this.rememberPosition = true,
    this.quality = 'auto',
    this.onRefreshPlayback,
    this.onRequestFloating,
  });

  final String playbackUrl;
  final DateTime? expiresAt;
  final bool blockPlayback;
  final bool autoPlay;
  final bool rememberPosition;
  final String quality;
  final Future<VideoPlaybackModel?> Function()? onRefreshPlayback;
  final VoidCallback? onRequestFloating;

  @override
  State<RshdEmbedVideoPlayer> createState() => RshdEmbedVideoPlayerState();
}

class RshdEmbedVideoPlayerState extends State<RshdEmbedVideoPlayer> {
  WebViewController? _controller;
  Timer? _refreshTimer;
  Timer? _loadingTimeoutTimer;
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _errorMessage;
  String _activePlaybackUrl = '';
  DateTime? _activeExpiresAt;

  static const _playbackErrorMessage =
      'تعذّر تشغيل الفيديو. أعد المحاولة أو حدّث الصفحة.';

  static const _loadingTimeout = Duration(seconds: 20);

  @override
  void initState() {
    super.initState();
    _activePlaybackUrl = widget.playbackUrl;
    _activeExpiresAt = widget.expiresAt;
    unawaited(_initializePlayer());
    _scheduleRefreshTimer();
  }

  @override
  void didUpdateWidget(covariant RshdEmbedVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.blockPlayback && !oldWidget.blockPlayback) {
      unawaited(_suspendForProtection());
    } else if (!widget.blockPlayback && oldWidget.blockPlayback) {
      unawaited(_loadUrl(_activePlaybackUrl));
    }

    if (oldWidget.playbackUrl != widget.playbackUrl &&
        widget.playbackUrl.isNotEmpty &&
        widget.playbackUrl != _activePlaybackUrl) {
      _activePlaybackUrl = widget.playbackUrl;
      unawaited(_loadUrl(_activePlaybackUrl));
    }

    if (oldWidget.expiresAt != widget.expiresAt) {
      _activeExpiresAt = widget.expiresAt;
      _scheduleRefreshTimer();
    }

    if (oldWidget.autoPlay != widget.autoPlay ||
        oldWidget.rememberPosition != widget.rememberPosition ||
        oldWidget.quality != widget.quality) {
      unawaited(_loadUrl(_activePlaybackUrl));
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _loadingTimeoutTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializePlayer() async {
    final uri = Uri.tryParse(_activePlaybackUrl);
    if (uri == null || !uri.hasScheme) {
      _setError(_playbackErrorMessage);
      return;
    }

    try {
      final controller = createEmbedWebViewController(
        onPageStarted: (_) => _beginLoading(),
        onPageFinished: (_) => _finishLoading(),
        onWebResourceError: (error) {
          if (!mounted) {
            return;
          }

          if (error.isForMainFrame ?? true) {
            _setError(_playbackErrorMessage);
          }
        },
      );

      _controller = controller;
      await _loadUrl(_activePlaybackUrl);
    } catch (_) {
      _setError(
        'تعذّر تهيئة مشغّل الفيديو. أعد تشغيل التطبيق بالكامل (flutter run).',
      );
    }
  }

  void _beginLoading() {
    _loadingTimeoutTimer?.cancel();
    _loadingTimeoutTimer = Timer(_loadingTimeout, () {
      if (mounted && _isLoading) {
        _setError(_playbackErrorMessage);
      }
    });

    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }
  }

  void _finishLoading() {
    _loadingTimeoutTimer?.cancel();

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadUrl(String url) async {
    final controller = _controller;
    if (controller == null) {
      return;
    }

    _beginLoading();
    await controller.loadRequest(
      Uri.parse(
        playbackUrlWithPreferences(
          url,
          autoPlay: widget.autoPlay,
          rememberPosition: widget.rememberPosition,
          quality: widget.quality,
        ),
      ),
    );
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
      unawaited(_refreshPlayback());
      return;
    }

    _refreshTimer = Timer(delay, _refreshPlayback);
  }

  Future<void> _refreshPlayback() async {
    if (_isRefreshing || widget.onRefreshPlayback == null) {
      return;
    }

    setState(() => _isRefreshing = true);

    try {
      final refreshedPlayback = await widget.onRefreshPlayback!();
      if (!mounted ||
          refreshedPlayback == null ||
          refreshedPlayback.url.isEmpty) {
        return;
      }

      _activePlaybackUrl = refreshedPlayback.url;
      _activeExpiresAt = refreshedPlayback.expiresAt ?? widget.expiresAt;
      await _loadUrl(_activePlaybackUrl);
      _scheduleRefreshTimer();
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  void _setError(String message) {
    _loadingTimeoutTimer?.cancel();

    if (!mounted) {
      return;
    }

    setState(() {
      _errorMessage = message;
      _isLoading = false;
    });
  }

  Future<void> _retry() async {
    if (widget.onRefreshPlayback != null) {
      await _refreshPlayback();
      return;
    }

    await _loadUrl(_activePlaybackUrl);
  }

  Future<void> _suspendForProtection() async {
    final controller = _controller;
    if (controller == null) return;
    await controller.loadRequest(Uri.parse('about:blank'));
  }

  @override
  Widget build(BuildContext context) {
    if (widget.blockPlayback) {
      return ColoredBox(color: AppColors.of(context).primary);
    }

    if (_errorMessage != null) {
      return _PlaybackErrorState(message: _errorMessage!, onRetry: _retry);
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        if (_controller != null) WebViewWidget(controller: _controller!),
        if (_isLoading || _isRefreshing)
          ColoredBox(
            color: Colors.black87,
            child: Center(
              child: CircularProgressIndicator(
                color: AppColors.of(context).darkGold,
              ),
            ),
          ),
      ],
    );
  }
}

class _PlaybackErrorState extends StatelessWidget {
  const _PlaybackErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFE4E6), Color(0xFFFFF7ED)],
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.play_disabled_rounded,
            color: AppColors.of(context).error,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            'تعذّر التشغيل',
            style: AppTextStyles.subtitleOf(
              context,
            ).copyWith(color: AppColors.of(context).text),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: AppTextStyles.bodyOf(
              context,
            ).copyWith(color: AppColors.of(context).textMuted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }
}
