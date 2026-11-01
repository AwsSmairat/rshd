import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

/// How the student moves through the document.
enum PdfReadingDirection {
  /// Pages stacked top to bottom, scrolled continuously.
  vertical,

  /// One page at a time, swiped sideways.
  horizontal,
}

/// Size and rotation of a page as stored by the annotation document.
///
/// The size is the *unrotated* page box, which is what earlier versions of
/// the viewer recorded, so existing saved annotations stay compatible.
class PdfPageInfo {
  const PdfPageInfo({
    required this.width,
    required this.height,
    required this.rotationDegrees,
  });

  final double width;
  final double height;
  final int rotationDegrees;
}

/// PDF document renderer that hosts one overlay *inside* every page.
///
/// The overlay lives in the page's own coordinate space, so it pans and zooms
/// with the page instead of being re-aligned from the viewer's scroll and
/// zoom after the fact. Annotations therefore stay exactly where they were
/// drawn at every zoom level, and they simply grow or shrink with the page.
class PdfDocumentView extends StatefulWidget {
  const PdfDocumentView({
    super.key,
    required this.bytes,
    required this.sourceName,
    required this.controller,
    required this.direction,
    required this.interactive,
    required this.pageOverlayBuilder,
    required this.onReady,
    required this.onPageChanged,
    this.initialPage = 1,
  });

  final Uint8List bytes;
  final String sourceName;
  final PdfViewerController controller;
  final PdfReadingDirection direction;

  /// When false (a drawing tool is active) one finger belongs to the page
  /// overlay, so it draws instead of scrolling. Two fingers still pinch to
  /// zoom and move the page.
  final bool interactive;

  /// Builds the annotation overlay for one page, sized to that page.
  final Widget Function(Size pageSize, int pageNumber) pageOverlayBuilder;

  final void Function(int pageCount, Map<int, PdfPageInfo> pages) onReady;
  final ValueChanged<int> onPageChanged;
  final int initialPage;

  @override
  State<PdfDocumentView> createState() => _PdfDocumentViewState();
}

class _PdfDocumentViewState extends State<PdfDocumentView> {
  static const _pageGap = 12.0;

  int _currentPage = 1;

  /// Fingers currently on the viewer, tracked so that a second finger can
  /// turn panning on while a drawing tool is active.
  final Set<int> _pointers = {};
  bool get _multiTouch => _pointers.length > 1;

  void _pointerDown(PointerDownEvent event) {
    final wasMulti = _multiTouch;
    _pointers.add(event.pointer);
    if (!widget.interactive && _multiTouch != wasMulti) setState(() {});
  }

  void _pointerUp(PointerEvent event) {
    final wasMulti = _multiTouch;
    _pointers.remove(event.pointer);
    if (!widget.interactive && _multiTouch != wasMulti) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage;
  }

  @override
  void didUpdateWidget(covariant PdfDocumentView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.direction != widget.direction) {
      // Changing the layout re-lays out every page; land back on the page the
      // student was reading rather than wherever the old offset falls.
      final page = _currentPage;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && widget.controller.isReady) {
          widget.controller.goToPage(
            pageNumber: page,
            anchor: PdfPageAnchor.center,
            duration: Duration.zero,
          );
        }
      });
    }
  }

  static int _degrees(PdfPageRotation rotation) => switch (rotation) {
    PdfPageRotation.clockwise90 => 90,
    PdfPageRotation.clockwise180 => 180,
    PdfPageRotation.clockwise270 => 270,
    _ => 0,
  };

  PdfPageLayout _horizontalLayout(List<PdfPage> pages, PdfViewerParams params) {
    final height =
        pages.fold<double>(0, (h, page) => math.max(h, page.height)) +
        params.margin * 2;
    final rects = <Rect>[];
    var x = params.margin;
    for (final page in pages) {
      rects.add(
        Rect.fromLTWH(x, (height - page.height) / 2, page.width, page.height),
      );
      x += page.width + params.margin;
    }
    return PdfPageLayout(pageLayouts: rects, documentSize: Size(x, height));
  }

  /// In horizontal mode a swipe should land on a whole page, like turning a
  /// page, rather than stopping half-way between two.
  void _snapToPage(ScaleEndDetails details) {
    if (widget.direction != PdfReadingDirection.horizontal) return;
    // A fast pen stroke must not turn the page.
    if (!widget.interactive) return;
    final controller = widget.controller;
    if (!controller.isReady) return;
    // When zoomed into a page the student is reading detail, not paging.
    if (controller.currentZoom > controller.minScale * 1.05) return;

    final velocity = details.velocity.pixelsPerSecond.dx;
    var target = controller.pageNumber ?? _currentPage;
    if (velocity < -250) {
      target = _currentPage + 1;
    } else if (velocity > 250) {
      target = _currentPage - 1;
    }
    target = target.clamp(1, controller.pageCount);

    controller.goToPage(
      pageNumber: target,
      anchor: PdfPageAnchor.center,
      duration: const Duration(milliseconds: 260),
    );
  }

  @override
  Widget build(BuildContext context) {
    final horizontal = widget.direction == PdfReadingDirection.horizontal;

    // The listener only observes; it takes no part in the gesture arena.
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _pointerDown,
      onPointerUp: _pointerUp,
      onPointerCancel: _pointerUp,
      child: _buildViewer(horizontal),
    );
  }

  Widget _buildViewer(bool horizontal) {
    return PdfViewer.data(
      widget.bytes,
      sourceName: widget.sourceName,
      controller: widget.controller,
      initialPageNumber: widget.initialPage,
      params: PdfViewerParams(
        margin: _pageGap,
        backgroundColor: Colors.transparent,
        panEnabled: widget.interactive || _multiTouch,
        scaleEnabled: true,
        layoutPages: horizontal ? _horizontalLayout : null,
        // Horizontal shows one whole page; vertical fits the page width.
        sizeDelegateProvider: horizontal
            ? PdfViewerSizeDelegateProviderLegacy(
                calculateInitialZoom:
                    (document, controller, fitZoom, coverZoom) => fitZoom,
              )
            : null,
        onInteractionEnd: _snapToPage,
        onViewerReady: (document, controller) {
          final pages = <int, PdfPageInfo>{};
          for (final page in document.pages) {
            final degrees = _degrees(page.rotation);
            final quarterTurn = degrees == 90 || degrees == 270;
            pages[page.pageNumber] = PdfPageInfo(
              width: quarterTurn ? page.height : page.width,
              height: quarterTurn ? page.width : page.height,
              rotationDegrees: degrees,
            );
          }
          widget.onReady(document.pages.length, pages);
        },
        onPageChanged: (pageNumber) {
          if (pageNumber == null) return;
          _currentPage = pageNumber;
          widget.onPageChanged(pageNumber);
        },
        pageOverlaysBuilder: (context, pageRect, page) => [
          SizedBox.fromSize(
            size: pageRect.size,
            child: widget.pageOverlayBuilder(pageRect.size, page.pageNumber),
          ),
        ],
      ),
    );
  }
}
