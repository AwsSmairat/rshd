import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../data/privacy_policy_config.dart';

class PrivacyContactInfo {
  const PrivacyContactInfo({
    required this.privacyEmail,
    required this.supportEmail,
    required this.supportPhone,
    required this.companyAddress,
    required this.supportHours,
  });

  final String privacyEmail;
  final String supportEmail;
  final String supportPhone;
  final String companyAddress;
  final String supportHours;
}

class PrivacyPolicyContactCard extends StatelessWidget {
  const PrivacyPolicyContactCard({
    super.key,
    required this.contact,
    required this.onPrivacyContact,
    required this.onReportIssue,
  });

  final PrivacyContactInfo contact;
  final VoidCallback onPrivacyContact;
  final VoidCallback onReportIssue;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.contact_mail_outlined, color: AppColors.darkGold, size: 22),
              const SizedBox(width: 8),
              Text(
                'بيانات التواصل',
                style: AppTextStyles.subtitle.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _ContactRow(
            icon: Icons.privacy_tip_outlined,
            label: 'بريد الخصوصية',
            value: contact.privacyEmail,
          ),
          _ContactRow(
            icon: Icons.support_agent_outlined,
            label: 'بريد الدعم',
            value: contact.supportEmail,
          ),
          if (contact.supportPhone.isNotEmpty)
            _ContactRow(
              icon: Icons.phone_outlined,
              label: 'الهاتف',
              value: contact.supportPhone,
            ),
          if (contact.companyAddress.isNotEmpty)
            _ContactRow(
              icon: Icons.location_on_outlined,
              label: 'العنوان',
              value: contact.companyAddress,
            ),
          _ContactRow(
            icon: Icons.access_time_outlined,
            label: 'ساعات الدعم',
            value: contact.supportHours,
          ),
          const SizedBox(height: 16),
          PrivacyActionButtons(
            onPrivacyContact: onPrivacyContact,
            onReportIssue: onReportIssue,
          ),
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    if (value.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.darkGold),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.body.copyWith(
                    fontSize: 12,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTextStyles.body.copyWith(
                    fontSize: 14,
                    height: 1.4,
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

class PrivacyActionButtons extends StatelessWidget {
  const PrivacyActionButtons({
    super.key,
    required this.onPrivacyContact,
    required this.onReportIssue,
    this.compact = false,
  });

  final VoidCallback onPrivacyContact;
  final VoidCallback onReportIssue;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onPrivacyContact,
              icon: const Icon(Icons.mail_outline, size: 18),
              label: const Text('الخصوصية'),
              style: _outlineStyle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onReportIssue,
              icon: const Icon(Icons.report_outlined, size: 18),
              label: const Text('إبلاغ'),
              style: _outlineStyle,
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          label: 'التواصل بخصوص الخصوصية',
          button: true,
          child: OutlinedButton.icon(
            onPressed: onPrivacyContact,
            icon: const Icon(Icons.mail_outline),
            label: const Text('التواصل بخصوص الخصوصية'),
            style: _outlineStyle,
          ),
        ),
        const SizedBox(height: 10),
        Semantics(
          label: 'الإبلاغ عن مشكلة',
          button: true,
          child: OutlinedButton.icon(
            onPressed: onReportIssue,
            icon: const Icon(Icons.report_outlined),
            label: const Text('الإبلاغ عن مشكلة'),
            style: _outlineStyle,
          ),
        ),
      ],
    );
  }

  ButtonStyle get _outlineStyle => OutlinedButton.styleFrom(
        foregroundColor: AppColors.darkGold,
        side: const BorderSide(color: AppColors.darkGold),
        minimumSize: const Size(double.infinity, 46),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      );
}

class DeleteAccountButton extends StatelessWidget {
  const DeleteAccountButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
  });

  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'طلب حذف الحساب',
      button: true,
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: OutlinedButton.icon(
          onPressed: isLoading ? null : onPressed,
          icon: isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.delete_outline, color: Color(0xFF991B1B)),
          label: Text(
            isLoading ? 'جارٍ المعالجة...' : 'طلب حذف الحساب',
            style: const TextStyle(
              color: Color(0xFF991B1B),
              fontWeight: FontWeight.w700,
            ),
          ),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Color(0xFF991B1B)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> launchPrivacyEmail({
  required String email,
  required String subject,
  BuildContext? context,
}) async {
  if (email.isEmpty) {
    if (context != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('بريد التواصل غير متوفر حالياً')),
      );
    }
    return;
  }

  final uri = Uri(
    scheme: 'mailto',
    path: email,
    queryParameters: {'subject': subject},
  );

  final launched = await launchUrl(uri);
  if (!launched && context != null && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(email)),
    );
  }
}

PrivacyContactInfo resolvePrivacyContactInfo({
  String? platformSupportEmail,
  String? platformSupportPhone,
}) {
  return PrivacyContactInfo(
    privacyEmail: PrivacyPolicyConfig.privacyEmail,
    supportEmail: (platformSupportEmail != null && platformSupportEmail.isNotEmpty)
        ? platformSupportEmail
        : PrivacyPolicyConfig.supportEmail,
    supportPhone: (platformSupportPhone != null && platformSupportPhone.isNotEmpty)
        ? platformSupportPhone
        : PrivacyPolicyConfig.supportPhone,
    companyAddress: PrivacyPolicyConfig.companyAddress,
    supportHours: PrivacyPolicyConfig.supportHours,
  );
}
