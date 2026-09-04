import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/platform/platform_settings.dart';
import '../../core/platform/platform_settings_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_button.dart';
import '../../core/l10n/app_strings.dart';

class MaintenanceScreen extends ConsumerWidget {
  const MaintenanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(platformSettingsProvider);

    final message = settings.maybeWhen(
      data: (value) => value.maintenanceMessage,
      orElse: () => PlatformSettings.fallback.maintenanceMessage,
    );

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.construction_rounded,
                size: 72,
                color: AppColors.of(context).accent,
              ),
              const SizedBox(height: 24),
              Text(AppStrings.of(context).t('المنصة تحت الصيانة'),
                style: AppTextStyles.titleOf(
                  context,
                ).copyWith(color: AppColors.of(context).primary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(AppStrings.of(context).t(message),
                style: AppTextStyles.subtitleOf(context),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              AppButton(
                label: AppStrings.of(context).t('إعادة المحاولة'),
                onPressed: () =>
                    ref.read(platformSettingsProvider.notifier).refresh(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
