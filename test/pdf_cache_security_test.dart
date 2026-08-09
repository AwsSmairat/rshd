import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:rshd/features/pdf_editor/services/pdf_cache_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  Future<Directory> tempDocumentsDir() async => tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('rshd_pdf_cache_test');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('pdf cache is scoped per user and cleared on logout', () async {
    final userOneCache = PdfCacheService(
      userId: 1,
      documentsDirectoryProvider: tempDocumentsDir,
    );
    final userTwoCache = PdfCacheService(
      userId: 2,
      documentsDirectoryProvider: tempDocumentsDir,
    );

    await userOneCache.save(10, Uint8List.fromList([1, 2, 3]));
    await userTwoCache.save(10, Uint8List.fromList([4, 5, 6]));

    expect(await userOneCache.hasCached(10), isTrue);
    expect(await userTwoCache.hasCached(10), isTrue);

    await PdfCacheService(
      documentsDirectoryProvider: tempDocumentsDir,
    ).clearAll();

    expect(await userOneCache.hasCached(10), isFalse);
    expect(await userTwoCache.hasCached(10), isFalse);
  });

  test('account switch clears previous user cache only', () async {
    final userOneCache = PdfCacheService(
      userId: 11,
      documentsDirectoryProvider: tempDocumentsDir,
    );
    final userTwoCache = PdfCacheService(
      userId: 22,
      documentsDirectoryProvider: tempDocumentsDir,
    );

    await userOneCache.save(7, Uint8List.fromList([9]));
    await userTwoCache.save(7, Uint8List.fromList([8]));

    await userOneCache.clearForUser(11);

    expect(await userOneCache.hasCached(7), isFalse);
    expect(await userTwoCache.hasCached(7), isTrue);
  });

  test('cache root lives under app documents pdf_cache path', () async {
    final cache = PdfCacheService(
      userId: 99,
      documentsDirectoryProvider: tempDocumentsDir,
    );

    await cache.save(1, Uint8List.fromList([1]));

    final cacheFile = File('${tempDir.path}/pdf_cache/99/1.pdf');
    expect(await cacheFile.exists(), isTrue);
    expect(cacheFile.path.contains('/pdf_cache/99/'), isTrue);
  });
}
