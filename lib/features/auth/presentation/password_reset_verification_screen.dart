import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import 'password_reset_controller.dart';
import 'widgets/auth_form_parts.dart';
import 'widgets/auth_page_scaffold.dart';
import 'widgets/auth_primary_button.dart';
import 'widgets/otp_input_row.dart';

class PasswordResetVerificationScreen extends ConsumerStatefulWidget {
  const PasswordResetVerificationScreen({super.key, required this.email});

  final String email;

  @override
  ConsumerState<PasswordResetVerificationScreen> createState() =>
      _PasswordResetVerificationScreenState();
}

class _PasswordResetVerificationScreenState
    extends ConsumerState<PasswordResetVerificationScreen> {
  final _otpKey = GlobalKey<OtpInputRowState>();
  Timer? _resendTimer;
  int _secondsRemaining = 60;
  bool _isResending = false;
  bool _isVerifying = false;
  String _code = '';
  AuthButtonState _buttonState = AuthButtonState.idle;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    _resendTimer?.cancel();
    setState(() => _secondsRemaining = 60);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_secondsRemaining <= 1) {
        timer.cancel();
        setState(() => _secondsRemaining = 0);
        return;
      }
      setState(() => _secondsRemaining -= 1);
    });
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

  Future<void> _verify() async {
    // `onCompleted` can fire while a manual verify is already in flight.
    if (_isVerifying) {
      return;
    }

    if (_code.length != 6) {
      await _flashFailure();
      return;
    }

    _isVerifying = true;
    setState(() => _buttonState = AuthButtonState.loading);

    final bool success;
    try {
      success = await ref
          .read(passwordResetControllerProvider.notifier)
          .verifyCode(email: widget.email, code: _code);
    } finally {
      _isVerifying = false;
    }

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

    context.push(
      '${AppRoutes.passwordResetNew}'
      '?email=${Uri.encodeComponent(widget.email.trim())}',
    );
  }

  Future<void> _resend() async {
    if (_secondsRemaining > 0 || _isResending) {
      return;
    }

    setState(() => _isResending = true);
    final success = await ref
        .read(passwordResetControllerProvider.notifier)
        .resendCode(widget.email);

    if (!mounted) {
      return;
    }

    setState(() => _isResending = false);

    if (success) {
      _otpKey.currentState?.clear();
      setState(() => _code = '');
      _startResendTimer();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.of(context).t('تم إرسال رمز جديد'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(passwordResetControllerProvider);
    final strings = AppStrings.of(context);
    final colors = AppColors.of(context);

    return AuthPageScaffold(
      title: strings.verifyCodeTitle,
      subtitle: strings.verifyCodeSubtitle,
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
        AuthEmailChip(email: widget.email),
        const SizedBox(height: 22),

        OtpInputRow(
          key: _otpKey,
          length: 6,
          // Turns every cell green with a check the moment the code is
          // accepted, before the route changes.
          status: _buttonState == AuthButtonState.success
              ? OtpStatus.verified
              : OtpStatus.idle,
          onChanged: (value) => _code = value,
          onCompleted: (value) {
            _code = value;
            _verify();
          },
        ),

        if (state.errorMessage != null) ...[
          const SizedBox(height: 18),
          AuthErrorBanner(message: strings.t(state.errorMessage!)),
        ],
        const SizedBox(height: 24),

        AuthPrimaryButton(
          label: strings.verifyAction,
          variant: AuthButtonVariant.gold,
          state: _buttonState,
          onPressed: _verify,
        ),
        const SizedBox(height: 10),

        AuthResendRow(
          secondsRemaining: _secondsRemaining,
          isResending: _isResending,
          onResend: _resend,
        ),
      ],
    );
  }
}
