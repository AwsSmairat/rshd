import 'package:flutter/material.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../data/help_center_model.dart';
import '../../../core/l10n/app_strings.dart';

Future<bool> showHelpMessageSheet({
  required BuildContext context,
  required TeacherContactModel teacher,
  required Future<void> Function(String message) onSend,
}) async {
  final sent = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.of(context).cardWhite,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => _HelpMessageSheet(teacher: teacher, onSend: onSend),
  );

  return sent ?? false;
}

class _HelpMessageSheet extends StatefulWidget {
  const _HelpMessageSheet({required this.teacher, required this.onSend});

  final TeacherContactModel teacher;
  final Future<void> Function(String message) onSend;

  @override
  State<_HelpMessageSheet> createState() => _HelpMessageSheetState();
}

class _HelpMessageSheetState extends State<_HelpMessageSheet> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final message = _controller.text.trim();

    if (message.length < 3) {
      setState(() => _error = 'يجب أن تكون الرسالة 3 أحرف على الأقل');
      return;
    }

    setState(() {
      _sending = true;
      _error = null;
    });

    try {
      await widget.onSend(message);
      if (!mounted) return;
      Navigator.pop(context, true);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _error = error.message.isNotEmpty
            ? error.message
            : 'تعذر إرسال الرسالة';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _error = 'تعذر إرسال الرسالة';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, bottomInset + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(AppStrings.of(context).t('رسالة إلى ${widget.teacher.instructorName}'),
            style: AppTextStyles.subtitleOf(
              context,
            ).copyWith(fontWeight: FontWeight.w800, fontSize: 17),
          ),
          const SizedBox(height: 4),
          Text(AppStrings.of(context).t(widget.teacher.subjectTitle),
            style: AppTextStyles.bodyOf(
              context,
            ).copyWith(fontSize: 13, color: AppColors.of(context).textMuted),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            focusNode: _focusNode,
            enabled: !_sending,
            maxLines: 5,
            minLines: 4,
            maxLength: 2000,
            textAlign: TextAlign.right,
            decoration: InputDecoration(
              hintText: AppStrings.of(context).t('اكتب رسالتك هنا...'),
              hintTextDirection: TextDirection.rtl,
              filled: true,
              fillColor: AppColors.of(context).background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: AppColors.of(context).darkGold),
              ),
              counterText: '',
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(AppStrings.of(context).t(_error!),
              style: AppTextStyles.bodyOf(
                context,
              ).copyWith(fontSize: 12, color: AppColors.of(context).error),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _sending ? null : () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(AppStrings.of(context).t('إلغاء')),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: _sending ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.of(context).darkGold,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _sending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(AppStrings.of(context).t('إرسال')),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
