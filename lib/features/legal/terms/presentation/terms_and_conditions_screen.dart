import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/layout/app_layout_metrics.dart';
import '../../../../core/platform/platform_settings_controller.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/widgets/responsive_content.dart';
import '../data/terms_and_conditions_config.dart';
import '../data/terms_and_conditions_model.dart';
import '../presentation/terms_and_conditions_controller.dart';
import '../widgets/terms_contact_card.dart';
import '../widgets/terms_header.dart';
import '../widgets/terms_section_tile.dart';
import '../../../../core/l10n/app_strings.dart';

class TermsAndConditionsPage extends ConsumerStatefulWidget {
  const TermsAndConditionsPage({super.key});

  @override
  ConsumerState<TermsAndConditionsPage> createState() =>
      _TermsAndConditionsPageState();
}

class _TermsAndConditionsPageState
    extends ConsumerState<TermsAndConditionsPage> {
  final Set<String> _expandedIds = {};
  bool _acceptChecked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(termsAndConditionsControllerProvider.notifier).load();
    });
  }

  void _toggle(String id) {
    setState(() {
      if (_expandedIds.contains(id)) {
        _expandedIds.remove(id);
      } else {
        _expandedIds.add(id);
      }
    });
  }

  void _expandAll(List<TermsSectionData> sections) {
    setState(() => _expandedIds.addAll(sections.map((s) => s.id)));
  }

  void _collapseAll() => setState(_expandedIds.clear);

  double _readProgress(List<TermsSectionData> sections) {
    if (sections.isEmpty) return 0;
    return _expandedIds.where((id) => sections.any((s) => s.id == id)).length /
        sections.length;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(termsAndConditionsControllerProvider);
    final platform = ref.watch(platformSettingsProvider).valueOrNull;

    ref.listen(termsAndConditionsControllerProvider, (prev, next) {
      if (next.errorMessage != null &&
          next.errorMessage != prev?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.of(context).t(next.errorMessage!)),
            backgroundColor: const Color(0xFF991B1B),
          ),
        );
      }
      if (next.acceptanceMessage != null &&
          next.acceptanceMessage != prev?.acceptanceMessage) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppStrings.of(context).t(next.acceptanceMessage!))));
      }
    });

    return Scaffold(
      backgroundColor: AppColors.of(context).background,
      body: switch (state.status) {
        TermsLoadStatus.initial || TermsLoadStatus.loading =>
          LoadingWidget(message: AppStrings.of(context).t('جاري تحميل الشروط والأحكام...')),
        TermsLoadStatus.error => ErrorView(
          message: state.errorMessage ?? 'تعذر تحميل الشروط',
          onRetry: () => ref
              .read(termsAndConditionsControllerProvider.notifier)
              .load(refresh: true),
        ),
        TermsLoadStatus.loaded || TermsLoadStatus.offline => _buildContent(
          state,
          platform?.platformName ?? 'RSHD',
          platform?.supportEmail,
          platform?.supportPhone,
        ),
      },
    );
  }

  Widget _buildContent(
    TermsAndConditionsState state,
    String platformName,
    String? supportEmail,
    String? supportPhone,
  ) {
    final doc = state.document!;
    final metrics = AppLayoutMetrics.of(context);
    final contact = resolveTermsContactInfo(
      platformSupportEmail: supportEmail,
      platformSupportPhone: supportPhone,
    );
    final accordionSections = doc.sections
        .where((s) => s.id != 'contact')
        .toList();
    final progress = _readProgress(accordionSections);

    return RefreshIndicator(
      onRefresh: () => ref
          .read(termsAndConditionsControllerProvider.notifier)
          .load(refresh: true),
      color: AppColors.of(context).secondary,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: TermsHeader(
              title: doc.title,
              subtitle: doc.subtitle,
              version: doc.version,
              lastUpdated: doc.lastUpdated,
            ),
          ),
          if (state.isOfflineFallback || doc.isLocal)
            const SliverToBoxAdapter(
              child: ResponsiveContent(
                padding: EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: _OfflineBanner(),
              ),
            ),
          SliverToBoxAdapter(
            child: ResponsiveContent(
              padding: EdgeInsets.fromLTRB(
                metrics.outerHorizontalInset,
                12,
                metrics.outerHorizontalInset,
                MediaQuery.paddingOf(context).bottom + 20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (doc.requiresAcceptance) ...[
                    TermsAcceptanceCard(
                      checked: _acceptChecked,
                      isLoading: state.isAccepting,
                      onCheckedChanged: (v) =>
                          setState(() => _acceptChecked = v),
                      onAccept: () async {
                        if (!_acceptChecked) return;
                        final ok = await ref
                            .read(termsAndConditionsControllerProvider.notifier)
                            .acceptTerms();
                        if (ok && mounted) {
                          setState(() => _acceptChecked = false);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                  ],
                  _controls(accordionSections, progress),
                  const SizedBox(height: 8),
                  TermsAccordion(
                    sections: accordionSections,
                    expandedIds: _expandedIds,
                    onToggle: _toggle,
                    extraForSection: (section) {
                      if (section.id == 'privacy_link') {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: OutlinedButton.icon(
                            onPressed: () =>
                                context.push(AppRoutes.privacyPolicy),
                            icon: const Icon(Icons.privacy_tip_outlined),
                            label: Text(AppStrings.of(context).t('فتح سياسة الخصوصية')),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.of(context).darkGold,
                              side: BorderSide(
                                color: AppColors.of(context).darkGold,
                              ),
                              minimumSize: const Size(double.infinity, 44),
                            ),
                          ),
                        );
                      }
                      if (section.id == 'user_termination') {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: OutlinedButton.icon(
                            onPressed: () =>
                                context.push(AppRoutes.deleteAccount),
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Color(0xFF991B1B),
                            ),
                            label: Text(AppStrings.of(context).t('طلب حذف الحساب'),
                              style: TextStyle(color: Color(0xFF991B1B)),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF991B1B)),
                              minimumSize: const Size(double.infinity, 44),
                            ),
                          ),
                        );
                      }
                      if (section.id == 'account_creation') {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: OutlinedButton.icon(
                            onPressed: () => context.push(AppRoutes.profile),
                            icon: const Icon(Icons.security_outlined),
                            label: Text(AppStrings.of(context).t('إعدادات الأمان')),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.of(context).darkGold,
                              side: BorderSide(
                                color: AppColors.of(context).darkGold,
                              ),
                              minimumSize: const Size(double.infinity, 44),
                            ),
                          ),
                        );
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TermsContactCard(
                    contact: contact,
                    onContact: () => launchTermsEmail(
                      email: contact.supportEmail,
                      subject: TermsAndConditionsConfig.supportEmailSubject,
                      context: context,
                    ),
                    onReport: () => launchTermsEmail(
                      email: contact.legalEmail,
                      subject: TermsAndConditionsConfig.reportViolationSubject,
                      context: context,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TermsFooter(
                    platformName: platformName,
                    version: doc.version,
                    lastUpdated: doc.lastUpdated,
                    onPrivacy: () => context.push(AppRoutes.privacyPolicy),
                    onDeleteAccount: () =>
                        context.push(AppRoutes.deleteAccount),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _controls(List<TermsSectionData> sections, double progress) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(AppStrings.of(context).t('الأقسام'),
              style: AppTextStyles.subtitleOf(context).copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.of(context).primary,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => _expandAll(sections),
              child: Text(AppStrings.of(context).t('فتح جميع الأقسام')),
            ),
            TextButton(
              onPressed: _expandedIds.isNotEmpty ? _collapseAll : null,
              child: Text(AppStrings.of(context).t('إغلاق جميع الأقسام')),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  minHeight: 5,
                  value: progress,
                  backgroundColor: AppColors.of(
                    context,
                  ).primary.withValues(alpha: 0.08),
                  color: AppColors.of(context).accent,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(AppStrings.of(context).t('${(progress * 100).round()}%'),
              style: AppTextStyles.bodyOf(context).copyWith(
                fontSize: 12,
                color: AppColors.of(context).textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(AppStrings.of(context).t('مؤشر القراءة: الأقسام التي فتحتها'),
          style: AppTextStyles.bodyOf(
            context,
          ).copyWith(fontSize: 11, color: AppColors.of(context).textMuted),
        ),
      ],
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.of(context).accent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.of(context).darkGold.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.cloud_off_outlined,
            color: AppColors.of(context).darkGold,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(AppStrings.of(context).t('تعذر الاتصال — يتم عرض النسخة المحلية الاحتياطية.'),
              style: AppTextStyles.bodyOf(context).copyWith(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
