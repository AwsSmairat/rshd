import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/platform/webview_bootstrap.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  ensureWebViewPlatformInitialized();
  runApp(
    const ProviderScope(
      child: RshdApp(),
    ),
  );
}
