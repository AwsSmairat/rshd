import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/liquid_glass_surface.dart';
import '../data/models/quiz_model.dart';
import 'quiz_score_helper.dart';
import 'quiz_stat_item.dart';
import '../../../core/l10n/app_strings.dart';

class QuizStatsGrid extends StatelessWidget {
  const QuizStatsGrid({
    super.key,
    this.quiz,
    this.submittedAt,
    this.questionsCount,
    this.scoreDisplay,
    this.finishTimeLabel = 'وقت الإنهاء',
    this.finishDateLabel = 'تاريخ الإنهاء',
  });

  final QuizModel? quiz;
  final String? submittedAt;
  final int? questionsCount;
  final String? scoreDisplay;
  final String finishTimeLabel;
  final String finishDateLabel;

  @override
  Widget build(BuildContext context) {
    final attemptSubmittedAt = submittedAt ?? quiz?.latestAttempt?.submittedAt;
    final count =
        questionsCount ??
        quiz?.questionsCount ??
        quiz?.latestAttempt?.questionsCount;

    final stats = [
      _StatData(
        icon: Icons.format_list_numbered_rounded,
        label: AppStrings.of(context).t('عدد الأسئلة'),
        value: count != null ? _formatQuestionsCount(context, count) : '—',
      ),
      _StatData(
        icon: scoreDisplay != null
            ? Icons.grade_outlined
            : Icons.schedule_outlined,
        label: scoreDisplay != null
            ? AppStrings.of(context).t('الدرجة')
            : AppStrings.of(context).t('مدة الاختبار'),
        value:
            scoreDisplay ??
            (quiz?.durationMinutes != null
                ? AppStrings.of(context).t('${quiz!.durationMinutes} دقيقة')
                : '—'),
      ),
      _StatData(
        icon: Icons.timer_outlined,
        label: AppStrings.of(context).t(finishTimeLabel),
        value: QuizDateHelper.formatTime(
          attemptSubmittedAt,
          locale: AppStrings.of(context).dateLocale,
        ),
      ),
      _StatData(
        icon: Icons.calendar_today_outlined,
        label: AppStrings.of(context).t(finishDateLabel),
        value: QuizDateHelper.formatDate(
          attemptSubmittedAt,
          locale: AppStrings.of(context).dateLocale,
        ),
      ),
    ];

    return LiquidGlassSurface(
      borderRadius: BorderRadius.circular(24),
      padding: EdgeInsets.zero,
      fillOpacity: 0.38,
      borderOpacity: 0.7,
      blurSigma: 16,
      tintColor: AppColors.of(context).accent,
      tintOpacity: 0.03,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildCell(
                  context,
                  stats[0],
                  showRightBorder: true,
                  showBottomBorder: true,
                ),
              ),
              Expanded(
                child: _buildCell(context, stats[1], showBottomBorder: true),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: _buildCell(context, stats[2], showRightBorder: true),
              ),
              Expanded(child: _buildCell(context, stats[3])),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCell(
    BuildContext context,
    _StatData stat, {
    bool showRightBorder = false,
    bool showBottomBorder = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          right: showRightBorder
              ? BorderSide(color: Colors.white.withValues(alpha: 0.45))
              : BorderSide.none,
          bottom: showBottomBorder
              ? BorderSide(color: Colors.white.withValues(alpha: 0.45))
              : BorderSide.none,
        ),
      ),
      child: QuizStatItem(
        icon: stat.icon,
        label: stat.label,
        value: stat.value,
      ),
    );
  }
}

class _StatData {
  const _StatData({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;
}

String _formatQuestionsCount(BuildContext context, int count) {
  if (count == 1) {
    return AppStrings.of(context).t('1 سؤال');
  }
  if (count == 2) {
    return AppStrings.of(context).t('2 سؤالان');
  }
  return AppStrings.of(context).t('$count أسئلة');
}
