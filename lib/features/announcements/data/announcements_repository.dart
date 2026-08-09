import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/api_response.dart';
import 'models/announcement_model.dart';

class AnnouncementsRepository {
  AnnouncementsRepository({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<List<AnnouncementModel>> getAnnouncements() async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.announcements,
    );

    final apiResponse = ApiResponse<List<dynamic>>.fromJson(
      Map<String, dynamic>.from(response.data as Map),
      (json) => json is List ? json : <dynamic>[],
    );

    if (!apiResponse.success) {
      throw ApiException(
        message: apiResponse.message ?? 'تعذر جلب الإعلانات.',
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
          (item) => AnnouncementModel.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
  }

  Future<AnnouncementModel?> findById(int announcementId) async {
    final announcements = await getAnnouncements();
    for (final announcement in announcements) {
      if (announcement.id == announcementId) {
        return announcement;
      }
    }
    return null;
  }
}

final announcementsRepositoryProvider = Provider<AnnouncementsRepository>((
  ref,
) {
  return AnnouncementsRepository(apiClient: ref.watch(apiClientProvider));
});
