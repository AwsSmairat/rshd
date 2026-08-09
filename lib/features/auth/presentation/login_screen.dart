import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/layout/auth_layout_metrics.dart';
import '../../../core/network/api_client.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import 'auth_controller.dart';
import 'widgets/auth_screen_shell.dart';
import 'widgets/gold_gradient_button.dart';
import 'widgets/login_header.dart';
import 'widgets/luxury_login_card.dart';
import 'widgets/login_remember_row.dart';
import 'widgets/luxury_text_field.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key, this.initialEmail});

  final String? initialEmail;

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;

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
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

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
        context.go(AppRoutes.home);
      case LoginFlowResult.requiresEmailVerification:
        final email =
            ref.read(authControllerProvider).pendingVerificationEmail ??
            _emailController.text.trim();
        context.go(
          '${AppRoutes.verifyEmail}?email=${Uri.encodeComponent(email)}',
        );
      case LoginFlowResult.failed:
        break;
      case LoginFlowResult.cancelled:
        break;
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
    final fieldErrors = authState.fieldErrors;
    final metrics = AuthLayoutMetrics.of(context);

    return Scaffold(
      body: AuthScreenShell(
        header: const LoginHeader(),
        footer: const LoginFooter(),
        body: LuxuryLoginCard(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const LoginCardTitle(),
                SizedBox(height: metrics.sectionSpacing),
                if (authState.errorMessage != null) ...[
                  Container(
                    padding: EdgeInsets.all(metrics.isTablet ? 14 : 12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Text(
                      authState.errorMessage!,
                      style: AppTextStyles.error.copyWith(
                        fontSize: metrics.isTablet ? 14 : null,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(height: metrics.fieldSpacing),
                ],
                LuxuryTextField(
                  controller: _emailController,
                  label: 'البريد الإلكتروني',
                  hintText: 'example@domain.com',
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  icon: Icons.mail_outline,
                  errorText: fieldErrors['email'],
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'البريد الإلكتروني مطلوب';
                    }
                    if (!value.contains('@')) {
                      return 'أدخل بريداً إلكترونياً صالحاً';
                    }
                    return null;
                  },
                ),
                SizedBox(height: metrics.fieldSpacing),
                LuxuryTextField(
                  controller: _passwordController,
                  label: 'كلمة المرور',
                  hintText: '••••••••',
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  icon: Icons.lock_outline,
                  trailing: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: AppColors.accent,
                      size: metrics.isTablet ? 22 : 20,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  errorText: fieldErrors['password'],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'كلمة المرور مطلوبة';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                LoginRememberRow(
                  rememberMe: _rememberMe,
                  onRememberMeChanged: (value) {
                    setState(() {
                      _rememberMe = value;
                    });
                  },
                  onForgotPassword: _openForgotPassword,
                  isTablet: metrics.isTablet,
                ),
                SizedBox(height: metrics.isTablet ? 22 : 18),
                GoldGradientButton(
                  label: 'دخول',
                  icon: Icons.arrow_back,
                  isLoading: authState.status == AuthStatus.loading,
                  onPressed: _submit,
                ),
                SizedBox(height: metrics.fieldSpacing),
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'ليس لديك حساب؟ ',
                      style: TextStyle(
                        fontSize: metrics.isTablet ? 14 : 13,
                        color: AppColors.textMuted.withValues(alpha: 0.9),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.push(AppRoutes.register),
                      child: Text(
                        'إنشاء حساب جديد',
                        style: TextStyle(
                          fontSize: metrics.isTablet ? 14 : 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
