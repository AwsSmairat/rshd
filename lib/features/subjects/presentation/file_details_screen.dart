import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/models/lesson_file_model.dart';
import 'subjects_controller.dart';

class FileDetailsScreen extends ConsumerStatefulWidget {
  const FileDetailsScreen({
    super.key,
    required this.fileId,
  });

  final int fileId;

  @override
  ConsumerState<FileDetailsScreen> createState() => _FileDetailsScreenState();
}

class _FileDetailsScreenState extends ConsumerState<FileDetailsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(fileDetailsControllerProvider(widget.fileId).notifier)
          .load(widget.fileId);
    });
  }

  void _handleUnauthorized(String? message) {
    if (message != null && message.contains('انتهت الجلسة') && mounted) {
      ref.read(authControllerProvider.notifier).logout();
      context.go(AppRoutes.login);
    }
  }

  void _openPdfViewer(LessonFileModel file) {
    context.push(
      AppRoutes.filePdfViewer(file.id),
      extra: {
        'title': file.title,
        'fileUrl': file.fileUrl ?? '',
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(fileDetailsControllerProvider(widget.fileId));

    ref.listen(fileDetailsControllerProvider(widget.fileId), (prev, next) {
      _handleUnauthorized(next.errorMessage);
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(state.file?.title ?? 'تفاصيل الملف'),
      ),
      body: _buildBody(state),
    );
  }

  Widget _buildBody(FileDetailsState state) {
    switch (state.status) {
      case FeatureLoadStatus.initial:
      case FeatureLoadStatus.loading:
        return const LoadingWidget(message: 'جاري تحميل الملف...');
      case FeatureLoadStatus.error:
        return ErrorView(
          message: state.errorMessage ?? 'تعذر تحميل الملف',
          onRetry: () => ref
              .read(fileDetailsControllerProvider(widget.fileId).notifier)
              .load(widget.fileId),
        );
      case FeatureLoadStatus.empty:
      case FeatureLoadStatus.loaded:
        final file = state.file;
        if (file == null) {
          return const ErrorView(message: 'الملف غير موجود');
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                children: [
                  Icon(
                    file.fileIcon,
                    size: 56,
                    color: AppColors.secondary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    file.title,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.title,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _InfoRow(label: 'نوع الملف', value: file.fileTypeLabel),
            _InfoRow(label: 'الحجم', value: file.formattedSize),
            const SizedBox(height: 16),
            _buildActionSection(file),
          ],
        );
    }
  }

  Widget _buildActionSection(LessonFileModel file) {
    final fileUrl = file.fileUrl?.trim() ?? '';

    if (file.fileType == 'pdf' && fileUrl.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _openPdfViewer(file),
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: const Text('عرض داخل التطبيق'),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'الملفات متاحة للعرض داخل التطبيق فقط ولا يمكن تنزيلها أو حفظها.',
            style: AppTextStyles.body.copyWith(
              color: AppColors.textMuted,
              fontSize: 12,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Text(
        fileUrl.isEmpty
            ? 'رابط الملف غير متوفر حالياً'
            : 'هذا النوع من الملفات غير متاح للعرض حالياً، ولا يمكن تنزيله أو حفظه من التطبيق.',
        style: AppTextStyles.body.copyWith(
          color: AppColors.textMuted,
          height: 1.5,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: AppTextStyles.body.copyWith(
              color: AppColors.textMuted,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.body,
            ),
          ),
        ],
      ),
    );
  }
}
