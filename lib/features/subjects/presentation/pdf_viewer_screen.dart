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
import '../../pdf_editor/services/pdf_coordinate_mapper.dart';
import '../../pdf_editor/services/pdf_export_service.dart';
import '../../pdf_editor/widgets/pdf_editor_toolbar.dart';
import '../../pdf_editor/widgets/pdf_page_annotation_layer.dart';
import '../../pdf_editor/widgets/pen_settings_sheet.dart';

/// Professional in-app PDF editor with page-bound annotations.
class PdfViewerScreen extends ConsumerStatefulWidget {
  const PdfViewerScreen({
    super.key,
    required this.fileId,
    required this.title,
    required this.fileUrl,
  });

  final int fileId;
  final String title;
  final String fileUrl;

  @override
  ConsumerState<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends ConsumerState<PdfViewerScreen>
    with WidgetsBindingObserver {
  final PdfViewerController _pdfController = PdfViewerController();
  final PdfExportService _exportService = PdfExportService();

  bool _isLoading = true;
  bool _hasError = false;
  Size _viewportSize = Size.zero;
  Size _pdfPageSize = const Size(595, 842);
  final Map<int, Size> _pageSizes = {};
  bool _sessionRestored = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(pdfEditorControllerProvider(widget.fileId).notifier).load();
    });
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
      color: _state.penSettings.color,
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

    var progress = 0.0;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            return AlertDialog(
              title: const Text('جاري التصدير'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LinearProgressIndicator(value: progress),
                  const SizedBox(height: 12),
                  Text('${(progress * 100).round()}%'),
                ],
              ),
            );
          },
        );
      },
    );

    try {
      final file = await _exportService.exportAnnotatedPdf(
        sourceUrl: widget.fileUrl,
        originalFileName: widget.title,
        annotationJson: _state.annotationJson,
        onProgress: (value, _) {
          progress = value;
        },
      );
      if (!mounted) return;
      Navigator.pop(context);
      _showSnackBar('تم حفظ النسخة: ${file.path.split('/').last}');
    } catch (_) {
      if (!mounted) return;
      Navigator.pop(context);
      _showSnackBar('تعذر تصدير الملف');
    }
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
    _editor.setTool(tool);

    if (tool == PdfEditorTool.shapes) {
      _showShapePicker();
      return;
    }

    if (tool == PdfEditorTool.pen ||
        tool == PdfEditorTool.highlighter ||
        tool == PdfEditorTool.eraser) {
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

  PdfPageLayoutMetrics _metrics(PdfEditorState state) {
    return PdfPageLayoutMetrics(
      pdfPageSize: _pdfPageSize,
      viewportSize: _viewportSize,
      zoomLevel: state.zoomLevel,
    );
  }

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

    final fileUrl = widget.fileUrl.trim();
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
          body: _buildBody(fileUrl),
          bottomNavigationBar: isTabletLandscape
              ? null
              : PdfEditorToolbar(
                  currentTool: _state.currentTool,
                  canUndo: _editor.canUndo,
                  canRedo: _editor.canRedo,
                  visible: _state.toolbarVisible,
                  isTabletLandscape: false,
                  onToolSelected: _handleToolSelected,
                  onUndo: _editor.undo,
                  onRedo: _editor.redo,
                  onToggleVisibility: _editor.toggleToolbar,
                ),
          floatingActionButton: null,
        ),
      ),
    );
  }

  Widget _buildBody(String fileUrl) {
    if (fileUrl.isEmpty) {
      return const ErrorView(message: 'رابط الملف غير متوفر حالياً');
    }

    final uri = Uri.tryParse(fileUrl);
    if (uri == null || !uri.hasScheme) {
      return const ErrorView(message: 'تعذر فتح ملف PDF، يرجى المحاولة لاحقاً');
    }

    if (_hasError) {
      return ErrorView(
        message: 'تعذر فتح ملف PDF، يرجى المحاولة لاحقاً',
        onRetry: () => setState(() {
          _hasError = false;
          _isLoading = true;
        }),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        _viewportSize = Size(constraints.maxWidth, constraints.maxHeight);
        final metrics = _metrics(_state);

        return Stack(
          children: [
            SfPdfViewer.network(
              fileUrl,
              controller: _pdfController,
              pageLayoutMode: PdfPageLayoutMode.single,
              scrollDirection: PdfScrollDirection.vertical,
              canShowScrollHead: false,
              canShowScrollStatus: false,
              canShowPaginationDialog: false,
              enableTextSelection: _state.currentTool == PdfEditorTool.view,
              canShowTextSelectionMenu: false,
              canShowHyperlinkDialog: false,
              onDocumentLoaded: (details) {
                if (!mounted) return;
                final pageCount = _pdfController.pageCount;
                if (details.document.pages.count > 0) {
                  for (var i = 0; i < details.document.pages.count; i++) {
                    final page = details.document.pages[i];
                    _pageSizes[i + 1] =
                        Size(page.size.width, page.size.height);
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
              },
              onDocumentLoadFailed: (_) {
                if (!mounted) return;
                setState(() {
                  _isLoading = false;
                  _hasError = true;
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
            if (!_isLoading && _viewportSize != Size.zero)
              PdfPageAnnotationLayer(
                tool: _state.currentTool,
                annotations: _state.currentPageAnnotations,
                metrics: metrics,
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
                onSelectAnnotation: _editor.selectAnnotation,
                onMoveAnnotation: (id, x, y) {
                  _editor.moveAnnotation(
                    id: id,
                    pageNumber: _state.currentPage,
                    x: x,
                    y: y,
                  );
                },
              ),
            if (_isLoading) const LoadingWidget(message: 'جاري تحميل ملف PDF...'),
            if (MediaQuery.sizeOf(context).shortestSide >= 600 &&
                MediaQuery.orientationOf(context) == Orientation.landscape)
              PdfEditorToolbar(
                currentTool: _state.currentTool,
                canUndo: _editor.canUndo,
                canRedo: _editor.canRedo,
                visible: _state.toolbarVisible,
                isTabletLandscape: true,
                onToolSelected: _handleToolSelected,
                onUndo: _editor.undo,
                onRedo: _editor.redo,
                onToggleVisibility: _editor.toggleToolbar,
              ),
          ],
        );
      },
    );
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
