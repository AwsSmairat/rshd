import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/apple_sign_in_service.dart';
import '../../../core/platform/platform_settings_controller.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import 'auth_controller.dart';
import 'widgets/auth_or_divider.dart';
import 'widgets/register_form_field.dart';
import 'widgets/register_header.dart';
import 'widgets/register_login_link.dart';
import 'widgets/register_submit_button.dart';
import 'widgets/security_notice_card.dart';
import 'widgets/social_auth_buttons_row.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signInWithGoogle() async {
    final result =
        await ref.read(authControllerProvider.notifier).signInWithGoogle();

    if (!mounted || result == LoginFlowResult.cancelled) {
      return;
    }

    if (result == LoginFlowResult.success) {
      context.go(AppRoutes.home);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final result = await ref.read(authControllerProvider.notifier).register(
          name: _nameController.text,
          email: _emailController.text,
          phone: _phoneController.text,
          password: _passwordController.text,
          passwordConfirmation: _confirmPasswordController.text,
        );

    if (!mounted) {
      return;
    }

    switch (result) {
      case RegisterResult.requiresEmailVerification:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'تم إنشاء الحساب وإرسال رمز التحقق إلى بريدك الإلكتروني',
            ),
          ),
        );
        final email = ref.read(authControllerProvider).pendingVerificationEmail ??
            _emailController.text.trim();
        context.go(
          '${AppRoutes.verifyEmail}?email=${Uri.encodeComponent(email)}',
        );
      case RegisterResult.authenticated:
        context.go(AppRoutes.home);
      case RegisterResult.failed:
        break;
    }
  }

  Widget _visibilityToggle({
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return IconButton(
      icon: Icon(
        obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        color: AppColors.textMuted,
        size: 20,
      ),
      onPressed: onToggle,
    );
  }

  Future<void> _signInWithApple() async {
    final result =
        await ref.read(authControllerProvider.notifier).signInWithApple();

    if (!mounted || result == LoginFlowResult.cancelled) {
      return;
    }

    if (result == LoginFlowResult.success) {
      context.go(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final platformSettings = ref.watch(platformSettingsProvider);
    final showApple = ref.watch(appleSignInServiceProvider).isSupported;
    final registrationEnabled = platformSettings.maybeWhen(
      data: (settings) => settings.studentRegistrationEnabled,
      orElse: () => true,
    );
    final fieldErrors = authState.fieldErrors;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const RegisterHeader(),
            Transform.translate(
              offset: const Offset(0, -8),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'إنشاء حساب طالب جديد',
                        style: AppTextStyles.title.copyWith(
                          fontSize: 22,
                          color: AppColors.primary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'أنشئ حسابك ثم أكد بريدك الإلكتروني للوصول إلى التطبيق',
                        style: AppTextStyles.subtitle.copyWith(
                          height: 1.5,
                          fontSize: 13,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      if (!registrationEnabled) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.cardWhite,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.accent),
                          ),
                          child: Text(
                            'التسجيل الذاتي للطلاب غير مفعّل حالياً.',
                            style: AppTextStyles.subtitle,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (authState.errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.error.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Text(
                            authState.errorMessage!,
                            style: AppTextStyles.error,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      RegisterFormField(
                        controller: _nameController,
                        hintText: 'الاسم الكامل',
                        textInputAction: TextInputAction.next,
                        icon: Icons.person_outline,
                        errorText: fieldErrors['name'],
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'الاسم مطلوب';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      RegisterFormField(
                        controller: _emailController,
                        hintText: 'البريد الإلكتروني',
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
                      const SizedBox(height: 14),
                      RegisterFormField(
                        controller: _phoneController,
                        hintText: 'رقم الهاتف (اختياري)',
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        icon: Icons.phone_outlined,
                        errorText: fieldErrors['phone'],
                      ),
                      const SizedBox(height: 14),
                      RegisterFormField(
                        controller: _passwordController,
                        hintText: 'كلمة المرور',
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.next,
                        icon: Icons.lock_outline,
                        trailing: _visibilityToggle(
                          obscure: _obscurePassword,
                          onToggle: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        errorText: fieldErrors['password'],
                        validator: (value) {
                          if (value == null || value.length < 8) {
                            return 'كلمة المرور 8 أحرف على الأقل';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      RegisterFormField(
                        controller: _confirmPasswordController,
                        hintText: 'تأكيد كلمة المرور',
                        obscureText: _obscureConfirmPassword,
                        textInputAction: TextInputAction.done,
                        icon: Icons.lock_outline,
                        trailing: _visibilityToggle(
                          obscure: _obscureConfirmPassword,
                          onToggle: () {
                            setState(() {
                              _obscureConfirmPassword =
                                  !_obscureConfirmPassword;
                            });
                          },
                        ),
                        errorText: fieldErrors['password_confirmation'],
                        validator: (value) {
                          if (value != _passwordController.text) {
                            return 'كلمة المرور غير متطابقة';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      const SecurityNoticeCard(),
                      const SizedBox(height: 20),
                      RegisterSubmitButton(
                        label: 'إنشاء حساب',
                        isLoading: authState.status == AuthStatus.loading,
                        onPressed: registrationEnabled ? _submit : null,
                      ),
                      const SizedBox(height: 20),
                      const AuthOrDivider(),
                      const SizedBox(height: 20),
                      SocialAuthButtonsRow(
                        showApple: showApple,
                        isLoading: authState.status == AuthStatus.loading,
                        onGooglePressed:
                            registrationEnabled ? _signInWithGoogle : null,
                        onApplePressed: registrationEnabled && showApple
                            ? _signInWithApple
                            : null,
                      ),
                      const SizedBox(height: 20),
                      RegisterLoginLink(
                        onLoginTap: () => context.go(AppRoutes.login),
                      ),
                      SizedBox(height: bottomInset + 24),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
