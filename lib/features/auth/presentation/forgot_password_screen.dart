import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import 'password_reset_controller.dart';
import 'widgets/auth_form_parts.dart';
import 'widgets/auth_input_field.dart';
import 'widgets/auth_page_scaffold.dart';
import 'widgets/auth_primary_button.dart';

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
  AuthButtonState _buttonState = AuthButtonState.idle;

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

  /// Drops the button back to its resting state after a rejection.
  Future<void> _flashFailure() async {
    setState(() => _buttonState = AuthButtonState.failure);
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (mounted) {
      setState(() => _buttonState = AuthButtonState.idle);
    }
  }

  Future<void> _submit() async {
    if (_buttonState == AuthButtonState.loading ||
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
        .requestReset(_emailController.text);

    if (!mounted) {
      return;
    }

    if (!success) {
      await _flashFailure();
      return;
    }

    setState(() => _buttonState = AuthButtonState.success);
    // Let the arrow finish its run before the route changes.
    await Future<void>.delayed(const Duration(milliseconds: 620));
    if (!mounted) {
      return;
    }

    context.push(
      '${AppRoutes.passwordResetVerify}'
      '?email=${Uri.encodeComponent(_emailController.text.trim())}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(passwordResetControllerProvider);
    final strings = AppStrings.of(context);
    final colors = AppColors.of(context);

    return AuthPageScaffold(
      title: strings.t('نسيت كلمة المرور؟'),
      subtitle: strings.forgotPasswordSubtitle,
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
                controller: _emailController,
                label: strings.emailFieldLabel,
                hintText: strings.emailFieldHint,
                icon: Icons.mail_outline_rounded,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.email],
                errorText: state.fieldErrors['email'],
                onFieldSubmitted: (_) => _submit(),
                validator: (value) {
                  final trimmed = value?.trim() ?? '';
                  if (trimmed.isEmpty) {
                    return strings.t('البريد الإلكتروني مطلوب');
                  }
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(trimmed)) {
                    return strings.t('صيغة البريد غير صحيحة');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 26),

              AuthPrimaryButton(
                label: strings.sendRecoveryCode,
                variant: AuthButtonVariant.gold,
                state: _buttonState,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
