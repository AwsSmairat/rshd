import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Soft-filled auth field: leading icon, label and value stacked in a single
/// rounded tile, matching the RSHD sign-in panel.
///
/// Built on [FormField] so `Form.validate()` keeps working exactly as before,
/// while the message itself renders *below* the tile instead of inside it —
/// the tile never changes shape when an error appears.
///
/// [errorText] carries server-side field errors and takes precedence over the
/// local [validator] result.
class AuthInputField extends StatefulWidget {
  const AuthInputField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.hintText,
    this.keyboardType,
    this.obscureText = false,
    this.textInputAction,
    this.validator,
    this.errorText,
    this.trailing,
    this.onFieldSubmitted,
    this.autofillHints,
    this.focusNode,
    this.readOnly = false,
    this.onTap,
  });

  /// Blocks keyboard editing; pair with [onTap] for picker-backed fields.
  final bool readOnly;

  /// Tapping anywhere on the tile triggers this (used by the date picker).
  final VoidCallback? onTap;

  /// Optional externally owned focus node; one is created when omitted.
  final FocusNode? focusNode;

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? hintText;
  final TextInputType? keyboardType;
  final bool obscureText;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final String? errorText;
  final Widget? trailing;
  final ValueChanged<String>? onFieldSubmitted;
  final Iterable<String>? autofillHints;

  @override
  State<AuthInputField> createState() => _AuthInputFieldState();
}

class _AuthInputFieldState extends State<AuthInputField> {
  /// Only non-null when this widget created the node and therefore owns it.
  FocusNode? _ownedFocusNode;
  bool _focused = false;

  FocusNode get _focusNode =>
      widget.focusNode ?? (_ownedFocusNode ??= FocusNode());

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_handleFocusChange);
  }

  void _handleFocusChange() {
    if (!mounted) {
      return;
    }
    if (_focusNode.hasFocus != _focused) {
      setState(() => _focused = _focusNode.hasFocus);
    }
  }

  @override
  void didUpdateWidget(AuthInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode?.removeListener(_handleFocusChange);
      _focusNode.addListener(_handleFocusChange);
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _ownedFocusNode?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FormField<String>(
      initialValue: widget.controller.text,
      // Always validate the live controller text. The field's own value can be
      // stale when the controller is populated programmatically (e.g. the
      // remembered email restored after the first frame).
      validator: (_) => widget.validator?.call(widget.controller.text),
      builder: (field) {
        // Server-reported errors outrank the local validator message.
        final error = widget.errorText ?? field.errorText;
        final hasError = error != null;

        final borderColor = hasError
            ? colors.error.withValues(alpha: 0.55)
            : _focused
            ? colors.accent
            : (isDark
                  ? colors.white.withValues(alpha: 0.10)
                  : Colors.white.withValues(alpha: 0.75));

        final tile = AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: isDark
                ? colors.white.withValues(alpha: 0.05)
                : colors.white.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(18),
            // Constant width: animating it reflows the tile's content box and
            // nudges the label and the value by half a point on every focus
            // change. Only the colour reacts.
            border: Border.all(color: borderColor, width: 1.5),
            boxShadow: _focused && !isDark
                ? [
                    BoxShadow(
                      color: colors.accent.withValues(alpha: 0.12),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          padding: const EdgeInsetsDirectional.fromSTEB(16, 10, 8, 10),
          child: Row(
            children: [
              Icon(
                widget.icon,
                size: 22,
                color: hasError
                    ? colors.error
                    : _focused
                    ? colors.accent
                    : colors.primary.withValues(alpha: isDark ? 0.75 : 0.65),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.label,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: colors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    TextField(
                      controller: widget.controller,
                      focusNode: _focusNode,
                      readOnly: widget.readOnly,
                      onTap: widget.onTap,
                      showCursor: !widget.readOnly,
                      keyboardType: widget.keyboardType,
                      obscureText: widget.obscureText,
                      textInputAction: widget.textInputAction,
                      onChanged: field.didChange,
                      onSubmitted: widget.onFieldSubmitted,
                      autofillHints: widget.autofillHints,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: colors.text,
                      ),
                      cursorColor: colors.accent,
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: widget.hintText,
                        hintStyle: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          color: colors.textMuted.withValues(alpha: 0.6),
                        ),
                        contentPadding: EdgeInsets.zero,
                        filled: false,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.trailing != null) widget.trailing!,
            ],
          ),
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Picker-backed fields are read-only, so the whole tile — not just
            // the text span — has to answer to a tap.
            if (widget.onTap != null)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: widget.onTap,
                child: tile,
              )
            else
              tile,
            AnimatedSize(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              alignment: Alignment.topCenter,
              child: hasError
                  ? Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(
                        18,
                        6,
                        18,
                        0,
                      ),
                      child: Text(
                        error,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: colors.error,
                        ),
                      ),
                    )
                  : const SizedBox(width: double.infinity),
            ),
          ],
        );
      },
    );
  }
}
