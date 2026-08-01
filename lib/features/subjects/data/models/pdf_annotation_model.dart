class PdfAnnotationModel {
  const PdfAnnotationModel({
    required this.fileId,
    required this.annotationJson,
    this.updatedAt,
  });

  final int fileId;
  final Map<String, dynamic> annotationJson;
  final String? updatedAt;

  factory PdfAnnotationModel.fromJson(Map<String, dynamic> json) {
    final raw = json['annotation_json'];

    return PdfAnnotationModel(
      fileId: _asInt(json['file_id']),
      annotationJson: raw is Map
          ? Map<String, dynamic>.from(raw)
          : PdfAnnotationDocument.empty(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  static int _asInt(dynamic value, [int fallback = 0]) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse('$value') ?? fallback;
  }
}

/// Helper for reading/writing the annotation JSON structure.
///
/// TODO: Improve page coordinate mapping for multi-page PDF.
class PdfAnnotationDocument {
  PdfAnnotationDocument([Map<String, dynamic>? json])
      : _root = _normalize(json);

  final Map<String, dynamic> _root;

  static Map<String, dynamic> empty() => {
        'pages': <String, dynamic>{},
      };

  static Map<String, dynamic> _normalize(Map<String, dynamic>? json) {
    if (json == null || json.isEmpty) {
      return empty();
    }

    if (json.containsKey('pages') && json['pages'] is Map) {
      return Map<String, dynamic>.from(json);
    }

    return empty();
  }

  Map<String, dynamic> toJson() => Map<String, dynamic>.from(_root);

  Map<String, dynamic> pageData(int pageNumber) {
    final pages = _root.putIfAbsent('pages', () => <String, dynamic>{})
        as Map<String, dynamic>;
    final key = '$pageNumber';

    if (!pages.containsKey(key) || pages[key] is! Map) {
      pages[key] = _emptyPage();
    }

    return pages[key] as Map<String, dynamic>;
  }

  void setPageData(int pageNumber, Map<String, dynamic> data) {
    final pages = _root.putIfAbsent('pages', () => <String, dynamic>{})
        as Map<String, dynamic>;
    pages['$pageNumber'] = data;
  }

  Map<String, dynamic>? getPage(int pageNumber) {
    final pages = _root['pages'];
    if (pages is! Map) {
      return null;
    }

    final page = pages['$pageNumber'];
    if (page is! Map) {
      return null;
    }

    return Map<String, dynamic>.from(page);
  }

  static Map<String, dynamic> _emptyPage() => {
        'notes': <dynamic>[],
        'drawings': <dynamic>[],
        'highlights': <dynamic>[],
      };

  static String newId() => DateTime.now().microsecondsSinceEpoch.toString();

  static List<Map<String, dynamic>> listOf(Map<String, dynamic>? page, String key) {
    final value = page?[key];
    if (value is! List) {
      return [];
    }

    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }
}
