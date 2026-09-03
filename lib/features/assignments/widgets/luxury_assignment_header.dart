import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../auth/presentation/widgets/login_header.dart';

class LuxuryAssignmentHeader extends StatelessWidget {
  const LuxuryAssignmentHeader({
    super.key,
    required this.title,
    this.watermarkIcon = Icons.assignment_outlined,
  });

  final String title;
  final IconData watermarkIcon;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    final canPop = context.canPop();

    return ClipPath(
      clipper: LoginHeaderWaveClipper(),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 176),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF091729),
              AppColors.of(context).primary,
              AppColors.of(context).secondaryNavy,
            ],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              left: -24,
              top: topInset + 18,
              child: Icon(
                watermarkIcon,
                size: 110,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
            Positioned(
              right: -10,
              top: topInset + 42,
              child: Container(
                width: 120,
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      AppColors.of(context).accent.withValues(alpha: 0.35),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16, topInset + 8, 16, 40),
              child: SizedBox(
                height: 44,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.of(context).white,
                      ),
                    ),
                    if (canPop)
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: _BackButton(onTap: () => context.pop()),
                      ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 14,
              child: Center(
                child: Container(
                  width: 110,
                  height: 2,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    gradient: LinearGradient(
                      colors: [
                        AppColors.of(context).accent.withValues(alpha: 0.12),
                        AppColors.of(context).accent,
                        AppColors.of(context).accent.withValues(alpha: 0.12),
                      ],
                    ),
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

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.08),
            border: Border.all(
              color: AppColors.of(context).white.withValues(alpha: 0.22),
            ),
          ),
          child: Icon(
            Icons.arrow_forward_ios_rounded,
            color: AppColors.of(context).white,
            size: 18,
          ),
        ),
      ),
    );
  }
}
