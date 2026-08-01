import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../data/models/pdf_annotation_model.dart';
import '../data/subjects_repository.dart';

enum PdfAnnotationTool {
  view,
  pen,
  note,
  highlight,
}

enum PdfAnnotationStatus {
  initial,
  loading,
  loaded,
  saving,
  error,
}

class PdfAnnotationState {
  const PdfAnnotationState({
    this.status = PdfAnnotationStatus.initial,
    this.annotationJson = const {},
    this.currentPage = 1,
    this.currentTool = PdfAnnotationTool.view,
    this.errorMessage,
    this.saveMessage,
    this.loadFailed = false,
  });

  final PdfAnnotationStatus status;
  final Map<String, dynamic> annotationJson;
  final int currentPage;
  final PdfAnnotationTool currentTool;
  final String? errorMessage;
  final String? saveMessage;
  final bool loadFailed;

  PdfAnnotationDocument get document => PdfAnnotationDocument(annotationJson);

  Map<String, dynamic>? get currentPageData =>
      document.getPage(currentPage);

  PdfAnnotationState copyWith({
    PdfAnnotationStatus? status,
    Map<String, dynamic>? annotationJson,
    int? currentPage,
    PdfAnnotationTool? currentTool,
    String? errorMessage,
    String? saveMessage,
    bool? loadFailed,
    bool clearMessages = false,
  }) {
    return PdfAnnotationState(
      status: status ?? this.status,
      annotationJson: annotationJson ?? this.annotationJson,
      currentPage: currentPage ?? this.currentPage,
      currentTool: currentTool ?? this.currentTool,
      errorMessage: clearMessages ? null : (errorMessage ?? this.errorMessage),
      saveMessage: clearMessages ? null : (saveMessage ?? this.saveMessage),
      loadFailed: loadFailed ?? this.loadFailed,
    );
  }
}

String mapAnnotationError(ApiException error) {
  if (error.isForbidden) {
    return 'لا تملك صلاحية تعديل هذا الملف';
  }
  if (error.statusCode == null && error.message.contains('اتصال')) {
    return 'تعذر الاتصال بالسيرفر';
  }
  return error.message;
}

class PdfAnnotationController extends StateNotifier<PdfAnnotationState> {
  PdfAnnotationController(this._repository) : super(const PdfAnnotationState());

  final SubjectsRepository _repository;

  Future<void> load(int fileId) async {
    state = state.copyWith(
      status: PdfAnnotationStatus.loading,
      clearMessages: true,
    );

    try {
      final model = await _repository.getFileAnnotations(fileId);
      state = PdfAnnotationState(
        status: PdfAnnotationStatus.loaded,
        annotationJson: model.annotationJson.isEmpty
            ? PdfAnnotationDocument.empty()
            : model.annotationJson,
      );
    } on ApiException catch (error) {
      if (kDebugMode) {
        debugPrint('Failed to load annotations: ${error.message}');
      }
      state = PdfAnnotationState(
        status: PdfAnnotationStatus.loaded,
        annotationJson: PdfAnnotationDocument.empty(),
        loadFailed: true,
        errorMessage: mapAnnotationError(error),
      );
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Failed to load annotations: $error');
      }
      state = const PdfAnnotationState(
        status: PdfAnnotationStatus.loaded,
        loadFailed: true,
      );
    }
  }

  Future<bool> save(int fileId) async {
    state = state.copyWith(
      status: PdfAnnotationStatus.saving,
      clearMessages: true,
    );

    try {
      final model = await _repository.saveFileAnnotations(
        fileId,
        state.annotationJson,
      );

      state = state.copyWith(
        status: PdfAnnotationStatus.loaded,
        annotationJson: model.annotationJson,
        saveMessage: 'تم حفظ الملاحظات',
      );
      return true;
    } on ApiException catch (error) {
      state = state.copyWith(
        status: PdfAnnotationStatus.loaded,
        errorMessage: mapAnnotationError(error).contains('صلاحية')
            ? mapAnnotationError(error)
            : 'تعذر حفظ الملاحظات',
      );
      return false;
    } catch (_) {
      state = state.copyWith(
        status: PdfAnnotationStatus.loaded,
        errorMessage: 'تعذر الاتصال بالسيرفر',
      );
      return false;
    }
  }

  void setTool(PdfAnnotationTool tool) {
    state = state.copyWith(currentTool: tool);
  }

  void setCurrentPage(int pageNumber) {
    if (pageNumber <= 0) {
      return;
    }
    state = state.copyWith(currentPage: pageNumber);
  }

  void addDrawing(int pageNumber, List<Map<String, dynamic>> points) {
    if (points.length < 2) {
      return;
    }

    final document = PdfAnnotationDocument(
      Map<String, dynamic>.from(state.annotationJson),
    );
    final page = document.pageData(pageNumber);
    final drawings = PdfAnnotationDocument.listOf(page, 'drawings');
    drawings.add({
      'id': PdfAnnotationDocument.newId(),
      'points': points,
      'color': '#D6B56D',
      'stroke_width': 3,
    });
    page['drawings'] = drawings;

    state = state.copyWith(annotationJson: document.toJson());
  }

  void addNote(int pageNumber, double x, double y, String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return;
    }

    final document = PdfAnnotationDocument(
      Map<String, dynamic>.from(state.annotationJson),
    );
    final page = document.pageData(pageNumber);
    final notes = PdfAnnotationDocument.listOf(page, 'notes');
    notes.add({
      'id': PdfAnnotationDocument.newId(),
      'text': trimmed,
      'x': x,
      'y': y,
      'created_at': DateTime.now().toIso8601String(),
    });
    page['notes'] = notes;

    state = state.copyWith(annotationJson: document.toJson());
  }

  void addHighlight(
    int pageNumber,
    double x,
    double y,
    double width,
    double height,
  ) {
    if (width.abs() < 8 || height.abs() < 8) {
      return;
    }

    final document = PdfAnnotationDocument(
      Map<String, dynamic>.from(state.annotationJson),
    );
    final page = document.pageData(pageNumber);
    final highlights = PdfAnnotationDocument.listOf(page, 'highlights');
    highlights.add({
      'id': PdfAnnotationDocument.newId(),
      'x': x,
      'y': y,
      'width': width,
      'height': height,
      'color': '#D6B56D',
    });
    page['highlights'] = highlights;

    state = state.copyWith(annotationJson: document.toJson());
  }
}

final pdfAnnotationControllerProvider = StateNotifierProvider.autoDispose
    .family<PdfAnnotationController, PdfAnnotationState, int>((ref, fileId) {
  return PdfAnnotationController(ref.watch(subjectsRepositoryProvider));
});
