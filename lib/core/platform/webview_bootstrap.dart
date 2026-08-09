import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

import '../security/safe_external_url.dart';

/// Registers the native WebView implementation before any [WebViewController] is created.
void ensureWebViewPlatformInitialized() {
  if (WebViewPlatform.instance != null) {
    return;
  }

  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
      WebViewPlatform.instance = AndroidWebViewPlatform();
    case TargetPlatform.iOS:
    case TargetPlatform.macOS:
      WebViewPlatform.instance = WebKitWebViewPlatform();
    default:
      break;
  }
}

/// Creates a controller tuned for Bunny Stream embed playback.
WebViewController createEmbedWebViewController({
  required void Function(String url) onPageStarted,
  required void Function(String url) onPageFinished,
  required void Function(WebResourceError error) onWebResourceError,
}) {
  ensureWebViewPlatformInitialized();

  if (WebViewPlatform.instance == null) {
    throw StateError('WebView platform is not available on this device.');
  }

  late final PlatformWebViewControllerCreationParams params;

  if (WebViewPlatform.instance is WebKitWebViewPlatform) {
    params = WebKitWebViewControllerCreationParams(
      allowsInlineMediaPlayback: true,
      mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
    );
  } else {
    params = const PlatformWebViewControllerCreationParams();
  }

  final controller = WebViewController.fromPlatformCreationParams(params)
    ..setJavaScriptMode(JavaScriptMode.unrestricted)
    ..setBackgroundColor(Colors.black)
    ..setNavigationDelegate(
      NavigationDelegate(
        onPageStarted: onPageStarted,
        onPageFinished: onPageFinished,
        onWebResourceError: onWebResourceError,
        onNavigationRequest: (request) {
          final uri = Uri.tryParse(request.url);
          if (uri == null || !SafeExternalUrl.isWebViewNavigationAllowed(uri)) {
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
      ),
    );

  if (controller.platform is AndroidWebViewController) {
    unawaited(
      (controller.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(false),
    );
  }

  return controller;
}
