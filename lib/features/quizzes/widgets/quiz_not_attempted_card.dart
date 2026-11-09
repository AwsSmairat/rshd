import 'package:flutter/material.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/liquid_glass_surface.dart';

/// Shown before the first attempt: what to expect once the quiz starts.
class QuizNotAttemptedCard extends StatelessWidget {
  const QuizNotAttemptedCard({
    super.key,
    this.durationMinutes,
    this.allowRetake = false,
  });

  final int? durationMinutes;
  final bool allowRetake;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final colors = AppColors.of(context);
    final en = strings.isEnglish;

    final rules = <(IconData, String)>[
      if (durationMinutes != null && durationMinutes! > 0)
        (
          Icons.timer_outlined,
          en
              ? 'The timer starts as soon as you begin ($durationMinutes min).'
              : 'يبدأ المؤقت فور بدء الاختبار (مدته $durationMinutes دقيقة).',
        ),
      (
        Icons.send_rounded,
        en
            ? 'The quiz is submitted automatically when time runs out.'
            : 'يُسلَّم الاختبار تلقائياً عند انتهاء الوقت.',
      ),
      (
        Icons.swap_horiz_rounded,
        en
            ? 'Move between questions and change answers before submitting.'
            : 'تنقّل بين الأسئلة وعدّل إجاباتك قبل التسليم.',
      ),
      (
        allowRetake ? Icons.replay_rounded : Icons.lock_outline_rounded,
        allowRetake
            ? (en
                  ? 'You can retake the quiz after submitting.'
                  : 'يمكنك إعادة الاختبار بعد التسليم.')
            : (en
                  ? 'One attempt only: answers can\'t be changed after submitting.'
                  : 'محاولة واحدة فقط، ولا يمكن التعديل بعد التسليم.'),
      ),
    ];

    return LiquidGlassSurface(
      borderRadius: BorderRadius.circular(22),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      fillOpacity: 0.34,
      borderOpacity: 0.62,
      blurSigma: 16,
      tintColor: colors.accent,
      tintOpacity: 0.05,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            strings.t('قبل أن تبدأ'),
            style: AppTextStyles.subtitleOf(context).copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: colors.primary,
            ),
          ),
          const SizedBox(height: 12),
          for (final (icon, text) in rules)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: colors.accent.withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 16, color: colors.darkGold),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: Text(
                        text,
                        style: AppTextStyles.bodyOf(context).copyWith(
                          fontSize: 14,
                          height: 1.5,
                          color: colors.text,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
