import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../subjects/data/subjects_repository.dart';
import '../models/annotation_enums.dart';
import '../models/pdf_editor_models.dart';
import '../services/annotation_local_cache.dart';
import '../utils/undo_redo_stack.dart';

class PenSettings {
  const PenSettings({
    this.color = const Color(0xFF0B1F3A),
    this.strokeWidth = 0.004,
    this.opacity = 1.0,
    this.penKind = PenKind.ink,
  });

  final Color color;
  final double strokeWidth;
  final double opacity;
  final PenKind penKind;

  PenSettings copyWith({
    Color? color,
    double? strokeWidth,
    double? opacity,
    PenKind? penKind,
  }) {
    return PenSettings(
      color: color ?? this.color,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      opacity: opacity ?? this.opacity,
      penKind: penKind ?? this.penKind,
    );
  }
}

class HighlighterSettings {
  const HighlighterSettings({
    this.color = const Color(0xFFFFEB3B),
    this.strokeWidth = 0.02,
    this.opacity = 0.35,
  });

  final Color color;
  final double strokeWidth;
  final double opacity;

  HighlighterSettings copyWith({
    Color? color,
    double? strokeWidth,
    double? opacity,
  }) {
    return HighlighterSettings(
      color: color ?? this.color,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      opacity: opacity ?? this.opacity,
    );
  }
}

class TextSettings {
  const TextSettings({
    this.color = const Color(0xFF0B1F3A),
    this.fontSize = 0.027,
  });

  final Color color;
  final double fontSize;

  TextSettings copyWith({Color? color, double? fontSize}) {
    return TextSettings(
      color: color ?? this.color,
      fontSize: fontSize ?? this.fontSize,
    );
  }
}

class PdfEditorState {
  const PdfEditorState({
    this.status = PdfAnnotationStatus.initial,
    this.annotationJson = const {},
    this.currentPage = 1,
    this.totalPages = 0,
    this.currentTool = PdfEditorTool.view,
    this.saveStatus = PdfSaveStatus.saved,
    this.errorMessage,
    this.loadFailed = false,
    this.hasUnsavedChanges = false,
    this.pendingSync = false,
    this.penSettings = const PenSettings(),
    this.highlighterSettings = const HighlighterSettings(),
    this.eraserMode = EraserMode.whole,
    this.eraserSize = 0.015,
    this.allowFingerDrawing = true,
    this.selectedAnnotationId,
    this.shapeTool = PdfEditorShapeTool.rectangle,
    this.toolbarVisible = true,
    this.toolbarExpanded = true,
    this.textSettings = const TextSettings(),
    this.zoomLevel = 1.0,
  });

  final PdfAnnotationStatus status;
  final Map<String, dynamic> annotationJson;
  final int currentPage;
  final int totalPages;
  final PdfEditorTool currentTool;
  final PdfSaveStatus saveStatus;
  final String? errorMessage;
  final bool loadFailed;
  final bool hasUnsavedChanges;
  final bool pendingSync;
  final PenSettings penSettings;
  final HighlighterSettings highlighterSettings;
  final EraserMode eraserMode;
  final double eraserSize;
  final bool allowFingerDrawing;
  final String? selectedAnnotationId;
  final PdfEditorShapeTool shapeTool;
  final bool toolbarVisible;
  final bool toolbarExpanded;
  final TextSettings textSettings;
  final double zoomLevel;

  PdfAnnotationDocumentV2 get document =>
      PdfAnnotationDocumentV2(annotationJson);

  List<PdfEditorAnnotation> get currentPageAnnotations =>
      document.annotationsForPage(currentPage);

  PdfEditorState copyWith({
    PdfAnnotationStatus? status,
    Map<String, dynamic>? annotationJson,
    int? currentPage,
    int? totalPages,
    PdfEditorTool? currentTool,
    PdfSaveStatus? saveStatus,
    String? errorMessage,
    bool? loadFailed,
    bool? hasUnsavedChanges,
    bool? pendingSync,
    PenSettings? penSettings,
    HighlighterSettings? highlighterSettings,
    EraserMode? eraserMode,
    double? eraserSize,
    bool? allowFingerDrawing,
    String? selectedAnnotationId,
    PdfEditorShapeTool? shapeTool,
    bool? toolbarVisible,
    bool? toolbarExpanded,
    TextSettings? textSettings,
    double? zoomLevel,
    bool clearSelected = false,
    bool clearError = false,
  }) {
    return PdfEditorState(
      status: status ?? this.status,
      annotationJson: annotationJson ?? this.annotationJson,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      currentTool: currentTool ?? this.currentTool,
      saveStatus: saveStatus ?? this.saveStatus,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      loadFailed: loadFailed ?? this.loadFailed,
      hasUnsavedChanges: hasUnsavedChanges ?? this.hasUnsavedChanges,
      pendingSync: pendingSync ?? this.pendingSync,
      penSettings: penSettings ?? this.penSettings,
      highlighterSettings: highlighterSettings ?? this.highlighterSettings,
      eraserMode: eraserMode ?? this.eraserMode,
      eraserSize: eraserSize ?? this.eraserSize,
      allowFingerDrawing: allowFingerDrawing ?? this.allowFingerDrawing,
      selectedAnnotationId: clearSelected
          ? null
          : (selectedAnnotationId ?? this.selectedAnnotationId),
      shapeTool: shapeTool ?? this.shapeTool,
      toolbarVisible: toolbarVisible ?? this.toolbarVisible,
      toolbarExpanded: toolbarExpanded ?? this.toolbarExpanded,
      textSettings: textSettings ?? this.textSettings,
      zoomLevel: zoomLevel ?? this.zoomLevel,
    );
  }
}

enum PdfAnnotationStatus { initial, loading, loaded, saving, error }

String mapPdfEditorError(ApiException error) {
  if (error.isForbidden) {
    return 'لا تملك صلاحية تعديل هذا الملف';
  }
  if (error.statusCode == null && error.message.contains('اتصال')) {
    return 'تعذر الاتصال بالسيرفر';
  }
  return error.message;
}

class PdfEditorController extends StateNotifier<PdfEditorState> {
  PdfEditorController(
    this._repository,
    this._fileId, {
    AnnotationLocalCache? localCache,
  }) : super(const PdfEditorState()) {
    _localCache = localCache ?? AnnotationLocalCache();
  }

  final SubjectsRepository _repository;
  final int _fileId;
  late final AnnotationLocalCache _localCache;
  final UndoRedoStack<Map<String, dynamic>> _history = UndoRedoStack();
  Timer? _autoSaveTimer;
  Timer? _syncTimer;
  bool _isDisposed = false;
  Map<String, dynamic>? _batchSnapshot;
  PdfAnnotationDocumentV2? _batchDocument;

  @override
  void dispose() {
    _isDisposed = true;
    _autoSaveTimer?.cancel();
    _syncTimer?.cancel();
    super.dispose();
  }

  Future<void> load() async {
    if (_isDisposed) return;

    state = state.copyWith(
      status: PdfAnnotationStatus.loading,
      clearError: true,
    );

    Map<String, dynamic>? local;
    try {
      local = await _localCache.loadAnnotations(_fileId);
    } catch (_) {}

    if (_isDisposed) return;

    try {
      final model = await _repository.getFileAnnotations(_fileId);
      if (_isDisposed) return;

      final remote = model.annotationJson.isEmpty
          ? PdfAnnotationDocumentV2.empty(documentId: _fileId)
          : PdfAnnotationDocumentV2(model.annotationJson).toJson();

      final merged = _mergeLocalAndRemote(local, remote);

      if (_isDisposed) return;

      state = PdfEditorState(
        status: PdfAnnotationStatus.loaded,
        annotationJson: merged,
        saveStatus: (local?['pending_sync'] == true)
            ? PdfSaveStatus.offlinePending
            : PdfSaveStatus.saved,
        pendingSync: local?['pending_sync'] == true,
      );
      _history.clear();
    } on ApiException catch (error) {
      if (_isDisposed) return;

      if (local != null) {
        state = PdfEditorState(
          status: PdfAnnotationStatus.loaded,
          annotationJson: local,
          saveStatus: PdfSaveStatus.offlinePending,
          pendingSync: true,
          loadFailed: true,
          errorMessage: 'تم تحميل نسخة محلية — سيتم المزامنة عند عودة الإنترنت',
        );
        return;
      }

      state = PdfEditorState(
        status: PdfAnnotationStatus.loaded,
        annotationJson: PdfAnnotationDocumentV2.empty(documentId: _fileId),
        loadFailed: true,
        errorMessage: mapPdfEditorError(error),
      );
    } catch (error) {
      if (_isDisposed) return;

      if (kDebugMode) {
        debugPrint('PdfEditorController.load: $error');
      }

      if (local != null) {
        state = PdfEditorState(
          status: PdfAnnotationStatus.loaded,
          annotationJson: local,
          saveStatus: PdfSaveStatus.offlinePending,
          pendingSync: true,
        );
        return;
      }

      state = const PdfEditorState(
        status: PdfAnnotationStatus.loaded,
        loadFailed: true,
      );
    }
  }

  Map<String, dynamic> _mergeLocalAndRemote(
    Map<String, dynamic>? local,
    Map<String, dynamic> remote,
  ) {
    if (local == null) return remote;

    final localUpdated = DateTime.tryParse('${local['cached_at']}');
    final remoteUpdated = DateTime.tryParse('${remote['updated_at']}');
    if (local['pending_sync'] == true &&
        (localUpdated != null &&
            (remoteUpdated == null || localUpdated.isAfter(remoteUpdated)))) {
      return local;
    }
    return remote;
  }

  void setTotalPages(int count) {
    if (count <= 0 || count == state.totalPages) return;
    state = state.copyWith(totalPages: count);
  }

  void setZoomLevel(double zoom) {
    state = state.copyWith(zoomLevel: zoom);
  }

  void setCurrentPage(int pageNumber) {
    if (pageNumber <= 0) return;
    state = state.copyWith(currentPage: pageNumber, clearSelected: true);
    _persistSession();
  }

  void setTool(PdfEditorTool tool) {
    state = state.copyWith(currentTool: tool, clearSelected: true);
  }

  void toggleToolbar() {
    state = state.copyWith(toolbarVisible: !state.toolbarVisible);
  }

  void toggleToolbarExpanded() {
    state = state.copyWith(toolbarExpanded: !state.toolbarExpanded);
  }

  void setTextSettings(TextSettings settings) {
    state = state.copyWith(textSettings: settings);
  }

  void setPenSettings(PenSettings settings) {
    state = state.copyWith(penSettings: settings);
  }

  void setHighlighterSettings(HighlighterSettings settings) {
    state = state.copyWith(highlighterSettings: settings);
  }

  void setEraserMode(EraserMode mode) {
    state = state.copyWith(eraserMode: mode);
  }

  void setAllowFingerDrawing(bool value) {
    state = state.copyWith(allowFingerDrawing: value);
  }

  void setShapeTool(PdfEditorShapeTool tool) {
    state = state.copyWith(shapeTool: tool, currentTool: PdfEditorTool.shapes);
  }

  void setEraserSize(double size) {
    state = state.copyWith(eraserSize: size);
  }

  void registerPageSize(int pageNumber, double width, double height) {
    final document = PdfAnnotationDocumentV2(
      Map<String, dynamic>.from(state.annotationJson),
    );
    document.ensurePageSize(pageNumber, width, height);
    state = state.copyWith(annotationJson: document.toJson());
  }

  void _commitDocument(PdfAnnotationDocumentV2 document) {
    _history.push(Map<String, dynamic>.from(state.annotationJson));
    _applyDocument(document, schedulePersistence: true);
  }

  void beginBatch() {
    _batchSnapshot ??= Map<String, dynamic>.from(state.annotationJson);
    _batchDocument = PdfAnnotationDocumentV2(
      Map<String, dynamic>.from(state.annotationJson),
    );
  }

  void endBatch() {
    if (_batchSnapshot == null || _batchDocument == null) return;

    final json = _batchDocument!.toJson();
    json['pending_sync'] = true;
    if (!_mapsEqual(_batchSnapshot!, json)) {
      _history.push(_batchSnapshot!);
      state = state.copyWith(
        annotationJson: json,
        hasUnsavedChanges: true,
        saveStatus: PdfSaveStatus.unsaved,
        pendingSync: true,
      );
      _scheduleLocalSave(json);
      _scheduleRemoteSync();
    } else {
      state = state.copyWith(annotationJson: json);
    }

    _batchSnapshot = null;
    _batchDocument = null;
  }

  void _applyDocument(
    PdfAnnotationDocumentV2 document, {
    required bool schedulePersistence,
  }) {
    final json = document.toJson();
    json['pending_sync'] = true;
    state = state.copyWith(
      annotationJson: json,
      hasUnsavedChanges: true,
      saveStatus: PdfSaveStatus.unsaved,
      pendingSync: true,
    );
    if (schedulePersistence) {
      _scheduleLocalSave(json);
      _scheduleRemoteSync();
    }
  }

  bool _mapsEqual(Map<String, dynamic> a, Map<String, dynamic> b) {
    return a.toString() == b.toString();
  }

  PdfAnnotationDocumentV2 _workingDocument() {
    if (_batchDocument != null) return _batchDocument!;
    return PdfAnnotationDocumentV2(
      Map<String, dynamic>.from(state.annotationJson),
    );
  }

  void _replaceWorkingDocument(PdfAnnotationDocumentV2 document) {
    if (_batchDocument != null) {
      _batchDocument = document;
      final json = document.toJson();
      json['pending_sync'] = true;
      state = state.copyWith(
        annotationJson: json,
        hasUnsavedChanges: true,
        saveStatus: PdfSaveStatus.unsaved,
        pendingSync: true,
      );
      return;
    }
    _applyDocument(document, schedulePersistence: false);
  }

  void _scheduleLocalSave(Map<String, dynamic> json) {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(milliseconds: 800), () async {
      if (_isDisposed) return;
      state = state.copyWith(saveStatus: PdfSaveStatus.saving);
      try {
        await _localCache.saveAnnotations(_fileId, json);
        if (_isDisposed) return;
        state = state.copyWith(
          saveStatus: state.pendingSync
              ? PdfSaveStatus.offlinePending
              : PdfSaveStatus.saved,
        );
      } catch (_) {
        if (_isDisposed) return;
        state = state.copyWith(saveStatus: PdfSaveStatus.failed);
      }
    });
  }

  void _scheduleRemoteSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer(const Duration(seconds: 3), () {
      saveToServer(showErrors: false);
    });
  }

  Future<void> saveToServer({bool showErrors = true}) async {
    if (_isDisposed || state.status == PdfAnnotationStatus.saving) return;

    state = state.copyWith(
      status: PdfAnnotationStatus.saving,
      saveStatus: PdfSaveStatus.saving,
      clearError: true,
    );

    try {
      final payload = Map<String, dynamic>.from(state.annotationJson);
      payload.remove('pending_sync');
      payload.remove('cached_at');
      payload['updated_at'] = DateTime.now().toIso8601String();

      final model = await _repository.saveFileAnnotations(_fileId, payload);
      if (_isDisposed) return;

      await _localCache.saveAnnotations(_fileId, {
        ...model.annotationJson,
        'pending_sync': false,
        'last_synced_at': DateTime.now().toIso8601String(),
      });
      if (_isDisposed) return;

      state = state.copyWith(
        status: PdfAnnotationStatus.loaded,
        annotationJson: model.annotationJson,
        saveStatus: PdfSaveStatus.saved,
        hasUnsavedChanges: false,
        pendingSync: false,
      );
    } on ApiException catch (error) {
      if (_isDisposed) return;

      final message = mapPdfEditorError(error);
      state = state.copyWith(
        status: PdfAnnotationStatus.loaded,
        saveStatus: PdfSaveStatus.failed,
        pendingSync: true,
        errorMessage: showErrors ? message : state.errorMessage,
      );
    } catch (_) {
      if (_isDisposed) return;

      state = state.copyWith(
        status: PdfAnnotationStatus.loaded,
        saveStatus: PdfSaveStatus.offlinePending,
        pendingSync: true,
        errorMessage: showErrors ? 'تعذر الاتصال بالسيرفر' : state.errorMessage,
      );
    }
  }

  Future<void> flushOnBackground() async {
    if (_isDisposed) return;

    final json = Map<String, dynamic>.from(state.annotationJson);
    json['pending_sync'] = true;

    await _localCache.saveAnnotations(_fileId, json);
    if (_isDisposed) return;

    if (state.hasUnsavedChanges || state.pendingSync) {
      await saveToServer(showErrors: false);
    }

    if (_isDisposed) return;
    await _persistSession();
  }

  Future<void> restoreSession(PdfViewerSessionController session) async {
    if (_isDisposed) return;

    final saved = await _localCache.loadSession(_fileId);
    if (_isDisposed || saved == null) return;

    session.jumpToPage(saved.pageNumber);
    session.setZoom(saved.zoomLevel);

    if (_isDisposed) return;

    state = state.copyWith(
      currentPage: saved.pageNumber,
      zoomLevel: saved.zoomLevel,
    );
  }

  Future<void> _persistSession() async {
    if (_isDisposed) return;

    final pageNumber = state.currentPage;
    final zoomLevel = state.zoomLevel;

    await _localCache.saveSession(
      _fileId,
      PdfReadingSession(pageNumber: pageNumber, zoomLevel: zoomLevel),
    );
  }

  void undo() {
    final previous = _history.undo(state.annotationJson);
    if (previous == null) return;
    state = state.copyWith(
      annotationJson: previous,
      hasUnsavedChanges: true,
      saveStatus: PdfSaveStatus.unsaved,
      pendingSync: true,
    );
    _scheduleLocalSave(previous);
    _scheduleRemoteSync();
  }

  void redo() {
    final next = _history.redo(state.annotationJson);
    if (next == null) return;
    state = state.copyWith(
      annotationJson: next,
      hasUnsavedChanges: true,
      saveStatus: PdfSaveStatus.unsaved,
      pendingSync: true,
    );
    _scheduleLocalSave(next);
    _scheduleRemoteSync();
  }

  bool get canUndo => _history.canUndo;
  bool get canRedo => _history.canRedo;

  void addInkStroke({
    required int pageNumber,
    required List<NormalizedPoint> points,
    required AnnotationType type,
    required Color color,
    required double strokeWidth,
    required double opacity,
    PenKind penKind = PenKind.ink,
  }) {
    if (points.length < 2) return;

    final document = PdfAnnotationDocumentV2(
      Map<String, dynamic>.from(state.annotationJson),
    );
    final now = DateTime.now();
    document.addAnnotation(
      PdfEditorAnnotation(
        id: PdfAnnotationDocumentV2.newId(),
        type: type,
        pageNumber: pageNumber,
        createdAt: now,
        updatedAt: now,
        data: {
          'points': points.map((p) => p.toJson()).toList(),
          'color': _colorToHex(color),
          'stroke_width': strokeWidth,
          'opacity': opacity,
          'pen_type': penKind.name,
        },
      ),
    );
    _commitDocument(document);
  }

  void addHighlightRect({
    required int pageNumber,
    required double x,
    required double y,
    required double width,
    required double height,
    required Color color,
    required double opacity,
  }) {
    if (width.abs() < 0.005 || height.abs() < 0.005) return;

    final document = PdfAnnotationDocumentV2(
      Map<String, dynamic>.from(state.annotationJson),
    );
    final now = DateTime.now();
    document.addAnnotation(
      PdfEditorAnnotation(
        id: PdfAnnotationDocumentV2.newId(),
        type: AnnotationType.highlighter,
        pageNumber: pageNumber,
        x: x,
        y: y,
        width: width,
        height: height,
        createdAt: now,
        updatedAt: now,
        data: {'color': _colorToHex(color), 'opacity': opacity},
      ),
    );
    _commitDocument(document);
  }

  void addNote({
    required int pageNumber,
    required double x,
    required double y,
    required String text,
    String? author,
  }) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final document = PdfAnnotationDocumentV2(
      Map<String, dynamic>.from(state.annotationJson),
    );
    final now = DateTime.now();
    document.addAnnotation(
      PdfEditorAnnotation(
        id: PdfAnnotationDocumentV2.newId(),
        type: AnnotationType.note,
        pageNumber: pageNumber,
        x: x,
        y: y,
        createdAt: now,
        updatedAt: now,
        data: {'text': trimmed, 'author': ?author},
      ),
    );
    _commitDocument(document);
  }

  void addTextBox({
    required int pageNumber,
    required double x,
    required double y,
    required String text,
    Color? color,
    double? fontSize,
    TextAlign align = TextAlign.right,
  }) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final resolvedColor = color ?? state.textSettings.color;
    final resolvedFontSize = fontSize ?? state.textSettings.fontSize;
    final direction = _detectTextDirection(trimmed);

    final document = PdfAnnotationDocumentV2(
      Map<String, dynamic>.from(state.annotationJson),
    );
    final now = DateTime.now();
    document.addAnnotation(
      PdfEditorAnnotation(
        id: PdfAnnotationDocumentV2.newId(),
        type: AnnotationType.text,
        pageNumber: pageNumber,
        x: x,
        y: y,
        width: 0.3,
        height: 0.08,
        createdAt: now,
        updatedAt: now,
        data: {
          'text': trimmed,
          'color': _colorToHex(resolvedColor),
          'font_size': resolvedFontSize,
          'align': align.name,
          'font_weight': 'normal',
          'text_direction': direction.name,
        },
      ),
    );
    _commitDocument(document);
  }

  void addShape({
    required int pageNumber,
    required PdfEditorShapeTool shape,
    required double x,
    required double y,
    required double width,
    required double height,
    required Color strokeColor,
    Color? fillColor,
    required double strokeWidth,
    required double opacity,
  }) {
    if (width.abs() < 0.005 && height.abs() < 0.005) return;

    final document = PdfAnnotationDocumentV2(
      Map<String, dynamic>.from(state.annotationJson),
    );
    final now = DateTime.now();
    document.addAnnotation(
      PdfEditorAnnotation(
        id: PdfAnnotationDocumentV2.newId(),
        type: AnnotationType.shape,
        pageNumber: pageNumber,
        x: x,
        y: y,
        width: width,
        height: height,
        createdAt: now,
        updatedAt: now,
        data: {
          'shape': shape.name,
          'stroke_color': _colorToHex(strokeColor),
          if (fillColor != null) 'fill_color': _colorToHex(fillColor),
          'stroke_width': strokeWidth,
          'opacity': opacity,
        },
      ),
    );
    _commitDocument(document);
  }

  void updateTextBox({
    required String id,
    required int pageNumber,
    required String text,
    Color? color,
    double? fontSize,
  }) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final document = _workingDocument();
    final items = document.annotationsForPage(pageNumber);
    final index = items.indexWhere((item) => item.id == id);
    if (index < 0) return;

    final current = items[index];
    final nextData = Map<String, dynamic>.from(current.data);
    nextData['text'] = trimmed;
    nextData['text_direction'] = _detectTextDirection(trimmed).name;
    if (color != null) nextData['color'] = _colorToHex(color);
    if (fontSize != null) nextData['font_size'] = fontSize;

    items[index] = current.copyWith(updatedAt: DateTime.now(), data: nextData);
    document.setAnnotationsForPage(pageNumber, items);

    if (_batchDocument != null) {
      _replaceWorkingDocument(document);
    } else {
      _commitDocument(document);
    }
  }

  void updateAnnotationStyle({
    required String id,
    required int pageNumber,
    Color? color,
    double? strokeWidth,
    double? opacity,
    double? fontSize,
  }) {
    final document = _workingDocument();
    final items = document.annotationsForPage(pageNumber);
    final index = items.indexWhere((item) => item.id == id);
    if (index < 0) return;

    final current = items[index];
    final nextData = Map<String, dynamic>.from(current.data);

    switch (current.type) {
      case AnnotationType.ink:
      case AnnotationType.highlighter:
        if (color != null) nextData['color'] = _colorToHex(color);
        if (strokeWidth != null) nextData['stroke_width'] = strokeWidth;
        if (opacity != null) nextData['opacity'] = opacity;
      case AnnotationType.text:
        if (color != null) nextData['color'] = _colorToHex(color);
        if (fontSize != null) nextData['font_size'] = fontSize;
      case AnnotationType.shape:
        if (color != null) nextData['stroke_color'] = _colorToHex(color);
        if (strokeWidth != null) nextData['stroke_width'] = strokeWidth;
        if (opacity != null) nextData['opacity'] = opacity;
      case AnnotationType.note:
      case AnnotationType.image:
        break;
    }

    items[index] = current.copyWith(updatedAt: DateTime.now(), data: nextData);
    document.setAnnotationsForPage(pageNumber, items);

    if (_batchDocument != null) {
      _replaceWorkingDocument(document);
    } else {
      _commitDocument(document);
    }
  }

  void deleteSelectedAnnotation() {
    final id = state.selectedAnnotationId;
    if (id == null) return;
    deleteAnnotation(id, state.currentPage);
    selectAnnotation(null);
  }

  void deleteAnnotation(String id, int pageNumber) {
    final document = PdfAnnotationDocumentV2(
      Map<String, dynamic>.from(state.annotationJson),
    );
    document.removeAnnotation(id, pageNumber);
    _commitDocument(document);
  }

  void updateNoteText(String id, int pageNumber, String text) {
    final document = PdfAnnotationDocumentV2(
      Map<String, dynamic>.from(state.annotationJson),
    );
    final items = document.annotationsForPage(pageNumber);
    final index = items.indexWhere((item) => item.id == id);
    if (index < 0) return;

    final current = items[index];
    items[index] = current.copyWith(
      updatedAt: DateTime.now(),
      data: {...current.data, 'text': text.trim()},
    );
    document.setAnnotationsForPage(pageNumber, items);
    _commitDocument(document);
  }

  void moveAnnotation({
    required String id,
    required int pageNumber,
    required double x,
    required double y,
  }) {
    final document = _workingDocument();
    final items = document.annotationsForPage(pageNumber);
    final index = items.indexWhere((item) => item.id == id);
    if (index < 0) return;

    final current = items[index];
    items[index] = current.copyWith(
      x: x.clamp(0.0, 1.0),
      y: y.clamp(0.0, 1.0),
      updatedAt: DateTime.now(),
    );
    document.setAnnotationsForPage(pageNumber, items);
    _replaceWorkingDocument(document);
  }

  void selectAnnotation(String? id) {
    state = state.copyWith(selectedAnnotationId: id, clearSelected: id == null);
  }

  void eraseAtPoint({
    required int pageNumber,
    required NormalizedPoint point,
    required double radius,
  }) {
    final document = _workingDocument();
    final items = document.annotationsForPage(pageNumber);
    final radiusSquared = radius * radius;

    if (state.eraserMode == EraserMode.whole) {
      for (final item in List.of(items)) {
        if (item.type == AnnotationType.note ||
            item.type == AnnotationType.text) {
          continue;
        }
        if (_hitTest(item, point, radius)) {
          document.removeAnnotation(item.id, pageNumber);
        }
      }
      if (_batchDocument != null) {
        _replaceWorkingDocument(document);
      } else {
        _commitDocument(document);
      }
      return;
    }

    var changed = false;
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      if (item.type != AnnotationType.ink &&
          item.type != AnnotationType.highlighter) {
        continue;
      }
      final rawPoints = item.data['points'];
      if (rawPoints is! List) continue;

      final points = rawPoints
          .whereType<Map>()
          .map(
            (entry) =>
                NormalizedPoint.fromJson(Map<String, dynamic>.from(entry)),
          )
          .where((p) => _distanceSquared(p, point) > radiusSquared)
          .toList();

      if (points.length != rawPoints.length) {
        changed = true;
        if (points.length < 2) {
          document.removeAnnotation(item.id, pageNumber);
        } else {
          items[i] = item.copyWith(
            updatedAt: DateTime.now(),
            data: {
              ...item.data,
              'points': points.map((p) => p.toJson()).toList(),
            },
          );
          document.setAnnotationsForPage(pageNumber, items);
        }
      }
    }

    if (changed) {
      if (_batchDocument != null) {
        _replaceWorkingDocument(document);
      } else {
        _commitDocument(document);
      }
    }
  }

  bool _hitTest(
    PdfEditorAnnotation item,
    NormalizedPoint point,
    double radius,
  ) {
    if (item.type == AnnotationType.note || item.type == AnnotationType.text) {
      return _distanceSquared(NormalizedPoint(item.x, item.y), point) <=
          (radius * 2) * (radius * 2);
    }
    final rawPoints = item.data['points'];
    if (rawPoints is List) {
      final radiusSquared = radius * radius;
      for (final raw in rawPoints.whereType<Map>()) {
        if (_distanceSquared(
              NormalizedPoint.fromJson(Map<String, dynamic>.from(raw)),
              point,
            ) <=
            radiusSquared) {
          return true;
        }
      }
    }
    if (item.width != 0 || item.height != 0) {
      final left = item.width >= 0 ? item.x : item.x + item.width;
      final top = item.height >= 0 ? item.y : item.y + item.height;
      final rect = Rect.fromLTWH(
        left,
        top,
        item.width.abs(),
        item.height.abs(),
      );
      return rect.contains(Offset(point.nx, point.ny));
    }
    return false;
  }

  double _distanceSquared(NormalizedPoint a, NormalizedPoint b) {
    final dx = a.nx - b.nx;
    final dy = a.ny - b.ny;
    return dx * dx + dy * dy;
  }

  TextDirection _detectTextDirection(String text) {
    final hasArabic = RegExp(r'[\u0600-\u06FF]').hasMatch(text);
    final hasLatin = RegExp(r'[A-Za-z]').hasMatch(text);
    if (hasArabic && !hasLatin) return TextDirection.rtl;
    if (hasLatin && !hasArabic) return TextDirection.ltr;
    return TextDirection.rtl;
  }

  String _colorToHex(Color color) {
    return '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}';
  }
}

/// Thin wrapper around Syncfusion controller for session restore.
class PdfViewerSessionController {
  PdfViewerSessionController(this._jumpToPage, this._setZoom);

  final void Function(int page) _jumpToPage;
  final void Function(double zoom) _setZoom;

  void jumpToPage(int page) => _jumpToPage(page);
  void setZoom(double zoom) => _setZoom(zoom);
}

final pdfEditorControllerProvider = StateNotifierProvider.autoDispose
    .family<PdfEditorController, PdfEditorState, int>((ref, fileId) {
      final userId = ref.watch(authControllerProvider).user?.id;

      return PdfEditorController(
        ref.watch(subjectsRepositoryProvider),
        fileId,
        localCache: AnnotationLocalCache(userId: userId),
      );
    });

// Backward compatibility aliases for existing imports.
typedef PdfAnnotationTool = PdfEditorTool;
typedef PdfAnnotationState = PdfEditorState;
typedef PdfAnnotationController = PdfEditorController;
final pdfAnnotationControllerProvider = pdfEditorControllerProvider;
