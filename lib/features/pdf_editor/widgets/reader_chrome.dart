import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdfrx/pdfrx.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/rshd_loader.dart';
import '../models/annotation_enums.dart';
import 'eraser_icon.dart';
import 'pen_settings_sheet.dart';

const _navy = Color(0xFF0B1F3A);

/// Frosted surface shared by the reader's floating bars.
class _Frosted extends StatelessWidget {
  const _Frosted({
    required this.child,
    this.radius = 22,
    this.padding = EdgeInsets.zero,
  });

  final Widget child;
  final double radius;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shape = BorderRadius.circular(radius);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: shape,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.10),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: shape,
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: shape,
              color: colors.cardWhite.withValues(alpha: isDark ? 0.86 : 0.9),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : _navy.withValues(alpha: 0.06),
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _BarIcon extends StatelessWidget {
  const _BarIcon({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onTap,
      icon: Icon(icon, size: 22),
      color: color ?? AppColors.of(context).text,
      style: IconButton.styleFrom(minimumSize: const Size(44, 44)),
    );
  }
}

/// Top of the reader: back, the document title with the page it's on, and
/// the document actions (pages, search, save, more).
class ReaderTopBar extends StatelessWidget {
  const ReaderTopBar({
    super.key,
    required this.title,
    required this.currentPage,
    required this.totalPages,
    required this.saveStatus,
    required this.onBack,
    required this.onPages,
    required this.onSearch,
    required this.onSave,
    required this.onMore,
  });

  final String title;
  final int currentPage;
  final int totalPages;
  final PdfSaveStatus saveStatus;
  final VoidCallback onBack;
  final VoidCallback onPages;
  final VoidCallback onSearch;
  final VoidCallback onSave;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final colors = AppColors.of(context);
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return Container(
      color: colors.background,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 56,
          child: Row(
            children: [
              const SizedBox(width: 4),
              _BarIcon(
                icon: isRtl
                    ? Icons.arrow_forward_ios_rounded
                    : Icons.arrow_back_ios_new_rounded,
                tooltip: strings.back,
                onTap: onBack,
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      strings.t(title),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: colors.text,
                      ),
                    ),
                    if (totalPages > 0)
                      Text(
                        strings.t('صفحة $currentPage من $totalPages'),
                        style: TextStyle(
                          fontSize: 11.5,
                          color: colors.textMuted,
                        ),
                      ),
                  ],
                ),
              ),
              _SaveIndicator(status: saveStatus, onSave: onSave),
              _BarIcon(
                icon: Icons.grid_view_rounded,
                tooltip: strings.t('الصفحات'),
                onTap: onPages,
              ),
              _BarIcon(
                icon: Icons.search_rounded,
                tooltip: strings.t('بحث'),
                onTap: onSearch,
              ),
              _BarIcon(
                icon: Icons.more_horiz_rounded,
                tooltip: strings.t('المزيد'),
                onTap: onMore,
              ),
              const SizedBox(width: 4),
            ],
          ),
        ),
      ),
    );
  }
}

/// Cloud-style save state: a quiet tick when saved, a loader while saving,
/// a tappable warning when it failed.
class _SaveIndicator extends StatelessWidget {
  const _SaveIndicator({required this.status, required this.onSave});

  final PdfSaveStatus status;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final colors = AppColors.of(context);
    if (status == PdfSaveStatus.saving) {
      return const SizedBox(
        width: 44,
        child: Center(child: RshdLoader(size: 9)),
      );
    }
    final (icon, color, label) = switch (status) {
      PdfSaveStatus.saved => (
        Icons.cloud_done_outlined,
        const Color(0xFF15803D),
        'تم الحفظ',
      ),
      PdfSaveStatus.unsaved => (
        Icons.cloud_upload_outlined,
        colors.darkGold,
        'حفظ',
      ),
      PdfSaveStatus.offlinePending => (
        Icons.cloud_off_outlined,
        colors.textMuted,
        'محفوظ على الجهاز',
      ),
      _ => (
        Icons.error_outline_rounded,
        colors.error,
        'تعذر الحفظ — أعد المحاولة',
      ),
    };
    return _BarIcon(
      icon: icon,
      tooltip: strings.t(label),
      color: color,
      onTap: status == PdfSaveStatus.saved ? null : onSave,
    );
  }
}

class _ToolSpec {
  const _ToolSpec(this.tool, this.label, this.icon);

  final PdfEditorTool tool;
  final String label;
  final IconData icon;
}

const _tools = [
  _ToolSpec(PdfEditorTool.view, 'تصفّح', Icons.pan_tool_alt_outlined),
  _ToolSpec(PdfEditorTool.pen, 'قلم', Icons.edit_outlined),
  _ToolSpec(PdfEditorTool.highlighter, 'تظليل', Icons.border_color_outlined),
  _ToolSpec(PdfEditorTool.eraser, 'ممحاة', Icons.auto_fix_normal_outlined),
  _ToolSpec(PdfEditorTool.lasso, 'تحديد', Icons.gesture_rounded),
  _ToolSpec(PdfEditorTool.shapes, 'أشكال', Icons.category_outlined),
  _ToolSpec(PdfEditorTool.text, 'نص', Icons.text_fields_rounded),
  _ToolSpec(PdfEditorTool.note, 'ملاحظة', Icons.sticky_note_2_outlined),
];

/// The floating tool palette: every tool one tap away, the pen or
/// highlighter colours inline while that tool is active, and undo/redo.
/// Tapping the active tool again opens its settings.
class ReaderToolPalette extends StatelessWidget {
  const ReaderToolPalette({
    super.key,
    required this.currentTool,
    required this.penColor,
    required this.highlighterColor,
    required this.canUndo,
    required this.canRedo,
    required this.onToolSelected,
    required this.onColorSelected,
    required this.onUndo,
    required this.onRedo,
  });

  final PdfEditorTool currentTool;
  final Color penColor;
  final Color highlighterColor;
  final bool canUndo;
  final bool canRedo;
  final ValueChanged<PdfEditorTool> onToolSelected;
  final ValueChanged<Color> onColorSelected;
  final VoidCallback onUndo;
  final VoidCallback onRedo;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final colors = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final swatches = switch (currentTool) {
      PdfEditorTool.pen => (PenSettingsSheet.penColors, penColor),
      PdfEditorTool.highlighter => (
        PenSettingsSheet.highlighterColors,
        highlighterColor,
      ),
      _ => null,
    };

    Widget divider() => Container(
      width: 1,
      height: 26,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      color: colors.textMuted.withValues(alpha: 0.2),
    );

    return _Frosted(
      radius: 26,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final spec in _tools)
              _ToolButton(
                spec: spec,
                selected: spec.tool == currentTool,
                onTap: () {
                  HapticFeedback.selectionClick();
                  onToolSelected(spec.tool);
                },
              ),
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              child: swatches == null
                  ? const SizedBox.shrink()
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        divider(),
                        for (final c in swatches.$1)
                          _Swatch(
                            color: c,
                            selected: c.toARGB32() == swatches.$2.toARGB32(),
                            onTap: () => onColorSelected(c),
                          ),
                      ],
                    ),
            ),
            divider(),
            IconButton(
              tooltip: strings.t('تراجع'),
              onPressed: canUndo ? onUndo : null,
              icon: const Icon(Icons.undo_rounded, size: 21),
              color: isDark ? colors.accent : _navy,
              disabledColor: colors.textMuted.withValues(alpha: 0.35),
            ),
            IconButton(
              tooltip: strings.t('إعادة'),
              onPressed: canRedo ? onRedo : null,
              icon: const Icon(Icons.redo_rounded, size: 21),
              color: isDark ? colors.accent : _navy,
              disabledColor: colors.textMuted.withValues(alpha: 0.35),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({
    required this.spec,
    required this.selected,
    required this.onTap,
  });

  final _ToolSpec spec;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fill = isDark ? colors.accent : _navy;
    final strings = AppStrings.of(context);
    final iconColor = selected
        ? (isDark ? _navy : Colors.white)
        : colors.text.withValues(alpha: 0.8);

    return Tooltip(
      message: strings.t(spec.label),
      child: Semantics(
        button: true,
        selected: selected,
        label: strings.t(spec.label),
        excludeSemantics: true,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            width: 44,
            height: 44,
            margin: const EdgeInsets.symmetric(horizontal: 1),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected ? fill : Colors.transparent,
            ),
            child: spec.tool == PdfEditorTool.eraser
                ? Center(child: EraserIcon(size: 21, color: iconColor))
                : Icon(spec.icon, size: 21, color: iconColor),
          ),
        ),
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        width: 36,
        height: 44,
        alignment: Alignment.center,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: selected ? 26 : 22,
          height: selected ? 26 : 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            border: Border.all(
              color: selected ? colors.cardWhite : Colors.transparent,
              width: 2.5,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.6),
                      blurRadius: 0,
                      spreadRadius: 2,
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 3,
                    ),
                  ],
          ),
        ),
      ),
    );
  }
}

/// The zoom at which the page fills the screen the way the reader opens it:
/// the whole page when paging sideways, the page width when scrolling down.
double readerFitZoom(
  PdfViewerController controller, {
  required bool horizontal,
}) {
  if (horizontal) return controller.minScale;
  return math.max(controller.coverScale, controller.minScale);
}

/// Bottom of the reader: zoom controls with the live zoom level, and the
/// page counter that opens the page overview.
class ReaderBottomBar extends StatelessWidget {
  const ReaderBottomBar({
    super.key,
    required this.controller,
    required this.currentPage,
    required this.totalPages,
    required this.onPages,
    this.horizontal = false,
  });

  final PdfViewerController controller;
  final int currentPage;
  final int totalPages;
  final VoidCallback onPages;

  /// Whether pages are laid out side by side (one whole page fitted)
  /// rather than in a column (page width fitted).
  final bool horizontal;

  /// Each tap on + or − changes the zoom by a quarter, in small even steps.
  static const _zoomStep = 1.25;

  void _zoomBy(double factor) {
    final target = (controller.currentZoom * factor).clamp(
      controller.minScale,
      controller.maxScale,
    );
    controller.setZoom(
      controller.centerPosition,
      target,
      duration: const Duration(milliseconds: 220),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final colors = AppColors.of(context);

    return Row(
      children: [
        _Frosted(
          radius: 22,
          child: AnimatedBuilder(
            animation: controller,
            builder: (context, _) {
              final ready = controller.isReady;
              // 100% = the page fitted to the screen.
              final fit = ready
                  ? readerFitZoom(controller, horizontal: horizontal)
                  : 0.0;
              final percent = fit > 0
                  ? (controller.currentZoom / fit * 100).round()
                  : 100;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: strings.t('تصغير'),
                    onPressed:
                        ready &&
                            controller.currentZoom > controller.minScale * 1.01
                        ? () => _zoomBy(1 / _zoomStep)
                        : null,
                    icon: const Icon(Icons.remove_rounded, size: 20),
                  ),
                  GestureDetector(
                    // Tap the level to go back to the fitted page.
                    onTap: ready
                        ? () => controller.setZoom(
                            controller.centerPosition,
                            fit,
                            duration: const Duration(milliseconds: 260),
                          )
                        : null,
                    child: SizedBox(
                      width: 52,
                      child: Text(
                        '$percent%',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: colors.text,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: strings.t('تكبير'),
                    onPressed:
                        ready &&
                            controller.currentZoom < controller.maxScale * 0.99
                        ? () => _zoomBy(_zoomStep)
                        : null,
                    icon: const Icon(Icons.add_rounded, size: 20),
                  ),
                ],
              );
            },
          ),
        ),
        const Spacer(),
        if (totalPages > 0)
          GestureDetector(
            onTap: onPages,
            child: _Frosted(
              radius: 22,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.layers_outlined,
                    size: 18,
                    color: colors.textMuted,
                  ),
                  const SizedBox(width: 8),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: SlideTransition(
                        position: Tween(
                          begin: const Offset(0, 0.4),
                          end: Offset.zero,
                        ).animate(anim),
                        child: child,
                      ),
                    ),
                    child: Text(
                      '$currentPage / $totalPages',
                      key: ValueKey(currentPage),
                      // "3 / 25" reads left to right in Arabic too.
                      textDirection: TextDirection.ltr,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: colors.text,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Every page as a thumbnail; the current one framed in gold. Picking a
/// page closes the overview and glides there.
Future<void> showReaderPages(
  BuildContext context, {
  required PdfDocument document,
  required int currentPage,
  required ValueChanged<int> onSelect,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _PagesSheet(
      document: document,
      currentPage: currentPage,
      onSelect: (page) {
        Navigator.of(context).pop();
        onSelect(page);
      },
    ),
  );
}

class _PagesSheet extends StatelessWidget {
  const _PagesSheet({
    required this.document,
    required this.currentPage,
    required this.onSelect,
  });

  final PdfDocument document;
  final int currentPage;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final strings = AppStrings.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final columns = width >= 900 ? 5 : (width >= 600 ? 4 : 3);
    final count = document.pages.length;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scroll) => Container(
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.textMuted.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
              child: Row(
                children: [
                  Text(
                    strings.t('الصفحات'),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: colors.text,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$count',
                    style: TextStyle(fontSize: 14, color: colors.textMuted),
                  ),
                ],
              ),
            ),
            Expanded(
              child: GridView.builder(
                controller: scroll,
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 14,
                  childAspectRatio: 0.66,
                ),
                itemCount: count,
                itemBuilder: (context, i) {
                  final page = i + 1;
                  final current = page == currentPage;
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onSelect(page);
                    },
                    child: Column(
                      children: [
                        Expanded(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: current
                                    ? colors.darkGold
                                    : Colors.transparent,
                                width: 2.5,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.08,
                                      ),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                                child: PdfPageView(
                                  document: document,
                                  pageNumber: page,
                                  maximumDpi: 72,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: current
                                ? colors.darkGold
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '$page',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: current ? Colors.white : colors.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
