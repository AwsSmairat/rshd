import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/platform/platform_settings_controller.dart';
import '../../../../core/router/app_router.dart';
import '../auth_controller.dart';
import 'auth_form_parts.dart';
import 'auth_input_field.dart';
import 'auth_primary_button.dart';
import 'birth_date_sheet.dart';
import 'register_legal_links.dart';

/// Create-account half of the unified auth screen.
///
/// Fields, validators, the `register()` call and the success routing are
/// carried over unchanged from the standalone register screen; only the
/// presentation is new. Its [GlobalKey]<[FormState]> and controllers are
/// private to this widget, so sign-in validation never leaks in.
class RegisterForm extends ConsumerStatefulWidget {
  const RegisterForm({
    super.key,
    required this.showErrors,
    required this.onSubmitStarted,
  });

  /// False while the visible errors belong to the other tab.
  final bool showErrors;

  /// Lets the parent record which tab owns the controller's error state.
  final VoidCallback onSubmitStarted;

  @override
  ConsumerState<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends ConsumerState<RegisterForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  AuthButtonState _buttonState = AuthButtonState.idle;

  /// Selected date of birth. The 18+ rule is enforced against this value.
  DateTime? _birthDate;

  static const _minimumAge = 18;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _birthDateController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// Whole years elapsed, so a birthday later this year still counts as
  /// "not yet 18".
  int _ageOn(DateTime birthDate, DateTime today) {
    var age = today.year - birthDate.year;
    final hadBirthday =
        today.month > birthDate.month ||
        (today.month == birthDate.month && today.day >= birthDate.day);
    if (!hadBirthday) {
      age -= 1;
    }
    return age;
  }

  Future<void> _pickBirthDate() async {
    FocusScope.of(context).unfocus();

    final now = DateTime.now();
    final latestAllowed = DateTime(now.year - _minimumAge, now.month, now.day);

    final picked = await showBirthDateSheet(
      context,
      initial: _birthDate ?? latestAllowed,
      earliest: DateTime(now.year - 100),
      // The wheels stop at the 18th birthday, so the common path cannot
      // produce an under-age date at all; the validator stays as a backstop.
      latest: latestAllowed,
    );

    if (picked == null || !mounted) {
      return;
    }

    setState(() {
      _birthDate = picked;
      _birthDateController.text =
          '${picked.day} ${MaterialLocalizations.of(context).formatMonthYear(picked)}';
    });
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
        .register(
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
        setState(() => _buttonState = AuthButtonState.success);
        await Future<void>.delayed(const Duration(milliseconds: 620));
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppStrings.of(
                context,
              ).t('تم إنشاء الحساب وإرسال رمز التحقق إلى بريدك الإلكتروني'),
            ),
          ),
        );
        final email =
            ref.read(authControllerProvider).pendingVerificationEmail ??
            _emailController.text.trim();
        context.go(
          '${AppRoutes.verifyEmail}?email=${Uri.encodeComponent(email)}',
        );
      case RegisterResult.authenticated:
        setState(() => _buttonState = AuthButtonState.success);
        await Future<void>.delayed(const Duration(milliseconds: 620));
        if (!mounted) {
          return;
        }
        context.go(AppRoutes.home);
      case RegisterResult.failed:
        await _flashFailure();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final strings = AppStrings.of(context);
    final registrationEnabled = ref
        .watch(platformSettingsProvider)
        .maybeWhen(
          data: (settings) => settings.studentRegistrationEnabled,
          orElse: () => true,
        );

    final fieldErrors = widget.showErrors
        ? authState.fieldErrors
        : const <String, String>{};
    final bannerMessage = widget.showErrors ? authState.errorMessage : null;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!registrationEnabled) ...[
            AuthNoticeBanner(
              message: strings.t('التسجيل الذاتي للطلاب غير مفعّل حالياً.'),
            ),
            const SizedBox(height: 16),
          ],

          if (bannerMessage != null) ...[
            AuthErrorBanner(message: strings.t(bannerMessage)),
            const SizedBox(height: 16),
          ],

          AuthInputField(
            controller: _nameController,
            label: strings.fullName,
            hintText: strings.fullNameHint,
            icon: Icons.person_outline_rounded,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.name],
            errorText: fieldErrors['name'],
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return strings.t('الاسم مطلوب');
              }
              return null;
            },
          ),
          const SizedBox(height: 10),

          AuthInputField(
            controller: _emailController,
            label: strings.emailFieldLabel,
            hintText: strings.emailFieldHint,
            icon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
            errorText: fieldErrors['email'],
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
          const SizedBox(height: 10),

          AuthInputField(
            controller: _phoneController,
            label: strings.phoneRequiredLabel,
            hintText: strings.t('07xxxxxxxx'),
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.telephoneNumber],
            errorText: fieldErrors['phone'],
            validator: (value) {
              final phone = value?.trim() ?? '';
              if (phone.isEmpty) {
                return strings.phoneRequiredError;
              }
              if (phone.replaceAll(RegExp(r'[^0-9]'), '').length < 7) {
                return strings.phoneInvalidError;
              }
              return null;
            },
          ),
          const SizedBox(height: 10),

          AuthInputField(
            controller: _birthDateController,
            label: strings.birthDate,
            hintText: strings.birthDateHint,
            icon: Icons.cake_outlined,
            readOnly: true,
            onTap: _pickBirthDate,
            errorText: fieldErrors['birth_date'],
            validator: (_) {
              final birthDate = _birthDate;
              if (birthDate == null) {
                return strings.birthDateRequiredError;
              }
              if (_ageOn(birthDate, DateTime.now()) < _minimumAge) {
                return strings.minimumAgeError;
              }
              return null;
            },
          ),
          const SizedBox(height: 10),

          AuthInputField(
            controller: _passwordController,
            label: strings.passwordFieldLabel,
            hintText: strings.t('8 أحرف على الأقل'),
            icon: Icons.lock_outline_rounded,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.newPassword],
            errorText: fieldErrors['password'],
            trailing: AuthVisibilityToggle(
              obscured: _obscurePassword,
              onToggle: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
            validator: (value) {
              if (value == null || value.length < 8) {
                return strings.t('كلمة المرور 8 أحرف على الأقل');
              }
              return null;
            },
          ),
          const SizedBox(height: 10),

          AuthInputField(
            controller: _confirmPasswordController,
            label: strings.confirmPasswordLabel,
            hintText: strings.t('أعد إدخال كلمة المرور'),
            icon: Icons.lock_outline_rounded,
            obscureText: _obscureConfirmPassword,
            textInputAction: TextInputAction.done,
            errorText: fieldErrors['password_confirmation'],
            onFieldSubmitted: (_) => _submit(),
            trailing: AuthVisibilityToggle(
              obscured: _obscureConfirmPassword,
              onToggle: () => setState(
                () => _obscureConfirmPassword = !_obscureConfirmPassword,
              ),
            ),
            validator: (value) {
              if (value != _passwordController.text) {
                return strings.t('كلمة المرور غير متطابقة');
              }
              return null;
            },
          ),
          const SizedBox(height: 14),

          const RegisterLegalLinks(),
          const SizedBox(height: 16),

          AuthPrimaryButton(
            label: strings.t('إنشاء حساب'),
            state: _buttonState,
            onPressed: registrationEnabled ? _submit : null,
          ),
        ],
      ),
    );
  }
}
