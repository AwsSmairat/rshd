import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../widgets/terms_contact_card.dart';
import 'terms_acceptance_gate_controller.dart';
import 'terms_and_conditions_controller.dart';
import '../../../../core/l10n/app_strings.dart';

class TermsAcceptanceScreen extends ConsumerStatefulWidget {
  const TermsAcceptanceScreen({super.key});

  @override
  ConsumerState<TermsAcceptanceScreen> createState() =>
      _TermsAcceptanceScreenState();
}

class _TermsAcceptanceScreenState extends ConsumerState<TermsAcceptanceScreen> {
  bool _checked = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(termsAndConditionsControllerProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final gate = ref.watch(termsAcceptanceGateProvider);
    final termsState = ref.watch(termsAndConditionsControllerProvider);
    final document = termsState.document;
    final gateNotifier = ref.read(termsAcceptanceGateProvider.notifier);

    ref.listen(termsAcceptanceGateProvider, (previous, next) {
      if (!next.requiresAcceptance && (previous?.requiresAcceptance ?? false)) {
        if (mounted) {
          context.go(AppRoutes.home);
        }
      }
    });

    return Scaffold(
      backgroundColor: AppColors.of(context).background,
      appBar: AppBar(
        title: Text(AppStrings.of(context).t('تحديث الشروط والأحكام')),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.of(context).cardWhite,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppStrings.of(context).t('تم تحديث الشروط والأحكام'),
                      style: AppTextStyles.titleOf(context).copyWith(
                        fontSize: 20,
                        color: AppColors.of(context).primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(AppStrings.of(context).t('يرجى قراءة النسخة الحالية والموافقة عليها لمتابعة استخدام التطبيق.'),
                      style: AppTextStyles.bodyOf(context),
                    ),
                    const SizedBox(height: 12),
                    if (gate.status != null) ...[
                      Text(AppStrings.of(context).t('الإصدار الحالي: ${gate.status!.currentVersion}'),
                        style: AppTextStyles.bodyOf(
                          context,
                        ).copyWith(fontWeight: FontWeight.w600),
                      ),
                      if (gate.status!.lastUpdated != null &&
                          gate.status!.lastUpdated!.isNotEmpty)
                        Text(AppStrings.of(context).t('آخر تحديث: ${gate.status!.lastUpdated}'),
                          style: AppTextStyles.bodyOf(
                            context,
                          ).copyWith(color: AppColors.of(context).textMuted),
                        ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => context.push(AppRoutes.termsAndConditions),
                icon: const Icon(Icons.description_outlined),
                label: Text(AppStrings.of(context).t('عرض الشروط والأحكام')),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  foregroundColor: AppColors.of(context).darkGold,
                  side: BorderSide(color: AppColors.of(context).darkGold),
                ),
              ),
              const SizedBox(height: 16),
              TermsAcceptanceCard(
                checked: _checked,
                isLoading: gate.isLoading,
                onCheckedChanged: (value) => setState(() => _checked = value),
                onAccept: () async {
                  final success = await gateNotifier.accept();
                  if (success && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(AppStrings.of(context).t('تم تسجيل موافقتك على الشروط')),
                      ),
                    );
                  }
                },
              ),
              if (gate.errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(AppStrings.of(context).t(gate.errorMessage!),
                  style: AppTextStyles.bodyOf(
                    context,
                  ).copyWith(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ],
              const Spacer(),
              if (document != null)
                Text(AppStrings.of(context).t('النسخة المعروضة: ${document.version}'),
                  style: AppTextStyles.bodyOf(context).copyWith(
                    fontSize: 12,
                    color: AppColors.of(context).textMuted,
                  ),
                  textAlign: TextAlign.center,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
