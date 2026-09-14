import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'package:rshd/features/pdf_editor/services/pdf_cache_service.dart';
import 'package:rshd/features/settings/data/student_avatar_store.dart';

/// Clears protected offline content when the authenticated user changes or logs out.
class ProtectedContentCache {
  ProtectedContentCache._();

  static Future<void> clearAll({
    Future<Directory> Function()? documentsDirectoryProvider,
  }) async {
    await StudentAvatarStore(
      documentsDirectoryProvider: documentsDirectoryProvider,
    ).clear();
    await PdfCacheService(
      documentsDirectoryProvider: documentsDirectoryProvider,
    ).clearAll();
    await _clearDirectory(
      'pdf_annotations',
      documentsDirectoryProvider: documentsDirectoryProvider,
    );
    await _clearDirectory(
      'pdf_sessions',
      documentsDirectoryProvider: documentsDirectoryProvider,
    );
    await _clearDirectory(
      'pdf_exports',
      documentsDirectoryProvider: documentsDirectoryProvider,
    );
  }

  static Future<void> clearForUser(
    int userId, {
    Future<Directory> Function()? documentsDirectoryProvider,
  }) async {
    // The avatar cache currently uses one device-local filename rather than a
    // user-scoped path, so it must be removed whenever the user changes.
    await StudentAvatarStore(
      documentsDirectoryProvider: documentsDirectoryProvider,
    ).clear();
    await PdfCacheService(
      userId: userId,
      documentsDirectoryProvider: documentsDirectoryProvider,
    ).clearForUser(userId);
    await _clearUserScopedDirectory(
      'pdf_annotations',
      userId,
      documentsDirectoryProvider: documentsDirectoryProvider,
    );
    await _clearUserScopedDirectory(
      'pdf_sessions',
      userId,
      documentsDirectoryProvider: documentsDirectoryProvider,
    );
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

  static Future<void> _clearDirectory(
    String folderName, {
    Future<Directory> Function()? documentsDirectoryProvider,
  }) async {
    final dir =
        await (documentsDirectoryProvider ??
            getApplicationDocumentsDirectory)();
    final folder = Directory('${dir.path}/$folderName');
    if (await folder.exists()) {
      await folder.delete(recursive: true);
    }
  }

  static Future<void> _clearUserScopedDirectory(
    String folderName,
    int userId, {
    Future<Directory> Function()? documentsDirectoryProvider,
  }) async {
    final dir =
        await (documentsDirectoryProvider ??
            getApplicationDocumentsDirectory)();
    final folder = Directory('${dir.path}/$folderName/$userId');
    if (await folder.exists()) {
      await folder.delete(recursive: true);
    }
  }
}
