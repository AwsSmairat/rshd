import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';

/// Visual state of the whole code row.
enum OtpStatus {
  /// Normal entry.
  idle,

  /// The code was accepted: every cell turns green and shows a check.
  verified,
}

class OtpInputRow extends StatefulWidget {
  const OtpInputRow({
    super.key,
    required this.length,
    required this.onCompleted,
    this.onChanged,
    this.status = OtpStatus.idle,
  });

  final int length;
  final ValueChanged<String> onCompleted;
  final ValueChanged<String>? onChanged;
  final OtpStatus status;

  @override
  State<OtpInputRow> createState() => OtpInputRowState();
}

class OtpInputRowState extends State<OtpInputRow> {
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(widget.length, (_) => TextEditingController());
    _focusNodes = List.generate(widget.length, (_) => FocusNode());
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  String get value => _controllers.map((c) => c.text).join();

  void clear() {
    for (final controller in _controllers) {
      controller.clear();
    }
    _focusNodes.first.requestFocus();
    widget.onChanged?.call('');
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: LayoutBuilder(
        builder: (context, constraints) {
          const gap = 10.0;
          final cellWidth =
              (constraints.maxWidth - gap * (widget.length - 1)) /
              widget.length;
          // Cells read as squares that comfortably hold the glyph rather than
          // thin slots: height tracks width, with sane bounds.
          final cellHeight = (cellWidth * 1.22).clamp(56.0, 72.0);
          final fontSize = (cellHeight * 0.42).clamp(20.0, 28.0);
          final colors = AppColors.of(context);
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final isVerified = widget.status == OtpStatus.verified;

          return Row(
            children: List.generate(widget.length, (index) {
              return Padding(
                padding: EdgeInsetsDirectional.only(
                  start: index == 0 ? 0 : gap,
                ),
                child: isVerified
                    ? _VerifiedCell(width: cellWidth, height: cellHeight)
                    : SizedBox(
                        width: cellWidth,
                        height: cellHeight,
                        child: TextField(
                          controller: _controllers[index],
                          focusNode: _focusNodes[index],
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          textInputAction: index == widget.length - 1
                              ? TextInputAction.done
                              : TextInputAction.next,
                          obscureText: false,
                          autocorrect: false,
                          enableSuggestions: false,
                          autofillHints: index == 0
                              ? const [AutofillHints.oneTimeCode]
                              : null,
                          maxLength: 1,
                          style: TextStyle(
                            fontSize: fontSize,
                            fontWeight: FontWeight.w700,
                            color: colors.text,
                            height: 1.1,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: InputDecoration(
                            counterText: '',
                            filled: true,
                            // Theme-aware: a hard white cell would glare on the
                            // dark surface.
                            fillColor: isDark
                                ? colors.white.withValues(alpha: 0.07)
                                : colors.white.withValues(alpha: 0.9),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 17,
                            ),
                            isDense: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: isDark
                                    ? colors.white.withValues(alpha: 0.12)
                                    : colors.primary.withValues(alpha: 0.09),
                                // Constant width so the digit never shifts when a
                                // cell takes focus.
                                width: 1.5,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: colors.accent,
                                width: 1.5,
                              ),
                            ),
                          ),
                          onChanged: (value) {
                            if (value.length > 1) {
                              _handlePaste(value);
                              return;
                            }
                            if (value.isNotEmpty && index < widget.length - 1) {
                              _focusNodes[index + 1].requestFocus();
                            }
                            if (value.isEmpty && index > 0) {
                              _focusNodes[index - 1].requestFocus();
                            }
                            widget.onChanged?.call(this.value);
                            if (this.value.length == widget.length) {
                              widget.onCompleted(this.value);
                            }
                          },
                        ),
                      ),
              );
            }),
          );
        },
      ),
    );
  }

  void _handlePaste(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    for (var i = 0; i < widget.length; i++) {
      _controllers[i].text = i < digits.length ? digits[i] : '';
    }
    final code = value;
    widget.onChanged?.call(code);
    if (code.length == widget.length) {
      widget.onCompleted(code);
      FocusScope.of(context).unfocus();
    }
  }
}

/// A cell once the code has been accepted: green ground with a check.
class _VerifiedCell extends StatelessWidget {
  const _VerifiedCell({required this.width, required this.height});

  static const _green = Color(0xFF17865A);

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.85, end: 1),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: _green.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _green, width: 1.5),
        ),
        child: Center(
          child: Icon(Icons.check_rounded, size: height * 0.46, color: _green),
        ),
      ),
    );
  }
}
