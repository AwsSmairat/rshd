import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/annotation_enums.dart';

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
      color: AppColors.cardWhite,
      elevation: 1,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: [
              IconButton(
                tooltip: 'رجوع',
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                color: AppColors.primary,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      fileName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.subtitle.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      totalPages > 0
                          ? 'الصفحة: $currentPage من $totalPages'
                          : 'الصفحة: $currentPage',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              _SaveStatusChip(
                status: saveStatus,
                onRetry: onRetrySave,
              ),
              IconButton(
                tooltip: 'بحث',
                onPressed: onSearch,
                icon: const Icon(Icons.search_rounded),
                color: AppColors.primary,
              ),
              IconButton(
                tooltip: 'حفظ',
                onPressed: saveStatus == PdfSaveStatus.saving ? null : onSave,
                icon: const Icon(Icons.save_rounded),
                color: AppColors.primary,
              ),
              IconButton(
                tooltip: 'المزيد',
                onPressed: onMore,
                icon: const Icon(Icons.more_vert_rounded),
                color: AppColors.primary,
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
      PdfSaveStatus.saved => ('تم الحفظ', AppColors.secondary, Icons.check_circle_outline),
      PdfSaveStatus.saving => ('جارٍ الحفظ...', AppColors.accent, Icons.sync),
      PdfSaveStatus.unsaved => ('تعديلات غير محفوظة', AppColors.darkGold, Icons.edit_note),
      PdfSaveStatus.failed => ('فشل الحفظ', AppColors.error, Icons.error_outline),
      PdfSaveStatus.offlinePending =>
        ('سيتم المزامنة', AppColors.textMuted, Icons.cloud_upload_outlined),
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
            Text(
              label,
              style: AppTextStyles.caption.copyWith(color: color, fontSize: 11),
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
            backgroundColor: AppColors.primary,
            onPressed: onToggleVisibility,
            child: const Icon(Icons.keyboard_arrow_up, color: Colors.white),
          ),
        ),
      );
    }

    final content = Material(
      color: AppColors.glassToolbar,
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
              ? _buildTabletLayout()
              : _buildPhoneLayout(),
        ),
      ),
    );

    if (isTabletLandscape) {
      return Align(alignment: Alignment.centerRight, child: content);
    }
    return content;
  }

  Widget _buildPhoneLayout() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            IconButton(
              tooltip: expanded ? 'طي الأدوات' : 'إظهار الأدوات',
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
                          label: item.$2,
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
                    label: item.$2,
                    icon: item.$3,
                    selected: currentTool == item.$1,
                    onTap: () => onToolSelected(item.$1),
                  ),
                ),
                _ToolButton(
                  label: 'تراجع',
                  icon: Icons.undo_rounded,
                  selected: false,
                  enabled: canUndo,
                  onTap: onUndo,
                ),
                _ToolButton(
                  label: 'إعادة',
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

  Widget _buildTabletLayout() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ..._primaryTools.map(
          (item) => _ToolButton(
            label: item.$2,
            icon: item.$3,
            selected: currentTool == item.$1,
            onTap: () => onToolSelected(item.$1),
          ),
        ),
        if (expanded) ...[
          const Divider(height: 16),
          ..._secondaryTools.map(
            (item) => _ToolButton(
              label: item.$2,
              icon: item.$3,
              selected: currentTool == item.$1,
              onTap: () => onToolSelected(item.$1),
            ),
          ),
          _ToolButton(
            label: 'تراجع',
            icon: Icons.undo_rounded,
            selected: false,
            enabled: canUndo,
            onTap: onUndo,
          ),
          _ToolButton(
            label: 'إعادة',
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
        ? AppColors.textMuted.withValues(alpha: 0.5)
        : selected
            ? AppColors.accent
            : AppColors.primary;
    final labelColor = !enabled
        ? AppColors.textMuted.withValues(alpha: 0.5)
        : selected
            ? AppColors.primary
            : AppColors.secondary;
    final borderColor =
        selected ? AppColors.primary : const Color(0xFFD1D5DB);
    final backgroundColor = selected
        ? AppColors.accent.withValues(alpha: 0.18)
        : AppColors.cardWhite;

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
            splashColor: AppColors.accent.withValues(alpha: 0.2),
            highlightColor: AppColors.primary.withValues(alpha: 0.08),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              constraints: const BoxConstraints(minWidth: 58, minHeight: 52),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: borderColor,
                  width: selected ? 2 : 1,
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.12),
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
                  Text(
                    label,
                    style: AppTextStyles.caption.copyWith(
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
