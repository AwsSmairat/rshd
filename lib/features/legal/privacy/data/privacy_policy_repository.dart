import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import 'privacy_policy_content.dart';
import 'privacy_policy_model.dart';

/// TODO: عند إضافة Endpoint في لوحة الإدارة، استخدم [ApiEndpoints.privacyPolicy]
/// وحدّث [PrivacyPolicyRepository.fetch] لتحليل الاستجابة بعد التحقق (Sanitization).
class PrivacyPolicyRepository {
  PrivacyPolicyRepository(this._client);

  // ignore: unused_field — يُستخدم عند تفعيل Endpoint البعيد.
  final ApiClient _client;

  PrivacyPolicyDocument? _cached;

  Future<PrivacyPolicyDocument> fetch({bool forceRefresh = false}) async {
    if (!forceRefresh && _cached != null) {
      return _cached!.copyWithSource(PrivacyPolicySource.cached);
    }

    try {
      final remote = await _fetchRemote();
      _cached = remote;
      return remote;
    } on ApiException catch (error) {
      if (_isOfflineError(error)) {
        return PrivacyPolicyContent.buildLocalDocument().copyWithSource(
          PrivacyPolicySource.local,
        );
      }
      rethrow;
    } on DioException catch (error) {
      if (_isDioOffline(error)) {
        return PrivacyPolicyContent.buildLocalDocument().copyWithSource(
          PrivacyPolicySource.local,
        );
      }
      rethrow;
    } catch (_) {
      return PrivacyPolicyContent.buildLocalDocument().copyWithSource(
        PrivacyPolicySource.local,
      );
    }
  }

  Future<PrivacyPolicyDocument> _fetchRemote() async {
    // TODO: عند توفر Endpoint:
    // final response = await _client.get<Map<String, dynamic>>(
    //   ApiEndpoints.privacyPolicy,
    // );
    // return _parseRemote(response.data);

    return PrivacyPolicyContent.buildLocalDocument();
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

extension on PrivacyPolicyDocument {
  PrivacyPolicyDocument copyWithSource(PrivacyPolicySource source) {
    return PrivacyPolicyDocument(
      title: title,
      subtitle: subtitle,
      lastUpdated: lastUpdated,
      version: version,
      sections: sections,
      source: source,
    );
  }
}

final privacyPolicyRepositoryProvider = Provider<PrivacyPolicyRepository>((ref) {
  return PrivacyPolicyRepository(ref.watch(apiClientProvider));
});
