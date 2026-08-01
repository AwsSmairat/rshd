import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_widget.dart';
import '../widgets/pdf_annotation_overlay.dart';
import 'pdf_annotation_controller.dart';

/// In-app PDF viewer with MVP annotations support.
///
/// TODO: Replace demo PDF URL with Bunny.net / Cloudflare R2 secure URL later.
/// TODO: Export annotated PDF.
/// TODO: Add Apple Pencil optimized support.
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

class _PdfViewerScreenState extends ConsumerState<PdfViewerScreen> {
  final PdfViewerController _pdfController = PdfViewerController();
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(pdfAnnotationControllerProvider(widget.fileId).notifier)
          .load(widget.fileId);
    });
  }

  @override
  void dispose() {
    _pdfController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _showNoteDialog(Offset position) async {
    final controller = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('إضافة ملاحظة'),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'اكتب ملاحظتك هنا',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('حفظ'),
            ),
          ],
        );
      },
    );

    if (text == null || text.trim().isEmpty || !mounted) {
      return;
    }

    final annotationState = ref.read(pdfAnnotationControllerProvider(widget.fileId));
    ref.read(pdfAnnotationControllerProvider(widget.fileId).notifier).addNote(
          annotationState.currentPage,
          position.dx,
          position.dy,
          text,
        );
  }

  void _showExistingNote(Map<String, dynamic> note) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('ملاحظة'),
          content: Text(note['text']?.toString() ?? ''),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إغلاق'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveAnnotations() async {
    final saved = await ref
        .read(pdfAnnotationControllerProvider(widget.fileId).notifier)
        .save(widget.fileId);

    if (!mounted) {
      return;
    }

    if (saved) {
      _showSnackBar('تم حفظ الملاحظات');
    }
  }

  @override
  Widget build(BuildContext context) {
    final fileUrl = widget.fileUrl.trim();
    final annotationState = ref.watch(pdfAnnotationControllerProvider(widget.fileId));

    ref.listen(pdfAnnotationControllerProvider(widget.fileId), (prev, next) {
      if (next.loadFailed &&
          next.errorMessage != null &&
          prev?.loadFailed != true) {
        _showSnackBar('تعذر تحميل الملاحظات السابقة');
      }

      if (next.errorMessage != null &&
          next.errorMessage != prev?.errorMessage &&
          next.status != PdfAnnotationStatus.saving) {
        _showSnackBar(next.errorMessage!);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: _buildBody(fileUrl, annotationState),
      bottomNavigationBar: _AnnotationToolbar(
        currentTool: annotationState.currentTool,
        isSaving: annotationState.status == PdfAnnotationStatus.saving,
        onToolSelected: (tool) => ref
            .read(pdfAnnotationControllerProvider(widget.fileId).notifier)
            .setTool(tool),
        onSave: _saveAnnotations,
      ),
    );
  }

  Widget _buildBody(String fileUrl, PdfAnnotationState annotationState) {
    if (fileUrl.isEmpty) {
      return const ErrorView(message: 'رابط الملف غير متوفر حالياً');
    }

    final uri = Uri.tryParse(fileUrl);
    if (uri == null || !uri.hasScheme) {
      return const ErrorView(
        message: 'تعذر فتح ملف PDF، يرجى المحاولة لاحقاً',
      );
    }

    if (_hasError) {
      return ErrorView(
        message: 'تعذر فتح ملف PDF، يرجى المحاولة لاحقاً',
        onRetry: () {
          setState(() {
            _hasError = false;
            _isLoading = true;
          });
        },
      );
    }

    return Stack(
      children: [
        SfPdfViewer.network(
          fileUrl,
          controller: _pdfController,
          canShowScrollHead: false,
          canShowScrollStatus: false,
          canShowPaginationDialog: false,
          enableTextSelection: false,
          canShowTextSelectionMenu: false,
          canShowHyperlinkDialog: false,
          onDocumentLoaded: (_) {
            if (!mounted) {
              return;
            }
            setState(() => _isLoading = false);
            ref
                .read(pdfAnnotationControllerProvider(widget.fileId).notifier)
                .setCurrentPage(_pdfController.pageNumber);
          },
          onDocumentLoadFailed: (_) {
            if (!mounted) {
              return;
            }
            setState(() {
              _isLoading = false;
              _hasError = true;
            });
          },
          onPageChanged: (details) {
            ref
                .read(pdfAnnotationControllerProvider(widget.fileId).notifier)
                .setCurrentPage(details.newPageNumber);
          },
        ),
        if (!_isLoading)
          PdfAnnotationOverlay(
            tool: annotationState.currentTool,
            pageData: annotationState.currentPageData,
            onDrawingComplete: (points) {
              ref
                  .read(pdfAnnotationControllerProvider(widget.fileId).notifier)
                  .addDrawing(annotationState.currentPage, points);
            },
            onNotePositionSelected: _showNoteDialog,
            onHighlightComplete: (rect) {
              ref
                  .read(pdfAnnotationControllerProvider(widget.fileId).notifier)
                  .addHighlight(
                    annotationState.currentPage,
                    rect.left,
                    rect.top,
                    rect.width,
                    rect.height,
                  );
            },
            onNoteMarkerTap: _showExistingNote,
          ),
        if (_isLoading)
          const LoadingWidget(message: 'جاري تحميل ملف PDF...'),
      ],
    );
  }
}

class _AnnotationToolbar extends StatelessWidget {
  const _AnnotationToolbar({
    required this.currentTool,
    required this.isSaving,
    required this.onToolSelected,
    required this.onSave,
  });

  final PdfAnnotationTool currentTool;
  final bool isSaving;
  final ValueChanged<PdfAnnotationTool> onToolSelected;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      elevation: 6,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              _ToolChip(
                label: 'عرض',
                icon: Icons.visibility_outlined,
                selected: currentTool == PdfAnnotationTool.view,
                onTap: () => onToolSelected(PdfAnnotationTool.view),
              ),
              _ToolChip(
                label: 'قلم',
                icon: Icons.draw_outlined,
                selected: currentTool == PdfAnnotationTool.pen,
                onTap: () => onToolSelected(PdfAnnotationTool.pen),
              ),
              _ToolChip(
                label: 'ملاحظة',
                icon: Icons.sticky_note_2_outlined,
                selected: currentTool == PdfAnnotationTool.note,
                onTap: () => onToolSelected(PdfAnnotationTool.note),
              ),
              _ToolChip(
                label: 'تحديد',
                icon: Icons.highlight_outlined,
                selected: currentTool == PdfAnnotationTool.highlight,
                onTap: () => onToolSelected(PdfAnnotationTool.highlight),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: isSaving ? null : onSave,
                icon: isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: const Text('حفظ'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToolChip extends StatelessWidget {
  const _ToolChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.secondary.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.secondary : const Color(0xFFE5E7EB),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected ? AppColors.secondary : AppColors.textMuted,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: AppTextStyles.body.copyWith(
                  fontSize: 11,
                  color: selected ? AppColors.secondary : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
