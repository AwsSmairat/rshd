export '../../pdf_editor/controllers/pdf_editor_controller.dart';
export '../../pdf_editor/models/annotation_enums.dart';
export '../../pdf_editor/models/pdf_editor_models.dart';

import '../../pdf_editor/models/annotation_enums.dart';
import '../../pdf_editor/models/pdf_editor_models.dart';

// Legacy document helper kept for older widgets.
class PdfAnnotationDocument {
  PdfAnnotationDocument([Map<String, dynamic>? json])
    : _v2 = PdfAnnotationDocumentV2(json);

  final PdfAnnotationDocumentV2 _v2;

  static Map<String, dynamic> empty() => PdfAnnotationDocumentV2.empty();

  Map<String, dynamic> toJson() => _v2.toJson();

  Map<String, dynamic> pageData(int pageNumber) {
    final annotations = _v2.annotationsForPage(pageNumber);
    return {
      'notes': annotations
          .where((a) => a.type == AnnotationType.note)
          .map(
            (a) => {
              'id': a.id,
              'text': a.data['text'],
              'x': a.x,
              'y': a.y,
              'created_at': a.createdAt?.toIso8601String(),
            },
          )
          .toList(),
      'drawings': annotations
          .where((a) => a.type == AnnotationType.ink)
          .map(
            (a) => {
              'id': a.id,
              'points': a.data['points'],
              'color': a.data['color'],
              'stroke_width': a.data['stroke_width'],
            },
          )
          .toList(),
      'highlights': annotations
          .where((a) => a.type == AnnotationType.highlighter)
          .map(
            (a) => {
              'id': a.id,
              'x': a.x,
              'y': a.y,
              'width': a.width,
              'height': a.height,
              'color': a.data['color'],
            },
          )
          .toList(),
    };
  }

  Map<String, dynamic>? getPage(int pageNumber) => pageData(pageNumber);

  static String newId() => PdfAnnotationDocumentV2.newId();

  static List<Map<String, dynamic>> listOf(
    Map<String, dynamic>? page,
    String key,
  ) {
    if (page == null) return [];
    final value = page[key];
    if (value is! List) return [];
    return value
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }
}
