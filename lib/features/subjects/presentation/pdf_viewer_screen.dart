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
import '../../pdf_editor/services/pdf_share_service.dart';
import '../../pdf_editor/services/pdf_viewer_source_loader.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/subjects_repository.dart';
import '../../pdf_editor/widgets/annotation_text_dialog.dart';
import '../../pdf_editor/widgets/pdf_annotation_overlay_host.dart';
import '../../pdf_editor/widgets/pdf_editor_toolbar.dart';
import '../../pdf_editor/widgets/pen_settings_sheet.dart';
import '../../pdf_editor/widgets/text_settings_sheet.dart';
import '../../../core/l10n/app_strings.dart';
import '../data/document_format.dart';
import '../data/office_document_pdf_converter.dart';

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

  PdfViewerSourceLoader _sourceLoader() {
    final userId = ref.read(authControllerProvider).user?.id;
    return PdfViewerSourceLoader(
      userId: userId,
      repository: ref.read(subjectsRepositoryProvider),
    );
  }

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
      final bytes = await _sourceLoader().load(
        fileId: widget.fileId,
        repository: ref.read(subjectsRepositoryProvider),
      );
      if (!mounted) return;

      final format = detectDocumentFormat(bytes);
      if (format == DocumentFormat.oleDoc) {
        setState(() {
          _hasError = true;
          _isLoading = false;
          _loadErrorMessage =
              'تعذر عرض ملف Word القديم. ارفع الملف بصيغة DOCX أو PDF.';
        });
        return;
      }

      var pdfBytes = bytes;
      if (format != DocumentFormat.pdf) {
        pdfBytes = await OfficeDocumentPdfConverter().convert(bytes);
        await _sourceLoader().saveConverted(widget.fileId, pdfBytes);
      }

      if (!mounted) return;
      setState(() {
        _pdfBytes = pdfBytes;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _isLoading = false;
        _loadErrorMessage = 'تعذر فتح الملف، يرجى المحاولة لاحقاً';
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
      ref
          .read(pdfEditorControllerProvider(widget.fileId).notifier)
          .flushOnBackground();
    }
  }

  PdfEditorController get _editor =>
      ref.read(pdfEditorControllerProvider(widget.fileId).notifier);

  PdfEditorState get _state =>
      ref.watch(pdfEditorControllerProvider(widget.fileId));

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(AppStrings.of(context).t(message))));
  }

  Future<void> _showNoteDialog(double x, double y) async {
    final text = await showDialog<String>(
      context: context,
      builder: (context) => const AnnotationTextDialog(
        title: 'إضافة ملاحظة',
        hintText: 'اكتب ملاحظتك هنا',
        maxLines: 4,
        cancelLabel: 'إلغاء',
        confirmLabel: 'حفظ',
      ),
    );

    if (text == null || text.trim().isEmpty || !mounted) return;
    _editor.addNote(pageNumber: _state.currentPage, x: x, y: y, text: text);
  }

  Future<void> _showTextDialog(double x, double y) async {
    final text = await showDialog<String>(
      context: context,
      builder: (context) => const AnnotationTextDialog(
        title: 'إضافة نص',
        hintText: 'اكتب النص',
        cancelLabel: 'إلغاء',
        confirmLabel: 'إضافة',
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
    final text = await showDialog<String>(
      context: context,
      builder: (context) => AnnotationTextDialog(
        title: 'تعديل النص',
        initialText: annotation.data['text']?.toString() ?? '',
        cancelLabel: 'إلغاء',
        confirmLabel: 'حفظ',
        deleteLabel: 'حذف',
        onDelete: () {
          _editor.deleteAnnotation(annotation.id, annotation.pageNumber);
          _editor.selectAnnotation(null);
        },
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

  void _handleAnnotationTap(PdfEditorAnnotation annotation) {
    switch (annotation.type) {
      case AnnotationType.text:
        _showTextEditDialog(annotation);
      case AnnotationType.note:
        _showExistingNote(annotation);
      default:
        _showSelectionActions(annotation);
    }
  }

  void _showSelectionActions(PdfEditorAnnotation annotation) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.of(context).cardWhite,
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
                  title: Text(AppStrings.of(context).t('تعديل النص')),
                  onTap: () {
                    Navigator.pop(context);
                    _showTextEditDialog(annotation);
                  },
                ),
              if (annotation.type == AnnotationType.note)
                ListTile(
                  leading: const Icon(Icons.sticky_note_2_outlined),
                  title: Text(AppStrings.of(context).t('فتح الملاحظة')),
                  onTap: () {
                    Navigator.pop(context);
                    _showExistingNote(annotation);
                  },
                ),
              ListTile(
                leading: Icon(
                  Icons.delete_outline,
                  color: AppColors.of(context).error,
                ),
                title: Text(AppStrings.of(context).t('حذف')),
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

  Future<void> _showExistingNote(PdfEditorAnnotation note) async {
    final text = await showDialog<String>(
      context: context,
      builder: (context) => AnnotationTextDialog(
        title: 'ملاحظة',
        initialText: note.data['text']?.toString() ?? '',
        maxLines: 5,
        autofocus: false,
        cancelLabel: 'إغلاق',
        confirmLabel: 'حفظ',
        deleteLabel: 'حذف',
        onDelete: () => _editor.deleteAnnotation(note.id, note.pageNumber),
      ),
    );

    if (text == null || !mounted) return;
    _editor.updateNoteText(note.id, note.pageNumber, text);
  }

  Future<void> _handleSave() async {
    await _editor.saveToServer();
    if (!mounted) return;
    // `_state` is captured during build, so re-read the post-save status.
    final saveStatus = ref
        .read(pdfEditorControllerProvider(widget.fileId))
        .saveStatus;
    if (saveStatus == PdfSaveStatus.saved) {
      _showSnackBar('تم حفظ جميع التعديلات');
    }
  }

  Future<void> _handleExport({required bool saveAsCopy}) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          AppStrings.of(context).t(saveAsCopy ? 'حفظ نسخة جديدة' : 'تصدير PDF'),
        ),
        content: Text(
          AppStrings.of(context).t(
            saveAsCopy
                ? 'سيتم إنشاء نسخة PDF جديدة تحتوي على التعليقات مع الاحتفاظ بالملف الأصلي.'
                : 'سيتم تصدير نسخة PDF تحتوي على التعليقات المدمجة.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppStrings.of(context).t('إلغاء')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppStrings.of(context).t('متابعة')),
          ),
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
              builder: (context, message, child) {
                return AlertDialog(
                  title: Text(AppStrings.of(context).t('تصدير PDF')),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      LinearProgressIndicator(
                        value: progress > 0 && progress < 1 ? progress : null,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        AppStrings.of(context).t(message),
                        textAlign: TextAlign.center,
                      ),
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
        title: Text(AppStrings.of(context).t('نجاح التصدير')),
        content: Text(
          AppStrings.of(context).t('تم إنشاء الملف:\n${result.fileName}'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppStrings.of(context).t('إغلاق')),
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
            label: Text(AppStrings.of(context).t('مشاركة')),
          ),
        ],
      ),
    );
  }

  Future<void> _showExportErrorDialog({required VoidCallback onRetry}) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppStrings.of(context).t('تعذر التصدير')),
        content: Text(
          AppStrings.of(
            context,
          ).t('حدث خطأ أثناء إنشاء ملف PDF. يمكنك المحاولة مرة أخرى.'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppStrings.of(context).t('إغلاق')),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              onRetry();
            },
            child: Text(AppStrings.of(context).t('إعادة المحاولة')),
          ),
        ],
      ),
    );
  }

  void _openMoreMenu() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.of(context).cardWhite,
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
                title: Text(AppStrings.of(context).t('حفظ التعديلات')),
                onTap: () {
                  Navigator.pop(context);
                  _handleSave();
                },
              ),
              ListTile(
                leading: const Icon(Icons.file_copy_outlined),
                title: Text(AppStrings.of(context).t('حفظ نسخة جديدة')),
                onTap: () {
                  Navigator.pop(context);
                  _handleExport(saveAsCopy: true);
                },
              ),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf_outlined),
                title: Text(AppStrings.of(context).t('تصدير PDF مدمج')),
                onTap: () {
                  Navigator.pop(context);
                  _handleExport(saveAsCopy: false);
                },
              ),
              SwitchListTile(
                secondary: const Icon(Icons.touch_app_outlined),
                title: Text(AppStrings.of(context).t('الرسم بالإصبع')),
                value: _state.allowFingerDrawing,
                onChanged: (value) => _editor.setAllowFingerDrawing(value),
              ),
              ListTile(
                leading: const Icon(Icons.view_carousel_outlined),
                title: Text(AppStrings.of(context).t('صور الصفحات')),
                subtitle: Text(
                  AppStrings.of(context).t('الانتقال السريع بين الصفحات'),
                ),
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
      backgroundColor: AppColors.of(context).cardWhite,
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
                  title: Text(AppStrings.of(context).t('الصفحة $page')),
                  trailing: _state.currentPage == page
                      ? Icon(Icons.check, color: AppColors.of(context).accent)
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
    _showSnackBar(
      'البحث متاح للملفات التي تحتوي على نص قابل للاستخراج — قريباً',
    );
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
      backgroundColor: AppColors.of(context).cardWhite,
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
                  AppStrings.of(context).t('اختر الشكل'),
                  style: AppTextStyles.subtitleOf(
                    context,
                  ).copyWith(color: AppColors.of(context).primary),
                  textAlign: TextAlign.right,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.end,
                  children: [
                    _ShapeOption(
                      label: AppStrings.of(context).t('مستطيل'),
                      icon: Icons.crop_square_outlined,
                      onTap: () {
                        _editor.setShapeTool(PdfEditorShapeTool.rectangle);
                        Navigator.pop(context);
                      },
                    ),
                    _ShapeOption(
                      label: AppStrings.of(context).t('دائرة'),
                      icon: Icons.circle_outlined,
                      onTap: () {
                        _editor.setShapeTool(PdfEditorShapeTool.circle);
                        Navigator.pop(context);
                      },
                    ),
                    _ShapeOption(
                      label: AppStrings.of(context).t('خط'),
                      icon: Icons.remove,
                      onTap: () {
                        _editor.setShapeTool(PdfEditorShapeTool.line);
                        Navigator.pop(context);
                      },
                    ),
                    _ShapeOption(
                      label: AppStrings.of(context).t('سهم'),
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
      if (next.loadFailed &&
          prev?.loadFailed != true &&
          next.errorMessage != null) {
        _showSnackBar(next.errorMessage!);
      }
      if (next.errorMessage != null &&
          next.errorMessage != prev?.errorMessage &&
          next.saveStatus == PdfSaveStatus.failed) {
        _showSnackBar(next.errorMessage!);
      }
    });

    final isTabletLandscape =
        MediaQuery.sizeOf(context).shortestSide >= 600 &&
        MediaQuery.orientationOf(context) == Orientation.landscape;

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyZ, control: true): () {
          if (_editor.canUndo) _editor.undo();
        },
        const SingleActivator(LogicalKeyboardKey.keyZ, meta: true): () {
          if (_editor.canUndo) _editor.undo();
        },
        const SingleActivator(
          LogicalKeyboardKey.keyZ,
          shift: true,
          control: true,
        ): () {
          if (_editor.canRedo) _editor.redo();
        },
        const SingleActivator(
          LogicalKeyboardKey.keyZ,
          shift: true,
          meta: true,
        ): () {
          if (_editor.canRedo) _editor.redo();
        },
        const SingleActivator(LogicalKeyboardKey.keyS, control: true):
            _handleSave,
        const SingleActivator(LogicalKeyboardKey.keyS, meta: true): _handleSave,
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          backgroundColor: AppColors.of(context).background,
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
        message: _loadErrorMessage ?? 'تعذر فتح الملف، يرجى المحاولة لاحقاً',
        onRetry: _preparePdfSource,
      );
    }

    if (_isLoading || _pdfBytes == null) {
      return LoadingWidget(
        message: AppStrings.of(context).t('جاري تحميل الملف...'),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Sizing the viewer to the page's own aspect ratio makes the rendered
        // page fill its box exactly, so the annotation overlay lines up with
        // the page instead of guessing where the viewer placed it.
        _viewportSize = PdfCoordinateMapper.fitPageInViewport(
          pageSize: PdfCoordinateMapper.effectivePageSize(
            width: _pdfPageSize.width,
            height: _pdfPageSize.height,
            rotationDegrees: _currentPageRotation,
          ),
          viewportSize: Size(constraints.maxWidth, constraints.maxHeight),
        );
        final isViewTool = _state.currentTool == PdfEditorTool.view;

        return Stack(
          children: [
            Center(
              child: SizedBox.fromSize(
                size: _viewportSize,
                child: Stack(
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
                        onDocumentLoaded: (details) =>
                            _handleDocumentLoaded(details),
                        onDocumentLoadFailed: (_) {
                          if (!mounted) return;
                          setState(() {
                            _isLoading = false;
                            _hasError = true;
                            _loadErrorMessage =
                                'تعذر فتح ملف PDF، يرجى المحاولة لاحقاً';
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
                              strokeWidth:
                                  _state.highlighterSettings.strokeWidth,
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
                        onBatchBegin: _editor.beginBatch,
                        onBatchEnd: _editor.endBatch,
                        onAnnotationTap: _handleAnnotationTap,
                      ),
                  ],
                ),
              ),
            ),
            if (_isLoading)
              LoadingWidget(
                message: AppStrings.of(context).t('جاري تحميل ملف PDF...'),
              ),
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
      color: AppColors.of(context).background,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: AppColors.of(context).primary, size: 20),
              const SizedBox(width: 6),
              Text(
                AppStrings.of(context).t(label),
                style: AppTextStyles.bodyOf(context).copyWith(
                  color: AppColors.of(context).primary,
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
