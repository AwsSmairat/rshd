import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import 'assignment_file_helper.dart';
import 'assignment_section_card.dart';
import '../../../core/l10n/app_strings.dart';

class AssignmentFilePickerCard extends StatelessWidget {
  const AssignmentFilePickerCard({
    super.key,
    required this.selectedFile,
    required this.onPickFile,
    required this.onRemoveFile,
  });

  final PlatformFile? selectedFile;
  final VoidCallback onPickFile;
  final VoidCallback onRemoveFile;

  @override
  Widget build(BuildContext context) {
    return AssignmentSectionCard(
      title: AppStrings.of(context).t('ملف الحل'),
      icon: Icons.cloud_upload_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(AppStrings.of(context).t('يمكنك رفع ملف PDF أو Word أو صورة أو ZIP'),
            style: AppTextStyles.bodyOf(
              context,
            ).copyWith(fontSize: 13, color: AppColors.of(context).textMuted),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: onPickFile,
            icon: const Icon(Icons.upload_file_outlined, size: 20),
            label: Text(AppStrings.of(context).t('اختيار ملف')),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.of(context).primary,
              side: BorderSide(
                color: AppColors.of(context).accent.withValues(alpha: 0.7),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
          const SizedBox(height: 14),
          if (selectedFile == null)
            _EmptyFileBox()
          else
            _SelectedFileBox(file: selectedFile!, onRemove: onRemoveFile),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 14,
                color: AppColors.of(context).textMuted.withValues(alpha: 0.9),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(AppStrings.of(context).t('يجب كتابة إجابة أو رفع ملف واحد على الأقل'),
                  style: AppTextStyles.bodyOf(context).copyWith(
                    fontSize: 12,
                    color: AppColors.of(context).textMuted,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyFileBox extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.of(context).accent.withValues(alpha: 0.35),
          style: BorderStyle.solid,
          width: 1.2,
        ),
        color: AppColors.of(context).cardWhite.withValues(alpha: 0.35),
      ),
      child: Column(
        children: [
          Icon(
            Icons.folder_open_outlined,
            size: 32,
            color: AppColors.of(context).darkGold.withValues(alpha: 0.8),
          ),
          const SizedBox(height: 8),
          Text(AppStrings.of(context).t('لم يتم اختيار ملف بعد'),
            style: AppTextStyles.bodyOf(
              context,
            ).copyWith(color: AppColors.of(context).textMuted),
          ),
        ],
      ),
    );
  }
}

class _SelectedFileBox extends StatelessWidget {
  const _SelectedFileBox({required this.file, required this.onRemove});

  final PlatformFile file;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final icon = AssignmentFileHelper.iconFor(fileName: file.name);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AppColors.of(context).cardWhite.withValues(alpha: 0.55),
        border: Border.all(color: Colors.white.withValues(alpha: 0.7)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.of(context).accent.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.of(context).darkGold),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppStrings.of(context).t(file.name),
                  style: AppTextStyles.bodyOf(context).copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.of(context).primary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(AppStrings.of(context).t(AssignmentFileHelper.formatSize(file.size)),
                  style: AppTextStyles.bodyOf(context).copyWith(
                    fontSize: 12,
                    color: AppColors.of(context).textMuted,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onRemove,
            child: Text(AppStrings.of(context).t('إزالة'),
              style: AppTextStyles.bodyOf(context).copyWith(
                color: const Color(0xFF991B1B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
