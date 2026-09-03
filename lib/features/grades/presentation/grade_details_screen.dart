import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/layout/app_layout_metrics.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/responsive_content.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../subjects/presentation/subjects_controller.dart';
import '../../subjects/widgets/subjects_header.dart';
import '../data/models/grade_model.dart';
import '../widgets/grade_type_badge.dart';
import '../widgets/grades_state_views.dart';
import 'grades_controller.dart';

class GradeDetailsScreen extends ConsumerStatefulWidget {
  const GradeDetailsScreen({
    super.key,
    required this.gradeId,
    this.initialGrade,
  });

  final int gradeId;
  final GradeModel? initialGrade;

  @override
  ConsumerState<GradeDetailsScreen> createState() => _GradeDetailsScreenState();
}

class _GradeDetailsScreenState extends ConsumerState<GradeDetailsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDetails();
    });
  }

  void _loadDetails() {
    final cached =
        widget.initialGrade ??
        ref
            .read(gradesListControllerProvider.notifier)
            .findById(widget.gradeId);
    ref
        .read(gradeDetailsControllerProvider(widget.gradeId).notifier)
        .load(widget.gradeId, cached: cached);
  }

  void _handleUnauthorized(String? message) {
    if (message != null && message.contains('انتهت الجلسة') && mounted) {
      ref.read(authControllerProvider.notifier).logout();
      context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gradeDetailsControllerProvider(widget.gradeId));

    ref.listen(gradeDetailsControllerProvider(widget.gradeId), (
      previous,
      next,
    ) {
      _handleUnauthorized(next.errorMessage);
    });

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(
            child: SubjectsHeader(
              title: 'تفاصيل الدرجة',
              backgroundIcon: Icons.grade_outlined,
            ),
          ),
          ResponsiveSliverContent(
            padding: AppLayoutMetrics.of(
              context,
            ).pagePadding(top: 8, bottom: 28),
            sliver: _buildContent(state),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(GradeDetailsState state) {
    switch (state.status) {
      case FeatureLoadStatus.initial:
      case FeatureLoadStatus.loading:
        return const SliverToBoxAdapter(child: GradesLoadingSkeleton(count: 2));
      case FeatureLoadStatus.error:
        return SliverFillRemaining(
          hasScrollBody: false,
          child: ErrorView(
            message: state.errorMessage ?? 'حدث خطأ غير متوقع',
            onRetry: _loadDetails,
          ),
        );
      case FeatureLoadStatus.empty:
      case FeatureLoadStatus.loaded:
        final grade = state.grade;
        if (grade == null) {
          return SliverFillRemaining(
            hasScrollBody: false,
            child: ErrorView(
              message: 'الدرجة غير موجودة',
              onRetry: _loadDetails,
            ),
          );
        }

        return SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GradeTypeBadge(sourceType: grade.sourceType),
              const SizedBox(height: 16),
              Text(grade.displayTitle, style: AppTextStyles.titleOf(context)),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.of(context).accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Text(
                      'الدرجة',
                      style: AppTextStyles.bodyOf(
                        context,
                      ).copyWith(color: AppColors.of(context).textMuted),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${grade.grade}%',
                      style: AppTextStyles.titleOf(context).copyWith(
                        fontSize: 32,
                        color: AppColors.of(context).primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _InfoRow(label: 'نوع الدرجة', value: grade.sourceTypeLabel),
              _InfoRow(label: 'المادة', value: grade.subjectTitle ?? '—'),
              if (grade.createdAt != null && grade.createdAt!.isNotEmpty)
                _InfoRow(
                  label: 'التاريخ',
                  value: _formatDate(grade.createdAt!),
                ),
              if (grade.notes != null && grade.notes!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('الملاحظات', style: AppTextStyles.subtitleOf(context)),
                const SizedBox(height: 8),
                Text(grade.notes!, style: AppTextStyles.bodyOf(context)),
              ],
            ],
          ),
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
