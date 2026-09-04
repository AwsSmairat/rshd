import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/liquid_glass_surface.dart';
import '../data/models/announcement_model.dart';
import 'announcement_type_badge.dart';
import '../../../core/l10n/app_strings.dart';

class AnnouncementCard extends StatelessWidget {
  const AnnouncementCard({
    super.key,
    required this.announcement,
    required this.onTap,
  });

  final AnnouncementModel announcement;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final imageUrl = announcement.resolvedImageUrl;

    return LiquidGlassSurface(
      borderRadius: BorderRadius.circular(16),
      padding: const EdgeInsets.all(16),
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (imageUrl != null) ...[
            _AnnouncementThumb(imageUrl: imageUrl),
            const SizedBox(width: 12),
          ] else ...[
            AnnouncementTypeIcon(type: announcement.type),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppStrings.of(context).t(announcement.title),
                  style: AppTextStyles.titleOf(
                    context,
                  ).copyWith(fontSize: 16, fontWeight: FontWeight.w800),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                if (announcement.body != null &&
                    announcement.body!.trim().isNotEmpty)
                  Text(AppStrings.of(context).t(announcement.shortBody),
                    style: AppTextStyles.bodyOf(context).copyWith(
                      color: AppColors.of(context).textMuted,
                      fontSize: 13,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    AnnouncementTypeBadge(type: announcement.type),
                    if (announcement.subjectTitle != null &&
                        announcement.subjectTitle!.isNotEmpty)
                      Text(AppStrings.of(context).t(announcement.subjectTitle!),
                        style: AppTextStyles.bodyOf(context).copyWith(
                          fontSize: 12,
                          color: AppColors.of(context).secondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    if (announcement.createdAt != null &&
                        announcement.createdAt!.isNotEmpty)
                      Text(AppStrings.of(context).t(_formatDate(context, announcement.createdAt!)),
                        style: AppTextStyles.bodyOf(context).copyWith(
                          fontSize: 11,
                          color: AppColors.of(context).textMuted,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 14,
            color: AppColors.of(context).primary.withValues(alpha: 0.45),
          ),
        ],
      ),
    );
  }

  String _formatDate(BuildContext context, String raw) {
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) {
      return raw;
    }
    return DateFormat('yyyy/MM/dd', AppStrings.of(context).dateLocale).format(parsed.toLocal());
  }
}

class _AnnouncementThumb extends StatelessWidget {
  const _AnnouncementThumb({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Image.network(
        imageUrl,
        width: 72,
        height: 72,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 72,
            height: 72,
            color: AppColors.of(context).accent.withValues(alpha: 0.12),
            child: Icon(
              Icons.campaign_outlined,
              color: AppColors.of(context).darkGold,
            ),
          );
        },
      ),
    );
  }
}
