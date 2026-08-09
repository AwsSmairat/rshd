import 'dart:io';

import 'package:share_plus/share_plus.dart';

/// Shares exported PDF files through the native share sheet.
class PdfShareService {
  Future<void> shareExportedPdf({
    required File file,
    String? subject,
    String? text,
  }) async {
    if (!await file.exists()) {
      throw Exception('ملف التصدير غير موجود');
    }

    final fileName = file.uri.pathSegments.isNotEmpty
        ? file.uri.pathSegments.last
        : 'annotated.pdf';

    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/pdf', name: fileName)],
      subject: subject,
      text: text ?? 'ملف PDF مع التعليقات',
    );
  }
}
