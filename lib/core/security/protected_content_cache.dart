import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'package:rshd/features/pdf_editor/services/pdf_cache_service.dart';

/// Clears protected offline content when the authenticated user changes or logs out.
class ProtectedContentCache {
  ProtectedContentCache._();

  static Future<void> clearAll() async {
    await PdfCacheService().clearAll();
    await _clearDirectory('pdf_annotations');
    await _clearDirectory('pdf_sessions');
    await _clearDirectory('pdf_exports');
  }

  static Future<void> clearForUser(int userId) async {
    await PdfCacheService(userId: userId).clearForUser(userId);
    await _clearUserScopedDirectory('pdf_annotations', userId);
    await _clearUserScopedDirectory('pdf_sessions', userId);
  }

  static Future<void> onUserChanged({
    required int? previousUserId,
    required int? nextUserId,
  }) async {
    if (previousUserId != null && previousUserId != nextUserId) {
      await clearForUser(previousUserId);
    }
    if (nextUserId == null) {
      await clearAll();
    }
  }

  static Future<void> _clearDirectory(String folderName) async {
    final dir = await getApplicationDocumentsDirectory();
    final folder = Directory('${dir.path}/$folderName');
    if (await folder.exists()) {
      await folder.delete(recursive: true);
    }
  }

  static Future<void> _clearUserScopedDirectory(
    String folderName,
    int userId,
  ) async {
    final dir = await getApplicationDocumentsDirectory();
    final folder = Directory('${dir.path}/$folderName/$userId');
    if (await folder.exists()) {
      await folder.delete(recursive: true);
    }
  }
}
