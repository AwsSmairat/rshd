import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/storage_keys.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/api_response.dart';
import '../../shared/legal_document_parser.dart';
import '../../shared/legal_local_cache.dart';
import 'terms_and_conditions_content.dart';
import 'terms_and_conditions_model.dart';

class TermsAndConditionsRepository {
  TermsAndConditionsRepository(this._client, this._cache);

  final ApiClient _client;
  final LegalLocalCache _cache;

  TermsDocument? _memoryCached;
  TermsAcceptanceStatus? _acceptanceStatus;

  Future<TermsDocument> fetch({bool forceRefresh = false}) async {
    if (!forceRefresh && _memoryCached != null) {
      return _memoryCached!.copyWithSource(TermsSource.cached);
    }

    try {
      final status = await fetchAcceptanceStatus();
      final document = await _fetchRemote(status);
      _memoryCached = document;
      return document;
    } on ApiException catch (error) {
      if (_isOfflineError(error)) {
        return _loadCachedOrLocal(status: _acceptanceStatus);
      }
      rethrow;
    } on DioException catch (error) {
      if (_isDioOffline(error)) {
        return _loadCachedOrLocal(status: _acceptanceStatus);
      }
      rethrow;
    } catch (_) {
      return _loadCachedOrLocal(status: _acceptanceStatus);
    }
  }

  Future<TermsAcceptanceStatus?> fetchAcceptanceStatus() async {
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
      _acceptanceStatus = TermsAcceptanceStatus(
        accepted: data['accepted'] == true,
        currentVersion: data['current_version']?.toString() ?? '',
        requiresAcceptance: data['requires_acceptance'] == true,
        acceptedVersion: data['accepted_version']?.toString(),
        acceptedAt: data['accepted_at']?.toString(),
        lastUpdated: data['last_updated']?.toString(),
      );
      return _acceptanceStatus;
    } catch (_) {
      return null;
    }
  }

  Future<TermsDocument> _fetchRemote(TermsAcceptanceStatus? status) async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiEndpoints.legalTerms,
    );

    final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
      Map<String, dynamic>.from(response.data as Map),
      (json) => Map<String, dynamic>.from(json as Map),
    );

    if (!apiResponse.success || apiResponse.data == null) {
      throw ApiException(
        message: apiResponse.message ?? 'تعذر تحميل الشروط والأحكام',
        statusCode: response.statusCode,
        errors: apiResponse.errors,
      );
    }

    await _cache.save(StorageKeys.legalTermsCache, apiResponse.data!);

    return LegalDocumentParser.parseTerms(
      apiResponse.data!,
      source: TermsSource.remote,
      requiresAcceptance: status?.requiresAcceptance ?? false,
      acceptedVersion: status?.acceptedVersion,
    );
  }

  Future<TermsDocument> _loadCachedOrLocal({TermsAcceptanceStatus? status}) async {
    final cached = await _cache.load(StorageKeys.legalTermsCache);
    if (cached != null) {
      return LegalDocumentParser.parseTerms(
        cached,
        source: TermsSource.cached,
        requiresAcceptance: status?.requiresAcceptance ?? false,
        acceptedVersion: status?.acceptedVersion,
      );
    }

    return TermsAndConditionsContent.buildLocalDocument(
      requiresAcceptance: status?.requiresAcceptance ?? false,
      acceptedVersion: status?.acceptedVersion,
    );
  }

  Future<void> acceptTerms() async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiEndpoints.studentTermsAccept,
      data: const {'platform': 'flutter'},
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

    if (apiResponse.data != null) {
      final data = apiResponse.data!;
      _acceptanceStatus = TermsAcceptanceStatus(
        accepted: data['accepted'] == true,
        currentVersion: data['current_version']?.toString() ?? '',
        requiresAcceptance: data['requires_acceptance'] == true,
        acceptedVersion: data['accepted_version']?.toString(),
        acceptedAt: data['accepted_at']?.toString(),
        lastUpdated: data['last_updated']?.toString(),
      );
    }

    _memoryCached = null;
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
  return TermsAndConditionsRepository(
    ref.watch(apiClientProvider),
    LegalLocalCache(),
  );
});

final termsAcceptanceStatusProvider =
    FutureProvider<TermsAcceptanceStatus?>((ref) async {
  return ref.watch(termsAndConditionsRepositoryProvider).fetchAcceptanceStatus();
});
