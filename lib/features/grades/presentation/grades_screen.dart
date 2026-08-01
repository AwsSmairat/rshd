import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../subjects/presentation/subjects_controller.dart';
import '../../../core/layout/app_layout_metrics.dart';
import '../widgets/grade_card.dart';
import 'grades_controller.dart';

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

  void _handleUnauthorized(String? message) {
    if (message != null && message.contains('انتهت الجلسة') && mounted) {
      ref.read(authControllerProvider.notifier).logout();
      context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gradesListControllerProvider);

    ref.listen(gradesListControllerProvider, (previous, next) {
      _handleUnauthorized(next.errorMessage);
    });

    return Scaffold(
      appBar: AppBar(title: const Text('درجاتي')),
      body: _buildBody(state),
    );
  }

  Widget _buildBody(GradesListState state) {
    switch (state.status) {
      case FeatureLoadStatus.initial:
      case FeatureLoadStatus.loading:
        return const LoadingWidget(message: 'جاري تحميل الدرجات...');
      case FeatureLoadStatus.empty:
        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: const [
              SizedBox(height: 120),
              Center(child: Text('لا توجد درجات حالياً')),
            ],
          ),
        );
      case FeatureLoadStatus.error:
        return ErrorView(
          message: state.errorMessage ?? 'حدث خطأ غير متوقع',
          onRetry: () => ref.read(gradesListControllerProvider.notifier).load(),
        );
      case FeatureLoadStatus.loaded:
        final pagePadding = AppLayoutMetrics.of(context).pagePadding(
          top: 16,
          bottom: 16,
        );
        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: pagePadding,
            itemCount: state.grades.length + 1,
            separatorBuilder: (context, index) {
              if (index == 0) {
                return const SizedBox(height: 12);
              }
              return const SizedBox(height: 12);
            },
            itemBuilder: (context, index) {
              if (index == 0) {
                return _GradesSummary(state: state);
              }

              final grade = state.grades[index - 1];
              return GradeCard(
                grade: grade,
                onTap: () => context.push(AppRoutes.gradeDetails(grade.id)),
              );
            },
          ),
        );
    }
  }
}

class _GradesSummary extends StatelessWidget {
  const _GradesSummary({required this.state});

  final GradesListState state;

  @override
  Widget build(BuildContext context) {
    final average = state.averageGrade;
    final highest = state.highestGrade;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('ملخص الدرجات', style: AppTextStyles.subtitle),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _SummaryItem(
                  label: 'عدد الدرجات',
                  value: '${state.count}',
                ),
              ),
              Expanded(
                child: _SummaryItem(
                  label: 'المتوسط',
                  value: average != null
                      ? '${average.toStringAsFixed(1)}%'
                      : '—',
                ),
              ),
              Expanded(
                child: _SummaryItem(
                  label: 'الأعلى',
                  value: highest != null
                      ? '${highest.toStringAsFixed(1)}%'
                      : '—',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.title.copyWith(
            fontSize: 18,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTextStyles.body.copyWith(
            fontSize: 12,
            color: AppColors.textMuted,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
