import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/security/safe_url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../data/models/assignment_submission_model.dart';
import 'assignment_file_helper.dart';
import 'assignment_section_card.dart';

class SubmittedFileCard extends StatelessWidget {
  const SubmittedFileCard({super.key, required this.submission});

  final AssignmentSubmissionModel submission;

  Future<void> _openFile(BuildContext context) async {
    final url = submission.fileUrl;
    if (url == null || url.isEmpty) {
      return;
    }

    final uri = Uri.tryParse(url);
    if (uri == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تعذر فتح الملف')));
      return;
    }

    final launched = await SafeUrlLauncher.launch(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (!context.mounted) {
      return;
    }
    if (!launched) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تعذر فتح الملف')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!submission.hasFile) {
      return const SizedBox.shrink();
    }

    final icon = AssignmentFileHelper.iconFor(
      mimeType: submission.fileMimeType,
      fileName: submission.originalFileName,
    );
    final fileName = submission.originalFileName ?? 'ملف الحل';
    final size = AssignmentFileHelper.formatSize(submission.fileSize);
    final mime =
        submission.fileMimeType?.split('/').last.toUpperCase() ?? 'FILE';

    return AssignmentSectionCard(
      title: 'ملف الحل',
      icon: Icons.cloud_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: AppColors.of(context).cardWhite.withValues(alpha: 0.55),
              border: Border.all(color: Colors.white.withValues(alpha: 0.7)),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.of(context).accent.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: AppColors.of(context).darkGold,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fileName,
                        style: AppTextStyles.bodyOf(context).copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.of(context).primary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$size • $mime',
                        style: AppTextStyles.bodyOf(context).copyWith(
                          fontSize: 12,
                          color: AppColors.of(context).textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: () => _openFile(context),
            icon: const Icon(Icons.open_in_new_rounded, size: 18),
            label: const Text('فتح الملف'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.of(context).primary,
              side: BorderSide(
                color: AppColors.of(context).accent.withValues(alpha: 0.65),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ],
      ),
    );
  }
}

class AssignmentSubmissionDetailsCard extends StatelessWidget {
  const AssignmentSubmissionDetailsCard({super.key, required this.submission});

  final AssignmentSubmissionModel submission;

  @override
  Widget build(BuildContext context) {
    final evaluation = AssignmentGradeHelper.evaluationLabel(submission.grade);

    return AssignmentSectionCard(
      title: 'تفاصيل التسليم',
      icon: Icons.edit_note_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (submission.answerText != null &&
              submission.answerText!.trim().isNotEmpty)
            _DetailRow(
              icon: Icons.notes_outlined,
              label: 'نص الإجابة',
              value: submission.answerText!,
            ),
          if (submission.submittedAt != null)
            _DetailRow(
              icon: Icons.calendar_today_outlined,
              label: 'تاريخ الإرسال',
              value: _formatDate(submission.submittedAt!),
            ),
          if (submission.grade != null && submission.grade!.isNotEmpty)
            _DetailRow(
              icon: Icons.star_outline,
              label: 'الدرجة',
              value: '${submission.grade} / 100',
              valueColor: const Color(0xFF15803D),
            ),
          if (evaluation != null)
            _DetailRow(
              icon: Icons.grade_outlined,
              label: 'التقييم',
              value: evaluation,
              valueColor: const Color(0xFF15803D),
            ),
          if (submission.feedback != null &&
              submission.feedback!.trim().isNotEmpty)
            _DetailRow(
              icon: Icons.rate_review_outlined,
              label: 'ملاحظات المدرس',
              value: submission.feedback!,
            ),
        ],
      ),
    );
  }

  String _formatDate(String raw) {
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) {
      return raw;
    }
    return DateFormat('yyyy/MM/dd – HH:mm', 'ar').format(parsed.toLocal());
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.of(context).darkGold),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.bodyOf(context).copyWith(
                    fontSize: 12,
                    color: AppColors.of(context).textMuted,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: AppTextStyles.bodyOf(context).copyWith(
                    fontWeight: FontWeight.w600,
                    color: valueColor ?? AppColors.of(context).primary,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
