import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../auth/presentation/auth_controller.dart';
import '../widgets/lesson_file_card.dart';
import '../widgets/video_card.dart';
import 'subjects_controller.dart';

class LessonDetailsScreen extends ConsumerStatefulWidget {
  const LessonDetailsScreen({
    super.key,
    required this.lessonId,
  });

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

    return Scaffold(
      appBar: AppBar(
        title: Text(state.lesson?.title ?? 'تفاصيل الدرس'),
      ),
      body: _buildBody(state),
    );
  }

  Widget _buildBody(LessonDetailsState state) {
    switch (state.status) {
      case FeatureLoadStatus.initial:
      case FeatureLoadStatus.loading:
        return const LoadingWidget(message: 'جاري تحميل الدرس...');
      case FeatureLoadStatus.error:
        return ErrorView(
          message: state.errorMessage ?? 'تعذر تحميل الدرس',
          onRetry: () => ref
              .read(lessonDetailsControllerProvider(widget.lessonId).notifier)
              .load(widget.lessonId),
        );
      case FeatureLoadStatus.empty:
      case FeatureLoadStatus.loaded:
        final lesson = state.lesson;
        if (lesson == null) {
          return const ErrorView(message: 'الدرس غير موجود');
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(lesson.title, style: AppTextStyles.title),
            const SizedBox(height: 8),
            Text(
              lesson.isActive ? 'الحالة: متاح' : 'الحالة: ${lesson.status}',
              style: AppTextStyles.body.copyWith(color: AppColors.secondary),
            ),
            if (lesson.description != null && lesson.description!.isNotEmpty) ...[
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
          ],
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
