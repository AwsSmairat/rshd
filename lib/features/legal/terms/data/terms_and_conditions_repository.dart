import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/api_response.dart';
import 'terms_and_conditions_content.dart';
import 'terms_and_conditions_model.dart';

class TermsAndConditionsRepository {
  TermsAndConditionsRepository(this._client);

  // ignore: unused_field — يُستخدم عند تفعيل Endpoint البعيد.
  final ApiClient _client;

  TermsDocument? _cached;

  Future<TermsDocument> fetch({bool forceRefresh = false}) async {
    if (!forceRefresh && _cached != null) {
      return _cached!.copyWithSource(TermsSource.cached);
    }

    try {
      final status = await _fetchAcceptanceStatus();
      final document = await _fetchRemote(status);
      _cached = document;
      return document;
    } on ApiException catch (error) {
      if (_isOfflineError(error)) {
        return TermsAndConditionsContent.buildLocalDocument();
      }
      rethrow;
    } on DioException catch (error) {
      if (_isDioOffline(error)) {
        return TermsAndConditionsContent.buildLocalDocument();
      }
      rethrow;
    } catch (_) {
      return TermsAndConditionsContent.buildLocalDocument();
    }
  }

  Future<TermsAcceptanceStatus?> _fetchAcceptanceStatus() async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        ApiEndpoints.studentTermsStatus,
      );
      final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
        Map<String, dynamic>.from(response.data as Map),
        (json) => Map<String, dynamic>.from(json as Map),
      );
      if (!apiResponse.success || apiResponse.data == null) {
        return null;
      }
      final data = apiResponse.data!;
      return TermsAcceptanceStatus(
        currentVersion: data['current_version']?.toString() ?? '',
        requiresAcceptance: data['requires_acceptance'] == true,
        acceptedVersion: data['accepted_version']?.toString(),
        acceptedAt: data['accepted_at']?.toString(),
      );
    } catch (_) {
      return null;
    }
  }

  Future<TermsDocument> _fetchRemote(TermsAcceptanceStatus? status) async {
    // TODO: GET ApiEndpoints.termsAndConditions عند توفر محتوى منشور من الإدارة.
    return TermsAndConditionsContent.buildLocalDocument(
      requiresAcceptance: status?.requiresAcceptance ?? false,
      acceptedVersion: status?.acceptedVersion,
    );
  }

  Future<void> acceptTerms() async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiEndpoints.studentTermsAccept,
      data: const {},
    );

    final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
      Map<String, dynamic>.from(response.data as Map),
      (json) => Map<String, dynamic>.from(json as Map),
    );

    if (!apiResponse.success) {
      throw ApiException(
        message: apiResponse.message ?? 'تعذر تسجيل الموافقة',
        errors: apiResponse.errors,
      );
    }

    _cached = null;
  }

  bool _isOfflineError(ApiException error) {
    return error.statusCode == null &&
        (error.message.contains('اتصال') ||
            error.message.contains('Internet') ||
            error.message.contains('network'));
  }

  bool _isDioOffline(DioException error) {
    return error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout;
  }
}

extension on TermsDocument {
  TermsDocument copyWithSource(TermsSource source) {
    return TermsDocument(
      title: title,
      subtitle: subtitle,
      version: version,
      lastUpdated: lastUpdated,
      sections: sections,
      source: source,
      requiresAcceptance: requiresAcceptance,
      acceptedVersion: acceptedVersion,
    );
  }
}

final termsAndConditionsRepositoryProvider =
    Provider<TermsAndConditionsRepository>((ref) {
  return TermsAndConditionsRepository(ref.watch(apiClientProvider));
});
