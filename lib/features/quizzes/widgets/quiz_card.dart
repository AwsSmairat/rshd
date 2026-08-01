import 'package:flutter/material.dart';

import '../data/models/quiz_model.dart';
import 'liquid_glass_quiz_card.dart';

class QuizCard extends StatelessWidget {
  const QuizCard({
    super.key,
    required this.quiz,
    required this.onTap,
  });

  final QuizModel quiz;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return LiquidGlassQuizCard(
      quiz: quiz,
      onTap: onTap,
    );
  }
}
