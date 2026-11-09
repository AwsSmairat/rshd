import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/api_client.dart';
import '../network/api_endpoints.dart';

/// Tells the server which FCM token belongs to this signed-in session.
class PushTokensRepository {
  PushTokensRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<void> register({
    required String token,
    required String platform,
    String? appVersion,
  }) async {
    await _apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.pushTokens,
      data: {
        'token': token,
        'platform': platform,
        'app_version': ?appVersion,
      },
    );
  }

  Future<void> unregister(String token) async {
    await _apiClient.delete<Map<String, dynamic>>(
      ApiEndpoints.pushTokens,
      data: {'token': token},
    );
  }
}

final pushTokensRepositoryProvider = Provider<PushTokensRepository>((ref) {
  return PushTokensRepository(apiClient: ref.watch(apiClientProvider));
});
