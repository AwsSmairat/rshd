/// Builds safe export filenames for annotated PDFs.
class PdfExportFilename {
  static String build({
    String? courseTitle,
    required String documentTitle,
    DateTime? exportedAt,
  }) {
    final date = (exportedAt ?? DateTime.now()).toIso8601String().substring(
      0,
      10,
    );
    final course = sanitizeSegment(courseTitle);
    final document = sanitizeSegment(documentTitle);

    if (course.isNotEmpty && document.isNotEmpty) {
      return '${course}_${document}_annotated_$date.pdf';
    }
    if (document.isNotEmpty) {
      return '${document}_annotated_$date.pdf';
    }
    return 'annotated_$date.pdf';
  }

  /// Removes characters that are unsafe on common mobile/desktop filesystems.
  static String sanitizeSegment(String? input) {
    if (input == null) return '';
    var value = input.trim();
    if (value.isEmpty) return '';

    value = value.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    value = value.replaceAll(RegExp(r'\s+'), '_');
    value = value.replaceAll(RegExp(r'_+'), '_');
    value = value.replaceAll(RegExp(r'^_|_$'), '');

    return value;
  }
}
