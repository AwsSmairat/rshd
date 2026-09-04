import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/l10n/app_strings.dart';

class PrivacyPolicyFooter extends StatelessWidget {
  const PrivacyPolicyFooter({
    super.key,
    required this.platformName,
    required this.version,
    required this.lastUpdated,
    required this.onDeleteAccount,
    required this.onPrivacyContact,
    this.isDeleting = false,
  });

  final String platformName;
  final String version;
  final String lastUpdated;
  final VoidCallback onDeleteAccount;
  final VoidCallback onPrivacyContact;
  final bool isDeleting;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.of(context).cardWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            label: AppStrings.of(context).t('طلب حذف الحساب'),
            button: true,
            child: OutlinedButton.icon(
              onPressed: isDeleting ? null : onDeleteAccount,
              icon: isDeleting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.delete_outline, color: Color(0xFF991B1B)),
              label: Text(AppStrings.of(context).t(isDeleting ? 'جارٍ المعالجة...' : 'طلب حذف الحساب'),
                style: const TextStyle(
                  color: Color(0xFF991B1B),
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                side: const BorderSide(color: Color(0xFF991B1B)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Semantics(
            label: AppStrings.of(context).t('التواصل بخصوص الخصوصية'),
            button: true,
            child: OutlinedButton.icon(
              onPressed: onPrivacyContact,
              icon: const Icon(Icons.mail_outline),
              label: Text(AppStrings.of(context).t('التواصل بخصوص الخصوصية')),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.of(context).darkGold,
                side: BorderSide(color: AppColors.of(context).darkGold),
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Divider(
            color: AppColors.of(context).textMuted.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 12),
          Text(AppStrings.of(context).t(platformName),
            style: AppTextStyles.subtitleOf(context).copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.of(context).primary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(AppStrings.of(context).t('إصدار السياسة: $version'),
            style: AppTextStyles.bodyOf(
              context,
            ).copyWith(fontSize: 12, color: AppColors.of(context).textMuted),
            textAlign: TextAlign.center,
          ),
          Text(AppStrings.of(context).t('آخر تحديث: $lastUpdated'),
            style: AppTextStyles.bodyOf(
              context,
            ).copyWith(fontSize: 12, color: AppColors.of(context).textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
