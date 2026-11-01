import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../auth_controller.dart';
import 'auth_form_parts.dart';
import 'auth_input_field.dart';
import 'auth_primary_button.dart';

/// Sign-in half of the unified auth screen.
///
/// Owns its own [GlobalKey]<[FormState]> and controllers so validation state
/// never bleeds into the register form. The network call, the remembered-email
/// handling and the post-login routing are unchanged from the original
/// standalone login screen.
class SignInForm extends ConsumerStatefulWidget {
  const SignInForm({
    super.key,
    this.initialEmail,
    required this.showErrors,
    required this.onSubmitStarted,
  });

  final String? initialEmail;

  /// False while the visible errors belong to the other tab.
  final bool showErrors;

  /// Lets the parent record which tab owns the controller's error state.
  final VoidCallback onSubmitStarted;

  @override
  ConsumerState<SignInForm> createState() => _SignInFormState();
}

class _SignInFormState extends ConsumerState<SignInForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordFocus = FocusNode();
  bool _obscurePassword = true;
  bool _rememberMe = false;
  AuthButtonState _buttonState = AuthButtonState.idle;

  @override
  void initState() {
    super.initState();

    final initialEmail = widget.initialEmail?.trim();
    if (initialEmail != null && initialEmail.isNotEmpty) {
      _emailController.text = initialEmail;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRememberedCredentials();
    });
  }

  Future<void> _loadRememberedCredentials() async {
    if (widget.initialEmail != null && widget.initialEmail!.trim().isNotEmpty) {
      return;
    }

    final storage = ref.read(secureStorageProvider);
    final email = await storage.getRememberedEmail();
    if (!mounted || email == null) {
      return;
    }

    setState(() {
      _rememberMe = true;
      _emailController.text = email;
    });
  }

  Future<void> _persistRememberMePreference() async {
    final storage = ref.read(secureStorageProvider);
    await storage.saveRememberMe(
      enabled: _rememberMe,
      email: _emailController.text.trim(),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordFocus.dispose();
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

    widget.onSubmitStarted();
    setState(() => _buttonState = AuthButtonState.loading);

    final result = await ref
        .read(authControllerProvider.notifier)
        .login(
          email: _emailController.text,
          password: _passwordController.text,
        );

    if (!mounted) {
      return;
    }

    switch (result) {
      case LoginFlowResult.success:
        await _persistRememberMePreference();
        if (!mounted) {
          return;
        }
        setState(() => _buttonState = AuthButtonState.success);
        // Let the arrow finish its run before the route changes.
        await Future<void>.delayed(const Duration(milliseconds: 620));
        if (!mounted) {
          return;
        }
        context.go(AppRoutes.home);
      case LoginFlowResult.requiresEmailVerification:
        final email =
            ref.read(authControllerProvider).pendingVerificationEmail ??
            _emailController.text.trim();
        setState(() => _buttonState = AuthButtonState.success);
        await Future<void>.delayed(const Duration(milliseconds: 620));
        if (!mounted) {
          return;
        }
        context.go(
          '${AppRoutes.verifyEmail}?email=${Uri.encodeComponent(email)}',
        );
      case LoginFlowResult.failed:
        await _flashFailure();
    }
  }

  void _openForgotPassword() {
    final email = _emailController.text.trim();
    if (email.isNotEmpty) {
      context.push(
        '${AppRoutes.forgotPassword}?email=${Uri.encodeComponent(email)}',
      );
      return;
    }
    context.push(AppRoutes.forgotPassword);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final strings = AppStrings.of(context);
    final fieldErrors = widget.showErrors
        ? authState.fieldErrors
        : const <String, String>{};
    final bannerMessage = widget.showErrors ? authState.errorMessage : null;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (bannerMessage != null) ...[
            AuthErrorBanner(message: strings.t(bannerMessage)),
            const SizedBox(height: 16),
          ],

          AuthInputField(
            controller: _emailController,
            label: strings.emailFieldLabel,
            hintText: strings.emailFieldHint,
            icon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
            errorText: fieldErrors['email'],
            onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return strings.t('البريد الإلكتروني مطلوب');
              }
              if (!value.contains('@')) {
                return strings.t('أدخل بريداً إلكترونياً صالحاً');
              }
              return null;
            },
          ),
          const SizedBox(height: 14),

          AuthInputField(
            controller: _passwordController,
            focusNode: _passwordFocus,
            label: strings.passwordFieldLabel,
            hintText: strings.passwordFieldHint,
            icon: Icons.lock_outline_rounded,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.password],
            errorText: fieldErrors['password'],
            onFieldSubmitted: (_) => _submit(),
            trailing: AuthVisibilityToggle(
              obscured: _obscurePassword,
              onToggle: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return strings.t('كلمة المرور مطلوبة');
              }
              return null;
            },
          ),
          const SizedBox(height: 10),

          _RememberAndForgotRow(
            rememberMe: _rememberMe,
            onRememberMeChanged: (value) => setState(() => _rememberMe = value),
            onForgotPassword: _openForgotPassword,
          ),
          const SizedBox(height: 20),

          AuthPrimaryButton(
            label: strings.t('تسجيل الدخول'),
            state: _buttonState,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}

class _RememberAndForgotRow extends StatelessWidget {
  const _RememberAndForgotRow({
    required this.rememberMe,
    required this.onRememberMeChanged,
    required this.onForgotPassword,
  });

  final bool rememberMe;
  final ValueChanged<bool> onRememberMeChanged;
  final VoidCallback onForgotPassword;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final strings = AppStrings.of(context);

    return Row(
      // Both ends flex so a long "forgot password" label cannot push the row
      // past the panel on narrow phones.
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: InkWell(
            onTap: () => onRememberMeChanged(!rememberMe),
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 22,
                    width: 22,
                    child: Checkbox(
                      value: rememberMe,
                      onChanged: (value) => onRememberMeChanged(value ?? false),
                      activeColor: colors.accent,
                      checkColor: colors.primary,
                      side: BorderSide(
                        color: colors.textMuted.withValues(alpha: 0.45),
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      strings.t('تذكرني'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: colors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: TextButton(
            onPressed: onForgotPassword,
            style: TextButton.styleFrom(
              foregroundColor: colors.darkGold,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              strings.t('نسيت كلمة المرور؟'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
