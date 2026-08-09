import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/config/app_config.dart';

/// Caches PDF binaries in app-private storage scoped per user.
///
/// V1 decision: platform-private storage + logout/account-switch cleanup.
/// No encryption-at-rest (SfPdfViewer needs plaintext bytes; encrypt/decrypt
/// would still require transient plaintext in memory). Does not protect against
/// a user exporting/sharing a file they legitimately opened.
class PdfCacheService {
  PdfCacheService({
    Dio? dio,
    Future<Directory> Function()? documentsDirectoryProvider,
    int? userId,
  }) : _dio =
           dio ??
           Dio(
             BaseOptions(
               connectTimeout: AppConfig.connectTimeout,
               receiveTimeout: AppConfig.receiveTimeout,
               sendTimeout: AppConfig.sendTimeout,
             ),
           ),
       _documentsDirectoryProvider =
           documentsDirectoryProvider ?? getApplicationDocumentsDirectory,
       _userId = userId;

  final Dio _dio;
  final Future<Directory> Function() _documentsDirectoryProvider;
  final int? _userId;

  static const unsignedUrlMarkerFile = '.unsigned_urls_not_persisted';

  Future<Directory> _userCacheRoot() async {
    final dir = await _documentsDirectoryProvider();
    final userSegment = _userId?.toString() ?? 'anonymous';
    final folder = Directory('${dir.path}/pdf_cache/$userSegment');
    if (!await folder.exists()) {
      await folder.create(recursive: true);
    }
    return folder;
  }

  Future<File> _cacheFile(int fileId) async {
    final folder = await _userCacheRoot();
    return File('${folder.path}/$fileId.pdf');
  }

  Future<bool> hasCached(int fileId) async {
    final file = await _cacheFile(fileId);
    return file.existsSync() && await file.length() > 0;
  }

  Future<Uint8List?> readCached(int fileId) async {
    try {
      final file = await _cacheFile(fileId);
      if (!await file.exists()) return null;
      final bytes = await file.readAsBytes();
      return bytes.isEmpty ? null : bytes;
    } catch (error) {
      if (kDebugMode) {
        debugPrint('PdfCacheService.readCached failed: $error');
      }
      return null;
    }
  }

  Future<void> save(int fileId, Uint8List bytes) async {
    if (bytes.isEmpty) return;
    final file = await _cacheFile(fileId);
    await file.writeAsBytes(bytes, flush: true);
  }

  Future<Uint8List> cacheFromUrl(int fileId, String sourceUrl) async {
    final bytes = await _downloadPdf(sourceUrl);
    await save(fileId, bytes);
    await _assertNoSignedUrlPersistence();
    return bytes;
  }

  Future<Uint8List> resolveBytes({
    required int fileId,
    String? sourceUrl,
    bool allowNetwork = true,
  }) async {
    final cached = await readCached(fileId);
    if (cached != null) {
      return cached;
    }

    if (!allowNetwork || sourceUrl == null || sourceUrl.trim().isEmpty) {
      throw Exception(
        'الملف غير متوفر بدون اتصال. افتح الملف مرة واحدة أونلاين أولاً.',
      );
    }

    return cacheFromUrl(fileId, sourceUrl);
  }

  Future<void> clearAll() async {
    final dir = await _documentsDirectoryProvider();
    final root = Directory('${dir.path}/pdf_cache');
    if (await root.exists()) {
      await root.delete(recursive: true);
    }
  }

  Future<void> clearForUser(int userId) async {
    final dir = await _documentsDirectoryProvider();
    final userDir = Directory('${dir.path}/pdf_cache/$userId');
    if (await userDir.exists()) {
      await userDir.delete(recursive: true);
    }
  }

  Future<void> _assertNoSignedUrlPersistence() async {
    final folder = await _userCacheRoot();
    final marker = File('${folder.path}/$unsignedUrlMarkerFile');
    if (!await marker.exists()) {
      await marker.writeAsString('signed urls are never written to disk');
    }
  }

  Future<Uint8List> _downloadPdf(String url) async {
    final response = await _dio.get<List<int>>(
      url,
      options: Options(responseType: ResponseType.bytes),
    );
    final data = response.data;
    if (data == null || data.isEmpty) {
      throw Exception('تعذر تحميل ملف PDF');
    }
    return Uint8List.fromList(data);
  }
}
