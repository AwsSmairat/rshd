import 'package:flutter/material.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_colors.dart';

/// Text input dialog for note and text-box annotations.
///
/// The [TextEditingController] lives in this widget's state so it stays alive
/// through the route's exit transition, which keeps rebuilding the [TextField]
/// after `showDialog` has already returned.
class AnnotationTextDialog extends StatefulWidget {
  const AnnotationTextDialog({
    super.key,
    required this.title,
    required this.confirmLabel,
    required this.cancelLabel,
    this.initialText = '',
    this.hintText,
    this.maxLines = 3,
    this.autofocus = true,
    this.deleteLabel,
    this.onDelete,
  });

  final String title;
  final String confirmLabel;
  final String cancelLabel;
  final String initialText;
  final String? hintText;
  final int maxLines;
  final bool autofocus;
  final String? deleteLabel;
  final VoidCallback? onDelete;

  @override
  State<AnnotationTextDialog> createState() => _AnnotationTextDialogState();
}

class _AnnotationTextDialogState extends State<AnnotationTextDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialText,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final hint = widget.hintText;

    return AlertDialog(
      title: Text(strings.t(widget.title)),
      content: TextField(
        controller: _controller,
        autofocus: widget.autofocus,
        maxLines: widget.maxLines,
        textDirection: TextDirection.rtl,
        decoration: hint == null
            ? null
            : InputDecoration(hintText: strings.t(hint)),
      ),
      actions: [
        if (widget.deleteLabel != null && widget.onDelete != null)
          TextButton(
            onPressed: () {
              widget.onDelete!();
              Navigator.pop(context);
            },
            child: Text(
              strings.t(widget.deleteLabel!),
              style: TextStyle(color: AppColors.of(context).error),
            ),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(strings.t(widget.cancelLabel)),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: Text(strings.t(widget.confirmLabel)),
        ),
      ],
    );
  }
}
