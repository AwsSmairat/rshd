import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/painting.dart';
import 'package:path_provider/path_provider.dart';

/// Keeps a local copy of the student's avatar so the UI never has to fetch
/// the public `/storage` URL (staging currently answers 403 for those).
class StudentAvatarStore {
  StudentAvatarStore({Future<Directory> Function()? documentsDirectoryProvider})
    : _documentsDirectoryProvider =
          documentsDirectoryProvider ?? getApplicationDocumentsDirectory;

  final Future<Directory> Function() _documentsDirectoryProvider;

  Future<File> _file() async {
    final directory = await _documentsDirectoryProvider();
    return File('${directory.path}/student_avatar.jpg');
  }

  Future<String?> existingPath() async {
    final file = await _file();
    if (await file.exists() && await file.length() > 0) {
      return file.path;
    }
    return null;
  }

  Future<String> saveFromPath(String sourcePath) async {
    // Read bytes instead of File.copy: iOS picker paths are often
    // security-scoped and copy() fails, after which the tmp file vanishes.
    final bytes = await File(sourcePath).readAsBytes();
    return saveFromBytes(bytes);
  }

  Future<String> saveFromBytes(Uint8List bytes) async {
    if (bytes.isEmpty) {
      throw const FormatException('empty avatar');
    }
    final destination = await _file();
    await destination.writeAsBytes(bytes, flush: true);
    await FileImage(destination).evict();
    return destination.path;
  }

  Future<void> clear() async {
    final file = await _file();
    if (await file.exists()) {
      await FileImage(file).evict();
      await file.delete();
    }
  }
}
