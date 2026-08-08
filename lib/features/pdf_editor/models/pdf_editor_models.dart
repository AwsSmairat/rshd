import 'dart:math';
import 'dart:math' as math;

import 'annotation_enums.dart';

/// Normalized point (0–1) relative to PDF page dimensions.
class NormalizedPoint {
  const NormalizedPoint(this.nx, this.ny);

  final double nx;
  final double ny;

  Map<String, dynamic> toJson() => {'nx': nx, 'ny': ny};

  factory NormalizedPoint.fromJson(Map<String, dynamic> json) {
    return NormalizedPoint(
      _asDouble(json['nx'] ?? json['x']),
      _asDouble(json['ny'] ?? json['y']),
    );
  }

  static double _asDouble(dynamic value, [double fallback = 0]) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse('$value') ?? fallback;
  }
}

class PdfEditorAnnotation {
  PdfEditorAnnotation({
    required this.id,
    required this.type,
    required this.pageNumber,
    this.x = 0,
    this.y = 0,
    this.width = 0,
    this.height = 0,
    this.rotation = 0,
    this.createdAt,
    this.updatedAt,
    this.data = const {},
  });

  final String id;
  final AnnotationType type;
  final int pageNumber;
  final double x;
  final double y;
  final double width;
  final double height;
  final double rotation;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic> data;

  PdfEditorAnnotation copyWith({
    String? id,
    AnnotationType? type,
    int? pageNumber,
    double? x,
    double? y,
    double? width,
    double? height,
    double? rotation,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? data,
  }) {
    return PdfEditorAnnotation(
      id: id ?? this.id,
      type: type ?? this.type,
      pageNumber: pageNumber ?? this.pageNumber,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      rotation: rotation ?? this.rotation,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      data: data ?? Map<String, dynamic>.from(this.data),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'pageNumber': pageNumber,
        'x': x,
        'y': y,
        'width': width,
        'height': height,
        'rotation': rotation,
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
        ...data,
      };

  factory PdfEditorAnnotation.fromJson(Map<String, dynamic> json) {
    return PdfEditorAnnotation(
      id: json['id']?.toString() ?? PdfAnnotationDocumentV2.newId(),
      type: AnnotationType.values.firstWhere(
        (value) => value.name == json['type'],
        orElse: () => AnnotationType.ink,
      ),
      pageNumber: _asInt(json['pageNumber'] ?? json['page_number'], 1),
      x: _asDouble(json['x']),
      y: _asDouble(json['y']),
      width: _asDouble(json['width']),
      height: _asDouble(json['height']),
      rotation: _asDouble(json['rotation']),
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
      data: _extractData(json),
    );
  }

  static Map<String, dynamic> _extractData(Map<String, dynamic> json) {
    const reserved = {
      'id',
      'type',
      'pageNumber',
      'page_number',
      'x',
      'y',
      'width',
      'height',
      'rotation',
      'created_at',
      'updated_at',
    };
    return Map<String, dynamic>.fromEntries(
      json.entries.where((entry) => !reserved.contains(entry.key)),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  static double _asDouble(dynamic value, [double fallback = 0]) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse('$value') ?? fallback;
  }

  static int _asInt(dynamic value, [int fallback = 0]) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? fallback;
  }
}

/// V2 annotation document with normalized page coordinates.
class PdfAnnotationDocumentV2 {
  PdfAnnotationDocumentV2([Map<String, dynamic>? json])
      : _root = _normalize(json);

  final Map<String, dynamic> _root;

  static const int currentVersion = 2;

  static Map<String, dynamic> empty({int? documentId}) => {
        'version': currentVersion,
        if (documentId != null) 'document_id': documentId,
        'pages': <String, dynamic>{},
      };

  static Map<String, dynamic> _normalize(Map<String, dynamic>? json) {
    if (json == null || json.isEmpty) {
      return empty();
    }
    if (json['version'] == currentVersion && json['pages'] is Map) {
      return Map<String, dynamic>.from(json);
    }
    return migrateFromLegacy(json);
  }

  int get version => _asInt(_root['version'], 1);

  Map<String, dynamic> toJson() => Map<String, dynamic>.from(_root);

  Map<String, dynamic> pageMeta(int pageNumber) {
    final pages = _pagesMap();
    final key = '$pageNumber';
    if (!pages.containsKey(key) || pages[key] is! Map) {
      pages[key] = _emptyPage();
    }
    return pages[key] as Map<String, dynamic>;
  }

  void ensurePageSize(int pageNumber, double width, double height) {
    final page = pageMeta(pageNumber);
    page['page_width'] ??= width;
    page['page_height'] ??= height;
  }

  double pageWidth(int pageNumber) =>
      _asDouble(pageMeta(pageNumber)['page_width'], 595);

  double pageHeight(int pageNumber) =>
      _asDouble(pageMeta(pageNumber)['page_height'], 842);

  List<PdfEditorAnnotation> annotationsForPage(int pageNumber) {
    final page = pageMeta(pageNumber);
    final raw = page['annotations'];
    if (raw is! List) return [];

    return raw
        .whereType<Map>()
        .map((item) => PdfEditorAnnotation.fromJson(
              Map<String, dynamic>.from(item),
            ))
        .toList();
  }

  void setAnnotationsForPage(int pageNumber, List<PdfEditorAnnotation> items) {
    final page = pageMeta(pageNumber);
    page['annotations'] = items.map((item) => item.toJson()).toList();
  }

  void addAnnotation(PdfEditorAnnotation annotation) {
    final items = annotationsForPage(annotation.pageNumber);
    items.add(annotation);
    setAnnotationsForPage(annotation.pageNumber, items);
  }

  void updateAnnotation(PdfEditorAnnotation annotation) {
    final items = annotationsForPage(annotation.pageNumber);
    final index = items.indexWhere((item) => item.id == annotation.id);
    if (index >= 0) {
      items[index] = annotation;
      setAnnotationsForPage(annotation.pageNumber, items);
    }
  }

  void removeAnnotation(String id, int pageNumber) {
    final items = annotationsForPage(pageNumber)
      ..removeWhere((item) => item.id == id);
    setAnnotationsForPage(pageNumber, items);
  }

  PdfEditorAnnotation? findById(String id) {
    final pages = _root['pages'];
    if (pages is! Map) return null;

    for (final entry in pages.entries) {
      final pageNumber = int.tryParse(entry.key) ?? 0;
      for (final annotation in annotationsForPage(pageNumber)) {
        if (annotation.id == id) return annotation;
      }
    }
    return null;
  }

  List<PdfEditorAnnotation> get allAnnotations {
    final result = <PdfEditorAnnotation>[];
    final pages = _root['pages'];
    if (pages is! Map) return result;
    for (final key in pages.keys) {
      final pageNumber = int.tryParse('$key') ?? 0;
      result.addAll(annotationsForPage(pageNumber));
    }
    return result;
  }

  Map<String, dynamic> _pagesMap() {
    final raw = _root['pages'];
    if (raw is Map) {
      final normalized = <String, dynamic>{};
      for (final entry in raw.entries) {
        final value = entry.value;
        normalized[entry.key.toString()] = value is Map
            ? Map<String, dynamic>.from(value)
            : value;
      }
      _root['pages'] = normalized;
      return normalized;
    }
    final created = <String, dynamic>{};
    _root['pages'] = created;
    return created;
  }

  static Map<String, dynamic> _emptyPage() => {
        'page_width': 595.0,
        'page_height': 842.0,
        'annotations': <dynamic>[],
      };

  static String newId() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    String hex(int value) => value.toRadixString(16).padLeft(2, '0');
    return '${bytes.sublist(0, 4).map(hex).join()}-'
        '${bytes.sublist(4, 6).map(hex).join()}-'
        '${bytes.sublist(6, 8).map(hex).join()}-'
        '${bytes.sublist(8, 10).map(hex).join()}-'
        '${bytes.sublist(10, 16).map(hex).join()}';
  }

  static Map<String, dynamic> migrateFromLegacy(Map<String, dynamic> legacy) {
    final migrated = empty();
    final pages = legacy['pages'];
    if (pages is! Map) return migrated;

    final targetPages = migrated['pages'] as Map<String, dynamic>;

    for (final entry in pages.entries) {
      final pageKey = entry.key.toString();
      final page = Map<String, dynamic>.from(entry.value as Map);
      if (page.isEmpty) continue;

      final pageMap = Map<String, dynamic>.from(_emptyPage());
      final annotations = <Map<String, dynamic>>[];

      for (final drawing in _legacyList(page, 'drawings')) {
        final points = _legacyPointsToNormalized(drawing['points']);
        if (points.length < 2) continue;
        annotations.add({
          'id': drawing['id']?.toString() ?? newId(),
          'type': AnnotationType.ink.name,
          'pageNumber': int.tryParse(pageKey) ?? 1,
          'points': points.map((p) => p.toJson()).toList(),
          'color': drawing['color'] ?? '#D6B56D',
          'stroke_width': drawing['stroke_width'] ?? 3,
          'opacity': 1.0,
          'pen_type': PenKind.ink.name,
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      for (final highlight in _legacyList(page, 'highlights')) {
        final pw = _asDouble(pageMap['page_width'], 595);
        final ph = _asDouble(pageMap['page_height'], 842);
        annotations.add({
          'id': highlight['id']?.toString() ?? newId(),
          'type': AnnotationType.highlighter.name,
          'pageNumber': int.tryParse(pageKey) ?? 1,
          'x': _asDouble(highlight['x']) / pw,
          'y': _asDouble(highlight['y']) / ph,
          'width': _asDouble(highlight['width']) / pw,
          'height': _asDouble(highlight['height']) / ph,
          'color': highlight['color'] ?? '#D6B56D',
          'opacity': 0.35,
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      for (final note in _legacyList(page, 'notes')) {
        final pw = _asDouble(pageMap['page_width'], 595);
        final ph = _asDouble(pageMap['page_height'], 842);
        annotations.add({
          'id': note['id']?.toString() ?? newId(),
          'type': AnnotationType.note.name,
          'pageNumber': int.tryParse(pageKey) ?? 1,
          'x': _asDouble(note['x']) / pw,
          'y': _asDouble(note['y']) / ph,
          'text': note['text'] ?? '',
          'created_at':
              note['created_at']?.toString() ?? DateTime.now().toIso8601String(),
        });
      }

      pageMap['annotations'] = annotations;
      targetPages[pageKey] = pageMap;
    }

    migrated['version'] = currentVersion;
    migrated['migrated_from_legacy'] = true;
    return migrated;
  }

  static List<Map<String, dynamic>> _legacyList(
    Map<String, dynamic> page,
    String key,
  ) {
    final value = page[key];
    if (value is! List) return [];
    return value.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  static List<NormalizedPoint> _legacyPointsToNormalized(dynamic raw) {
    if (raw is! List) return [];
    final points = raw.whereType<Map>().map(
      (entry) => NormalizedPoint.fromJson(Map<String, dynamic>.from(entry)),
    ).toList();
    if (points.isEmpty) return [];

    final maxCoord = points.fold<double>(
      0,
      (currentMax, point) =>
          math.max(currentMax, math.max(point.nx, point.ny)),
    );

    if (maxCoord <= 1.5) return points;

    const defaultWidth = 400.0;
    const defaultHeight = 700.0;
    return points
        .map(
          (point) => NormalizedPoint(
            (point.nx / defaultWidth).clamp(0.0, 1.0),
            (point.ny / defaultHeight).clamp(0.0, 1.0),
          ),
        )
        .toList();
  }

  static double maxOf(double a, double b) => a > b ? a : b;

  static double _asDouble(dynamic value, [double fallback = 0]) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse('$value') ?? fallback;
  }

  static int _asInt(dynamic value, [int fallback = 0]) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? fallback;
  }
}
