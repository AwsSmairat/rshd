import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../data/terms_and_conditions_config.dart';

class TermsContactInfo {
  const TermsContactInfo({
    required this.supportEmail,
    required this.legalEmail,
    required this.supportPhone,
    required this.companyAddress,
    required this.supportHours,
    required this.companyLegalName,
  });

  final String supportEmail;
  final String legalEmail;
  final String supportPhone;
  final String companyAddress;
  final String supportHours;
  final String companyLegalName;
}

TermsContactInfo resolveTermsContactInfo({
  String? platformSupportEmail,
  String? platformSupportPhone,
}) {
  return TermsContactInfo(
    supportEmail: (platformSupportEmail != null && platformSupportEmail.isNotEmpty)
        ? platformSupportEmail
        : TermsAndConditionsConfig.supportEmail,
    legalEmail: TermsAndConditionsConfig.legalEmail,
    supportPhone: (platformSupportPhone != null && platformSupportPhone.isNotEmpty)
        ? platformSupportPhone
        : TermsAndConditionsConfig.supportPhone,
    companyAddress: TermsAndConditionsConfig.companyAddress,
    supportHours: TermsAndConditionsConfig.supportHours,
    companyLegalName: TermsAndConditionsConfig.companyLegalName,
  );
}

Future<void> launchTermsEmail({
  required String email,
  required String subject,
  BuildContext? context,
}) async {
  if (email.isEmpty) {
    if (context != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('بريد التواصل غير متوفر')),
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(email)));
  }
}

class TermsContactCard extends StatelessWidget {
  const TermsContactCard({
    super.key,
    required this.contact,
    required this.onContact,
    required this.onReport,
  });

  final TermsContactInfo contact;
  final VoidCallback onContact;
  final VoidCallback onReport;

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Text(
            'التواصل',
            style: AppTextStyles.subtitle.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          _row(Icons.support_agent_outlined, 'الدعم', contact.supportEmail),
          _row(Icons.gavel_outlined, 'الشؤون القانونية', contact.legalEmail),
          if (contact.supportPhone.isNotEmpty)
            _row(Icons.phone_outlined, 'الهاتف', contact.supportPhone),
          if (contact.companyAddress.isNotEmpty)
            _row(Icons.location_on_outlined, 'العنوان', contact.companyAddress),
          _row(Icons.access_time_outlined, 'ساعات العمل', contact.supportHours),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: onContact,
            icon: const Icon(Icons.mail_outline),
            label: const Text('تواصل معنا'),
            style: _style,
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: onReport,
            icon: const Icon(Icons.report_outlined),
            label: const Text('الإبلاغ عن مخالفة'),
            style: _style,
          ),
        ],
      ),
    );
  }

  ButtonStyle get _style => OutlinedButton.styleFrom(
        foregroundColor: AppColors.darkGold,
        side: const BorderSide(color: AppColors.darkGold),
        minimumSize: const Size(double.infinity, 46),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      );

  Widget _row(IconData icon, String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
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
                Text(label,
                    style: AppTextStyles.body.copyWith(
                      fontSize: 12,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w600,
                    )),
                Text(value, style: AppTextStyles.body.copyWith(fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TermsAcceptanceCard extends StatelessWidget {
  const TermsAcceptanceCard({
    super.key,
    required this.checked,
    required this.isLoading,
    required this.onCheckedChanged,
    required this.onAccept,
  });

  final bool checked;
  final bool isLoading;
  final ValueChanged<bool> onCheckedChanged;
  final VoidCallback onAccept;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.darkGold.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'مطلوب: موافقة على النسخة الجديدة',
            style: AppTextStyles.subtitle.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          CheckboxListTile(
            value: checked,
            onChanged: isLoading ? null : (v) => onCheckedChanged(v ?? false),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            title: const Text('قرأت الشروط والأحكام وأوافق عليها'),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: (!checked || isLoading) ? null : onAccept,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('موافقة ومتابعة'),
          ),
        ],
      ),
    );
  }
}

class TermsFooter extends StatelessWidget {
  const TermsFooter({
    super.key,
    required this.platformName,
    required this.version,
    required this.lastUpdated,
    required this.onPrivacy,
    required this.onDeleteAccount,
  });

  final String platformName;
  final String version;
  final String lastUpdated;
  final VoidCallback onPrivacy;
  final VoidCallback onDeleteAccount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OutlinedButton.icon(
            onPressed: onPrivacy,
            icon: const Icon(Icons.privacy_tip_outlined),
            label: const Text('سياسة الخصوصية'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.darkGold,
              side: const BorderSide(color: AppColors.darkGold),
              minimumSize: const Size(double.infinity, 46),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: onDeleteAccount,
            icon: const Icon(Icons.delete_outline, color: Color(0xFF991B1B)),
            label: const Text(
              'طلب حذف الحساب',
              style: TextStyle(color: Color(0xFF991B1B)),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF991B1B)),
              minimumSize: const Size(double.infinity, 46),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(platformName,
              textAlign: TextAlign.center,
              style: AppTextStyles.subtitle.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              )),
          Text('إصدار الشروط: $version',
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(
                fontSize: 12,
                color: AppColors.textMuted,
              )),
          Text('آخر تحديث: $lastUpdated',
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(
                fontSize: 12,
                color: AppColors.textMuted,
              )),
        ],
      ),
    );
  }
}
