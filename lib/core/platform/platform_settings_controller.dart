import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/api_client.dart';
import '../network/api_endpoints.dart';
import 'platform_settings.dart';

class PlatformSettingsRepository {
  PlatformSettingsRepository(this._client);

  final ApiClient _client;

  Future<PlatformSettings> fetchPublicSettings() async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiEndpoints.publicSettings,
    );

    final payload = response.data;
    if (payload == null) {
      return PlatformSettings.fallback;
    }

    return PlatformSettings.fromJson(payload);
  }
}

final platformSettingsRepositoryProvider = Provider<PlatformSettingsRepository>(
  (ref) {
    return PlatformSettingsRepository(ref.watch(apiClientProvider));
  },
);

final platformSettingsProvider =
    AsyncNotifierProvider<PlatformSettingsController, PlatformSettings>(
      PlatformSettingsController.new,
    );

extension ResolvedPlatformSettings on AsyncValue<PlatformSettings> {
  /// Never throws. Offline / loading / error all fall back to local defaults
  /// so splash and router redirects cannot hang.
  PlatformSettings get resolved => asData?.value ?? PlatformSettings.fallback;
}

class PlatformSettingsController extends AsyncNotifier<PlatformSettings> {
  @override
  Future<PlatformSettings> build() async {
    try {
      return await ref
          .read(platformSettingsRepositoryProvider)
          .fetchPublicSettings();
    } catch (_) {
      // Public settings must never block app startup (splash hang).
      return PlatformSettings.fallback;
    }
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(() async {
      return ref.read(platformSettingsRepositoryProvider).fetchPublicSettings();
    });
  }
}
