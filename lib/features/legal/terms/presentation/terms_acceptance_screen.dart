import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../widgets/terms_contact_card.dart';
import 'terms_acceptance_gate_controller.dart';
import 'terms_and_conditions_controller.dart';

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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('تحديث الشروط والأحكام'),
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
                  color: AppColors.cardWhite,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'تم تحديث الشروط والأحكام',
                      style: AppTextStyles.title.copyWith(
                        fontSize: 20,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'يرجى قراءة النسخة الحالية والموافقة عليها لمتابعة استخدام التطبيق.',
                      style: AppTextStyles.body,
                    ),
                    const SizedBox(height: 12),
                    if (gate.status != null) ...[
                      Text(
                        'الإصدار الحالي: ${gate.status!.currentVersion}',
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (gate.status!.lastUpdated != null &&
                          gate.status!.lastUpdated!.isNotEmpty)
                        Text(
                          'آخر تحديث: ${gate.status!.lastUpdated}',
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => context.push(AppRoutes.termsAndConditions),
                icon: const Icon(Icons.description_outlined),
                label: const Text('عرض الشروط والأحكام'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  foregroundColor: AppColors.darkGold,
                  side: const BorderSide(color: AppColors.darkGold),
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
                      const SnackBar(
                        content: Text('تم تسجيل موافقتك على الشروط'),
                      ),
                    );
                  }
                },
              ),
              if (gate.errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  gate.errorMessage!,
                  style: AppTextStyles.body.copyWith(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ],
              const Spacer(),
              if (document != null)
                Text(
                  'النسخة المعروضة: ${document.version}',
                  style: AppTextStyles.body.copyWith(
                    fontSize: 12,
                    color: AppColors.textMuted,
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
