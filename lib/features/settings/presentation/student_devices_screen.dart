import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../profile/data/models/device_model.dart';
import 'student_settings_controller.dart';
import '../../../core/l10n/app_strings.dart';

class StudentDevicesScreen extends ConsumerWidget {
  const StudentDevicesScreen({super.key, required this.devices});

  final List<DeviceModel> devices;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.of(context).t('الجلسات والأجهزة'))),
      body: devices.isEmpty
          ? Center(
              child: Text(AppStrings.of(context).t('لا توجد أجهزة مسجّلة'),
                style: AppTextStyles.bodyOf(
                  context,
                ).copyWith(color: AppColors.of(context).textMuted),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: devices.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final device = devices[index];
                return _DeviceTile(
                  device: device,
                  onRevoke: () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text(AppStrings.of(context).t('إلغاء الجهاز')),
                        content: Text(AppStrings.of(context).t('هل تريد تسجيل الخروج من "${device.deviceName ?? device.platform ?? 'جهاز'}"؟'),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: Text(AppStrings.of(context).t('إلغاء')),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: Text(AppStrings.of(context).t('تأكيد')),
                          ),
                        ],
                      ),
                    );
                    if (ok == true) {
                      final success = await ref
                          .read(studentSettingsControllerProvider.notifier)
                          .revokeDevice(device.id);
                      if (context.mounted) {
                        if (success) {
                          Navigator.pop(context);
                        }
                      }
                    }
                  },
                );
              },
            ),
    );
  }
}

class _DeviceTile extends StatelessWidget {
  const _DeviceTile({required this.device, required this.onRevoke});

  final DeviceModel device;
  final VoidCallback onRevoke;

  @override
  Widget build(BuildContext context) {
    final lastLogin = device.lastLoginAt;
    final formatted = lastLogin != null
        ? DateFormat(
            'yyyy/MM/dd HH:mm',
          ).format(DateTime.parse(lastLogin).toLocal())
        : '—';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.of(context).cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(AppStrings.of(context).t(device.deviceName ?? device.platform ?? 'جهاز'),
                  style: AppTextStyles.subtitleOf(
                    context,
                  ).copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              if (device.isActive)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.of(context).accent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(AppStrings.of(context).t('نشط'),
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(AppStrings.of(context).t('النظام: ${device.platform ?? '—'}'),
            style: AppTextStyles.bodyOf(
              context,
            ).copyWith(fontSize: 13, color: AppColors.of(context).textMuted),
          ),
          Text(AppStrings.of(context).t('آخر نشاط: $formatted'),
            style: AppTextStyles.bodyOf(
              context,
            ).copyWith(fontSize: 13, color: AppColors.of(context).textMuted),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton(
              onPressed: onRevoke,
              child: Text(AppStrings.of(context).t('إلغاء الجهاز')),
            ),
          ),
        ],
      ),
    );
  }
}
