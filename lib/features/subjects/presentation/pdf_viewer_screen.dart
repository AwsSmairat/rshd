import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../pdf_editor/controllers/pdf_editor_controller.dart';
import '../../pdf_editor/models/annotation_enums.dart';
import '../../pdf_editor/models/pdf_editor_models.dart';
import '../../pdf_editor/services/pdf_export_service.dart';
import '../../pdf_editor/services/pdf_share_service.dart';
import '../../pdf_editor/services/pdf_viewer_source_loader.dart';
import '../data/subjects_repository.dart';
import '../../pdf_editor/widgets/pdf_annotation_overlay_host.dart';
import '../../pdf_editor/widgets/pdf_editor_toolbar.dart';
import '../../pdf_editor/widgets/pen_settings_sheet.dart';
import '../../pdf_editor/widgets/text_settings_sheet.dart';

/// Professional in-app PDF editor with page-bound annotations.
class PdfViewerScreen extends ConsumerStatefulWidget {
  const PdfViewerScreen({
    super.key,
    required this.fileId,
    required this.title,
    this.courseTitle,
  });

  final int fileId;
  final String title;
  final String? courseTitle;

  @override
  ConsumerState<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends ConsumerState<PdfViewerScreen>
    with WidgetsBindingObserver {
  final PdfViewerController _pdfController = PdfViewerController();
  final PdfExportService _exportService = PdfExportService();
  final PdfShareService _shareService = PdfShareService();
  final PdfViewerSourceLoader _sourceLoader = PdfViewerSourceLoader();

  bool _isLoading = true;
  bool _hasError = false;
  String? _loadErrorMessage;
  Uint8List? _pdfBytes;
  Size _viewportSize = Size.zero;
  Size _pdfPageSize = const Size(595, 842);
  final Map<int, Size> _pageSizes = {};
  final Map<int, int> _pageRotations = {};
  bool _sessionRestored = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(pdfEditorControllerProvider(widget.fileId).notifier).load();
      _preparePdfSource();
    });
  }

  Future<void> _preparePdfSource() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _loadErrorMessage = null;
    });

    try {
      final bytes = await _sourceLoader.load(
        fileId: widget.fileId,
        repository: ref.read(subjectsRepositoryProvider),
      );
      if (!mounted) return;
      setState(() {
        _pdfBytes = bytes;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _isLoading = false;
        _loadErrorMessage = 'تعذر فتح ملف PDF، يرجى المحاولة لاحقاً';
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pdfController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      ref.read(pdfEditorControllerProvider(widget.fileId).notifier).flushOnBackground();
    }
  }

  PdfEditorController get _editor =>
      ref.read(pdfEditorControllerProvider(widget.fileId).notifier);

  PdfEditorState get _state => ref.watch(pdfEditorControllerProvider(widget.fileId));

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _showNoteDialog(double x, double y) async {
    final controller = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة ملاحظة'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 4,
          textDirection: TextDirection.rtl,
          decoration: const InputDecoration(hintText: 'اكتب ملاحظتك هنا'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );

    if (text == null || text.trim().isEmpty || !mounted) return;
    _editor.addNote(
      pageNumber: _state.currentPage,
      x: x,
      y: y,
      text: text,
    );
  }

  Future<void> _showTextDialog(double x, double y) async {
    final controller = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة نص'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          textDirection: TextDirection.rtl,
          decoration: const InputDecoration(hintText: 'اكتب النص'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('إضافة'),
          ),
        ],
      ),
    );

    if (text == null || text.trim().isEmpty || !mounted) return;
    _editor.addTextBox(
      pageNumber: _state.currentPage,
      x: x,
      y: y,
      text: text,
      color: _state.textSettings.color,
      fontSize: _state.textSettings.fontSize,
    );
  }

  Future<void> _showTextEditDialog(PdfEditorAnnotation annotation) async {
    final controller =
        TextEditingController(text: annotation.data['text']?.toString() ?? '');
    final text = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تعديل النص'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          textDirection: TextDirection.rtl,
        ),
        actions: [
          TextButton(
            onPressed: () {
              _editor.deleteAnnotation(annotation.id, annotation.pageNumber);
              _editor.selectAnnotation(null);
              Navigator.pop(context);
            },
            child: const Text('حذف', style: TextStyle(color: AppColors.error)),
          ),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );

    if (text == null || text.trim().isEmpty || !mounted) return;
    _editor.updateTextBox(
      id: annotation.id,
      pageNumber: annotation.pageNumber,
      text: text,
      color: _state.textSettings.color,
      fontSize: _state.textSettings.fontSize,
    );
  }

  void _showSelectionActions(PdfEditorAnnotation annotation) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.cardWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (annotation.type == AnnotationType.text)
                ListTile(
                  leading: const Icon(Icons.edit_outlined),
                  title: const Text('تعديل النص'),
                  onTap: () {
                    Navigator.pop(context);
                    _showTextEditDialog(annotation);
                  },
                ),
              if (annotation.type == AnnotationType.note)
                ListTile(
                  leading: const Icon(Icons.sticky_note_2_outlined),
                  title: const Text('فتح الملاحظة'),
                  onTap: () {
                    Navigator.pop(context);
                    _showExistingNote(annotation);
                  },
                ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: AppColors.error),
                title: const Text('حذف'),
                onTap: () {
                  _editor.deleteSelectedAnnotation();
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showExistingNote(PdfEditorAnnotation note) {
    final controller = TextEditingController(text: note.data['text']?.toString() ?? '');
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ملاحظة'),
        content: TextField(
          controller: controller,
          maxLines: 5,
          textDirection: TextDirection.rtl,
        ),
        actions: [
          TextButton(
            onPressed: () {
              _editor.deleteAnnotation(note.id, note.pageNumber);
              Navigator.pop(context);
            },
            child: const Text('حذف', style: TextStyle(color: AppColors.error)),
          ),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إغلاق')),
          FilledButton(
            onPressed: () {
              _editor.updateNoteText(note.id, note.pageNumber, controller.text);
              Navigator.pop(context);
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSave() async {
    await _editor.saveToServer();
    if (!mounted) return;
    if (_state.saveStatus == PdfSaveStatus.saved) {
      _showSnackBar('تم حفظ جميع التعديلات');
    }
  }

  Future<void> _handleExport({required bool saveAsCopy}) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(saveAsCopy ? 'حفظ نسخة جديدة' : 'تصدير PDF'),
        content: Text(
          saveAsCopy
              ? 'سيتم إنشاء نسخة PDF جديدة تحتوي على التعليقات مع الاحتفاظ بالملف الأصلي.'
              : 'سيتم تصدير نسخة PDF تحتوي على التعليقات المدمجة.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('متابعة')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final progressNotifier = ValueNotifier<double>(0);
    final messageNotifier = ValueNotifier<String>('جاري تجهيز الملف...');

    if (!mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return ValueListenableBuilder<double>(
          valueListenable: progressNotifier,
          builder: (context, progress, _) {
            return ValueListenableBuilder<String>(
              valueListenable: messageNotifier,
              builder: (context, message, __) {
                return AlertDialog(
                  title: const Text('تصدير PDF'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      LinearProgressIndicator(
                        value: progress > 0 && progress < 1 ? progress : null,
                      ),
                      const SizedBox(height: 12),
                      Text(message, textAlign: TextAlign.center),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );

    try {
      final result = await _exportService.exportAnnotatedPdf(
        fileId: widget.fileId,
        courseTitle: widget.courseTitle,
        documentTitle: widget.title,
        annotationJson: _state.annotationJson,
        onProgress: (value, message) {
          progressNotifier.value = value;
          messageNotifier.value = message;
        },
      );
      if (!mounted) return;
      Navigator.pop(context);
      await _showExportSuccessDialog(result);
    } catch (_) {
      if (!mounted) return;
      Navigator.pop(context);
      await _showExportErrorDialog(
        onRetry: () => _handleExport(saveAsCopy: saveAsCopy),
      );
    } finally {
      progressNotifier.dispose();
      messageNotifier.dispose();
    }
  }

  Future<void> _showExportSuccessDialog(PdfExportResult result) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('نجاح التصدير'),
        content: Text('تم إنشاء الملف:\n${result.fileName}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
          FilledButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _shareService.shareExportedPdf(
                  file: result.file,
                  subject: widget.title,
                );
              } catch (_) {
                if (!mounted) return;
                _showSnackBar('تعذر فتح نافذة المشاركة');
              }
            },
            icon: const Icon(Icons.share_outlined),
            label: const Text('مشاركة'),
          ),
        ],
      ),
    );
  }

  Future<void> _showExportErrorDialog({required VoidCallback onRetry}) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تعذر التصدير'),
        content: const Text('حدث خطأ أثناء إنشاء ملف PDF. يمكنك المحاولة مرة أخرى.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إغلاق')),
          FilledButton(onPressed: () {
            Navigator.pop(context);
            onRetry();
          }, child: const Text('إعادة المحاولة')),
        ],
      ),
    );
  }

  void _openMoreMenu() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.cardWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.save_as_outlined),
                title: const Text('حفظ التعديلات'),
                onTap: () {
                  Navigator.pop(context);
                  _handleSave();
                },
              ),
              ListTile(
                leading: const Icon(Icons.file_copy_outlined),
                title: const Text('حفظ نسخة جديدة'),
                onTap: () {
                  Navigator.pop(context);
                  _handleExport(saveAsCopy: true);
                },
              ),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf_outlined),
                title: const Text('تصدير PDF مدمج'),
                onTap: () {
                  Navigator.pop(context);
                  _handleExport(saveAsCopy: false);
                },
              ),
              SwitchListTile(
                secondary: const Icon(Icons.touch_app_outlined),
                title: const Text('الرسم بالإصبع'),
                value: _state.allowFingerDrawing,
                onChanged: (value) => _editor.setAllowFingerDrawing(value),
              ),
              ListTile(
                leading: const Icon(Icons.view_carousel_outlined),
                title: const Text('صور الصفحات'),
                subtitle: const Text('الانتقال السريع بين الصفحات'),
                onTap: () {
                  Navigator.pop(context);
                  _openPagePicker();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _openPagePicker() {
    if (_state.totalPages <= 0) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardWhite,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.5,
          builder: (context, scrollController) {
            return ListView.builder(
              controller: scrollController,
              itemCount: _state.totalPages,
              itemBuilder: (context, index) {
                final page = index + 1;
                return ListTile(
                  title: Text('الصفحة $page'),
                  trailing: _state.currentPage == page
                      ? const Icon(Icons.check, color: AppColors.accent)
                      : null,
                  onTap: () {
                    _pdfController.jumpToPage(page);
                    Navigator.pop(context);
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  void _openSearch() {
    _showSnackBar('البحث متاح للملفات التي تحتوي على نص قابل للاستخراج — قريباً');
  }

  void _handleToolSelected(PdfEditorTool tool) {
    final previousTool = _state.currentTool;
    _editor.setTool(tool);

    if (tool == PdfEditorTool.shapes) {
      if (previousTool != PdfEditorTool.shapes) {
        _showShapePicker();
      }
      return;
    }

    if (tool == PdfEditorTool.text) {
      if (previousTool != PdfEditorTool.text) {
        showTextSettingsSheet(
          context,
          settings: _state.textSettings,
          onChanged: _editor.setTextSettings,
        );
      }
      return;
    }

    if (tool == PdfEditorTool.pen ||
        tool == PdfEditorTool.highlighter ||
        tool == PdfEditorTool.eraser) {
      if (previousTool != tool) {
        showPenSettingsSheet(
          context,
          tool: tool,
          penSettings: _state.penSettings,
          highlighterSettings: _state.highlighterSettings,
          eraserMode: _state.eraserMode,
          eraserSize: _state.eraserSize,
          onPenChanged: _editor.setPenSettings,
          onHighlighterChanged: _editor.setHighlighterSettings,
          onEraserModeChanged: _editor.setEraserMode,
          onEraserSizeChanged: _editor.setEraserSize,
        );
      }
    }
  }

  void _showShapePicker() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.cardWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'اختر الشكل',
                  style: AppTextStyles.subtitle.copyWith(color: AppColors.primary),
                  textAlign: TextAlign.right,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.end,
                  children: [
                    _ShapeOption(
                      label: 'مستطيل',
                      icon: Icons.crop_square_outlined,
                      onTap: () {
                        _editor.setShapeTool(PdfEditorShapeTool.rectangle);
                        Navigator.pop(context);
                      },
                    ),
                    _ShapeOption(
                      label: 'دائرة',
                      icon: Icons.circle_outlined,
                      onTap: () {
                        _editor.setShapeTool(PdfEditorShapeTool.circle);
                        Navigator.pop(context);
                      },
                    ),
                    _ShapeOption(
                      label: 'خط',
                      icon: Icons.remove,
                      onTap: () {
                        _editor.setShapeTool(PdfEditorShapeTool.line);
                        Navigator.pop(context);
                      },
                    ),
                    _ShapeOption(
                      label: 'سهم',
                      icon: Icons.arrow_right_alt,
                      onTap: () {
                        _editor.setShapeTool(PdfEditorShapeTool.arrow);
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  int get _currentPageRotation => _pageRotations[_state.currentPage] ?? 0;

  @override
  Widget build(BuildContext context) {
    ref.listen(pdfEditorControllerProvider(widget.fileId), (prev, next) {
      if (next.loadFailed && prev?.loadFailed != true && next.errorMessage != null) {
        _showSnackBar(next.errorMessage!);
      }
      if (next.errorMessage != null &&
          next.errorMessage != prev?.errorMessage &&
          next.saveStatus == PdfSaveStatus.failed) {
        _showSnackBar(next.errorMessage!);
      }
    });

    final isTabletLandscape = MediaQuery.sizeOf(context).shortestSide >= 600 &&
        MediaQuery.orientationOf(context) == Orientation.landscape;

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyZ, control: true): () {
          if (_editor.canUndo) _editor.undo();
        },
        const SingleActivator(LogicalKeyboardKey.keyZ, meta: true): () {
          if (_editor.canUndo) _editor.undo();
        },
        const SingleActivator(LogicalKeyboardKey.keyZ, shift: true, control: true):
            () {
          if (_editor.canRedo) _editor.redo();
        },
        const SingleActivator(LogicalKeyboardKey.keyZ, shift: true, meta: true):
            () {
          if (_editor.canRedo) _editor.redo();
        },
        const SingleActivator(LogicalKeyboardKey.keyS, control: true): _handleSave,
        const SingleActivator(LogicalKeyboardKey.keyS, meta: true): _handleSave,
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          backgroundColor: AppColors.background,
          appBar: PdfEditorHeader(
            fileName: widget.title,
            currentPage: _state.currentPage,
            totalPages: _state.totalPages,
            saveStatus: _state.saveStatus,
            onBack: () => Navigator.maybePop(context),
            onSearch: _openSearch,
            onMore: _openMoreMenu,
            onSave: _handleSave,
            onRetrySave: _handleSave,
          ),
          body: _buildBody(),
          bottomNavigationBar: isTabletLandscape
              ? null
              : PdfEditorToolbar(
                  currentTool: _state.currentTool,
                  canUndo: _editor.canUndo,
                  canRedo: _editor.canRedo,
                  visible: _state.toolbarVisible,
                  expanded: _state.toolbarExpanded,
                  isTabletLandscape: false,
                  onToolSelected: _handleToolSelected,
                  onUndo: _editor.undo,
                  onRedo: _editor.redo,
                  onToggleExpanded: _editor.toggleToolbarExpanded,
                  onToggleVisibility: _editor.toggleToolbar,
                ),
          floatingActionButton: null,
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_hasError) {
      return ErrorView(
        message: _loadErrorMessage ?? 'تعذر فتح ملف PDF، يرجى المحاولة لاحقاً',
        onRetry: _preparePdfSource,
      );
    }

    if (_isLoading || _pdfBytes == null) {
      return const LoadingWidget(message: 'جاري تحميل ملف PDF...');
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        _viewportSize = Size(constraints.maxWidth, constraints.maxHeight);
        final isViewTool = _state.currentTool == PdfEditorTool.view;

        return Stack(
          children: [
            IgnorePointer(
              ignoring: !isViewTool,
              child: SfPdfViewer.memory(
              _pdfBytes!,
              controller: _pdfController,
              pageLayoutMode: PdfPageLayoutMode.single,
              scrollDirection: PdfScrollDirection.vertical,
              canShowScrollHead: false,
              canShowScrollStatus: false,
              canShowPaginationDialog: false,
              enableDoubleTapZooming: true,
              enableTextSelection: isViewTool,
              canShowTextSelectionMenu: false,
              canShowHyperlinkDialog: false,
              onDocumentLoaded: (details) => _handleDocumentLoaded(details),
              onDocumentLoadFailed: (_) {
                if (!mounted) return;
                setState(() {
                  _isLoading = false;
                  _hasError = true;
                  _loadErrorMessage = 'تعذر فتح ملف PDF، يرجى المحاولة لاحقاً';
                });
              },
              onPageChanged: (details) {
                _editor.setCurrentPage(details.newPageNumber);
                final pageSize = _pageSizes[details.newPageNumber];
                if (pageSize != null) {
                  _pdfPageSize = pageSize;
                  _editor.registerPageSize(
                    details.newPageNumber,
                    pageSize.width,
                    pageSize.height,
                  );
                  setState(() {});
                }
              },
              onZoomLevelChanged: (details) {
                _editor.setZoomLevel(details.newZoomLevel);
              },
            ),
            ),
            if (!_isLoading && _viewportSize != Size.zero)
              PdfAnnotationOverlayHost(
                pdfController: _pdfController,
                viewportSize: _viewportSize,
                pdfPageSize: _pdfPageSize,
                pageRotationDegrees: _currentPageRotation,
                passThroughTouches: isViewTool,
                tool: _state.currentTool,
                annotations: _state.currentPageAnnotations,
                penSettings: _state.penSettings,
                highlighterSettings: _state.highlighterSettings,
                eraserMode: _state.eraserMode,
                eraserSize: _state.eraserSize,
                allowFingerDrawing: _state.allowFingerDrawing,
                shapeTool: _state.shapeTool,
                selectedAnnotationId: _state.selectedAnnotationId,
                pageNumber: _state.currentPage,
                onInkComplete: (points, type) {
                  if (type == AnnotationType.highlighter) {
                    _editor.addInkStroke(
                      pageNumber: _state.currentPage,
                      points: points,
                      type: type,
                      color: _state.highlighterSettings.color,
                      strokeWidth: _state.highlighterSettings.strokeWidth,
                      opacity: _state.highlighterSettings.opacity,
                    );
                  } else {
                    _editor.addInkStroke(
                      pageNumber: _state.currentPage,
                      points: points,
                      type: type,
                      color: _state.penSettings.color,
                      strokeWidth: _state.penSettings.strokeWidth,
                      opacity: _state.penSettings.opacity,
                      penKind: _state.penSettings.penKind,
                    );
                  }
                },
                onHighlightComplete: (x, y, width, height) {
                  _editor.addHighlightRect(
                    pageNumber: _state.currentPage,
                    x: x,
                    y: y,
                    width: width,
                    height: height,
                    color: _state.highlighterSettings.color,
                    opacity: _state.highlighterSettings.opacity,
                  );
                },
                onShapeComplete: (x, y, width, height) {
                  _editor.addShape(
                    pageNumber: _state.currentPage,
                    shape: _state.shapeTool,
                    x: x,
                    y: y,
                    width: width,
                    height: height,
                    strokeColor: _state.penSettings.color,
                    strokeWidth: _state.penSettings.strokeWidth,
                    opacity: _state.penSettings.opacity,
                  );
                },
                onNoteTap: _showNoteDialog,
                onTextTap: _showTextDialog,
                onErase: (point) {
                  _editor.eraseAtPoint(
                    pageNumber: _state.currentPage,
                    point: point,
                    radius: _state.eraserSize,
                  );
                },
                onNoteMarkerTap: _showExistingNote,
                onSelectAnnotation: (id) {
                  _editor.selectAnnotation(id);
                  if (id != null && _state.currentTool == PdfEditorTool.lasso) {
                    final annotation = _state.currentPageAnnotations
                        .firstWhere((item) => item.id == id);
                    if (annotation.type != AnnotationType.text &&
                        annotation.type != AnnotationType.note) {
                      _showSelectionActions(annotation);
                    }
                  }
                },
                onMoveAnnotation: (id, x, y) {
                  _editor.moveAnnotation(
                    id: id,
                    pageNumber: _state.currentPage,
                    x: x,
                    y: y,
                  );
                },
                onBatchBegin: _editor.beginBatch,
                onBatchEnd: _editor.endBatch,
                onTextAnnotationTap: _showTextEditDialog,
              ),
            if (_isLoading) const LoadingWidget(message: 'جاري تحميل ملف PDF...'),
            if (MediaQuery.sizeOf(context).shortestSide >= 600 &&
                MediaQuery.orientationOf(context) == Orientation.landscape)
              PdfEditorToolbar(
                currentTool: _state.currentTool,
                canUndo: _editor.canUndo,
                canRedo: _editor.canRedo,
                visible: _state.toolbarVisible,
                expanded: _state.toolbarExpanded,
                isTabletLandscape: true,
                onToolSelected: _handleToolSelected,
                onUndo: _editor.undo,
                onRedo: _editor.redo,
                onToggleExpanded: _editor.toggleToolbarExpanded,
                onToggleVisibility: _editor.toggleToolbar,
              ),
          ],
        );
      },
    );
  }

  void _handleDocumentLoaded(PdfDocumentLoadedDetails details) {
    if (!mounted) return;
    final pageCount = _pdfController.pageCount;
    if (details.document.pages.count > 0) {
      for (var i = 0; i < details.document.pages.count; i++) {
        final page = details.document.pages[i];
        _pageSizes[i + 1] = Size(page.size.width, page.size.height);
        _pageRotations[i + 1] = _rotationDegrees(page.rotation);
      }
      final firstPage = details.document.pages[0];
      _pdfPageSize = Size(firstPage.size.width, firstPage.size.height);
      _editor.registerPageSize(1, firstPage.size.width, firstPage.size.height);
    }
    setState(() => _isLoading = false);
    _editor.setTotalPages(pageCount);
    _editor.setCurrentPage(_pdfController.pageNumber);
    if (!_sessionRestored) {
      _sessionRestored = true;
      _editor.restoreSession(
        PdfViewerSessionController(
          (page) => _pdfController.jumpToPage(page),
          (zoom) => _pdfController.zoomLevel = zoom,
        ),
      );
    }
  }

  int _rotationDegrees(dynamic rotation) {
    final name = rotation.toString();
    if (name.contains('rotateAngle90')) return 90;
    if (name.contains('rotateAngle180')) return 180;
    if (name.contains('rotateAngle270')) return 270;
    return 0;
  }
}

class _ShapeOption extends StatelessWidget {
  const _ShapeOption({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
