import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfrx/pdfrx.dart' show PdfViewerController;

import '../../../core/network/api_client.dart';
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
import '../../pdf_editor/widgets/pdf_document_view.dart';
import '../../pdf_editor/widgets/pdf_page_annotation_layer.dart';
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
  bool _sessionRestored = false;

  /// Student's chosen way of moving through pages; remembered per device.
  PdfReadingDirection _direction = PdfReadingDirection.vertical;

  /// Header and toolbar are shown. Picking a writing tool hides them so the
  /// page fills the screen; the side rail brings them back.
  bool _chromeVisible = true;
  static const _directionKey = 'pdf_reading_direction';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(pdfEditorControllerProvider(widget.fileId).notifier).load();
      _loadReadingDirection();
      _preparePdfSource();
    });
  }

  Future<void> _loadReadingDirection() async {
    final stored = await ref.read(secureStorageProvider).read(_directionKey);
    if (!mounted || stored == null) return;
    final direction = PdfReadingDirection.values
        .where((d) => d.name == stored)
        .firstOrNull;
    if (direction != null && direction != _direction) {
      setState(() => _direction = direction);
    }
  }

  Future<void> _setReadingDirection(PdfReadingDirection direction) async {
    if (direction == _direction) return;
    setState(() => _direction = direction);
    await ref.read(secureStorageProvider).write(_directionKey, direction.name);
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

  Future<void> _showNoteDialog(int pageNumber, double x, double y) async {
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
    _editor.addNote(pageNumber: pageNumber, x: x, y: y, text: text);
  }

  Future<void> _showTextDialog(int pageNumber, double x, double y) async {
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
      pageNumber: pageNumber,
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
      final pdfBytes = _pdfBytes;
      if (pdfBytes == null || pdfBytes.isEmpty) {
        throw Exception('مصدر ملف PDF غير متوفر');
      }

      final result = await _exportService.exportAnnotatedPdf(
        sourceBytes: pdfBytes,
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
              _ReadingDirectionPicker(
                value: _direction,
                onChanged: (direction) {
                  Navigator.pop(context);
                  _setReadingDirection(direction);
                },
              ),
              const Divider(height: 1),
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
                    _pdfController.goToPage(pageNumber: page);
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
    setState(() => _chromeVisible = tool == PdfEditorTool.view);

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
          appBar: !_chromeVisible
              ? null
              : PdfEditorHeader(
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
          bottomNavigationBar: isTabletLandscape || !_chromeVisible
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

    final isViewTool = _state.currentTool == PdfEditorTool.view;

    return Stack(
      children: [
        Positioned.fill(
          child: PdfDocumentView(
            bytes: _pdfBytes!,
            sourceName: 'lesson-file-${widget.fileId}',
            controller: _pdfController,
            direction: _direction,
            interactive: isViewTool,
            onReady: _handleDocumentReady,
            onPageChanged: _editor.setCurrentPage,
            pageOverlayBuilder: _buildPageOverlay,
          ),
        ),
        if (_chromeVisible &&
            MediaQuery.sizeOf(context).shortestSide >= 600 &&
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
        if (!_chromeVisible)
          PositionedDirectional(
            end: 10,
            top: 0,
            bottom: 0,
            child: SafeArea(
              child: Center(
                child: _WritingRail(
                  tool: _state.currentTool,
                  canUndo: _editor.canUndo,
                  canRedo: _editor.canRedo,
                  onShowTools: () => setState(() => _chromeVisible = true),
                  onUndo: _editor.undo,
                  onRedo: _editor.redo,
                  onDone: () => _handleToolSelected(PdfEditorTool.view),
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// Annotation layer for one page, laid out in that page's own space.
  ///
  /// [pageSize] is the page as currently displayed (already zoomed), so the
  /// layer needs no scroll or zoom of its own: normalised coordinates map
  /// straight onto it, and stroke widths — stored relative to page width —
  /// scale with the page.
  Widget _buildPageOverlay(Size pageSize, int pageNumber) {
    final metrics = PdfPageLayoutMetrics(
      displayPageSize: pageSize,
      viewportSize: pageSize,
      zoomLevel: 1,
    );

    return IgnorePointer(
      ignoring: _state.currentTool == PdfEditorTool.view,
      child: PdfPageAnnotationLayer(
        tool: _state.currentTool,
        annotations: _state.document.annotationsForPage(pageNumber),
        metrics: metrics,
        penSettings: _state.penSettings,
        highlighterSettings: _state.highlighterSettings,
        eraserMode: _state.eraserMode,
        eraserSize: _state.eraserSize,
        allowFingerDrawing: _state.allowFingerDrawing,
        shapeTool: _state.shapeTool,
        selectedAnnotationId: _state.selectedAnnotationId,
        pageNumber: pageNumber,
        onInkComplete: (points, type) {
          _editor.setCurrentPage(pageNumber);
          if (type == AnnotationType.highlighter) {
            _editor.addInkStroke(
              pageNumber: pageNumber,
              points: points,
              type: type,
              color: _state.highlighterSettings.color,
              strokeWidth: _state.highlighterSettings.strokeWidth,
              opacity: _state.highlighterSettings.opacity,
            );
          } else {
            _editor.addInkStroke(
              pageNumber: pageNumber,
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
            pageNumber: pageNumber,
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
            pageNumber: pageNumber,
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
        onNoteTap: (x, y) => _showNoteDialog(pageNumber, x, y),
        onTextTap: (x, y) => _showTextDialog(pageNumber, x, y),
        onErase: (point) {
          _editor.eraseAtPoint(
            pageNumber: pageNumber,
            point: point,
            radius: _state.eraserSize,
          );
        },
        onNoteMarkerTap: _showExistingNote,
        onSelectAnnotation: _editor.selectAnnotation,
        onMoveAnnotation: (id, x, y) {
          _editor.moveAnnotation(id: id, pageNumber: pageNumber, x: x, y: y);
        },
        onBatchBegin: _editor.beginBatch,
        onBatchEnd: _editor.endBatch,
        onAnnotationTap: _handleAnnotationTap,
      ),
    );
  }

  void _handleDocumentReady(int pageCount, Map<int, PdfPageInfo> pages) {
    if (!mounted) return;
    for (final entry in pages.entries) {
      _editor.registerPageSize(
        entry.key,
        entry.value.width,
        entry.value.height,
      );
    }
    _editor.setTotalPages(pageCount);
    if (!_sessionRestored) {
      _sessionRestored = true;
      // Only the page is restored: zoom levels saved by the old viewer used a
      // different scale and would land at the wrong magnification.
      _editor.restoreSession(
        PdfViewerSessionController(
          (page) => _pdfController.goToPage(pageNumber: page),
          (_) {},
        ),
      );
    }
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

/// Two large choices for how pages move: down, or sideways.
class _ReadingDirectionPicker extends StatelessWidget {
  const _ReadingDirectionPicker({required this.value, required this.onChanged});

  final PdfReadingDirection value;
  final ValueChanged<PdfReadingDirection> onChanged;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final colors = AppColors.of(context);

    Widget option(PdfReadingDirection direction, IconData icon, String label) {
      final selected = direction == value;
      return Expanded(
        child: Material(
          color: selected
              ? colors.accent.withValues(alpha: 0.16)
              : colors.background,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => onChanged(direction),
            child: Container(
              height: 86,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: selected
                      ? colors.accent
                      : colors.textMuted.withValues(alpha: 0.2),
                  width: selected ? 1.5 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 28,
                    color: selected ? colors.darkGold : colors.textMuted,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    strings.t(label),
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                      color: colors.text,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            strings.t('طريقة التصفح'),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: colors.textMuted,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              option(
                PdfReadingDirection.vertical,
                Icons.swap_vert_rounded,
                'للأسفل',
              ),
              const SizedBox(width: 12),
              option(
                PdfReadingDirection.horizontal,
                Icons.swap_horiz_rounded,
                'للجانب',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Floating side rail shown while writing full screen: the active tool (tap
/// to bring back every tool), undo, redo, and done.
class _WritingRail extends StatelessWidget {
  const _WritingRail({
    required this.tool,
    required this.canUndo,
    required this.canRedo,
    required this.onShowTools,
    required this.onUndo,
    required this.onRedo,
    required this.onDone,
  });

  final PdfEditorTool tool;
  final bool canUndo;
  final bool canRedo;
  final VoidCallback onShowTools;
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final VoidCallback onDone;

  static IconData _toolIcon(PdfEditorTool tool) => switch (tool) {
    PdfEditorTool.pen => Icons.draw_outlined,
    PdfEditorTool.highlighter => Icons.highlight_outlined,
    PdfEditorTool.eraser => Icons.auto_fix_off_outlined,
    PdfEditorTool.lasso => Icons.crop_free_outlined,
    PdfEditorTool.text => Icons.text_fields_outlined,
    PdfEditorTool.note => Icons.sticky_note_2_outlined,
    PdfEditorTool.shapes => Icons.category_outlined,
    _ => Icons.pan_tool_alt_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final strings = AppStrings.of(context);
    const navy = Color(0xFF0B1F3A);

    Widget action(
      IconData icon,
      String tooltip,
      VoidCallback? onPressed, {
      Color? color,
    }) {
      return IconButton(
        tooltip: strings.t(tooltip),
        onPressed: onPressed,
        icon: Icon(icon, size: 22),
        color: color ?? navy,
        disabledColor: navy.withValues(alpha: 0.25),
      );
    }

    return Material(
      color: colors.cardWhite.withValues(alpha: 0.96),
      elevation: 6,
      shadowColor: navy.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
        side: BorderSide(color: navy.withValues(alpha: 0.08)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Tooltip(
              message: strings.t('الأدوات'),
              child: InkWell(
                onTap: onShowTools,
                customBorder: const CircleBorder(),
                child: Container(
                  width: 44,
                  height: 44,
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: navy,
                    shape: BoxShape.circle,
                    border: Border.all(color: colors.accent, width: 1.5),
                  ),
                  child: Icon(_toolIcon(tool), color: colors.accent, size: 22),
                ),
              ),
            ),
            const SizedBox(height: 4),
            action(Icons.undo_rounded, 'تراجع', canUndo ? onUndo : null),
            action(Icons.redo_rounded, 'إعادة', canRedo ? onRedo : null),
            action(
              Icons.check_rounded,
              'إنهاء الكتابة',
              onDone,
              color: colors.accent,
            ),
          ],
        ),
      ),
    );
  }
}
