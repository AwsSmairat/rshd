import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../controllers/pdf_editor_controller.dart';
import '../models/annotation_enums.dart';

class PenSettingsSheet extends StatefulWidget {
  const PenSettingsSheet({
    super.key,
    required this.tool,
    required this.penSettings,
    required this.highlighterSettings,
    required this.eraserMode,
    required this.eraserSize,
    required this.onPenChanged,
    required this.onHighlighterChanged,
    required this.onEraserModeChanged,
    required this.onEraserSizeChanged,
  });

  final PdfEditorTool tool;
  final PenSettings penSettings;
  final HighlighterSettings highlighterSettings;
  final EraserMode eraserMode;
  final double eraserSize;
  final ValueChanged<PenSettings> onPenChanged;
  final ValueChanged<HighlighterSettings> onHighlighterChanged;
  final ValueChanged<EraserMode> onEraserModeChanged;
  final ValueChanged<double> onEraserSizeChanged;

  static const quickColors = [
    Color(0xFF0B1F3A),
    Color(0xFF111827),
    Color(0xFFB42318),
    Color(0xFF234E70),
    Color(0xFF067647),
    Color(0xFFD6B56D),
  ];

  @override
  State<PenSettingsSheet> createState() => _PenSettingsSheetState();
}

class _PenSettingsSheetState extends State<PenSettingsSheet> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textMuted.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _title,
            style: AppTextStyles.subtitle.copyWith(color: AppColors.primary),
            textAlign: TextAlign.right,
          ),
          const SizedBox(height: 16),
          if (widget.tool == PdfEditorTool.pen ||
              widget.tool == PdfEditorTool.highlighter)
            _ColorRow(
              colors: PenSettingsSheet.quickColors,
              selected: _currentColor,
              onSelected: _updateColor,
            ),
          if (widget.tool == PdfEditorTool.pen ||
              widget.tool == PdfEditorTool.highlighter) ...[
            const SizedBox(height: 16),
            Text('السماكة', style: AppTextStyles.caption),
            Slider(
              value: _currentStrokeWidth,
              min: widget.tool == PdfEditorTool.highlighter ? 0.01 : 0.002,
              max: widget.tool == PdfEditorTool.highlighter ? 0.05 : 0.02,
              activeColor: AppColors.primary,
              onChanged: _updateStrokeWidth,
            ),
            Text('الشفافية', style: AppTextStyles.caption),
            Slider(
              value: _currentOpacity,
              min: 0.1,
              max: 1,
              activeColor: AppColors.accent,
              onChanged: _updateOpacity,
            ),
            _PreviewStroke(
              color: _currentColor.withValues(alpha: _currentOpacity),
              strokeWidth: _currentStrokeWidth * 400,
            ),
          ],
          if (widget.tool == PdfEditorTool.eraser) ...[
            SegmentedButton<EraserMode>(
              segments: const [
                ButtonSegment(
                  value: EraserMode.partial,
                  label: Text('جزئي'),
                ),
                ButtonSegment(
                  value: EraserMode.whole,
                  label: Text('كامل'),
                ),
              ],
              selected: {widget.eraserMode},
              onSelectionChanged: (values) {
                widget.onEraserModeChanged(values.first);
              },
            ),
            const SizedBox(height: 12),
            Text('حجم الممحاة', style: AppTextStyles.caption),
            Slider(
              value: widget.eraserSize,
              min: 0.005,
              max: 0.04,
              activeColor: AppColors.primary,
              onChanged: widget.onEraserSizeChanged,
            ),
          ],
        ],
      ),
    );
  }

  String get _title => switch (widget.tool) {
        PdfEditorTool.pen => 'إعدادات القلم',
        PdfEditorTool.highlighter => 'إعدادات التظليل',
        PdfEditorTool.eraser => 'إعدادات الممحاة',
        _ => 'إعدادات الأداة',
      };

  Color get _currentColor => widget.tool == PdfEditorTool.highlighter
      ? widget.highlighterSettings.color
      : widget.penSettings.color;

  double get _currentStrokeWidth => widget.tool == PdfEditorTool.highlighter
      ? widget.highlighterSettings.strokeWidth
      : widget.penSettings.strokeWidth;

  double get _currentOpacity => widget.tool == PdfEditorTool.highlighter
      ? widget.highlighterSettings.opacity
      : widget.penSettings.opacity;

  void _updateColor(Color color) {
    if (widget.tool == PdfEditorTool.highlighter) {
      widget.onHighlighterChanged(widget.highlighterSettings.copyWith(color: color));
    } else {
      widget.onPenChanged(widget.penSettings.copyWith(color: color));
    }
    setState(() {});
  }

  void _updateStrokeWidth(double value) {
    if (widget.tool == PdfEditorTool.highlighter) {
      widget.onHighlighterChanged(
        widget.highlighterSettings.copyWith(strokeWidth: value),
      );
    } else {
      widget.onPenChanged(widget.penSettings.copyWith(strokeWidth: value));
    }
    setState(() {});
  }

  void _updateOpacity(double value) {
    if (widget.tool == PdfEditorTool.highlighter) {
      widget.onHighlighterChanged(
        widget.highlighterSettings.copyWith(opacity: value),
      );
    } else {
      widget.onPenChanged(widget.penSettings.copyWith(opacity: value));
    }
    setState(() {});
  }
}

class _ColorRow extends StatelessWidget {
  const _ColorRow({
    required this.colors,
    required this.selected,
    required this.onSelected,
  });

  final List<Color> colors;
  final Color selected;
  final ValueChanged<Color> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.end,
      children: colors.map((color) {
        final isSelected = color.toARGB32() == selected.toARGB32();
        return GestureDetector(
          onTap: () => onSelected(color),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? AppColors.accent : Colors.transparent,
                width: 3,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _PreviewStroke extends StatelessWidget {
  const _PreviewStroke({required this.color, required this.strokeWidth});

  final Color color;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: CustomPaint(
        size: const Size(200, 30),
        painter: _PreviewPainter(color: color, strokeWidth: strokeWidth),
      ),
    );
  }
}

class _PreviewPainter extends CustomPainter {
  _PreviewPainter({required this.color, required this.strokeWidth});

  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(8, size.height * 0.7)
      ..quadraticBezierTo(
        size.width * 0.35,
        size.height * 0.1,
        size.width * 0.65,
        size.height * 0.55,
      )
      ..quadraticBezierTo(
        size.width * 0.85,
        size.height * 0.85,
        size.width - 8,
        size.height * 0.35,
      );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _PreviewPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
  }
}

void showPenSettingsSheet(
  BuildContext context, {
  required PdfEditorTool tool,
  required PenSettings penSettings,
  required HighlighterSettings highlighterSettings,
  required EraserMode eraserMode,
  required double eraserSize,
  required ValueChanged<PenSettings> onPenChanged,
  required ValueChanged<HighlighterSettings> onHighlighterChanged,
  required ValueChanged<EraserMode> onEraserModeChanged,
  required ValueChanged<double> onEraserSizeChanged,
}) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) {
      return PenSettingsSheet(
        tool: tool,
        penSettings: penSettings,
        highlighterSettings: highlighterSettings,
        eraserMode: eraserMode,
        eraserSize: eraserSize,
        onPenChanged: onPenChanged,
        onHighlighterChanged: onHighlighterChanged,
        onEraserModeChanged: onEraserModeChanged,
        onEraserSizeChanged: onEraserSizeChanged,
      );
    },
  );
}
