import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/liquid_glass_surface.dart';

class GradesLoadingSkeleton extends StatelessWidget {
  const GradesLoadingSkeleton({super.key, this.count = 2});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(count, (index) {
        return Padding(
          padding: EdgeInsets.only(bottom: index == count - 1 ? 0 : 16),
          child: LiquidGlassSurface(
            borderRadius: BorderRadius.circular(24),
            padding: const EdgeInsets.all(18),
            fillOpacity: 0.3,
            borderOpacity: 0.55,
            blurSigma: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 96,
                  height: 14,
                  decoration: BoxDecoration(
                    color: AppColors.of(
                      context,
                    ).textMuted.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  height: 18,
                  decoration: BoxDecoration(
                    color: AppColors.of(
                      context,
                    ).textMuted.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: 140,
                  height: 14,
                  decoration: BoxDecoration(
                    color: AppColors.of(
                      context,
                    ).textMuted.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
