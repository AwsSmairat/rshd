import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/layout/auth_layout_metrics.dart';
import '../../../core/network/api_client.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import 'password_reset_controller.dart';
import 'widgets/auth_screen_shell.dart';
import 'widgets/gold_gradient_button.dart';
import 'widgets/login_header.dart';
import 'widgets/luxury_login_card.dart';
import 'widgets/luxury_text_field.dart';
import 'widgets/password_strength_indicator.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({
    super.key,
    required this.email,
  });

  final String email;

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _resetToken;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadResetToken());
  }

  Future<void> _loadResetToken() async {
    final session =
        await ref.read(secureStorageProvider).getPasswordResetSession();
    if (!mounted) return;
    if (session == null || session.email != widget.email.trim().toLowerCase()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('انتهت جلسة الاستعادة. يرجى البدء من جديد.')),
      );
      context.go(AppRoutes.forgotPassword);
      return;
    }
    setState(() => _resetToken = session.resetToken);
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_resetToken == null || !_formKey.currentState!.validate()) return;

    final success = await ref.read(passwordResetControllerProvider.notifier).resetPassword(
          email: widget.email,
          resetToken: _resetToken!,
          password: _passwordController.text,
          passwordConfirmation: _confirmController.text,
        );

    if (!mounted || !success) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم تغيير كلمة المرور بنجاح')),
    );

    context.go('${AppRoutes.login}?email=${Uri.encodeComponent(widget.email.trim())}');
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
                    tooltip: 'رجوع',
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  'كلمة مرور جديدة',
                  style: AppTextStyles.title.copyWith(color: AppColors.primary),
                  textAlign: TextAlign.right,
                ),
                SizedBox(height: metrics.fieldSpacing * 0.5),
                Text(
                  'اختر كلمة مرور قوية لحسابك (8 أحرف على الأقل، حرف كبير، ورقم).',
                  style: AppTextStyles.body.copyWith(color: AppColors.textMuted),
                  textAlign: TextAlign.right,
                ),
                SizedBox(height: metrics.sectionSpacing),
                LuxuryTextField(
                  controller: _passwordController,
                  label: 'كلمة المرور الجديدة',
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.next,
                  errorText: state.fieldErrors['password'],
                  trailing: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  validator: (value) {
                    if (value == null || value.length < 8) {
                      return 'يجب أن تكون كلمة المرور 8 أحرف على الأقل';
                    }
                    if (!RegExp(r'[A-Z]').hasMatch(value)) {
                      return 'يجب أن تحتوي على حرف كبير واحد على الأقل';
                    }
                    if (!RegExp(r'[0-9]').hasMatch(value)) {
                      return 'يجب أن تحتوي على رقم واحد على الأقل';
                    }
                    return null;
                  },
                ),
                SizedBox(height: metrics.fieldSpacing),
                PasswordStrengthIndicator(password: _passwordController.text),
                SizedBox(height: metrics.fieldSpacing),
                LuxuryTextField(
                  controller: _confirmController,
                  label: 'تأكيد كلمة المرور',
                  obscureText: _obscureConfirm,
                  textInputAction: TextInputAction.done,
                  errorText: state.fieldErrors['password_confirmation'],
                  trailing: IconButton(
                    icon: Icon(
                      _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                  validator: (value) {
                    if (value != _passwordController.text) {
                      return 'كلمتا المرور غير متطابقتين';
                    }
                    return null;
                  },
                ),
                if (state.errorMessage != null) ...[
                  SizedBox(height: metrics.fieldSpacing),
                  Text(
                    state.errorMessage!,
                    style: AppTextStyles.error,
                    textAlign: TextAlign.right,
                  ),
                ],
                SizedBox(height: metrics.sectionSpacing),
                GoldGradientButton(
                  label: 'تغيير كلمة المرور',
                  isLoading: state.isLoading || _resetToken == null,
                  onPressed: state.isLoading || _resetToken == null ? null : _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
