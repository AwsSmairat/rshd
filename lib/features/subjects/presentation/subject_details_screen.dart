import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/models/subject_model.dart';
import '../widgets/lesson_card.dart';
import 'subjects_controller.dart';

class SubjectDetailsScreen extends ConsumerStatefulWidget {
  const SubjectDetailsScreen({
    super.key,
    required this.subjectId,
    this.subject,
  });

  final int subjectId;
  final SubjectModel? subject;

  @override
  ConsumerState<SubjectDetailsScreen> createState() =>
      _SubjectDetailsScreenState();
}

class _SubjectDetailsScreenState extends ConsumerState<SubjectDetailsScreen> {
  bool _isRequesting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(subjectLessonsControllerProvider(widget.subjectId).notifier)
          .load(widget.subjectId);
    });
  }

  void _handleUnauthorized(String? message) {
    if (message != null && message.contains('انتهت الجلسة') && mounted) {
      ref.read(authControllerProvider.notifier).logout();
      context.go(AppRoutes.login);
    }
  }

  Future<void> _requestPurchase() async {
    setState(() => _isRequesting = true);
    final error = await ref
        .read(subjectsListControllerProvider.notifier)
        .requestPurchase(widget.subjectId);
    if (!mounted) {
      return;
    }
    setState(() => _isRequesting = false);

    final messenger = ScaffoldMessenger.of(context);
    if (error != null) {
      messenger.showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    messenger.showSnackBar(
      const SnackBar(
        content: Text('تم إرسال طلب الشراء. بانتظار تفعيل الإدارة.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final listState = ref.watch(subjectsListControllerProvider);
    SubjectModel? subject;
    for (final item in listState.subjects) {
      if (item.id == widget.subjectId) {
        subject = item;
        break;
      }
    }
    subject ??= widget.subject;

    final lessonsState =
        ref.watch(subjectLessonsControllerProvider(widget.subjectId));

    ref.listen(subjectLessonsControllerProvider(widget.subjectId), (prev, next) {
      _handleUnauthorized(next.errorMessage);
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(subject?.title ?? 'تفاصيل المادة'),
      ),
      body: subject == null
          ? const ErrorView(message: 'تعذر عرض بيانات المادة')
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (subject.resolvedCoverImageUrl != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Image.network(
                        subject.resolvedCoverImageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return ColoredBox(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            child: const Icon(
                              Icons.image_outlined,
                              color: AppColors.textMuted,
                              size: 40,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Text(subject.title, style: AppTextStyles.title),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _InfoChip(label: subject.categoryLabel),
                    if (subject.price != null)
                      _InfoChip(label: 'السعر: ${subject.price} د.أ'),
                    if (subject.isEnrollmentPending)
                      const _InfoChip(label: 'بانتظار التفعيل'),
                    if (subject.isEnrollmentActive)
                      const _InfoChip(label: 'مفعّلة'),
                  ],
                ),
                if (subject.instructor != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    'المدرّس: ${subject.instructor!.name}',
                    style: AppTextStyles.body,
                  ),
                ],
                if (subject.description != null &&
                    subject.description!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(subject.description!, style: AppTextStyles.body),
                ],
                const SizedBox(height: 24),
                if (!subject.isEnrollmentActive) ...[
                  if (subject.isEnrollmentPending)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        'طلب الشراء قيد المراجعة. يمكنك مشاهدة الفيديوهات المجانية حتى يتم تفعيل المادة.',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  else
                    FilledButton(
                      onPressed: _isRequesting ? null : _requestPurchase,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        _isRequesting ? 'جاري إرسال الطلب...' : 'طلب شراء المادة',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  const SizedBox(height: 12),
                  Text(
                    'معاينة المحتوى — الفيديوهات المجانية متاحة للمشاهدة',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textMuted,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Text(
                  'الأجزاء',
                  style: AppTextStyles.title.copyWith(fontSize: 20),
                ),
                const SizedBox(height: 12),
                _buildLessonsSection(lessonsState),
              ],
            ),
    );
  }

  Widget _buildLessonsSection(LessonsListState state) {
    switch (state.status) {
      case FeatureLoadStatus.initial:
      case FeatureLoadStatus.loading:
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: LoadingWidget(message: 'جاري تحميل الأجزاء...'),
        );
      case FeatureLoadStatus.empty:
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Center(child: Text('لا توجد أجزاء في هذه المادة')),
        );
      case FeatureLoadStatus.error:
        return ErrorView(
          message: state.errorMessage ?? 'تعذر تحميل الأجزاء',
          onRetry: () => ref
              .read(subjectLessonsControllerProvider(widget.subjectId).notifier)
              .load(widget.subjectId, refresh: true),
        );
      case FeatureLoadStatus.loaded:
        return Column(
          children: state.lessons
              .asMap()
              .entries
              .map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: LessonCard(
                    lesson: entry.value,
                    displayOrder: entry.key + 1,
                  ),
                ),
              )
              .toList(),
        );
    }
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: AppTextStyles.body.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
