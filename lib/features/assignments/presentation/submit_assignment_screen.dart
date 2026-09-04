import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/layout/app_layout_metrics.dart';
import '../../../core/widgets/responsive_content.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../subjects/presentation/subjects_controller.dart';
import '../data/models/assignment_model.dart';
import '../widgets/assignment_action_button.dart';
import '../widgets/assignment_download_file_card.dart';
import '../widgets/assignment_file_helper.dart';
import '../widgets/assignment_file_picker_card.dart';
import '../widgets/assignment_section_card.dart';
import '../widgets/assignment_submit_info_card.dart';
import '../widgets/assignments_state_views.dart';
import '../widgets/luxury_assignment_header.dart';
import 'assignments_controller.dart';
import '../../../core/l10n/app_strings.dart';

class SubmitAssignmentScreen extends ConsumerStatefulWidget {
  const SubmitAssignmentScreen({super.key, required this.assignmentId});

  final int assignmentId;

  @override
  ConsumerState<SubmitAssignmentScreen> createState() =>
      _SubmitAssignmentScreenState();
}

class _SubmitAssignmentScreenState
    extends ConsumerState<SubmitAssignmentScreen> {
  final _answerController = TextEditingController();
  PlatformFile? _selectedFile;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cached = ref
          .read(assignmentsListControllerProvider.notifier)
          .findById(widget.assignmentId);
      ref
          .read(
            assignmentDetailsControllerProvider(widget.assignmentId).notifier,
          )
          .load(widget.assignmentId, cached: cached);
    });
  }

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: AssignmentFileHelper.allowedExtensions,
      withData: false,
    );

    if (result == null || result.files.isEmpty) {
      return;
    }

    final file = result.files.first;
    final validationError = AssignmentFileHelper.validate(
      path: file.path,
      name: file.name,
      size: file.size,
    );

    if (validationError != null) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppStrings.of(context).t(validationError))));
      }
      return;
    }

    setState(() => _selectedFile = file);
  }

  Future<void> _submit() async {
    final answerText = _answerController.text.trim();
    final hasFile =
        _selectedFile?.path != null && _selectedFile!.path!.isNotEmpty;

    if (answerText.isEmpty && !hasFile) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.of(context).t('يرجى كتابة إجابة أو رفع ملف الحل.'))),
      );
      return;
    }

    if (hasFile) {
      final validationError = AssignmentFileHelper.validate(
        path: _selectedFile!.path,
        name: _selectedFile!.name,
        size: _selectedFile!.size,
      );
      if (validationError != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppStrings.of(context).t(validationError))));
        return;
      }
    }

    final submission = await ref
        .read(assignmentSubmitControllerProvider(widget.assignmentId).notifier)
        .submit(
          assignmentId: widget.assignmentId,
          answerText: answerText.isEmpty ? null : answerText,
          filePath: hasFile ? _selectedFile!.path : null,
          fileName: hasFile ? _selectedFile!.name : null,
        );

    if (!mounted || submission == null) {
      return;
    }

    final cached = ref
        .read(assignmentsListControllerProvider.notifier)
        .findById(widget.assignmentId);

    if (cached != null) {
      ref
          .read(assignmentsListControllerProvider.notifier)
          .upsertAssignment(cached.copyWith(submission: submission));
    }

    ref
        .read(assignmentDetailsControllerProvider(widget.assignmentId).notifier)
        .setAssignment(
          (cached ??
                  AssignmentModel(
                    id: widget.assignmentId,
                    subjectId: 0,
                    title: '',
                  ))
              .copyWith(submission: submission),
        );

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(AppStrings.of(context).t('تم تسليم الواجب بنجاح'))));

    context.pop();
  }

  void _handleUnauthorized(String? message) {
    if (message != null && message.contains('انتهت الجلسة') && mounted) {
      ref.read(authControllerProvider.notifier).logout();
      context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final submitState = ref.watch(
      assignmentSubmitControllerProvider(widget.assignmentId),
    );
    final detailsState = ref.watch(
      assignmentDetailsControllerProvider(widget.assignmentId),
    );
    final assignment = detailsState.assignment;
    final isSubmitting =
        submitState.status == AssignmentSubmitStatus.submitting;

    ref.listen(assignmentSubmitControllerProvider(widget.assignmentId), (
      previous,
      next,
    ) {
      _handleUnauthorized(next.errorMessage);
      if (next.status == AssignmentSubmitStatus.error &&
          next.errorMessage != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppStrings.of(context).t(next.errorMessage!))));
      }
    });

    Widget content;
    if (detailsState.status == FeatureLoadStatus.loading ||
        detailsState.status == FeatureLoadStatus.initial) {
      content = const AssignmentsLoadingSkeleton(count: 2);
    } else if (assignment == null) {
      content = AssignmentsErrorState(
        message: AppStrings.of(context).t('تعذر تحميل معلومات الواجب'),
        onRetry: () {
          final cached = ref
              .read(assignmentsListControllerProvider.notifier)
              .findById(widget.assignmentId);
          ref
              .read(
                assignmentDetailsControllerProvider(
                  widget.assignmentId,
                ).notifier,
              )
              .load(widget.assignmentId, cached: cached);
        },
      );
    } else {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AssignmentSubmitInfoCard(assignment: assignment),
          if (assignment.hasAttachment) ...[
            const SizedBox(height: 16),
            AssignmentDownloadFileCard(
              title: AppStrings.of(context).t('ملف الواجب من المدرس'),
              fileUrl: assignment.resolvedAttachmentUrl!,
              fileName: assignment.originalFileName,
              fileSize: assignment.fileSize,
              mimeType: assignment.fileMimeType,
              icon: Icons.download_outlined,
            ),
          ],
          const SizedBox(height: 16),
          AssignmentSectionCard(
            title: AppStrings.of(context).t('نص الإجابة'),
            icon: Icons.edit_outlined,
            child: TextFormField(
              controller: _answerController,
              maxLines: 8,
              maxLength: 2000,
              decoration: InputDecoration(
                hintText: AppStrings.of(context).t('اكتب إجابتك هنا...'),
                filled: true,
                fillColor: AppColors.of(
                  context,
                ).cardWhite.withValues(alpha: 0.7),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide(
                    color: AppColors.of(context).darkGold,
                    width: 1.4,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          AssignmentFilePickerCard(
            selectedFile: _selectedFile,
            onPickFile: _pickFile,
            onRemoveFile: () => setState(() => _selectedFile = null),
          ),
          const SizedBox(height: 24),
          AssignmentActionButton(
            label: isSubmitting ? 'جارٍ الإرسال...' : 'إرسال الواجب',
            icon: Icons.send_rounded,
            isLoading: isSubmitting,
            onPressed: isSubmitting ? null : _submit,
          ),
        ],
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: LuxuryAssignmentHeader(title: AppStrings.of(context).t('تسليم الواجب')),
          ),
          ResponsiveSliverContent(
            padding: AppLayoutMetrics.of(
              context,
            ).pagePadding(top: 8, bottom: 28),
            sliver: SliverToBoxAdapter(child: content),
          ),
        ],
      ),
    );
  }
}
