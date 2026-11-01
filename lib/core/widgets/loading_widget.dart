import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import 'rshd_loader.dart';
import '../theme/app_colors.dart';

class LoadingWidget extends StatelessWidget {
  const LoadingWidget({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          RshdLoader(
            size: 32,
            baseColor: AppColors.of(context).primary.withValues(alpha: 0.16),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(AppStrings.of(context).t(message!)),
          ],
        ],
      ),
    );
  }
}
