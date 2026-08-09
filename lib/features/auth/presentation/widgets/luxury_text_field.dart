import 'package:flutter/material.dart';

import '../../../../core/layout/auth_layout_metrics.dart';
import '../../../../core/theme/app_colors.dart';

class LuxuryTextField extends StatelessWidget {
  const LuxuryTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hintText,
    this.keyboardType,
    this.obscureText = false,
    this.textInputAction,
    this.validator,
    this.errorText,
    this.icon,
    this.trailing,
  });

  final TextEditingController controller;
  final String label;
  final String? hintText;
  final TextInputType? keyboardType;
  final bool obscureText;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final String? errorText;

  /// Leading icon at the start of the field (right side in RTL).
  final IconData? icon;

  /// Optional trailing widget (left side in RTL), e.g. password visibility toggle.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final metrics = AuthLayoutMetrics.of(context);
    final labelSize = metrics.isTablet ? 14.0 : 13.0;
    final fieldSize = metrics.isTablet ? 15.0 : 14.0;
    final verticalPadding = metrics.isTablet ? 16.0 : 14.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            label,
            style: TextStyle(
              fontSize: labelSize,
              fontWeight: FontWeight.w600,
              color: AppColors.text,
            ),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          textInputAction: textInputAction,
          validator: validator,
          textAlign: TextAlign.right,
          style: TextStyle(color: AppColors.text, fontSize: fieldSize),
          decoration: InputDecoration(
            hintText: hintText,
            errorText: errorText,
            filled: true,
            fillColor: AppColors.background,
            contentPadding: EdgeInsets.symmetric(
              horizontal: metrics.isTablet ? 14 : 12,
              vertical: verticalPadding,
            ),
            hintStyle: TextStyle(
              color: AppColors.textMuted.withValues(alpha: 0.65),
              fontSize: fieldSize,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: AppColors.accent.withValues(alpha: 0.45),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.error),
            ),
            prefixIcon: icon == null ? null : _FieldIcon(icon: icon!),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 44,
              minHeight: 48,
            ),
            suffixIcon: trailing,
            suffixIconConstraints: const BoxConstraints(
              minWidth: 44,
              minHeight: 48,
            ),
          ),
        ),
      ],
    );
  }
}

class _FieldIcon extends StatelessWidget {
  const _FieldIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 12, end: 4),
      child: Icon(icon, color: AppColors.accent, size: 22),
    );
  }
}
