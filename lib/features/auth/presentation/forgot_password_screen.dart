import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/layout/auth_layout_metrics.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import 'password_reset_controller.dart';
import 'widgets/auth_screen_shell.dart';
import 'widgets/gold_gradient_button.dart';
import 'widgets/login_header.dart';
import 'widgets/luxury_login_card.dart';
import 'widgets/luxury_text_field.dart';
import '../../../core/l10n/app_strings.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key, this.initialEmail});

  final String? initialEmail;

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(
      text: widget.initialEmail?.trim() ?? '',
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref
        .read(passwordResetControllerProvider.notifier)
        .requestReset(_emailController.text);

    if (!mounted || !success) return;

    context.push(
      '${AppRoutes.passwordResetVerify}?email=${Uri.encodeComponent(_emailController.text.trim())}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(passwordResetControllerProvider);
    final metrics = AuthLayoutMetrics.of(context);

    return Scaffold(
      body: AuthScreenShell(
        header: const LoginHeader(),
        body: LuxuryLoginCard(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: IconButton(
                    tooltip: AppStrings.of(context).t('رجوع'),
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    color: AppColors.of(context).primary,
                  ),
                ),
                Text(AppStrings.of(context).t('نسيت كلمة المرور؟'),
                  style: AppTextStyles.titleOf(
                    context,
                  ).copyWith(color: AppColors.of(context).primary),
                  textAlign: TextAlign.right,
                ),
                SizedBox(height: metrics.fieldSpacing * 0.5),
                Text(AppStrings.of(context).t('أدخل بريدك الإلكتروني وسنساعدك في استعادة الوصول إلى حسابك.'),
                  style: AppTextStyles.bodyOf(
                    context,
                  ).copyWith(color: AppColors.of(context).textMuted),
                  textAlign: TextAlign.right,
                ),
                SizedBox(height: metrics.sectionSpacing),
                LuxuryTextField(
                  controller: _emailController,
                  label: AppStrings.of(context).t('البريد الإلكتروني'),
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  errorText: state.fieldErrors['email'],
                  validator: (value) {
                    final trimmed = value?.trim() ?? '';
                    if (trimmed.isEmpty) return AppStrings.of(context).t('البريد الإلكتروني مطلوب');
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(trimmed)) {
                      return AppStrings.of(context).t('صيغة البريد غير صحيحة');
                    }
                    return null;
                  },
                ),
                if (state.errorMessage != null) ...[
                  SizedBox(height: metrics.fieldSpacing),
                  Text(AppStrings.of(context).t(state.errorMessage!),
                    style: AppTextStyles.errorOf(context),
                    textAlign: TextAlign.right,
                  ),
                ],
                SizedBox(height: metrics.sectionSpacing),
                GoldGradientButton(
                  label: AppStrings.of(context).t('إرسال رمز الاستعادة'),
                  isLoading: state.isLoading,
                  onPressed: state.isLoading ? null : _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
