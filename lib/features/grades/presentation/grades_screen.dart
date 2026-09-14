import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/widgets/responsive_content.dart';
import '../../subjects/presentation/subjects_controller.dart';
import '../widgets/grade_card.dart';
import '../widgets/grades_empty_state.dart';
import '../widgets/grades_header.dart';
import '../widgets/grades_summary_card.dart';
import 'grades_controller.dart';
import '../../../core/l10n/app_strings.dart';

class GradesScreen extends ConsumerStatefulWidget {
  const GradesScreen({super.key});

  @override
  ConsumerState<GradesScreen> createState() => _GradesScreenState();
}

class _GradesScreenState extends ConsumerState<GradesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(gradesListControllerProvider.notifier).load();
    });
  }

  Future<void> _refresh() {
    return ref.read(gradesListControllerProvider.notifier).load(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gradesListControllerProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: AppColors.of(context).darkGold,
        backgroundColor: AppColors.of(context).cardWhite,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            const SliverToBoxAdapter(child: GradesHeader()),
            ResponsiveSliverContent(sliver: _buildContent(state)),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(GradesListState state) {
    switch (state.status) {
      case FeatureLoadStatus.initial:
      case FeatureLoadStatus.loading:
        return SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.only(top: 24),
            child: LoadingWidget(message: AppStrings.of(context).t('جاري تحميل الدرجات...')),
          ),
        );
      case FeatureLoadStatus.empty:
        return const SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: GradesEmptyState()),
        );
      case FeatureLoadStatus.error:
        return SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: ErrorView(
              message: state.errorMessage ?? 'حدث خطأ غير متوقع',
              onRetry: () =>
                  ref.read(gradesListControllerProvider.notifier).load(),
            ),
          ),
        );
      case FeatureLoadStatus.loaded:
        return SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            if (index == 0) {
              return GradesSummaryCard(state: state);
            }
            if (index == 1) {
              return Padding(
                padding: const EdgeInsets.only(top: 20, bottom: 12),
                child: Text(AppStrings.of(context).t('سجل الدرجات'),
                  style: AppTextStyles.subtitleOf(context).copyWith(
                    color: AppColors.of(context).primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              );
            }

            final grade = state.grades[index - 2];
            final isLast = index == state.grades.length + 1;

            return Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
              child: GradeCard(
                grade: grade,
                onTap: () => context.push(AppRoutes.gradeDetails(grade.id)),
              ),
            );
          }, childCount: state.grades.length + 2),
        );
    }
  }
}
