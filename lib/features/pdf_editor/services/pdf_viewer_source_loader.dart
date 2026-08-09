import 'dart:typed_data';

import '../../subjects/data/subjects_repository.dart';
import 'pdf_cache_service.dart';

class PdfViewerSourceLoader {
  PdfViewerSourceLoader({
    PdfCacheService? cacheService,
    SubjectsRepository? repository,
    int? userId,
  }) : _cacheService = cacheService ?? PdfCacheService(userId: userId),
       _repository = repository;

  final PdfCacheService _cacheService;
  final SubjectsRepository? _repository;

  Future<Uint8List> load({
    required int fileId,
    SubjectsRepository? repository,
    bool allowNetwork = true,
  }) async {
    final cached = await _cacheService.readCached(fileId);
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }

    if (!allowNetwork) {
      throw Exception(
        'الملف غير متوفر بدون اتصال. افتح الملف مرة واحدة أونلاين أولاً.',
      );
    }

    final repo = repository ?? _repository;
    if (repo == null) {
      throw Exception('تعذر تحميل ملف PDF');
    }

    final download = await repo.getFileDownloadUrl(fileId);
    if (download.url.trim().isEmpty) {
      throw Exception('تعذر تحميل ملف PDF');
    }

    return _cacheService.cacheFromUrl(fileId, download.url);
  }

  Future<bool> hasCached(int fileId) => _cacheService.hasCached(fileId);
}
