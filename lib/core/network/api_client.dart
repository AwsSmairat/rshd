import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../storage/secure_storage_service.dart';
import 'api_endpoints.dart';
import 'api_exception.dart';
import 'redacted_log_interceptor.dart';
import 'session_invalidation.dart';

class ApiClient {
  ApiClient({
    required SecureStorageService secureStorage,
    Dio? dio,
    void Function()? onUnauthorized,
  }) : _secureStorage = secureStorage,
       _onUnauthorized = onUnauthorized {
    _dio =
        dio ??
        Dio(
          BaseOptions(
            baseUrl: AppConfig.baseUrl,
            connectTimeout: AppConfig.connectTimeout,
            receiveTimeout: AppConfig.receiveTimeout,
            sendTimeout: AppConfig.sendTimeout,
            headers: const {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
          ),
        );

    _dio.interceptors.add(
      InterceptorsWrapper(onRequest: _onRequest, onError: _onError),
    );

    if (AppConfig.enableNetworkLogs) {
      _dio.interceptors.add(RedactedLogInterceptor());
    }
  }

  final SecureStorageService _secureStorage;
  final void Function()? _onUnauthorized;
  late final Dio _dio;

  Dio get dio => _dio;

  Future<void> _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _secureStorage.getToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  void _onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) {
    if (err.response?.statusCode == 401 &&
        err.requestOptions.path != ApiEndpoints.logout &&
        _hasBearerAuthorization(err.requestOptions)) {
      _onUnauthorized?.call();
    }

    handler.next(err);
  }

  bool _hasBearerAuthorization(RequestOptions options) {
    final authorization = options.headers['Authorization']?.toString();
    return authorization != null &&
        authorization.startsWith('Bearer ') &&
        authorization.length > 'Bearer '.length;
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) {
    return _request(() => _dio.get<T>(path, queryParameters: queryParameters));
  }

  Future<Response<T>> post<T>(String path, {dynamic data}) {
    return _request(() => _dio.post<T>(path, data: data));
  }

  Future<Response<T>> patch<T>(String path, {dynamic data}) {
    return _request(() => _dio.patch<T>(path, data: data));
  }

  Future<Response<T>> delete<T>(String path, {dynamic data}) {
    return _request(() => _dio.delete<T>(path, data: data));
  }

  Future<Response<T>> _request<T>(Future<Response<T>> Function() call) async {
    try {
      return await call();
    } on DioException catch (error) {
      throw _mapDioException(error);
    } catch (_) {
      throw ApiException(message: 'خطأ غير متوقع. يرجى المحاولة لاحقاً.');
    }
  }

  ApiException _mapDioException(DioException error) {
    final response = error.response;
    final statusCode = response?.statusCode;
    final payload = _extractPayload(response?.data);

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.connectionError) {
      return ApiException(
        message: 'لا يوجد اتصال بالسيرفر. تحقق من الاتصال وحاول مرة أخرى.',
        statusCode: statusCode,
      );
    }

    if (payload != null) {
      final message =
          payload['message']?.toString() ??
          _defaultMessageForStatus(statusCode);

      return ApiException(
        message: message,
        statusCode: statusCode,
        errors: payload['errors'] is Map
            ? Map<String, dynamic>.from(payload['errors'] as Map)
            : null,
        data: payload['data'] is Map
            ? Map<String, dynamic>.from(payload['data'] as Map)
            : null,
        errorCode: payload['error_code']?.toString(),
      );
    }

    return ApiException(
      message: _defaultMessageForStatus(statusCode),
      statusCode: statusCode,
    );
  }

  Map<String, dynamic>? _extractPayload(dynamic data) {
    if (data == null) {
      return null;
    }

    if (data is Map<String, dynamic>) {
      return data;
    }

    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    if (data is String && data.trim().startsWith('{')) {
      try {
        final decoded = jsonDecode(data);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
        if (decoded is Map) {
          return Map<String, dynamic>.from(decoded);
        }
      } catch (_) {
        return null;
      }
    }

    return null;
  }

  String _defaultMessageForStatus(int? statusCode) {
    return switch (statusCode) {
      401 => 'غير مصرح. يرجى تسجيل الدخول.',
      403 => 'غير مصرح لك بالوصول.',
      404 => 'المورد غير موجود.',
      422 => 'The given data was invalid.',
      500 => 'خطأ في السيرفر. يرجى المحاولة لاحقاً.',
      _ => 'خطأ غير متوقع. يرجى المحاولة لاحقاً.',
    };
  }
}

final secureStorageProvider = Provider<SecureStorageService>(
  (ref) => SecureStorageService(),
);

final apiClientProvider = Provider<ApiClient>((ref) {
  final storage = ref.watch(secureStorageProvider);
  final sessionInvalidation = ref.read(sessionInvalidationProvider.notifier);

  return ApiClient(
    secureStorage: storage,
    onUnauthorized: sessionInvalidation.notifyUnauthorized,
  );
});
