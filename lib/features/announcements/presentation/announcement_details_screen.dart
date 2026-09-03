import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../subjects/presentation/subjects_controller.dart';
import '../../../core/layout/app_layout_metrics.dart';
import '../../../core/widgets/responsive_content.dart';
import '../../subjects/widgets/subjects_header.dart';
import '../data/models/announcement_model.dart';
import '../widgets/announcement_type_badge.dart';
import 'announcements_controller.dart';

class AnnouncementDetailsScreen extends ConsumerStatefulWidget {
  const AnnouncementDetailsScreen({
    super.key,
    required this.announcementId,
    this.initialAnnouncement,
  });

  final int announcementId;
  final AnnouncementModel? initialAnnouncement;

  @override
  ConsumerState<AnnouncementDetailsScreen> createState() =>
      _AnnouncementDetailsScreenState();
}

class _AnnouncementDetailsScreenState
    extends ConsumerState<AnnouncementDetailsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDetails();
    });
  }

  void _loadDetails() {
    final cached =
        widget.initialAnnouncement ??
        ref
            .read(announcementsListControllerProvider.notifier)
            .findById(widget.announcementId);

    ref
        .read(
          announcementDetailsControllerProvider(widget.announcementId).notifier,
        )
        .load(widget.announcementId, cached: cached);
  }

  void _handleUnauthorized(String? message) {
    if (message != null && message.contains('انتهت الجلسة') && mounted) {
      ref.read(authControllerProvider.notifier).logout();
      context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(
      announcementDetailsControllerProvider(widget.announcementId),
    );

    ref.listen(announcementDetailsControllerProvider(widget.announcementId), (
      previous,
      next,
    ) {
      _handleUnauthorized(next.errorMessage);
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF6F1E7),
      body: _buildBody(state),
    );
  }

  Widget _buildBody(AnnouncementDetailsState state) {
    switch (state.status) {
      case FeatureLoadStatus.initial:
      case FeatureLoadStatus.loading:
        return Column(
          children: const [
            SubjectsHeader(title: 'تفاصيل الإعلان'),
            Expanded(child: LoadingWidget(message: 'جاري تحميل الإعلان...')),
          ],
        );
      case FeatureLoadStatus.error:
        return Column(
          children: [
            const SubjectsHeader(title: 'تفاصيل الإعلان'),
            Expanded(
              child: ErrorView(
                message: state.errorMessage ?? 'تعذر تحميل الإعلان',
                onRetry: _loadDetails,
              ),
            ),
          ],
        );
      case FeatureLoadStatus.empty:
      case FeatureLoadStatus.loaded:
        final announcement = state.announcement;
        if (announcement == null) {
          return Column(
            children: [
              const SubjectsHeader(title: 'تفاصيل الإعلان'),
              Expanded(
                child: ErrorView(
                  message: 'الإعلان غير موجود',
                  onRetry: _loadDetails,
                ),
              ),
            ],
          );
        }

        return CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(
              child: SubjectsHeader(title: 'تفاصيل الإعلان'),
            ),
            ResponsiveSliverContent(
              padding: AppLayoutMetrics.of(
                context,
              ).pagePadding(top: 8, bottom: 32),
              sliver: SliverToBoxAdapter(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.of(context).cardWhite,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: AppColors.of(
                        context,
                      ).accent.withValues(alpha: 0.28),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.of(
                          context,
                        ).primary.withValues(alpha: 0.06),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (announcement.resolvedImageUrl != null) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: Image.network(
                              announcement.resolvedImageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: AppColors.of(context).background,
                                  alignment: Alignment.center,
                                  child: Icon(
                                    Icons.broken_image_outlined,
                                    color: AppColors.of(context).textMuted,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              announcement.title,
                              style: AppTextStyles.titleOf(context).copyWith(
                                fontSize: 22,
                                color: AppColors.of(context).primary,
                              ),
                            ),
                          ),
                          AnnouncementTypeBadge(type: announcement.type),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _InfoRow(label: 'النوع', value: announcement.typeLabel),
                      if (announcement.subjectTitle != null &&
                          announcement.subjectTitle!.isNotEmpty)
                        _InfoRow(
                          label: 'المادة',
                          value: announcement.subjectTitle!,
                        ),
                      if (announcement.createdAt != null &&
                          announcement.createdAt!.isNotEmpty)
                        _InfoRow(
                          label: 'التاريخ',
                          value: _formatDate(announcement.createdAt!),
                        ),
                      const SizedBox(height: 8),
                      Text(
                        'نص الإعلان',
                        style: AppTextStyles.subtitleOf(context).copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.of(context).primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        announcement.body ?? '—',
                        style: AppTextStyles.bodyOf(context).copyWith(
                          height: 1.6,
                          color: AppColors.of(context).text,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
    }
  }

  String _formatDate(String raw) {
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) {
      return raw;
    }
    return DateFormat('yyyy/MM/dd – HH:mm', 'ar').format(parsed.toLocal());
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.bodyOf(
              context,
            ).copyWith(color: AppColors.of(context).textMuted, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(value, style: AppTextStyles.bodyOf(context)),
        ],
      ),
    );
  }
}
