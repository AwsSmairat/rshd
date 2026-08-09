import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/api_response.dart';
import 'models/notification_model.dart';

class NotificationsRepository {
  NotificationsRepository({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<List<NotificationModel>> getNotifications() async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.notifications,
    );

    final apiResponse = ApiResponse<List<dynamic>>.fromJson(
      Map<String, dynamic>.from(response.data as Map),
      (json) => json is List ? json : <dynamic>[],
    );

    if (!apiResponse.success) {
      throw ApiException(
        message: apiResponse.message ?? 'تعذر جلب الإشعارات.',
        errors: apiResponse.errors,
      );
    }

    final rawList = apiResponse.data ?? [];
    if (rawList.isEmpty) {
      return [];
    }

    return rawList
        .whereType<Map>()
        .map(
          (item) => NotificationModel.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
  }

  Future<NotificationModel> markAsRead(int notificationId) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.markNotificationRead(notificationId),
    );

    final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
      Map<String, dynamic>.from(response.data as Map),
      (json) => Map<String, dynamic>.from(json as Map),
    );

    if (!apiResponse.success || apiResponse.data == null) {
      throw ApiException(
        message: apiResponse.message ?? 'تعذر تحديث حالة الإشعار',
        errors: apiResponse.errors,
      );
    }

    return NotificationModel.fromJson(apiResponse.data!);
  }
}

final notificationsRepositoryProvider = Provider<NotificationsRepository>((
  ref,
) {
  return NotificationsRepository(apiClient: ref.watch(apiClientProvider));
});
