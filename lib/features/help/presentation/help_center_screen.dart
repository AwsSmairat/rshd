import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/layout/app_layout_metrics.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/widgets/responsive_content.dart';
import '../../subjects/presentation/subjects_controller.dart';
import '../../subjects/widgets/subjects_header.dart';
import '../data/help_center_model.dart';
import '../presentation/help_center_controller.dart';
import '../widgets/help_center_cards.dart';
import '../widgets/help_message_sheet.dart';

class HelpCenterScreen extends ConsumerStatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  ConsumerState<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends ConsumerState<HelpCenterScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(helpCenterControllerProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(helpCenterControllerProvider);
    final metrics = AppLayoutMetrics.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: switch (state.status) {
        FeatureLoadStatus.initial || FeatureLoadStatus.loading =>
          const LoadingWidget(message: 'جاري تحميل مركز المساعدة...'),
        FeatureLoadStatus.error => ErrorView(
            message: state.errorMessage ?? 'تعذر تحميل مركز المساعدة',
            onRetry: () =>
                ref.read(helpCenterControllerProvider.notifier).load(refresh: true),
          ),
        FeatureLoadStatus.empty || FeatureLoadStatus.loaded => RefreshIndicator(
            onRefresh: () =>
                ref.read(helpCenterControllerProvider.notifier).load(refresh: true),
            color: AppColors.secondary,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                const SliverToBoxAdapter(
                  child: SubjectsHeader(
                    title: 'مركز المساعدة',
                    backgroundIcon: Icons.help_center_outlined,
                  ),
                ),
                SliverToBoxAdapter(
                  child: ResponsiveContent(
                    padding: EdgeInsets.fromLTRB(
                      metrics.outerHorizontalInset,
                      12,
                      metrics.outerHorizontalInset,
                      MediaQuery.paddingOf(context).bottom + 24,
                    ),
                    child: _buildContent(state),
                  ),
                ),
              ],
            ),
          ),
      },
    );
  }

  Widget _buildContent(HelpCenterState state) {
    final contacts = state.contacts;
    if (contacts == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'كيف يمكننا مساعدتك؟',
          style: AppTextStyles.subtitle.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'تواصل مع مدرّس مادتك أو مع فريق الدعم الفني',
          style: AppTextStyles.body.copyWith(
            fontSize: 13,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 16),
        HelpSupportCard(
          onContact: () => context.push(AppRoutes.technicalSupport),
        ),
        const SizedBox(height: 20),
        Text(
          'المدرسون — موادك المفعّلة',
          style: AppTextStyles.subtitle.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 10),
        if (contacts.teachers.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Text(
              'لا توجد مواد مفعّلة حالياً. فعّل مادة أولاً لتتمكن من التواصل مع مدرّسها.',
              style: AppTextStyles.body.copyWith(
                fontSize: 13,
                color: AppColors.textMuted,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          )
        else
          ...contacts.teachers.map(
            (teacher) => HelpTeacherContactTile(
              teacher: teacher,
              onContact: () => _openTeacherMessageSheet(teacher),
            ),
          ),
      ],
    );
  }

  Future<void> _openTeacherMessageSheet(TeacherContactModel teacher) async {
    final sent = await showHelpMessageSheet(
      context: context,
      teacher: teacher,
      onSend: (message) => ref
          .read(helpCenterControllerProvider.notifier)
          .sendMessage(subjectId: teacher.subjectId, message: message),
    );

    if (!mounted || !sent) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم إرسال رسالتك إلى المدرّس')),
    );
  }
}
