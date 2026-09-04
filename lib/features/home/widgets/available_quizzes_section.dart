import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../quizzes/data/models/quiz_model.dart';
import '../../quizzes/widgets/quiz_card.dart';
import 'home_section_header.dart';

class AvailableQuizzesSection extends StatelessWidget {
  const AvailableQuizzesSection({super.key, required this.quizzes});

  final List<QuizModel> quizzes;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HomeSectionHeader(
            title: AppStrings.of(context).quizzes,
            onViewAll: () => context.push(AppRoutes.quizzes),
          ),
          const SizedBox(height: 14),
          if (quizzes.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.of(context).cardWhite,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Text(AppStrings.of(context).t(AppStrings.of(context).noQuizzesYet),
                style: AppTextStyles.bodyOf(
                  context,
                ).copyWith(color: AppColors.of(context).textMuted),
                textAlign: TextAlign.center,
              ),
            )
          else
            ...quizzes.map(
              (quiz) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: QuizCard(
                  quiz: quiz,
                  onTap: () => context.push(AppRoutes.quizDetails(quiz.id)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
