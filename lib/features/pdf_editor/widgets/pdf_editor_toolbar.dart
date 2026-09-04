import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/annotation_enums.dart';
import '../../../core/l10n/app_strings.dart';

class PdfEditorHeader extends StatelessWidget implements PreferredSizeWidget {
  const PdfEditorHeader({
    super.key,
    required this.fileName,
    required this.currentPage,
    required this.totalPages,
    required this.saveStatus,
    required this.onBack,
    required this.onSearch,
    required this.onMore,
    required this.onSave,
    required this.onRetrySave,
  });

  final String fileName;
  final int currentPage;
  final int totalPages;
  final PdfSaveStatus saveStatus;
  final VoidCallback onBack;
  final VoidCallback onSearch;
  final VoidCallback onMore;
  final VoidCallback onSave;
  final VoidCallback onRetrySave;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.of(context).cardWhite,
      elevation: 1,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: [
              IconButton(
                tooltip: AppStrings.of(context).t('رجوع'),
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                color: AppColors.of(context).primary,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(AppStrings.of(context).t(fileName),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.subtitleOf(context).copyWith(
                        color: AppColors.of(context).primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(AppStrings.of(context).t(totalPages > 0
                          ? 'الصفحة: $currentPage من $totalPages'
                          : 'الصفحة: $currentPage'),
                      style: AppTextStyles.captionOf(
                        context,
                      ).copyWith(color: AppColors.of(context).textMuted),
                    ),
                  ],
                ),
              ),
              _SaveStatusChip(status: saveStatus, onRetry: onRetrySave),
              IconButton(
                tooltip: AppStrings.of(context).t('بحث'),
                onPressed: onSearch,
                icon: const Icon(Icons.search_rounded),
                color: AppColors.of(context).primary,
              ),
              IconButton(
                tooltip: AppStrings.of(context).t('حفظ'),
                onPressed: saveStatus == PdfSaveStatus.saving ? null : onSave,
                icon: const Icon(Icons.save_rounded),
                color: AppColors.of(context).primary,
              ),
              IconButton(
                tooltip: AppStrings.of(context).t('المزيد'),
                onPressed: onMore,
                icon: const Icon(Icons.more_vert_rounded),
                color: AppColors.of(context).primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SaveStatusChip extends StatelessWidget {
  const _SaveStatusChip({required this.status, required this.onRetry});

  final PdfSaveStatus status;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = switch (status) {
      PdfSaveStatus.saved => (
        'تم الحفظ',
        AppColors.of(context).secondary,
        Icons.check_circle_outline,
      ),
      PdfSaveStatus.saving => (
        'جارٍ الحفظ...',
        AppColors.of(context).accent,
        Icons.sync,
      ),
      PdfSaveStatus.unsaved => (
        'تعديلات غير محفوظة',
        AppColors.of(context).darkGold,
        Icons.edit_note,
      ),
      PdfSaveStatus.failed => (
        'فشل الحفظ',
        AppColors.of(context).error,
        Icons.error_outline,
      ),
      PdfSaveStatus.offlinePending => (
        'سيتم المزامنة',
        AppColors.of(context).textMuted,
        Icons.cloud_upload_outlined,
      ),
    };

    return InkWell(
      onTap: status == PdfSaveStatus.failed ? onRetry : null,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(AppStrings.of(context).t(label),
              style: AppTextStyles.captionOf(
                context,
              ).copyWith(color: color, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class PdfEditorToolbar extends StatelessWidget {
  const PdfEditorToolbar({
    super.key,
    required this.currentTool,
    required this.canUndo,
    required this.canRedo,
    required this.visible,
    required this.expanded,
    required this.isTabletLandscape,
    required this.onToolSelected,
    required this.onUndo,
    required this.onRedo,
    required this.onToggleExpanded,
    required this.onToggleVisibility,
  });

  final PdfEditorTool currentTool;
  final bool canUndo;
  final bool canRedo;
  final bool visible;
  final bool expanded;
  final bool isTabletLandscape;
  final ValueChanged<PdfEditorTool> onToolSelected;
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final VoidCallback onToggleExpanded;
  final VoidCallback onToggleVisibility;

  static const _primaryTools = [
    (PdfEditorTool.view, 'عرض', Icons.pan_tool_alt_outlined),
    (PdfEditorTool.pen, 'قلم', Icons.draw_outlined),
    (PdfEditorTool.highlighter, 'تظليل', Icons.highlight_outlined),
    (PdfEditorTool.eraser, 'ممحاة', Icons.auto_fix_off_outlined),
    (PdfEditorTool.lasso, 'تحديد', Icons.crop_free_outlined),
  ];

  static const _secondaryTools = [
    (PdfEditorTool.text, 'نص', Icons.text_fields_outlined),
    (PdfEditorTool.note, 'ملاحظة', Icons.sticky_note_2_outlined),
    (PdfEditorTool.shapes, 'أشكال', Icons.category_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    if (!visible) {
      return Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: FloatingActionButton.small(
            heroTag: 'show_toolbar',
            backgroundColor: AppColors.of(context).primary,
            onPressed: onToggleVisibility,
            child: const Icon(Icons.keyboard_arrow_up, color: Colors.white),
          ),
        ),
      );
    }

    final content = Material(
      color: AppColors.of(context).glassToolbar,
      elevation: 8,
      borderRadius: isTabletLandscape
          ? const BorderRadius.horizontal(left: Radius.circular(16))
          : const BorderRadius.vertical(top: Radius.circular(16)),
      child: SafeArea(
        top: false,
        left: !isTabletLandscape,
        right: true,
        bottom: !isTabletLandscape,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: isTabletLandscape
              ? _buildTabletLayout(context)
              : _buildPhoneLayout(context),
        ),
      ),
    );

    if (isTabletLandscape) {
      return Align(alignment: Alignment.centerRight, child: content);
    }
    return content;
  }

  Widget _buildPhoneLayout(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            IconButton(
              tooltip: expanded
                  ? AppStrings.of(context).t('طي الأدوات')
                  : AppStrings.of(context).t('إظهار الأدوات'),
              onPressed: onToggleExpanded,
              icon: Icon(
                expanded
                    ? Icons.keyboard_arrow_down
                    : Icons.keyboard_arrow_down,
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  children: _primaryTools
                      .map(
                        (item) => _ToolButton(
                          label: AppStrings.of(context).t(item.$2),
                          icon: item.$3,
                          selected: currentTool == item.$1,
                          onTap: () => onToolSelected(item.$1),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          ],
        ),
        if (expanded)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
            child: Row(
              children: [
                ..._secondaryTools.map(
                  (item) => _ToolButton(
                    label: AppStrings.of(context).t(item.$2),
                    icon: item.$3,
                    selected: currentTool == item.$1,
                    onTap: () => onToolSelected(item.$1),
                  ),
                ),
                _ToolButton(
                  label: AppStrings.of(context).t('تراجع'),
                  icon: Icons.undo_rounded,
                  selected: false,
                  enabled: canUndo,
                  onTap: onUndo,
                ),
                _ToolButton(
                  label: AppStrings.of(context).t('إعادة'),
                  icon: Icons.redo_rounded,
                  selected: false,
                  enabled: canRedo,
                  onTap: onRedo,
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ..._primaryTools.map(
          (item) => _ToolButton(
            label: AppStrings.of(context).t(item.$2),
            icon: item.$3,
            selected: currentTool == item.$1,
            onTap: () => onToolSelected(item.$1),
          ),
        ),
        if (expanded) ...[
          const Divider(height: 16),
          ..._secondaryTools.map(
            (item) => _ToolButton(
              label: AppStrings.of(context).t(item.$2),
              icon: item.$3,
              selected: currentTool == item.$1,
              onTap: () => onToolSelected(item.$1),
            ),
          ),
          _ToolButton(
            label: AppStrings.of(context).t('تراجع'),
            icon: Icons.undo_rounded,
            selected: false,
            enabled: canUndo,
            onTap: onUndo,
          ),
          _ToolButton(
            label: AppStrings.of(context).t('إعادة'),
            icon: Icons.redo_rounded,
            selected: false,
            enabled: canRedo,
            onTap: onRedo,
          ),
        ],
        IconButton(
          onPressed: onToggleExpanded,
          icon: Icon(
            expanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
          ),
        ),
      ],
    );
  }
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.enabled = true,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final iconColor = !enabled
        ? AppColors.of(context).textMuted.withValues(alpha: 0.5)
        : selected
        ? AppColors.of(context).accent
        : AppColors.of(context).primary;
    final labelColor = !enabled
        ? AppColors.of(context).textMuted.withValues(alpha: 0.5)
        : selected
        ? AppColors.of(context).primary
        : AppColors.of(context).secondary;
    final borderColor = selected
        ? AppColors.of(context).primary
        : const Color(0xFFD1D5DB);
    final backgroundColor = selected
        ? AppColors.of(context).accent.withValues(alpha: 0.18)
        : AppColors.of(context).cardWhite;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Semantics(
        button: true,
        label: label,
        selected: selected,
        enabled: enabled,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled ? onTap : null,
            borderRadius: BorderRadius.circular(12),
            splashColor: AppColors.of(context).accent.withValues(alpha: 0.2),
            highlightColor: AppColors.of(
              context,
            ).primary.withValues(alpha: 0.08),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              constraints: const BoxConstraints(minWidth: 58, minHeight: 52),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor, width: selected ? 2 : 1),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: AppColors.of(
                            context,
                          ).primary.withValues(alpha: 0.12),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 22, color: iconColor),
                  const SizedBox(height: 4),
                  Text(AppStrings.of(context).t(label),
                    style: AppTextStyles.captionOf(context).copyWith(
                      fontSize: 10,
                      color: labelColor,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
