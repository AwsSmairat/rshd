import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/layout/auth_layout_metrics.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import 'auth_controller.dart';
import 'widgets/auth_screen_shell.dart';
import 'widgets/gold_gradient_button.dart';
import 'widgets/login_header.dart';
import 'widgets/luxury_login_card.dart';
import 'widgets/otp_input_row.dart';

class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key, required this.email});

  final String email;

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
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

  Future<void> _submit() async {
    if (_code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال رمز مكوّن من 6 أرقام')),
      );
      return;
    }

    final success = await ref
        .read(authControllerProvider.notifier)
        .verifyEmail(email: widget.email, code: _code);

    if (success && mounted) {
      context.go(AppRoutes.home);
    }
  }

  Future<void> _resend() async {
    if (_secondsRemaining > 0 || _isResending) {
      return;
    }

    setState(() => _isResending = true);

    final success = await ref
        .read(authControllerProvider.notifier)
        .resendVerificationCode(email: widget.email);

    if (!mounted) {
      return;
    }

    setState(() => _isResending = false);

    if (success) {
      _otpKey.currentState?.clear();
      setState(() => _code = '');
      _startResendTimer();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم إرسال رمز جديد')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isVerifying = authState.status == AuthStatus.authenticating;
    final metrics = AuthLayoutMetrics.of(context);

    return Scaffold(
      body: AuthScreenShell(
        header: const LoginHeader(),
        footer: const LoginFooter(),
        body: LuxuryLoginCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: IconButton(
                  tooltip: 'رجوع',
                  onPressed: () => context.go(AppRoutes.login),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  color: AppColors.primary,
                ),
              ),
              Text(
                'تأكيد البريد الإلكتروني',
                style: AppTextStyles.title.copyWith(color: AppColors.primary),
                textAlign: TextAlign.right,
              ),
              SizedBox(height: metrics.fieldSpacing * 0.5),
              Text(
                'أدخل رمز التحقق المرسل إلى\n${widget.email}',
                style: AppTextStyles.body.copyWith(color: AppColors.textMuted),
                textAlign: TextAlign.right,
              ),
              SizedBox(height: metrics.sectionSpacing),
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  horizontal: metrics.isTablet ? 16 : 14,
                  vertical: metrics.isTablet ? 14 : 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.mail_outline_rounded,
                      color: AppColors.accent,
                      size: metrics.isTablet ? 22 : 20,
                    ),
                    SizedBox(width: metrics.fieldSpacing * 0.75),
                    Expanded(
                      child: Text(
                        widget.email,
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                        textAlign: TextAlign.right,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
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
                    _submit();
                  },
                ),
              ),
              if (authState.errorMessage != null) ...[
                SizedBox(height: metrics.fieldSpacing),
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
                    style: AppTextStyles.error,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
              SizedBox(height: metrics.sectionSpacing),
              GoldGradientButton(
                label: 'تأكيد الرمز',
                isLoading: isVerifying,
                onPressed: isVerifying ? null : _submit,
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
              SizedBox(height: metrics.fieldSpacing * 0.5),
              TextButton(
                onPressed: () => context.go(AppRoutes.login),
                child: const Text('العودة لتسجيل الدخول'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
