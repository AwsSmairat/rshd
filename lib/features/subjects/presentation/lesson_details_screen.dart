import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/layout/app_layout_metrics.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/responsive_content.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../assignments/data/models/assignment_model.dart';
import '../../quizzes/data/models/quiz_model.dart';
import '../widgets/lesson_content_tiles.dart';
import '../widgets/lesson_file_card.dart';
import '../widgets/subjects_header.dart';
import '../widgets/subjects_state_views.dart';
import '../widgets/video_card.dart';
import 'subjects_controller.dart';

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

  void _handleUnauthorized(String? message) {
    if (message != null && message.contains('انتهت الجلسة') && mounted) {
      ref.read(authControllerProvider.notifier).logout();
      context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(lessonDetailsControllerProvider(widget.lessonId));

    ref.listen(lessonDetailsControllerProvider(widget.lessonId), (prev, next) {
      _handleUnauthorized(next.errorMessage);
    });

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
          return const SliverFillRemaining(
            hasScrollBody: false,
            child: ErrorView(message: 'الدرس غير موجود'),
          );
        }

        return SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(lesson.title, style: AppTextStyles.title),
              const SizedBox(height: 8),
              Text(
                lesson.isActive ? 'الحالة: متاح' : 'الحالة: ${lesson.status}',
                style: AppTextStyles.body.copyWith(color: AppColors.secondary),
              ),
              if (lesson.description != null &&
                  lesson.description!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(lesson.description!, style: AppTextStyles.body),
              ],
              const SizedBox(height: 24),
              _ContentSection(
                title: 'الفيديوهات',
                emptyMessage: 'لا توجد فيديوهات لهذا الدرس حالياً',
                children: lesson.videos
                    .map(
                      (video) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: VideoCard(
                          video: video,
                          onTap: () {
                            if (video.isLocked) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'هذا الفيديو مقفل. فعّل المادة لمشاهدته.',
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
                title: 'الملفات',
                emptyMessage: 'لا توجد ملفات لهذا الدرس حالياً',
                children: lesson.files
                    .map(
                      (file) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: LessonFileCard(
                          file: file,
                          onTap: () {
                            if (file.isLocked) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'الملف مقفل. فعّل المادة لفتحه.',
                                  ),
                                ),
                              );
                              return;
                            }
                            context.push(AppRoutes.fileDetails(file.id));
                          },
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 16),
              _ContentSection(
                title: 'الواجبات',
                emptyMessage: 'لا توجد واجبات لهذا الجزء حالياً',
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
                title: 'الاختبارات',
                emptyMessage: 'لا توجد اختبارات لهذا الجزء حالياً',
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
          title,
          style: AppTextStyles.body.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 10),
        if (children.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Text(
              emptyMessage,
              style: AppTextStyles.body.copyWith(color: AppColors.textMuted),
            ),
          )
        else
          ...children,
      ],
    );
  }
}
