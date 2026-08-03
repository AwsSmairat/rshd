import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Persists annotation drafts and reading session locally for offline use.
class AnnotationLocalCache {
  Future<File> _annotationFile(int fileId) async {
    final dir = await getApplicationDocumentsDirectory();
    final folder = Directory('${dir.path}/pdf_annotations');
    if (!await folder.exists()) {
      await folder.create(recursive: true);
    }
    return File('${folder.path}/$fileId.json');
  }

  Future<File> _sessionFile(int fileId) async {
    final dir = await getApplicationDocumentsDirectory();
    final folder = Directory('${dir.path}/pdf_sessions');
    if (!await folder.exists()) {
      await folder.create(recursive: true);
    }
    return File('${folder.path}/$fileId.json');
  }

  Future<Map<String, dynamic>?> loadAnnotations(int fileId) async {
    try {
      final file = await _annotationFile(fileId);
      if (!await file.exists()) return null;
      final content = await file.readAsString();
      final decoded = jsonDecode(content);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (error) {
      if (kDebugMode) {
        debugPrint('AnnotationLocalCache.load failed: $error');
      }
    }
    return null;
  }

  Future<void> saveAnnotations(int fileId, Map<String, dynamic> json) async {
    try {
      final file = await _annotationFile(fileId);
      final payload = {
        ...json,
        'cached_at': DateTime.now().toIso8601String(),
        'pending_sync': json['pending_sync'] ?? false,
      };
      await file.writeAsString(jsonEncode(payload));
    } catch (error) {
      if (kDebugMode) {
        debugPrint('AnnotationLocalCache.save failed: $error');
      }
      rethrow;
    }
  }

  Future<void> markSynced(int fileId) async {
    final cached = await loadAnnotations(fileId);
    if (cached == null) return;
    cached['pending_sync'] = false;
    cached['last_synced_at'] = DateTime.now().toIso8601String();
    await saveAnnotations(fileId, cached);
  }

  Future<PdfReadingSession?> loadSession(int fileId) async {
    try {
      final file = await _sessionFile(fileId);
      if (!await file.exists()) return null;
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is Map<String, dynamic>) {
        return PdfReadingSession.fromJson(decoded);
      }
    } catch (_) {}
    return null;
  }

  Future<void> saveSession(int fileId, PdfReadingSession session) async {
    final file = await _sessionFile(fileId);
    await file.writeAsString(jsonEncode(session.toJson()));
  }
}

class PdfReadingSession {
  const PdfReadingSession({
    required this.pageNumber,
    required this.zoomLevel,
  });

  final int pageNumber;
  final double zoomLevel;

  Map<String, dynamic> toJson() => {
        'page_number': pageNumber,
        'zoom_level': zoomLevel,
      };

  factory PdfReadingSession.fromJson(Map<String, dynamic> json) {
    return PdfReadingSession(
      pageNumber: json['page_number'] is int
          ? json['page_number'] as int
          : int.tryParse('${json['page_number']}') ?? 1,
      zoomLevel: json['zoom_level'] is num
          ? (json['zoom_level'] as num).toDouble()
          : double.tryParse('${json['zoom_level']}') ?? 1,
    );
  }
}
