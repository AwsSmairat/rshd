import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'rshd_loader.dart';
import '../l10n/app_strings.dart';

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      child: isLoading
          ? RshdLoader(size: 13.6, color: AppColors.of(context).white)
          : Text(AppStrings.of(context).t(label)),
    );
  }
}
