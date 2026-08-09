import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

enum PasswordStrength { empty, weak, fair, strong }

class PasswordStrengthIndicator extends StatelessWidget {
  const PasswordStrengthIndicator({super.key, required this.password});

  final String password;

  static PasswordStrength evaluate(String password) {
    if (password.isEmpty) return PasswordStrength.empty;
    var score = 0;
    if (password.length >= 8) score++;
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'[0-9]').hasMatch(password)) score++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(password)) score++;
    if (score <= 1) return PasswordStrength.weak;
    if (score <= 2) return PasswordStrength.fair;
    return PasswordStrength.strong;
  }

  @override
  Widget build(BuildContext context) {
    final strength = evaluate(password);
    final (label, color, progress) = switch (strength) {
      PasswordStrength.empty => ('', AppColors.textMuted, 0.0),
      PasswordStrength.weak => ('ضعيفة', AppColors.error, 0.33),
      PasswordStrength.fair => ('متوسطة', AppColors.darkGold, 0.66),
      PasswordStrength.strong => ('قوية', AppColors.secondary, 1.0),
    };

    if (strength == PasswordStrength.empty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: AppColors.background,
            color: color,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'قوة كلمة المرور: $label',
          textAlign: TextAlign.right,
          style: TextStyle(fontSize: 12, color: color),
        ),
      ],
    );
  }
}
