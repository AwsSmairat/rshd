import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/api_response.dart';
import 'technical_support_model.dart';

class TechnicalSupportRepository {
  TechnicalSupportRepository(this._client);

  final ApiClient _client;

  Future<SupportConversationModel> getConversation() async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiEndpoints.studentSupportTicket,
    );

    final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
      Map<String, dynamic>.from(response.data as Map),
      (json) => Map<String, dynamic>.from(json as Map),
    );

    if (!apiResponse.success || apiResponse.data == null) {
      throw ApiException(
        message: apiResponse.message ?? 'تعذر تحميل محادثة الدعم',
        errors: apiResponse.errors,
      );
    }

    return SupportConversationModel.fromJson(apiResponse.data!);
  }

  Future<SupportConversationModel> sendMessage(String message) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiEndpoints.studentSupportMessages,
      data: {'message': message.trim()},
    );

    final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
      Map<String, dynamic>.from(response.data as Map),
      (json) => Map<String, dynamic>.from(json as Map),
    );

    if (!apiResponse.success || apiResponse.data == null) {
      throw ApiException(
        message: apiResponse.message ?? 'تعذر إرسال الرسالة',
        errors: apiResponse.errors,
      );
    }

    return SupportConversationModel.fromJson(apiResponse.data!);
  }
}

final technicalSupportRepositoryProvider =
    Provider<TechnicalSupportRepository>((ref) {
  return TechnicalSupportRepository(ref.watch(apiClientProvider));
});
