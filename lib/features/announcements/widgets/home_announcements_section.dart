import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/responsive_content.dart';
import '../data/models/announcement_model.dart';
import 'announcement_image_carousel.dart';

class HomeAnnouncementsSection extends StatelessWidget {
  const HomeAnnouncementsSection({
    super.key,
    required this.announcements,
    this.loadFailed = false,
  });

  final List<AnnouncementModel> announcements;
  final bool loadFailed;

  List<AnnouncementModel> get _carouselItems =>
      announcements.where((item) => item.hasCarouselImage).take(5).toList();

  @override
  Widget build(BuildContext context) {
    final carouselItems = _carouselItems;
    if (carouselItems.isEmpty && !loadFailed) {
      return const SizedBox.shrink();
    }

    return ResponsiveContent(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Container(
              width: 4,
              height: 20,
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 8),
          AnnouncementImageCarousel(announcements: carouselItems),
          if (loadFailed)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'تعذر تحميل بعض الإعلانات',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
}
