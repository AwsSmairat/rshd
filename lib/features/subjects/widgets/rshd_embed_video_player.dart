import 'dart:async';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../core/platform/webview_bootstrap.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Bunny Stream embed player (iframe.mediadelivery.net) for when CDN HLS is blocked.
class RshdEmbedVideoPlayer extends StatefulWidget {
  const RshdEmbedVideoPlayer({
    super.key,
    required this.playbackUrl,
    this.expiresAt,
    this.onRefreshPlayback,
  });

  final String playbackUrl;
  final DateTime? expiresAt;
  final Future<String?> Function()? onRefreshPlayback;

  @override
  State<RshdEmbedVideoPlayer> createState() => _RshdEmbedVideoPlayerState();
}

class _RshdEmbedVideoPlayerState extends State<RshdEmbedVideoPlayer> {
  WebViewController? _controller;
  Timer? _refreshTimer;
  Timer? _loadingTimeoutTimer;
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _errorMessage;
  String _activePlaybackUrl = '';

  static const _playbackErrorMessage =
      'تعذّر تشغيل الفيديو. أعد المحاولة أو حدّث الصفحة.';

  static const _loadingTimeout = Duration(seconds: 20);

  @override
  void initState() {
    super.initState();
    _activePlaybackUrl = widget.playbackUrl;
    unawaited(_initializePlayer());
    _scheduleRefreshTimer();
  }

  @override
  void didUpdateWidget(covariant RshdEmbedVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.playbackUrl != widget.playbackUrl &&
        widget.playbackUrl.isNotEmpty &&
        widget.playbackUrl != _activePlaybackUrl) {
      _activePlaybackUrl = widget.playbackUrl;
      unawaited(_loadUrl(_activePlaybackUrl));
    }

    if (oldWidget.expiresAt != widget.expiresAt) {
      _scheduleRefreshTimer();
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
    await controller.loadRequest(Uri.parse(url));
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
      final refreshedUrl = await widget.onRefreshPlayback!();
      if (!mounted || refreshedUrl == null || refreshedUrl.isEmpty) {
        return;
      }

      _activePlaybackUrl = refreshedUrl;
      await _loadUrl(refreshedUrl);
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

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return _PlaybackErrorState(
        message: _errorMessage!,
        onRetry: _retry,
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        if (_controller != null)
          WebViewWidget(controller: _controller!),
        if (_isLoading || _isRefreshing)
          const ColoredBox(
            color: Colors.black87,
            child: Center(
              child: CircularProgressIndicator(
                color: AppColors.darkGold,
              ),
            ),
          ),
      ],
    );
  }
}

class _PlaybackErrorState extends StatelessWidget {
  const _PlaybackErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFFE4E6),
            Color(0xFFFFF7ED),
          ],
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.play_disabled_rounded,
            color: AppColors.error,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            'تعذّر التشغيل',
            style: AppTextStyles.subtitle.copyWith(color: AppColors.text),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: AppTextStyles.body.copyWith(color: AppColors.textMuted),
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
