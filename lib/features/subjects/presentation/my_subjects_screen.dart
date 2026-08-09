import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/models/subject_model.dart';
import '../../../core/widgets/responsive_content.dart';
import '../widgets/luxury_subject_card.dart';
import '../widgets/subject_card.dart';
import '../widgets/subject_grouping_helper.dart';
import '../widgets/subject_section_header.dart';
import '../widgets/subjects_header.dart';
import '../widgets/subjects_state_views.dart';
import 'subjects_controller.dart';

class MySubjectsScreen extends ConsumerStatefulWidget {
  const MySubjectsScreen({super.key, this.category});

  final String? category;

  @override
  ConsumerState<MySubjectsScreen> createState() => _MySubjectsScreenState();
}

class _MySubjectsScreenState extends ConsumerState<MySubjectsScreen> {
  int? _requestingSubjectId;

  bool get _isCatalogMode =>
      widget.category != null && widget.category!.isNotEmpty;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _load();
    });
  }

  @override
  void didUpdateWidget(covariant MySubjectsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.category != widget.category) {
      _load(refresh: true);
    }
  }

  Future<void> _load({bool refresh = false}) {
    return ref
        .read(subjectsListControllerProvider.notifier)
        .load(refresh: refresh, category: widget.category);
  }

  Future<void> _refresh() => _load(refresh: true);

  void _handleUnauthorized(String? message) {
    if (message != null && message.contains('انتهت الجلسة') && mounted) {
      ref.read(authControllerProvider.notifier).logout();
      context.go(AppRoutes.login);
    }
  }

  String get _screenTitle {
    final category = widget.category;
    if (category == null || category.isEmpty) {
      return 'موادي';
    }
    return SubjectGroupingHelper.sectionTitles[category] ??
        SubjectModel.departmentSectionTitles[category] ??
        'موادي';
  }

  void _openSubject(SubjectModel subject) {
    context.push(AppRoutes.subjectDetails(subject.id), extra: subject);
  }

  Future<void> _requestPurchase(SubjectModel subject) async {
    setState(() => _requestingSubjectId = subject.id);
    final error = await ref
        .read(subjectsListControllerProvider.notifier)
        .requestPurchase(subject.id);
    if (!mounted) {
      return;
    }
    setState(() => _requestingSubjectId = null);

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
    final state = ref.watch(subjectsListControllerProvider);

    ref.listen(subjectsListControllerProvider, (previous, next) {
      _handleUnauthorized(next.errorMessage);
    });

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _buildBody(state),
    );
  }

  Widget _buildBody(SubjectsListState state) {
    return RefreshIndicator(
      onRefresh: _refresh,
      color: AppColors.darkGold,
      backgroundColor: AppColors.cardWhite,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: SubjectsHeader(title: _screenTitle)),
          ResponsiveSliverContent(sliver: _buildContent(state)),
        ],
      ),
    );
  }

  Widget _buildContent(SubjectsListState state) {
    switch (state.status) {
      case FeatureLoadStatus.initial:
      case FeatureLoadStatus.loading:
        return const SliverToBoxAdapter(
          child: SubjectsLoadingSkeleton(count: 3),
        );
      case FeatureLoadStatus.empty:
        return SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: SubjectsEmptyState(
              message: _isCatalogMode
                  ? 'لا توجد مواد في هذا القسم حالياً'
                  : 'لا توجد مواد مفعلة حالياً',
              subtitle: _isCatalogMode
                  ? 'عندما يضيف المدرّس مواداً ستظهر هنا لطلب الشراء'
                  : 'اطلب شراء مادة من الأقسام، ثم فعّلها الإدارة',
            ),
          ),
        );
      case FeatureLoadStatus.error:
        return SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: SubjectsErrorState(
              message: state.errorMessage ?? 'تعذر تحميل المواد',
              onRetry: _load,
            ),
          ),
        );
      case FeatureLoadStatus.loaded:
        final subjects = state.subjects;

        if (subjects.isEmpty) {
          return SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: SubjectsEmptyState(
                message: _isCatalogMode
                    ? 'لا توجد مواد في هذا القسم حالياً'
                    : 'لا توجد مواد مفعلة حالياً',
                subtitle: _isCatalogMode
                    ? 'عندما يضيف المدرّس مواداً ستظهر هنا لطلب الشراء'
                    : 'اطلب شراء مادة من الأقسام، ثم فعّلها الإدارة',
              ),
            ),
          );
        }

        if (_isCatalogMode) {
          return SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final subject = subjects[index];
              return Padding(
                padding: EdgeInsets.only(
                  bottom: index == subjects.length - 1 ? 0 : 16,
                ),
                child: LuxurySubjectCard(
                  subject: subject,
                  onTap: () => _openSubject(subject),
                  onRequestPurchase: subject.canRequestPurchase
                      ? () => _requestPurchase(subject)
                      : null,
                  isRequesting: _requestingSubjectId == subject.id,
                ),
              );
            }, childCount: subjects.length),
          );
        }

        final sections = SubjectGroupingHelper.groupSubjects(subjects);

        return SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final section = sections[index];
            return Padding(
              padding: EdgeInsets.only(
                bottom: index == sections.length - 1 ? 0 : 24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SubjectSectionHeader(
                    title: section.title,
                    categoryKey: section.categoryKey,
                  ),
                  const SizedBox(height: 14),
                  ...List.generate(section.subjects.length, (subjectIndex) {
                    final subject = section.subjects[subjectIndex];
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: subjectIndex == section.subjects.length - 1
                            ? 0
                            : 16,
                      ),
                      child: SubjectCard(
                        subject: subject,
                        onTap: () => _openSubject(subject),
                      ),
                    );
                  }),
                ],
              ),
            );
          }, childCount: sections.length),
        );
    }
  }
}
