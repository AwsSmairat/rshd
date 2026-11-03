import 'package:flutter/material.dart';
import '../../../core/widgets/stagger_reveal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../home/home_controller.dart';
import '../../../core/widgets/rshd_refresh_indicator.dart';
import '../../home/widgets/continue_learning_card.dart';
import '../../home/widgets/home_section_header.dart';
import '../widgets/catalog_subject_card.dart';
import '../widgets/study_year_bar.dart';
import '../widgets/subjects_page_header.dart';
import '../../home/widgets/academic_departments_section.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/layout/app_layout_metrics.dart';
import '../../../core/router/app_router.dart';
import '../../../core/widgets/card_grid.dart';
import '../data/models/subject_model.dart';
import '../../../core/widgets/responsive_content.dart';
import '../widgets/subject_grouping_helper.dart';
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

  /// Study-year filter on the medicine department page; null = all years.
  int? _selectedYear;

  bool get _isMedicineCatalog => widget.category == 'medicine';

  /// The department page has its own list; the tab shows enrolled courses.
  SubjectsListController _controller() => _isCatalogMode
      ? ref.read(subjectsCatalogControllerProvider(widget.category!).notifier)
      : ref.read(subjectsListControllerProvider.notifier);

  SubjectsListState _watchList() => _isCatalogMode
      ? ref.watch(subjectsCatalogControllerProvider(widget.category!))
      : ref.watch(subjectsListControllerProvider);

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
    return _controller().load(refresh: refresh, category: widget.category);
  }

  Future<void> _refresh() => _load(refresh: true);

  String get _screenTitle {
    final category = widget.category;
    final strings = AppStrings.of(context);
    if (category == null || category.isEmpty) {
      return strings.navSubjects;
    }
    return strings.departmentTitle(category);
  }

  void _openSubject(SubjectModel subject) {
    context.push(AppRoutes.subjectDetails(subject.id), extra: subject);
  }

  Future<void> _requestPurchase(SubjectModel subject) async {
    setState(() => _requestingSubjectId = subject.id);
    final error = await _controller().requestPurchase(subject.id);
    if (!mounted) {
      return;
    }
    setState(() => _requestingSubjectId = null);

    final messenger = ScaffoldMessenger.of(context);
    if (error != null) {
      messenger.showSnackBar(
        SnackBar(content: Text(AppStrings.of(context).t(error))),
      );
      return;
    }
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          AppStrings.of(
            context,
          ).t('تم إرسال طلب الشراء. بانتظار تفعيل الإدارة.'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = _watchList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _buildBody(state),
    );
  }

  Widget _buildBody(SubjectsListState state) {
    final strings = AppStrings.of(context);
    final loaded = state.status == FeatureLoadStatus.loaded;
    final subtitle = loaded
        ? strings.subjectCountLabel(state.subjects.length)
        : null;

    return RshdRefreshIndicator(
      onRefresh: _refresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          SliverSafeArea(
            bottom: false,
            sliver: SliverToBoxAdapter(
              child: ResponsiveContent(
                child: SubjectsPageHeader(
                  title: _screenTitle,
                  subtitle: subtitle,
                  onBack: Navigator.of(context).canPop()
                      ? () => Navigator.of(context).maybePop()
                      : null,
                ),
              ),
            ),
          ),
          if (_isMedicineCatalog)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 18),
                child: ResponsiveContent(
                  child: StudyYearBar(
                    selected: _selectedYear,
                    onChanged: (year) => setState(() => _selectedYear = year),
                  ),
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
          ResponsiveSliverContent(sliver: _buildContent(state)),
          // Browsing the catalogue by department lives on this tab.
          if (!_isCatalogMode)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 32),
                child: AcademicDepartmentsSection(
                  subjects:
                      ref
                          .watch(homeControllerProvider)
                          .dashboard
                          ?.catalogSubjects ??
                      const [],
                  showViewAll: false,
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 28)),
        ],
      ),
    );
  }

  IconData get _departmentIcon => switch (widget.category) {
    'medicine' => Icons.medical_services_outlined,
    'it' => Icons.code_rounded,
    'engineering' => Icons.architecture_outlined,
    _ => Icons.auto_stories_outlined,
  };

  /// Nothing to list: on a department page, say more are coming and offer a
  /// way back; on My courses, point to the departments below.
  Widget _emptyState() {
    final strings = AppStrings.of(context);
    if (_isCatalogMode) {
      return _emptyBox(
        SubjectsEmptyState(
          icon: _departmentIcon,
          message: strings.emptyDepartmentTitle,
          subtitle: strings.emptyDepartmentHint,
          actionLabel: strings.browseOtherDepartments,
          onAction: () => Navigator.of(context).maybePop(),
        ),
      );
    }
    return _emptyBox(
      SubjectsEmptyState(
        message: strings.emptyMyCoursesTitle,
        subtitle: strings.emptyMyCoursesHint,
      ),
    );
  }

  Widget _emptyBox(Widget child) => SliverToBoxAdapter(
    child: Padding(
      padding: const EdgeInsets.only(top: 36, bottom: 12),
      child: Center(child: child),
    ),
  );

  Widget _buildContent(SubjectsListState state) {
    switch (state.status) {
      case FeatureLoadStatus.initial:
      case FeatureLoadStatus.loading:
        return const SliverToBoxAdapter(
          child: SubjectsLoadingSkeleton(count: 3),
        );
      case FeatureLoadStatus.empty:
        return _emptyState();
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

        if (subjects.isEmpty) return _emptyState();

        if (_isCatalogMode) {
          final year = _selectedYear;
          final shown = year == null
              ? subjects
              : subjects.where((s) => s.studyYear == year).toList();
          if (shown.isEmpty) {
            final strings = AppStrings.of(context);
            return _emptyBox(
              SubjectsEmptyState(
                icon: Icons.school_outlined,
                message: strings.noCoursesForYear(year!),
                subtitle: strings.tryAnotherYear,
                actionLabel: strings.showAllYears,
                onAction: () => setState(() => _selectedYear = null),
              ),
            );
          }
          Widget card(int index) {
            final subject = shown[index];
            return StaggerReveal(
              order: index,
              child: CatalogSubjectCard(
                subject: subject,
                onTap: () => _openSubject(subject),
                onRequestPurchase: subject.canRequestPurchase
                    ? () => _requestPurchase(subject)
                    : null,
                isRequesting: _requestingSubjectId == subject.id,
              ),
            );
          }

          // Two columns of course cards on wide screens.
          final columns = AppLayoutMetrics.of(context).cardColumns;
          if (columns > 1) {
            return SliverGrid.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                mainAxisExtent: 168,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
              ),
              itemCount: shown.length,
              itemBuilder: (context, index) => card(index),
            );
          }
          return SliverList.separated(
            itemCount: shown.length,
            separatorBuilder: (_, _) => const SizedBox(height: 14),
            itemBuilder: (context, index) => card(index),
          );
        }

        final sections = SubjectGroupingHelper.groupSubjects(subjects);

        return SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final section = sections[index];
            return Padding(
              padding: EdgeInsets.only(
                bottom: index == sections.length - 1 ? 0 : 26,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  HomeSectionHeader(
                    title: AppStrings.of(
                      context,
                    ).departmentTitle(section.categoryKey),
                  ),
                  const SizedBox(height: 10),
                  CardGrid(
                    children: [
                      for (final subject in section.subjects)
                        ContinueLearningCard(
                          subject: subject,
                          progressPercent: subject.progressPercent ?? 0,
                        ),
                    ],
                  ),
                ],
              ),
            );
          }, childCount: sections.length),
        );
    }
  }
}
