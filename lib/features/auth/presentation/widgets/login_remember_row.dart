import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/l10n/app_strings.dart';

class LoginRememberRow extends StatelessWidget {
  const LoginRememberRow({
    super.key,
    required this.rememberMe,
    required this.onRememberMeChanged,
    required this.onForgotPassword,
    this.isTablet = false,
  });

  final bool rememberMe;
  final ValueChanged<bool> onRememberMeChanged;
  final VoidCallback onForgotPassword;
  final bool isTablet;

  @override
  Widget build(BuildContext context) {
    final fontSize = isTablet ? 14.0 : 13.0;

    return Row(
      children: [
        Expanded(
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton(
              onPressed: onForgotPassword,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.of(context).secondary,
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(AppStrings.of(context).t('نسيت كلمة المرور؟'),
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
        InkWell(
          onTap: () => onRememberMeChanged(!rememberMe),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsetsDirectional.only(start: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(AppStrings.of(context).t('تذكرني'),
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w600,
                    color: AppColors.of(context).textMuted,
                  ),
                ),
                SizedBox(
                  height: 24,
                  width: 24,
                  child: Checkbox(
                    value: rememberMe,
                    onChanged: (value) => onRememberMeChanged(value ?? false),
                    activeColor: AppColors.of(context).secondary,
                    checkColor: AppColors.of(context).white,
                    side: BorderSide(
                      color: AppColors.of(
                        context,
                      ).textMuted.withValues(alpha: 0.5),
                    ),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
