import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/network/api_client.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import 'password_reset_controller.dart';
import 'widgets/auth_form_parts.dart';
import 'widgets/auth_input_field.dart';
import 'widgets/auth_page_scaffold.dart';
import 'widgets/auth_primary_button.dart';
import 'widgets/password_strength_indicator.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key, required this.email});

  final String email;

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _resetToken;
  AuthButtonState _buttonState = AuthButtonState.idle;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadResetToken());
  }

  Future<void> _loadResetToken() async {
    final session = await ref
        .read(secureStorageProvider)
        .getPasswordResetSession();
    if (!mounted) {
      return;
    }
    if (session == null || session.email != widget.email.trim().toLowerCase()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppStrings.of(
              context,
            ).t('انتهت جلسة الاستعادة. يرجى البدء من جديد.'),
          ),
        ),
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

  /// Drops the button back to its resting state after a rejection.
  Future<void> _flashFailure() async {
    if (!mounted) {
      return;
    }
    setState(() => _buttonState = AuthButtonState.failure);
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (mounted) {
      setState(() => _buttonState = AuthButtonState.idle);
    }
  }

  Future<void> _submit() async {
    if (_resetToken == null ||
        _buttonState == AuthButtonState.loading ||
        _buttonState == AuthButtonState.success) {
      return;
    }

    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      await _flashFailure();
      return;
    }

    setState(() => _buttonState = AuthButtonState.loading);

    final success = await ref
        .read(passwordResetControllerProvider.notifier)
        .resetPassword(
          email: widget.email,
          resetToken: _resetToken!,
          password: _passwordController.text,
          passwordConfirmation: _confirmController.text,
        );

    if (!mounted) {
      return;
    }

    if (!success) {
      await _flashFailure();
      return;
    }

    setState(() => _buttonState = AuthButtonState.success);
    await Future<void>.delayed(const Duration(milliseconds: 620));
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppStrings.of(context).t('تم تغيير كلمة المرور بنجاح')),
      ),
    );

    context.go(
      '${AppRoutes.login}?email=${Uri.encodeComponent(widget.email.trim())}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(passwordResetControllerProvider);
    final strings = AppStrings.of(context);
    final colors = AppColors.of(context);

    // The reset token arrives one frame after mount; until then the action is
    // not safe to fire.
    final isReady = _resetToken != null;

    return AuthPageScaffold(
      title: strings.newPasswordTitle,
      subtitle: strings.newPasswordSubtitle,
      footer: TextButton(
        onPressed: () => context.go(AppRoutes.login),
        style: TextButton.styleFrom(
          foregroundColor: colors.darkGold,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        ),
        child: Text(
          strings.backToSignIn,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
      children: [
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (state.errorMessage != null) ...[
                AuthErrorBanner(message: strings.t(state.errorMessage!)),
                const SizedBox(height: 16),
              ],

              AuthInputField(
                controller: _passwordController,
                label: strings.newPasswordLabel,
                hintText: strings.t('8 أحرف على الأقل'),
                icon: Icons.lock_outline_rounded,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.newPassword],
                errorText: state.fieldErrors['password'],
                trailing: AuthVisibilityToggle(
                  obscured: _obscurePassword,
                  onToggle: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
                validator: (value) {
                  if (value == null || value.length < 8) {
                    return strings.t(
                      'يجب أن تكون كلمة المرور 8 أحرف على الأقل',
                    );
                  }
                  if (!RegExp(r'[A-Z]').hasMatch(value)) {
                    return strings.t(
                      'يجب أن تحتوي على حرف كبير واحد على الأقل',
                    );
                  }
                  if (!RegExp(r'[0-9]').hasMatch(value)) {
                    return strings.t('يجب أن تحتوي على رقم واحد على الأقل');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              PasswordStrengthIndicator(password: _passwordController.text),
              const SizedBox(height: 14),

              AuthInputField(
                controller: _confirmController,
                label: strings.confirmPasswordLabel,
                hintText: strings.t('أعد إدخال كلمة المرور'),
                icon: Icons.lock_outline_rounded,
                obscureText: _obscureConfirm,
                textInputAction: TextInputAction.done,
                errorText: state.fieldErrors['password_confirmation'],
                onFieldSubmitted: (_) => _submit(),
                trailing: AuthVisibilityToggle(
                  obscured: _obscureConfirm,
                  onToggle: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                ),
                validator: (value) {
                  if (value != _passwordController.text) {
                    return strings.t('كلمتا المرور غير متطابقتين');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 26),

              AuthPrimaryButton(
                label: strings.changePasswordAction,
                variant: AuthButtonVariant.gold,
                state: _buttonState,
                onPressed: isReady ? _submit : null,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
