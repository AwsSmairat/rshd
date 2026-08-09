import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/storage_keys.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/api_response.dart';
import '../../shared/legal_document_parser.dart';
import '../../shared/legal_local_cache.dart';
import 'privacy_policy_content.dart';
import 'privacy_policy_model.dart';

class PrivacyPolicyRepository {
  PrivacyPolicyRepository(this._client, this._cache);

  final ApiClient _client;
  final LegalLocalCache _cache;

  PrivacyPolicyDocument? _memoryCached;

  Future<PrivacyPolicyDocument> fetch({bool forceRefresh = false}) async {
    if (!forceRefresh && _memoryCached != null) {
      return _memoryCached!.copyWithSource(PrivacyPolicySource.cached);
    }

    try {
      final remote = await _fetchRemote();
      _memoryCached = remote;
      return remote;
    } on ApiException catch (error) {
      if (_isOfflineError(error)) {
        return _loadCachedOrLocal();
      }
      rethrow;
    } on DioException catch (error) {
      if (_isDioOffline(error)) {
        return _loadCachedOrLocal();
      }
      rethrow;
    } catch (_) {
      return _loadCachedOrLocal();
    }
  }

  Future<PrivacyPolicyDocument> _fetchRemote() async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiEndpoints.legalPrivacyPolicy,
    );

    final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
      Map<String, dynamic>.from(response.data as Map),
      (json) => Map<String, dynamic>.from(json as Map),
    );

    if (!apiResponse.success || apiResponse.data == null) {
      throw ApiException(
        message: apiResponse.message ?? 'تعذر تحميل سياسة الخصوصية',
        statusCode: response.statusCode,
        errors: apiResponse.errors,
      );
    }

    await _cache.save(StorageKeys.legalPrivacyCache, apiResponse.data!);

    return LegalDocumentParser.parsePrivacyPolicy(
      apiResponse.data!,
      source: PrivacyPolicySource.remote,
    );
  }

  Future<PrivacyPolicyDocument> _loadCachedOrLocal() async {
    final cached = await _cache.load(StorageKeys.legalPrivacyCache);
    if (cached != null) {
      return LegalDocumentParser.parsePrivacyPolicy(
        cached,
        source: PrivacyPolicySource.cached,
      );
    }

    return PrivacyPolicyContent.buildLocalDocument().copyWithSource(
      PrivacyPolicySource.local,
    );
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

final privacyPolicyRepositoryProvider = Provider<PrivacyPolicyRepository>((
  ref,
) {
  return PrivacyPolicyRepository(
    ref.watch(apiClientProvider),
    LegalLocalCache(),
  );
});
