import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/config/app_config.dart';
import 'core/config/release_environment_guard.dart';
import 'core/platform/webview_bootstrap.dart';
import 'core/push/push_messaging.dart';
import 'firebase_options.dart';
import 'core/startup/startup_timing.dart';

void main() {
  StartupTiming.mark('T0');
  WidgetsFlutterBinding.ensureInitialized();
  StartupTiming.mark('T1');
  ReleaseEnvironmentGuard.assertReleaseConfiguration(
    baseUrl: AppConfig.baseUrl,
  );
  ensureWebViewPlatformInitialized();
  // Starts in the background; push turns on once it's running.
  PushBootstrap.initialize(DefaultFirebaseOptions.currentPlatform);
  StartupTiming.mark('T2');
  runApp(const ProviderScope(child: RshdApp()));
}
