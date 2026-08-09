import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/liquid_glass_surface.dart';
import '../data/models/device_model.dart';
import 'linked_device_notice.dart';
import 'profile_detail_row.dart';

class DeviceInfoCard extends StatelessWidget {
  const DeviceInfoCard({super.key, required this.device});

  final DeviceModel? device;

  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) {
      return '—';
    }
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) {
      return raw;
    }
    return DateFormat('yyyy/MM/dd – HH:mm', 'ar').format(parsed.toLocal());
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
                  Icons.smartphone_outlined,
                  color: AppColors.darkGold,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'الجهاز المرتبط',
                style: AppTextStyles.subtitle.copyWith(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (device == null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                children: [
                  Icon(
                    Icons.devices_other_outlined,
                    color: AppColors.textMuted.withValues(alpha: 0.7),
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'لا يوجد جهاز مرتبط حالياً',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            ProfileDetailRow(
              icon: Icons.smartphone_outlined,
              label: 'اسم الجهاز',
              value: device!.deviceName?.isNotEmpty == true
                  ? device!.deviceName!
                  : '—',
            ),
            ProfileDetailRow(
              icon: Icons.layers_outlined,
              label: 'نوع النظام',
              value: device!.platformLabel,
            ),
            ProfileDetailRow(
              icon: Icons.schedule_outlined,
              label: 'آخر تسجيل دخول',
              value: _formatDate(device!.lastLoginAt),
              showDivider: false,
            ),
            const SizedBox(height: 16),
            const LinkedDeviceNotice(),
          ],
        ],
      ),
    );
  }
}
