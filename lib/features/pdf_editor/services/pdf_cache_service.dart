import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Caches PDF binaries locally so viewing/export can work offline.
class PdfCacheService {
  PdfCacheService({
    Dio? dio,
    Future<Directory> Function()? documentsDirectoryProvider,
  })  : _dio = dio ?? Dio(),
        _documentsDirectoryProvider =
            documentsDirectoryProvider ?? getApplicationDocumentsDirectory;

  final Dio _dio;
  final Future<Directory> Function() _documentsDirectoryProvider;

  Future<Directory> _cacheDirectory() async {
    final dir = await _documentsDirectoryProvider();
    final folder = Directory('${dir.path}/pdf_cache');
    if (!await folder.exists()) {
      await folder.create(recursive: true);
    }
    return folder;
  }

  Future<File> _cacheFile(int fileId) async {
    final folder = await _cacheDirectory();
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
      throw Exception('الملف غير متوفر بدون اتصال. افتح الملف مرة واحدة أونلاين أولاً.');
    }

    return cacheFromUrl(fileId, sourceUrl);
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
