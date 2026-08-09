import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/security/safe_url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import 'assignment_file_helper.dart';
import 'assignment_section_card.dart';

class AssignmentDownloadFileCard extends StatelessWidget {
  const AssignmentDownloadFileCard({
    super.key,
    required this.title,
    required this.fileUrl,
    this.fileName,
    this.fileSize,
    this.mimeType,
    this.icon = Icons.attach_file_outlined,
  });

  final String title;
  final String fileUrl;
  final String? fileName;
  final int? fileSize;
  final String? mimeType;
  final IconData icon;

  Future<void> _openFile(BuildContext context) async {
    final uri = Uri.tryParse(fileUrl);
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
    final fileIcon = AssignmentFileHelper.iconFor(
      mimeType: mimeType,
      fileName: fileName,
    );
    final displayName = fileName ?? 'ملف الواجب';
    final size = AssignmentFileHelper.formatSize(fileSize);
    final mime = mimeType?.split('/').last.toUpperCase() ?? 'FILE';

    return AssignmentSectionCard(
      title: title,
      icon: icon,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: AppColors.cardWhite.withValues(alpha: 0.55),
              border: Border.all(color: Colors.white.withValues(alpha: 0.7)),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(fileIcon, color: AppColors.darkGold, size: 26),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$size • $mime',
                        style: AppTextStyles.body.copyWith(
                          fontSize: 12,
                          color: AppColors.textMuted,
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
            icon: const Icon(Icons.download_rounded, size: 18),
            label: const Text('تحميل الملف'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: BorderSide(color: AppColors.accent.withValues(alpha: 0.65)),
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
