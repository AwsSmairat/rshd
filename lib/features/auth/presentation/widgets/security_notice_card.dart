import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/liquid_glass_surface.dart';

class SecurityNoticeCard extends StatelessWidget {
  const SecurityNoticeCard({super.key});

  @override
  Widget build(BuildContext context) {
    return LiquidGlassSurface(
      borderRadius: BorderRadius.circular(16),
      padding: const EdgeInsets.all(14),
      tintColor: AppColors.of(context).accent,
      tintOpacity: 0.12,
      borderOpacity: 0.55,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.of(context).accent.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.verified_user_outlined,
              color: AppColors.of(context).darkGold,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'بياناتك آمنة',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.of(context).primary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'نحن نلتزم بحماية بياناتك ولن نشاركها مع أي جهة خارجية',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.5,
                    color: AppColors.of(context).textMuted,
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
