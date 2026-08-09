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
    if (_code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال رمز مكوّن من 6 أرقام')),
      );
      return;
    }

    final success = await ref
        .read(passwordResetControllerProvider.notifier)
        .verifyCode(email: widget.email, code: _code);

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
      ).showSnackBar(const SnackBar(content: Text('تم إرسال رمز جديد')));
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
                  tooltip: 'رجوع',
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  color: AppColors.primary,
                ),
              ),
              Text(
                'تحقق من الرمز',
                style: AppTextStyles.title.copyWith(color: AppColors.primary),
                textAlign: TextAlign.right,
              ),
              SizedBox(height: metrics.fieldSpacing * 0.5),
              Text(
                'أدخل رمز الاستعادة المرسل إلى\n${widget.email}',
                style: AppTextStyles.body.copyWith(color: AppColors.textMuted),
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
                Text(
                  state.errorMessage!,
                  style: AppTextStyles.error,
                  textAlign: TextAlign.center,
                ),
              ],
              SizedBox(height: metrics.sectionSpacing),
              GoldGradientButton(
                label: 'تحقق',
                isLoading: state.isLoading,
                onPressed: state.isLoading ? null : _verify,
              ),
              SizedBox(height: metrics.fieldSpacing),
              TextButton(
                onPressed: (_secondsRemaining > 0 || _isResending)
                    ? null
                    : _resend,
                child: Text(
                  _secondsRemaining > 0
                      ? 'إعادة الإرسال بعد $_secondsRemaining ث'
                      : 'إعادة إرسال الرمز',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
