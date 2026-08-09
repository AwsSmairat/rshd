import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/layout/app_layout_metrics.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/responsive_content.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../subjects/presentation/subjects_controller.dart';
import '../widgets/assignment_action_button.dart';
import '../widgets/assignment_download_file_card.dart';
import '../widgets/assignment_hero_card.dart';
import '../widgets/assignment_section_card.dart';
import '../widgets/assignments_state_views.dart';
import '../widgets/luxury_assignment_header.dart';
import '../widgets/submitted_file_card.dart';
import 'assignments_controller.dart';

class AssignmentDetailsScreen extends ConsumerStatefulWidget {
  const AssignmentDetailsScreen({super.key, required this.assignmentId});

  final int assignmentId;

  @override
  ConsumerState<AssignmentDetailsScreen> createState() =>
      _AssignmentDetailsScreenState();
}

class _AssignmentDetailsScreenState
    extends ConsumerState<AssignmentDetailsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDetails();
    });
  }

  void _loadDetails() {
    final cached = ref
        .read(assignmentsListControllerProvider.notifier)
        .findById(widget.assignmentId);
    ref
        .read(assignmentDetailsControllerProvider(widget.assignmentId).notifier)
        .load(widget.assignmentId, cached: cached);
  }

  Future<void> _openSubmitScreen() async {
    await context.push(AppRoutes.submitAssignment(widget.assignmentId));
    if (!mounted) {
      return;
    }
    await ref
        .read(assignmentsListControllerProvider.notifier)
        .load(refresh: true);
    _loadDetails();
  }

  void _handleUnauthorized(String? message) {
    if (message != null && message.contains('انتهت الجلسة') && mounted) {
      ref.read(authControllerProvider.notifier).logout();
      context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(
      assignmentDetailsControllerProvider(widget.assignmentId),
    );

    ref.listen(assignmentDetailsControllerProvider(widget.assignmentId), (
      previous,
      next,
    ) {
      _handleUnauthorized(next.errorMessage);
    });

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(
            child: LuxuryAssignmentHeader(title: 'تفاصيل الواجب'),
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

  Widget _buildContent(AssignmentDetailsState state) {
    switch (state.status) {
      case FeatureLoadStatus.initial:
      case FeatureLoadStatus.loading:
        return const SliverToBoxAdapter(
          child: AssignmentsLoadingSkeleton(count: 2),
        );
      case FeatureLoadStatus.error:
        return SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: AssignmentsErrorState(
              message: state.errorMessage ?? 'تعذر تحميل الواجب',
              onRetry: _loadDetails,
            ),
          ),
        );
      case FeatureLoadStatus.empty:
      case FeatureLoadStatus.loaded:
        final assignment = state.assignment;
        if (assignment == null) {
          return SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: AssignmentsErrorState(
                message: 'الواجب غير موجود',
                onRetry: _loadDetails,
              ),
            ),
          );
        }

        final submission = assignment.submission;

        return SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AssignmentHeroCard(assignment: assignment),
              const SizedBox(height: 16),
              if (assignment.hasAttachment) ...[
                AssignmentDownloadFileCard(
                  title: 'ملف الواجب',
                  fileUrl: assignment.resolvedAttachmentUrl!,
                  fileName: assignment.originalFileName,
                  fileSize: assignment.fileSize,
                  mimeType: assignment.fileMimeType,
                  icon: Icons.description_outlined,
                ),
                const SizedBox(height: 16),
              ],
              if (assignment.description != null &&
                  assignment.description!.isNotEmpty) ...[
                AssignmentSectionCard(
                  title: 'الوصف',
                  icon: Icons.description_outlined,
                  child: Text(
                    assignment.description!,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              AssignmentInfoGrid(assignment: assignment),
              if (submission != null) ...[
                const SizedBox(height: 16),
                AssignmentSubmissionDetailsCard(submission: submission),
                const SizedBox(height: 16),
                SubmittedFileCard(submission: submission),
                const SizedBox(height: 24),
                AssignmentActionButton(
                  label: 'تعديل التسليم',
                  icon: Icons.refresh_rounded,
                  onPressed: _openSubmitScreen,
                ),
                const SizedBox(height: 12),
                AssignmentActionButton(
                  label: 'العودة إلى الواجبات',
                  icon: Icons.list_alt_outlined,
                  isPrimary: false,
                  onPressed: () => context.go(AppRoutes.assignments),
                ),
              ] else ...[
                const SizedBox(height: 24),
                AssignmentActionButton(
                  label: 'تسليم الواجب',
                  icon: Icons.upload_file_outlined,
                  onPressed: _openSubmitScreen,
                ),
              ],
            ],
          ),
        );
    }
  }
}
