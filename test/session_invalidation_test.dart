import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rshd/core/device/device_service.dart';
import 'package:rshd/core/network/api_client.dart';
import 'package:rshd/core/network/api_endpoints.dart';
import 'package:rshd/core/network/api_exception.dart';
import 'package:rshd/core/network/session_invalidation.dart';
import 'package:rshd/core/storage/secure_storage_service.dart';
import 'package:rshd/features/auth/data/auth_repository.dart';
import 'package:rshd/features/auth/presentation/auth_controller.dart';

class _TokenStorage extends SecureStorageService {
  _TokenStorage(this.token);

  final String? token;

  @override
  Future<String?> getToken() async => token;
}

class _StaticResponseAdapter implements HttpClientAdapter {
  _StaticResponseAdapter(this.statusCode);

  final int statusCode;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      '{"message":"test response"}',
      statusCode,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

ApiClient _client({
  required String? token,
  required int statusCode,
  required void Function() onUnauthorized,
}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://example.test',
      headers: const {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ),
  );

  dio.httpClientAdapter = _StaticResponseAdapter(statusCode);

  return ApiClient(
    secureStorage: _TokenStorage(token),
    dio: dio,
    onUnauthorized: onUnauthorized,
  );
}

class _FakeAuthRepository extends AuthRepository {
  _FakeAuthRepository()
    : super(
        apiClient: ApiClient(secureStorage: SecureStorageService()),
        secureStorage: SecureStorageService(),
        deviceService: DeviceService(secureStorage: SecureStorageService()),
      );

  int clearLocalSessionCalls = 0;

  @override
  Future<void> clearLocalSession() async {
    clearLocalSessionCalls++;
  }
}

void main() {
  test('authenticated 401 emits session invalidation', () async {
    var invalidations = 0;

    final client = _client(
      token: 'valid-looking-token',
      statusCode: 401,
      onUnauthorized: () => invalidations++,
    );

    await expectLater(
      client.get<Map<String, dynamic>>('/protected'),
      throwsA(isA<ApiException>()),
    );

    expect(invalidations, 1);
  });

  test('401 without bearer token does not invalidate session', () async {
    var invalidations = 0;

    final client = _client(
      token: null,
      statusCode: 401,
      onUnauthorized: () => invalidations++,
    );

    await expectLater(
      client.get<Map<String, dynamic>>('/public-or-login'),
      throwsA(isA<ApiException>()),
    );

    expect(invalidations, 0);
  });

  test('authenticated 403 does not invalidate session', () async {
    var invalidations = 0;

    final client = _client(
      token: 'valid-looking-token',
      statusCode: 403,
      onUnauthorized: () => invalidations++,
    );

    await expectLater(
      client.get<Map<String, dynamic>>('/protected'),
      throwsA(isA<ApiException>()),
    );

    expect(invalidations, 0);
  });

  test('logout 401 does not emit duplicate invalidation', () async {
    var invalidations = 0;

    final client = _client(
      token: 'expired-token',
      statusCode: 401,
      onUnauthorized: () => invalidations++,
    );

    await expectLater(
      client.post<Map<String, dynamic>>(ApiEndpoints.logout),
      throwsA(isA<ApiException>()),
    );

    expect(invalidations, 0);
  });

  test('session signal clears locally and unauthenticates once', () async {
    final repository = _FakeAuthRepository();

    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    // Instantiate AuthController so its invalidation listener is active.
    container.read(authControllerProvider);

    final notifier = container.read(sessionInvalidationProvider.notifier);
    notifier.notifyUnauthorized();
    notifier.notifyUnauthorized();

    await Future<void>.delayed(Duration.zero);

    expect(
      container.read(authControllerProvider).status,
      AuthStatus.unauthenticated,
    );
    expect(repository.clearLocalSessionCalls, 1);
  });
}
