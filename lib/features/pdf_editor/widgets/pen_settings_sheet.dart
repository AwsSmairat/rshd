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

  static const penColors = [
    Color(0xFF111827),
    Color(0xFF234E70),
    Color(0xFFB42318),
    Color(0xFF067647),
    Color(0xFFD6B56D),
  ];

  static const highlighterColors = [
    Color(0xFFFFEB3B),
    Color(0xFF81C784),
    Color(0xFF64B5F6),
    Color(0xFFF48FB1),
    Color(0xFFFFB74D),
  ];

  static const penWidthPresets = <(String, double)>[
    ('رفيع', 0.002),
    ('متوسط', 0.004),
    ('عريض', 0.008),
  ];

  @override
  State<PenSettingsSheet> createState() => _PenSettingsSheetState();
}

class _PenSettingsSheetState extends State<PenSettingsSheet> {
  late PenSettings _penSettings;
  late HighlighterSettings _highlighterSettings;
  late EraserMode _eraserMode;
  late double _eraserSize;

  @override
  void initState() {
    super.initState();
    _penSettings = widget.penSettings;
    _highlighterSettings = widget.highlighterSettings;
    _eraserMode = widget.eraserMode;
    _eraserSize = widget.eraserSize;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
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
                widget.tool == PdfEditorTool.highlighter) ...[
              _ColorRow(
                colors: widget.tool == PdfEditorTool.highlighter
                    ? PenSettingsSheet.highlighterColors
                    : PenSettingsSheet.penColors,
                selected: _currentColor,
                onSelected: _updateColor,
              ),
              const SizedBox(height: 16),
              if (widget.tool == PdfEditorTool.pen) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.end,
                  children: PenSettingsSheet.penWidthPresets.map((preset) {
                    final selected =
                        (_currentStrokeWidth - preset.$2).abs() < 0.0005;
                    return ChoiceChip(
                      label: Text(preset.$1),
                      selected: selected,
                      onSelected: (_) => _updateStrokeWidth(preset.$2),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
              ],
              Text('السماكة', style: AppTextStyles.caption),
              Slider(
                value: _currentStrokeWidth.clamp(
                  widget.tool == PdfEditorTool.highlighter ? 0.01 : 0.002,
                  widget.tool == PdfEditorTool.highlighter ? 0.05 : 0.02,
                ),
                min: widget.tool == PdfEditorTool.highlighter ? 0.01 : 0.002,
                max: widget.tool == PdfEditorTool.highlighter ? 0.05 : 0.02,
                activeColor: AppColors.primary,
                onChanged: _updateStrokeWidth,
              ),
              Text('الشفافية', style: AppTextStyles.caption),
              Slider(
                value: _currentOpacity.clamp(0.1, 1),
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
                  ButtonSegment(value: EraserMode.whole, label: Text('عنصر')),
                  ButtonSegment(value: EraserMode.partial, label: Text('جزء')),
                ],
                selected: {_eraserMode},
                onSelectionChanged: (values) {
                  setState(() => _eraserMode = values.first);
                  widget.onEraserModeChanged(values.first);
                },
              ),
              const SizedBox(height: 12),
              Text('حجم الممحاة', style: AppTextStyles.caption),
              Slider(
                value: _eraserSize.clamp(0.005, 0.04),
                min: 0.005,
                max: 0.04,
                activeColor: AppColors.primary,
                onChanged: (value) {
                  setState(() => _eraserSize = value);
                  widget.onEraserSizeChanged(value);
                },
              ),
            ],
          ],
        ),
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
      ? _highlighterSettings.color
      : _penSettings.color;

  double get _currentStrokeWidth => widget.tool == PdfEditorTool.highlighter
      ? _highlighterSettings.strokeWidth
      : _penSettings.strokeWidth;

  double get _currentOpacity => widget.tool == PdfEditorTool.highlighter
      ? _highlighterSettings.opacity
      : _penSettings.opacity;

  void _updateColor(Color color) {
    setState(() {
      if (widget.tool == PdfEditorTool.highlighter) {
        _highlighterSettings = _highlighterSettings.copyWith(color: color);
        widget.onHighlighterChanged(_highlighterSettings);
      } else {
        _penSettings = _penSettings.copyWith(color: color);
        widget.onPenChanged(_penSettings);
      }
    });
  }

  void _updateStrokeWidth(double value) {
    setState(() {
      if (widget.tool == PdfEditorTool.highlighter) {
        _highlighterSettings = _highlighterSettings.copyWith(
          strokeWidth: value,
        );
        widget.onHighlighterChanged(_highlighterSettings);
      } else {
        _penSettings = _penSettings.copyWith(strokeWidth: value);
        widget.onPenChanged(_penSettings);
      }
    });
  }

  void _updateOpacity(double value) {
    setState(() {
      if (widget.tool == PdfEditorTool.highlighter) {
        _highlighterSettings = _highlighterSettings.copyWith(opacity: value);
        widget.onHighlighterChanged(_highlighterSettings);
      } else {
        _penSettings = _penSettings.copyWith(opacity: value);
        widget.onPenChanged(_penSettings);
      }
    });
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
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => onSelected(color),
            customBorder: const CircleBorder(),
            child: Container(
              width: 36,
              height: 36,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.accent : Colors.transparent,
                  width: 2,
                ),
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
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
    isDismissible: true,
    enableDrag: true,
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
