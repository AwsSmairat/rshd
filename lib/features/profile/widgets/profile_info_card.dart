import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/liquid_glass_surface.dart';
import '../data/models/profile_model.dart';
import 'profile_detail_row.dart';

class ProfileInfoCard extends StatelessWidget {
  const ProfileInfoCard({
    super.key,
    required this.profile,
  });

  final ProfileModel profile;

  static const _successGreen = Color(0xFF16A34A);

  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) {
      return '—';
    }
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) {
      return raw;
    }
    return DateFormat('yyyy/MM/dd', 'ar').format(parsed.toLocal());
  }

  String _statusLabel() {
    switch (profile.status) {
      case 'active':
        return 'نشط';
      case 'inactive':
        return 'غير نشط';
      case 'pending':
        return 'قيد الانتظار';
      case 'blocked':
        return 'موقوف';
      default:
        return profile.statusLabel;
    }
  }

  Color? _statusColor() {
    if (profile.status == 'active') {
      return _successGreen;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return LiquidGlassSurface(
      borderRadius: BorderRadius.circular(22),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.person_outline,
                  color: AppColors.darkGold,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'بيانات الحساب',
                style: AppTextStyles.subtitle.copyWith(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ProfileDetailRow(
            icon: Icons.person_outline,
            label: 'الاسم',
            value: profile.name,
          ),
          ProfileDetailRow(
            icon: Icons.mail_outline,
            label: 'البريد الإلكتروني',
            value: profile.email,
          ),
          ProfileDetailRow(
            icon: Icons.phone_outlined,
            label: 'رقم الهاتف',
            value: profile.phone?.isNotEmpty == true ? profile.phone! : '—',
          ),
          ProfileDetailRow(
            icon: Icons.shield_outlined,
            label: 'الدور',
            value: profile.roleLabel,
          ),
          ProfileDetailRow(
            icon: Icons.verified_user_outlined,
            label: 'حالة الحساب',
            value: _statusLabel(),
            valueColor: _statusColor(),
          ),
          ProfileDetailRow(
            icon: Icons.calendar_today_outlined,
            label: 'تاريخ إنشاء الحساب',
            value: _formatDate(profile.createdAt),
            showDivider: false,
          ),
        ],
      ),
    );
  }
}
