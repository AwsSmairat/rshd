import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/api_response.dart';
import 'help_center_model.dart';

class HelpCenterRepository {
  HelpCenterRepository(this._client);

  final ApiClient _client;

  Future<HelpCenterContactsModel> getContacts() async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiEndpoints.studentHelpContacts,
    );

    final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
      Map<String, dynamic>.from(response.data as Map),
      (json) => Map<String, dynamic>.from(json as Map),
    );

    if (!apiResponse.success || apiResponse.data == null) {
      throw ApiException(
        message: apiResponse.message ?? 'تعذر تحميل جهات التواصل',
        errors: apiResponse.errors,
      );
    }

    return HelpCenterContactsModel.fromJson(apiResponse.data!);
  }

  Future<void> sendMessage({
    required int subjectId,
    required String message,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiEndpoints.studentHelpMessages,
      data: {'subject_id': subjectId, 'message': message.trim()},
    );

    final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
      Map<String, dynamic>.from(response.data as Map),
      (json) => Map<String, dynamic>.from(json as Map),
    );

    if (!apiResponse.success) {
      throw ApiException(
        message: apiResponse.message ?? 'تعذر إرسال الرسالة',
        errors: apiResponse.errors,
      );
    }
  }
}

final helpCenterRepositoryProvider = Provider<HelpCenterRepository>((ref) {
  return HelpCenterRepository(ref.watch(apiClientProvider));
});
