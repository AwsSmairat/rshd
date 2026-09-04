import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/liquid_glass_surface.dart';
import '../data/models/profile_model.dart';
import 'profile_detail_row.dart';

class ProfileInfoCard extends StatelessWidget {
  const ProfileInfoCard({super.key, required this.profile});

  final ProfileModel profile;

  static const _successGreen = Color(0xFF16A34A);

  String _formatDate(BuildContext context, String? raw) {
    if (raw == null || raw.isEmpty) {
      return '—';
    }
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) {
      return raw;
    }
    return DateFormat(
      'yyyy/MM/dd',
      AppStrings.of(context).dateLocale,
    ).format(parsed.toLocal());
  }

  String _statusLabel(AppStrings strings) {
    return strings.profileStatusLabel(profile.status);
  }

  Color? _statusColor() {
    if (profile.status == 'active') {
      return _successGreen;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
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
                  color: AppColors.of(context).background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.person_outline,
                  color: AppColors.of(context).darkGold,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              Text(AppStrings.of(context).t(strings.accountDetails),
                style: AppTextStyles.subtitleOf(context).copyWith(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.of(context).text,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ProfileDetailRow(
            icon: Icons.person_outline,
            label: strings.name,
            value: profile.name,
          ),
          ProfileDetailRow(
            icon: Icons.mail_outline,
            label: strings.email,
            value: profile.email,
          ),
          ProfileDetailRow(
            icon: Icons.phone_outlined,
            label: strings.phone,
            value: profile.phone?.isNotEmpty == true ? profile.phone! : '—',
          ),
          ProfileDetailRow(
            icon: Icons.shield_outlined,
            label: strings.role,
            value: strings.roleLabel(profile.role),
          ),
          ProfileDetailRow(
            icon: Icons.verified_user_outlined,
            label: strings.accountStatus,
            value: _statusLabel(strings),
            valueColor: _statusColor(),
          ),
          ProfileDetailRow(
            icon: Icons.calendar_today_outlined,
            label: strings.accountCreatedAt,
            value: _formatDate(context, profile.createdAt),
            showDivider: false,
          ),
        ],
      ),
    );
  }
}
