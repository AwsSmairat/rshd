import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/liquid_glass_surface.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/widgets/responsive_content.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/models/lesson_file_model.dart';
import 'subjects_controller.dart';

class FileDetailsScreen extends ConsumerStatefulWidget {
  const FileDetailsScreen({super.key, required this.fileId});

  final int fileId;

  @override
  ConsumerState<FileDetailsScreen> createState() => _FileDetailsScreenState();
}

class _FileDetailsScreenState extends ConsumerState<FileDetailsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _reloadFile();
    });
  }

  Future<void> _reloadFile() {
    return ref
        .read(fileDetailsControllerProvider(widget.fileId).notifier)
        .load(widget.fileId);
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
      extra: {'title': file.title},
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(fileDetailsControllerProvider(widget.fileId));

    ref.listen(fileDetailsControllerProvider(widget.fileId), (prev, next) {
      _handleUnauthorized(next.errorMessage);
    });

    return Scaffold(
      backgroundColor: AppColors.background,
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
          onRetry: _reloadFile,
        );
      case FeatureLoadStatus.empty:
      case FeatureLoadStatus.loaded:
        final file = state.file;
        if (file == null) {
          return const ErrorView(message: 'الملف غير موجود');
        }

        return RefreshIndicator(
          color: AppColors.accent,
          backgroundColor: AppColors.cardWhite,
          onRefresh: _reloadFile,
          edgeOffset: MediaQuery.paddingOf(context).top + kToolbarHeight,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              _FileDetailsHero(title: file.title),
              SliverToBoxAdapter(
                child: ResponsiveContent(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _FilePreviewCard(file: file),
                      const SizedBox(height: 18),
                      _FileMetaSection(file: file),
                      const SizedBox(height: 20),
                      _buildActionSection(file),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
    }
  }

  Widget _buildActionSection(LessonFileModel file) {
    if (file.isLocked) {
      return _FileStatusCard(
        icon: Icons.lock_outline_rounded,
        title: 'ملف مقفل',
        message: 'فعّل المادة لفتح هذا الملف والاطلاع عليه.',
        tone: _FileStatusTone.locked,
      );
    }

    if (file.fileType == 'pdf' && file.canOpen) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PrimaryActionButton(
            onPressed: () => _openPdfViewer(file),
            icon: Icons.auto_stories_outlined,
            label: 'عرض داخل التطبيق',
          ),
          const SizedBox(height: 12),
          _InfoNote(
            icon: Icons.visibility_outlined,
            text:
                'الملفات متاحة للعرض داخل التطبيق فقط ولا يمكن تنزيلها أو حفظها.',
          ),
        ],
      );
    }

    if (file.fileType == 'pdf' && !file.isLocked) {
      return _FileStatusCard(
        icon: Icons.hourglass_top_rounded,
        title: 'جاري تجهيز الملف',
        message:
            'الملف قيد المعالجة حالياً. اسحب للأسفل للتحديث أو حاول بعد لحظات.',
        tone: _FileStatusTone.pending,
        onRetry: _reloadFile,
      );
    }

    final fileUrl = file.fileUrl?.trim() ?? '';

    return _FileStatusCard(
      icon: Icons.info_outline_rounded,
      title: fileUrl.isEmpty ? 'الملف غير جاهز' : 'عرض غير متاح',
      message: fileUrl.isEmpty
          ? 'تعذر الوصول للملف حالياً. تأكد من اتصالك ثم حاول التحديث.'
          : 'هذا النوع من الملفات غير متاح للعرض حالياً داخل التطبيق.',
      tone: _FileStatusTone.pending,
      onRetry: fileUrl.isEmpty ? _reloadFile : null,
    );
  }
}

class _FileDetailsHero extends StatelessWidget {
  const _FileDetailsHero({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    final barHeight = kToolbarHeight + topInset;

    return SliverAppBar(
      expandedHeight: barHeight,
      collapsedHeight: barHeight,
      toolbarHeight: kToolbarHeight,
      pinned: true,
      stretch: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.white,
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
      ),
      flexibleSpace: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerRight,
            end: Alignment.centerLeft,
            colors: [AppColors.primary, AppColors.secondaryNavy],
          ),
        ),
      ),
    );
  }
}

class _FilePreviewCard extends StatelessWidget {
  const _FilePreviewCard({required this.file});

  final LessonFileModel file;

  Color get _accentColor {
    switch (file.fileType) {
      case 'pdf':
        return const Color(0xFFC0392B);
      case 'ppt':
        return const Color(0xFFD35400);
      case 'doc':
        return const Color(0xFF2471A3);
      case 'image':
        return AppColors.secondary;
      default:
        return AppColors.darkGold;
    }
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.glassShadow.withValues(alpha: 0.12),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: LiquidGlassSurface(
          borderRadius: BorderRadius.circular(22),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          fillOpacity: 0.34,
          tintColor: _accentColor,
          tintOpacity: 0.06,
          child: Column(
            children: [
              Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [
                      _accentColor.withValues(alpha: 0.18),
                      _accentColor.withValues(alpha: 0.08),
                    ],
                  ),
                  border: Border.all(
                    color: _accentColor.withValues(alpha: 0.22),
                    width: 1.2,
                  ),
                ),
                child: Icon(file.fileIcon, size: 42, color: _accentColor),
              ),
              const SizedBox(height: 16),
              Text(
                file.title,
                textAlign: TextAlign.center,
                style: AppTextStyles.title.copyWith(fontSize: 20, height: 1.35),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  file.fileTypeLabel,
                  style: AppTextStyles.caption.copyWith(
                    color: _accentColor,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FileMetaSection extends StatelessWidget {
  const _FileMetaSection({required this.file});

  final LessonFileModel file;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MetaChip(
            icon: Icons.insert_drive_file_outlined,
            label: 'النوع',
            value: file.fileTypeLabel,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MetaChip(
            icon: Icons.sd_storage_outlined,
            label: 'الحجم',
            value: file.formattedSize,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MetaChip(
            icon: file.isLocked
                ? Icons.lock_outline_rounded
                : Icons.check_circle_outline_rounded,
            label: 'الحالة',
            value: file.isLocked ? 'مقفل' : 'متاح',
            valueColor: file.isLocked
                ? AppColors.textMuted
                : AppColors.secondary,
          ),
        ),
      ],
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return LiquidGlassSurface(
      borderRadius: BorderRadius.circular(16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      fillOpacity: 0.28,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.secondary),
          const SizedBox(height: 8),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textMuted,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.body.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: valueColor ?? AppColors.text,
            ),
          ),
        ],
      ),
    );
  }
}

enum _FileStatusTone { pending, locked }

class _FileStatusCard extends StatelessWidget {
  const _FileStatusCard({
    required this.icon,
    required this.title,
    required this.message,
    required this.tone,
    this.onRetry,
  });

  final IconData icon;
  final String title;
  final String message;
  final _FileStatusTone tone;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final accent = tone == _FileStatusTone.locked
        ? AppColors.secondary
        : AppColors.darkGold;

    return LiquidGlassSurface(
      borderRadius: BorderRadius.circular(18),
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
      fillOpacity: 0.3,
      tintColor: accent,
      tintOpacity: 0.05,
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 26, color: accent),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: AppTextStyles.subtitle.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyles.body.copyWith(
              color: AppColors.textMuted,
              height: 1.55,
              fontSize: 13,
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('تحديث'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(
                  color: AppColors.primary.withValues(alpha: 0.18),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PrimaryActionButton extends StatelessWidget {
  const _PrimaryActionButton({
    required this.onPressed,
    required this.icon,
    required this.label,
  });

  final VoidCallback onPressed;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
          colors: [AppColors.primary, AppColors.secondaryNavy],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.22),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: AppColors.white, size: 22),
                const SizedBox(width: 10),
                Text(label, style: AppTextStyles.button.copyWith(fontSize: 15)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoNote extends StatelessWidget {
  const _InfoNote({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return LiquidGlassSurface(
      borderRadius: BorderRadius.circular(14),
      padding: const EdgeInsets.all(14),
      fillOpacity: 0.24,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.textMuted),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textMuted,
                height: 1.5,
                fontSize: 12.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
