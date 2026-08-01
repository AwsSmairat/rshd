import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/liquid_glass_surface.dart';
import '../data/models/lesson_model.dart';
import 'lesson_file_card.dart';
import 'video_card.dart';

class LessonCard extends StatefulWidget {
  const LessonCard({
    super.key,
    required this.lesson,
    required this.displayOrder,
    this.initiallyExpanded = false,
  });

  final LessonModel lesson;
  final int displayOrder;
  final bool initiallyExpanded;

  @override
  State<LessonCard> createState() => _LessonCardState();
}

class _LessonCardState extends State<LessonCard>
    with SingleTickerProviderStateMixin {
  late bool _expanded;
  late final AnimationController _chevronController;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
    _chevronController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
      value: _expanded ? 1 : 0,
    );
  }

  @override
  void dispose() {
    _chevronController.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    if (_expanded) {
      _chevronController.forward();
    } else {
      _chevronController.reverse();
    }
  }

  void _openVideo(BuildContext context, int videoId, {required bool locked}) {
    if (locked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('هذا الفيديو مقفل. فعّل المادة لمشاهدته.'),
        ),
      );
      return;
    }
    context.push(AppRoutes.videoDetails(videoId));
  }

  void _openFile(BuildContext context, int fileId, {required bool locked}) {
    if (locked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الملف مقفل. فعّل المادة لفتحه.'),
        ),
      );
      return;
    }
    context.push(AppRoutes.fileDetails(fileId));
  }

  @override
  Widget build(BuildContext context) {
    final lesson = widget.lesson;
    final hasContent = lesson.videos.isNotEmpty || lesson.files.isNotEmpty;

    return LiquidGlassSurface(
      borderRadius: BorderRadius.circular(14),
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          InkWell(
            onTap: _toggle,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor:
                        AppColors.secondary.withValues(alpha: 0.15),
                    child: Text(
                      '${widget.displayOrder}',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lesson.title,
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        if (lesson.description != null &&
                            lesson.description!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            lesson.description!,
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.textMuted,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 6),
                        Text(
                          _summaryLabel(lesson),
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.secondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  RotationTransition(
                    turns: Tween<double>(begin: 0, end: 0.5)
                        .animate(_chevronController),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppColors.primary.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: _ExpandedBody(
              lesson: lesson,
              hasContent: hasContent,
              onVideoTap: _openVideo,
              onFileTap: _openFile,
            ),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 220),
            sizeCurve: Curves.easeInOut,
          ),
        ],
      ),
    );
  }

  String _summaryLabel(LessonModel lesson) {
    final parts = <String>[];
    if (lesson.videosCount > 0) {
      parts.add('${lesson.videosCount} فيديو');
    }
    if (lesson.filesCount > 0) {
      parts.add('${lesson.filesCount} ملف');
    }
    if (parts.isEmpty) {
      return lesson.isActive ? 'متاح' : lesson.status;
    }
    return parts.join(' · ');
  }
}

class _ExpandedBody extends StatelessWidget {
  const _ExpandedBody({
    required this.lesson,
    required this.hasContent,
    required this.onVideoTap,
    required this.onFileTap,
  });

  final LessonModel lesson;
  final bool hasContent;
  final void Function(BuildContext context, int videoId, {required bool locked})
      onVideoTap;
  final void Function(BuildContext context, int fileId, {required bool locked})
      onFileTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(
            height: 1,
            color: AppColors.primary.withValues(alpha: 0.08),
          ),
          const SizedBox(height: 12),
          if (!hasContent)
            Text(
              'لا يوجد محتوى في هذا الجزء بعد',
              style: AppTextStyles.body.copyWith(color: AppColors.textMuted),
            )
          else ...[
            if (lesson.videos.isNotEmpty) ...[
              Text(
                'الفيديوهات',
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 8),
              ...lesson.videos.map(
                (video) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: VideoCard(
                    video: video,
                    onTap: () => onVideoTap(
                      context,
                      video.id,
                      locked: video.isLocked,
                    ),
                  ),
                ),
              ),
            ],
            if (lesson.files.isNotEmpty) ...[
              if (lesson.videos.isNotEmpty) const SizedBox(height: 4),
              Text(
                'الملفات',
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 8),
              ...lesson.files.map(
                (file) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: LessonFileCard(
                    file: file,
                    onTap: () => onFileTap(
                      context,
                      file.id,
                      locked: file.isLocked,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
