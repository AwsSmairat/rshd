import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/widgets/responsive_content.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/models/subject_model.dart';
import '../data/subjects_repository.dart';
import '../widgets/lesson_card.dart';
import '../widgets/subject_details_header.dart';
import 'subjects_controller.dart';
import '../../../core/l10n/app_strings.dart';

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
  bool _isCancelling = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cached = ref
          .read(subjectsListControllerProvider.notifier)
          .findSubjectById(widget.subjectId);

      ref
          .read(subjectDetailsControllerProvider(widget.subjectId).notifier)
          .load(
            widget.subjectId,
            initial: widget.subject,
            cached: cached,
            refresh: true,
          );

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

    try {
      final updated = await ref
          .read(subjectsRepositoryProvider)
          .requestPurchase(widget.subjectId);

      if (!mounted) {
        return;
      }

      final current = ref
          .read(subjectDetailsControllerProvider(widget.subjectId))
          .subject;
      final merged = (current ?? updated).copyWith(
        enrollmentStatus: updated.enrollmentStatus,
      );

      ref
          .read(subjectDetailsControllerProvider(widget.subjectId).notifier)
          .updateSubject(merged);
      ref
          .read(subjectsListControllerProvider.notifier)
          .syncEnrollmentStatus(widget.subjectId, updated.enrollmentStatus);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.of(context).t('تم إرسال طلب الشراء. بانتظار تفعيل الإدارة.')),
        ),
      );
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppStrings.of(context).t(mapSubjectsError(error)))));
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppStrings.of(context).t('تعذر إرسال طلب الشراء'))));
    } finally {
      if (mounted) {
        setState(() => _isRequesting = false);
      }
    }
  }

  Future<void> _cancelPurchase() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppStrings.of(context).t('إلغاء طلب الشراء')),
        content: Text(AppStrings.of(context).t('هل تريد إلغاء طلب شراء هذه المادة؟ يمكنك إرسال طلب جديد لاحقاً.'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppStrings.of(context).t('تراجع')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.of(context).error,
            ),
            child: Text(AppStrings.of(context).t('إلغاء الطلب')),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() => _isCancelling = true);

    try {
      final updated = await ref
          .read(subjectsRepositoryProvider)
          .cancelPurchaseRequest(widget.subjectId);

      if (!mounted) {
        return;
      }

      final current = ref
          .read(subjectDetailsControllerProvider(widget.subjectId))
          .subject;
      final merged = (current ?? updated).copyWith(
        enrollmentStatus: updated.enrollmentStatus,
      );

      ref
          .read(subjectDetailsControllerProvider(widget.subjectId).notifier)
          .updateSubject(merged);
      ref
          .read(subjectsListControllerProvider.notifier)
          .syncEnrollmentStatus(widget.subjectId, updated.enrollmentStatus);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppStrings.of(context).t('تم إلغاء طلب الشراء.'))));
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppStrings.of(context).t(mapSubjectsError(error)))));
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppStrings.of(context).t('تعذر إلغاء طلب الشراء'))));
    } finally {
      if (mounted) {
        setState(() => _isCancelling = false);
      }
    }
  }

  Future<void> _retry() async {
    await ref
        .read(subjectDetailsControllerProvider(widget.subjectId).notifier)
        .load(widget.subjectId, refresh: true);
    await ref
        .read(subjectLessonsControllerProvider(widget.subjectId).notifier)
        .load(widget.subjectId, refresh: true);

    final refreshedSubject = ref
        .read(subjectDetailsControllerProvider(widget.subjectId))
        .subject;
    if (refreshedSubject != null) {
      ref
          .read(subjectsListControllerProvider.notifier)
          .syncSubjectProgress(refreshedSubject);
    }
  }

  @override
  Widget build(BuildContext context) {
    final detailsState = ref.watch(
      subjectDetailsControllerProvider(widget.subjectId),
    );
    final subject = detailsState.subject;

    final lessonsState = ref.watch(
      subjectLessonsControllerProvider(widget.subjectId),
    );

    ref.listen(subjectLessonsControllerProvider(widget.subjectId), (
      prev,
      next,
    ) {
      _handleUnauthorized(next.errorMessage);
    });

    ref.listen(subjectDetailsControllerProvider(widget.subjectId), (
      prev,
      next,
    ) {
      _handleUnauthorized(next.errorMessage);
    });

    return Scaffold(
      backgroundColor: AppColors.of(context).background,
      body: _buildBody(detailsState, lessonsState, subject),
    );
  }

  Widget _buildBody(
    SubjectDetailsState detailsState,
    LessonsListState lessonsState,
    SubjectModel? subject,
  ) {
    switch (detailsState.status) {
      case FeatureLoadStatus.initial:
      case FeatureLoadStatus.loading:
        return LoadingWidget(message: AppStrings.of(context).t('جاري تحميل بيانات المادة...'));
      case FeatureLoadStatus.error:
        return ErrorView(
          message: detailsState.errorMessage ?? 'تعذر عرض بيانات المادة',
          onRetry: _retry,
        );
      case FeatureLoadStatus.empty:
      case FeatureLoadStatus.loaded:
        if (subject == null) {
          return ErrorView(message: AppStrings.of(context).t('تعذر عرض بيانات المادة'), onRetry: _retry);
        }
        return RefreshIndicator(
          onRefresh: _retry,
          child: _buildSubjectContent(subject, lessonsState),
        );
    }
  }

  Widget _buildSubjectContent(
    SubjectModel subject,
    LessonsListState lessonsState,
  ) {
    final lessonsCount = lessonsState.status == FeatureLoadStatus.loaded
        ? lessonsState.lessons.length
        : 0;

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      slivers: [
        SubjectDetailsHero(subject: subject),
        SliverToBoxAdapter(
          child: ResponsiveContent(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
            child: SubjectDetailsMetaCard(
              subject: subject,
              lessonsCount: lessonsCount,
              isRequesting: _isRequesting,
              isCancelling: _isCancelling,
              onRequestPurchase: _requestPurchase,
              onCancelPurchase: _cancelPurchase,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: ResponsiveContent(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
            child: SubjectDetailsSectionHeader(
              title: AppStrings.of(context).t('الأجزاء'),
              count: lessonsCount > 0 ? lessonsCount : null,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: ResponsiveContent(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
            child: _buildLessonsSection(lessonsState),
          ),
        ),
      ],
    );
  }

  Widget _buildLessonsSection(LessonsListState state) {
    switch (state.status) {
      case FeatureLoadStatus.initial:
      case FeatureLoadStatus.loading:
        return Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: LoadingWidget(message: AppStrings.of(context).t('جاري تحميل الأجزاء...')),
        );
      case FeatureLoadStatus.empty:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 28),
          child: Center(
            child: Text(AppStrings.of(context).t('لا توجد أجزاء في هذه المادة'),
              style: TextStyle(
                color: AppColors.of(context).textMuted.withValues(alpha: 0.9),
              ),
            ),
          ),
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
                  padding: const EdgeInsets.only(bottom: 12),
                  child: LessonCard(
                    lesson: entry.value,
                    displayOrder: entry.key + 1,
                    initiallyExpanded:
                        entry.key == 0 && state.lessons.length == 1,
                  ),
                ),
              )
              .toList(),
        );
    }
  }
}
