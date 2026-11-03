import 'package:flutter/material.dart';

import '../utils/open_lesson_file.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/layout/app_layout_metrics.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/responsive_content.dart';
import '../../assignments/data/models/assignment_model.dart';
import '../../quizzes/data/models/quiz_model.dart';
import '../widgets/lesson_content_tiles.dart';
import '../widgets/lesson_file_card.dart';
import '../widgets/subjects_header.dart';
import '../widgets/subjects_state_views.dart';
import '../widgets/video_card.dart';
import 'subjects_controller.dart';
import '../../../core/l10n/app_strings.dart';

class LessonDetailsScreen extends ConsumerStatefulWidget {
  const LessonDetailsScreen({super.key, required this.lessonId});

  final int lessonId;

  @override
  ConsumerState<LessonDetailsScreen> createState() =>
      _LessonDetailsScreenState();
}

class _LessonDetailsScreenState extends ConsumerState<LessonDetailsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(lessonDetailsControllerProvider(widget.lessonId).notifier)
          .load(widget.lessonId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(lessonDetailsControllerProvider(widget.lessonId));

    final title = state.lesson?.title ?? 'تفاصيل الدرس';

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: SubjectsHeader(
              title: title,
              backgroundIcon: Icons.play_lesson_outlined,
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

  Widget _buildContent(LessonDetailsState state) {
    switch (state.status) {
      case FeatureLoadStatus.initial:
      case FeatureLoadStatus.loading:
        return const SliverToBoxAdapter(
          child: SubjectsLoadingSkeleton(count: 3),
        );
      case FeatureLoadStatus.error:
        return SliverFillRemaining(
          hasScrollBody: false,
          child: ErrorView(
            message: state.errorMessage ?? 'تعذر تحميل الدرس',
            onRetry: () => ref
                .read(lessonDetailsControllerProvider(widget.lessonId).notifier)
                .load(widget.lessonId),
          ),
        );
      case FeatureLoadStatus.empty:
      case FeatureLoadStatus.loaded:
        final lesson = state.lesson;
        if (lesson == null) {
          return SliverFillRemaining(
            hasScrollBody: false,
            child: ErrorView(
              message: AppStrings.of(context).t('الدرس غير موجود'),
            ),
          );
        }

        return SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // The title is already the page header; show the state as a
              // small badge instead of repeating it.
              _StatusBadge(
                label: AppStrings.of(
                  context,
                ).t(lesson.isActive ? 'متاح' : lesson.status),
                active: lesson.isActive,
              ),
              if (lesson.description != null &&
                  lesson.description!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  AppStrings.of(context).t(lesson.description!),
                  style: AppTextStyles.bodyOf(context),
                ),
              ],
              const SizedBox(height: 24),
              _ContentSection(
                title: AppStrings.of(context).t('الفيديوهات'),
                emptyMessage: AppStrings.of(
                  context,
                ).t('لا توجد فيديوهات لهذا الدرس حالياً'),
                children: lesson.videos
                    .map(
                      (video) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: VideoCard(
                          video: video,
                          onTap: () {
                            if (video.isLocked) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    AppStrings.of(context).t(
                                      'هذا الفيديو مقفل. فعّل المادة لمشاهدته.',
                                    ),
                                  ),
                                ),
                              );
                              return;
                            }
                            context.push(AppRoutes.videoDetails(video.id));
                          },
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 16),
              _ContentSection(
                title: AppStrings.of(context).t('الملفات'),
                emptyMessage: AppStrings.of(
                  context,
                ).t('لا توجد ملفات لهذا الدرس حالياً'),
                children: lesson.files
                    .map(
                      (file) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: LessonFileCard(
                          file: file,
                          onTap: () => openLessonFile(context, file),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 16),
              _ContentSection(
                title: AppStrings.of(context).t('الواجبات'),
                emptyMessage: AppStrings.of(
                  context,
                ).t('لا توجد واجبات لهذا الجزء حالياً'),
                children: lesson.assignments
                    .map(
                      (AssignmentModel assignment) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: LessonAssignmentTile(
                          assignment: assignment,
                          onTap: () => context.push(
                            AppRoutes.assignmentDetails(assignment.id),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 16),
              _ContentSection(
                title: AppStrings.of(context).t('الاختبارات'),
                emptyMessage: AppStrings.of(
                  context,
                ).t('لا توجد اختبارات لهذا الجزء حالياً'),
                children: lesson.quizzes
                    .map(
                      (QuizModel quiz) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: LessonQuizTile(
                          quiz: quiz,
                          onTap: () =>
                              context.push(AppRoutes.quizDetails(quiz.id)),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        );
    }
  }
}

class _ContentSection extends StatelessWidget {
  const _ContentSection({
    required this.title,
    required this.emptyMessage,
    required this.children,
  });

  final String title;
  final String emptyMessage;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.of(context).t(title),
          style: AppTextStyles.bodyOf(
            context,
          ).copyWith(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        const SizedBox(height: 10),
        if (children.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.of(context).white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Text(
              AppStrings.of(context).t(emptyMessage),
              style: AppTextStyles.bodyOf(
                context,
              ).copyWith(color: AppColors.of(context).textMuted),
            ),
          )
        else
          ...children,
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.active});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active
        ? const Color(0xFF15803D)
        : AppColors.of(context).textMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            active ? Icons.check_circle_rounded : Icons.lock_clock_rounded,
            size: 15,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
