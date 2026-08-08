import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'screen_protection_platform.dart';
import 'screen_protection_service.dart';

final screenProtectionServiceProvider =
    ChangeNotifierProvider<ScreenProtectionService>((ref) {
  final service = ScreenProtectionService();
  ref.onDispose(service.dispose);
  return service;
});

final shouldHideProtectedContentProvider = Provider<bool>((ref) {
  return ref.watch(
    screenProtectionServiceProvider.select((service) => service.shouldHideContent),
  );
});

final isScreenCapturedProvider = Provider<bool>((ref) {
  return ref.watch(
    screenProtectionServiceProvider.select((service) => service.isScreenCaptured),
  );
});

final screenProtectionActiveProvider = Provider<bool>((ref) {
  return ref.watch(
    screenProtectionServiceProvider.select((service) => service.isProtectionActive),
  );
});

/// Exposed for tests to inject a fake platform.
void configureScreenProtectionPlatformForTests(
  ScreenProtectionPlatform platform,
) {
  ScreenProtectionPlatform.instance = platform;
}
