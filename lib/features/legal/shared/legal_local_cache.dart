import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Persists the last successfully fetched legal document JSON on disk.
class LegalLocalCache {
  LegalLocalCache({Directory? directory}) : _directory = directory;

  Directory? _directory;

  Future<Directory> _resolveDirectory() async {
    return _directory ??= await getApplicationDocumentsDirectory();
  }

  Future<void> save(String key, Map<String, dynamic> payload) async {
    final dir = await _resolveDirectory();
    final file = File('${dir.path}/$key.json');
    await file.writeAsString(jsonEncode(payload));
  }

  Future<Map<String, dynamic>?> load(String key) async {
    try {
      final dir = await _resolveDirectory();
      final file = File('${dir.path}/$key.json');
      if (!await file.exists()) {
        return null;
      }

      final decoded = jsonDecode(await file.readAsString());
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> clear(String key) async {
    try {
      final dir = await _resolveDirectory();
      final file = File('${dir.path}/$key.json');
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }
}
