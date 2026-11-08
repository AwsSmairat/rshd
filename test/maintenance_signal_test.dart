import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rshd/core/network/api_client.dart';
import 'package:rshd/core/storage/secure_storage_service.dart';

class _Storage extends SecureStorageService {
  @override
  Future<String?> getToken() async => 'token';
}

class _Adapter implements HttpClientAdapter {
  _Adapter(this.statusCode, this.body);

  final int statusCode;
  final String body;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      body,
      statusCode,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Future<int> _maintenanceCalls(int statusCode, String body) async {
  var calls = 0;
  final dio = Dio(BaseOptions(baseUrl: 'https://example.test'))
    ..httpClientAdapter = _Adapter(statusCode, body);
  final client = ApiClient(
    secureStorage: _Storage(),
    dio: dio,
    onMaintenance: () => calls++,
  );
  try {
    await client.get<Map<String, dynamic>>('/me');
  } catch (_) {
    // The request itself fails; only the signal matters here.
  }
  return calls;
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  test('a maintenance reply from the server raises the signal', () async {
    expect(
      await _maintenanceCalls(
        503,
        '{"success":false,"maintenance":true,"message":"صيانة"}',
      ),
      1,
    );
  });

  test('other server errors do not', () async {
    expect(await _maintenanceCalls(503, '{"message":"busy"}'), 0);
    expect(await _maintenanceCalls(500, '{"maintenance":true}'), 0);
  });
}
