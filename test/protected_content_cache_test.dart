import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:rshd/core/security/protected_content_cache.dart';
import 'package:rshd/features/settings/data/student_avatar_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  Future<Directory> tempDocumentsDir() async => tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'rshd_protected_content_cache_test',
    );
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('clearAll removes cached student avatar', () async {
    final avatarStore = StudentAvatarStore(
      documentsDirectoryProvider: tempDocumentsDir,
    );

    final path = await avatarStore.saveFromBytes(
      Uint8List.fromList([1, 2, 3, 4]),
    );

    expect(await File(path).exists(), isTrue);
    expect(await avatarStore.existingPath(), path);

    await ProtectedContentCache.clearAll(
      documentsDirectoryProvider: tempDocumentsDir,
    );

    expect(await File(path).exists(), isFalse);
    expect(await avatarStore.existingPath(), isNull);
  });
}
