import 'dart:async';

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
import 'widgets/otp_input_row.dart';
import '../../../core/l10n/app_strings.dart';

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

  Future<void> _verify() async {
    // `onCompleted` can fire while a manual verify is already in flight.
    if (_isVerifying) {
      return;
    }

    if (_code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.of(context).t('يرجى إدخال رمز مكوّن من 6 أرقام'))),
      );
      return;
    }

    _isVerifying = true;
    final bool success;
    try {
      success = await ref
          .read(passwordResetControllerProvider.notifier)
          .verifyCode(email: widget.email, code: _code);
    } finally {
      _isVerifying = false;
    }

    if (!mounted || !success) return;

    context.push(
      '${AppRoutes.passwordResetNew}?email=${Uri.encodeComponent(widget.email.trim())}',
    );
  }

  Future<void> _resend() async {
    if (_secondsRemaining > 0 || _isResending) return;

    setState(() => _isResending = true);
    final success = await ref
        .read(passwordResetControllerProvider.notifier)
        .resendCode(widget.email);

    if (!mounted) return;

    setState(() => _isResending = false);

    if (success) {
      _otpKey.currentState?.clear();
      _startResendTimer();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppStrings.of(context).t('تم إرسال رمز جديد'))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(passwordResetControllerProvider);
    final metrics = AuthLayoutMetrics.of(context);

    return Scaffold(
      body: AuthScreenShell(
        header: const LoginHeader(),
        body: LuxuryLoginCard(
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
              Text(AppStrings.of(context).t('تحقق من الرمز'),
                style: AppTextStyles.titleOf(
                  context,
                ).copyWith(color: AppColors.of(context).primary),
                textAlign: TextAlign.right,
              ),
              SizedBox(height: metrics.fieldSpacing * 0.5),
              Text(AppStrings.of(context).t('أدخل رمز الاستعادة المرسل إلى\n${widget.email}'),
                style: AppTextStyles.bodyOf(
                  context,
                ).copyWith(color: AppColors.of(context).textMuted),
                textAlign: TextAlign.right,
              ),
              SizedBox(height: metrics.sectionSpacing),
              SizedBox(
                width: double.infinity,
                child: OtpInputRow(
                  key: _otpKey,
                  length: 6,
                  onChanged: (value) => _code = value,
                  onCompleted: (value) {
                    _code = value;
                    _verify();
                  },
                ),
              ),
              if (state.errorMessage != null) ...[
                SizedBox(height: metrics.fieldSpacing),
                Text(AppStrings.of(context).t(state.errorMessage!),
                  style: AppTextStyles.errorOf(context),
                  textAlign: TextAlign.center,
                ),
              ],
              SizedBox(height: metrics.sectionSpacing),
              GoldGradientButton(
                label: AppStrings.of(context).t('تحقق'),
                isLoading: state.isLoading,
                onPressed: state.isLoading ? null : _verify,
              ),
              SizedBox(height: metrics.fieldSpacing),
              TextButton(
                onPressed: (_secondsRemaining > 0 || _isResending)
                    ? null
                    : _resend,
                child: Text(AppStrings.of(context).t(_secondsRemaining > 0
                      ? 'إعادة الإرسال بعد $_secondsRemaining ث'
                      : 'إعادة إرسال الرمز'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
