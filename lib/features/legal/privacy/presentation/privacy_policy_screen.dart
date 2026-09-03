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
import '../data/privacy_policy_config.dart';
import '../data/privacy_policy_model.dart';
import 'privacy_policy_controller.dart';
import '../widgets/privacy_policy_contact_card.dart'
    show
        DeleteAccountButton,
        PrivacyContactInfo,
        launchPrivacyEmail,
        resolvePrivacyContactInfo;
import '../widgets/privacy_policy_footer.dart';
import '../widgets/privacy_policy_header.dart';
import '../widgets/privacy_policy_intro_card.dart';
import '../widgets/privacy_policy_section_tile.dart';

class PrivacyPolicyPage extends ConsumerStatefulWidget {
  const PrivacyPolicyPage({super.key});

  @override
  ConsumerState<PrivacyPolicyPage> createState() => _PrivacyPolicyPageState();
}

class _PrivacyPolicyPageState extends ConsumerState<PrivacyPolicyPage> {
  final Set<String> _expandedIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(privacyPolicyControllerProvider.notifier).load();
    });
  }

  void _toggleSection(String id) {
    setState(() {
      if (_expandedIds.contains(id)) {
        _expandedIds.remove(id);
      } else {
        _expandedIds.add(id);
      }
    });
  }

  void _expandAll(List<PrivacyPolicySectionData> sections) {
    setState(() {
      _expandedIds
        ..clear()
        ..addAll(sections.map((s) => s.id));
    });
  }

  void _collapseAll() {
    setState(_expandedIds.clear);
  }

  void _openDeleteAccount() {
    context.push(AppRoutes.deleteAccount);
  }

  void _contactPrivacy(String email) {
    launchPrivacyEmail(
      email: email,
      subject: PrivacyPolicyConfig.privacyEmailSubject,
      context: context,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(privacyPolicyControllerProvider);
    final platformSettings = ref.watch(platformSettingsProvider).valueOrNull;
    final contact = resolvePrivacyContactInfo(
      platformSupportEmail: platformSettings?.supportEmail,
      platformSupportPhone: platformSettings?.supportPhone,
    );

    return Scaffold(
      backgroundColor: AppColors.of(context).background,
      body: switch (state.status) {
        PrivacyPolicyLoadStatus.initial || PrivacyPolicyLoadStatus.loading =>
          const LoadingWidget(message: 'جاري تحميل سياسة الخصوصية...'),
        PrivacyPolicyLoadStatus.error => ErrorView(
          message: state.errorMessage ?? 'تعذر تحميل سياسة الخصوصية',
          onRetry: () => ref
              .read(privacyPolicyControllerProvider.notifier)
              .load(refresh: true),
        ),
        PrivacyPolicyLoadStatus.loaded ||
        PrivacyPolicyLoadStatus.offline => _buildContent(
          state,
          contact,
          platformSettings?.platformName ?? 'RSHD',
        ),
      },
    );
  }

  Widget _buildContent(
    PrivacyPolicyState state,
    PrivacyContactInfo contact,
    String platformName,
  ) {
    final document = state.document!;
    final metrics = AppLayoutMetrics.of(context);
    final introSection = document.sections.firstWhere(
      (s) => s.id == 'introduction',
      orElse: () => document.sections.first,
    );
    final bodySections = document.sections
        .where((s) => s.id != 'introduction')
        .toList();
    final accordionSections = bodySections
        .where((s) => s.id != 'contact')
        .toList();

    return RefreshIndicator(
      onRefresh: () => ref
          .read(privacyPolicyControllerProvider.notifier)
          .load(refresh: true),
      color: AppColors.of(context).secondary,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: PrivacyPolicyHeader(
              title: document.title,
              subtitle: document.subtitle,
              lastUpdated: document.lastUpdated,
            ),
          ),
          if (state.isOfflineFallback || document.isLocal)
            SliverToBoxAdapter(
              child: ResponsiveContent(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: _OfflineBanner(isLocal: document.isLocal),
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
              child: metrics.isTablet
                  ? _buildTabletLayout(
                      document: document,
                      introSection: introSection,
                      accordionSections: accordionSections,
                      contact: contact,
                      platformName: platformName,
                    )
                  : _buildPhoneLayout(
                      document: document,
                      introSection: introSection,
                      accordionSections: accordionSections,
                      contact: contact,
                      platformName: platformName,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneLayout({
    required PrivacyPolicyDocument document,
    required PrivacyPolicySectionData introSection,
    required List<PrivacyPolicySectionData> accordionSections,
    required PrivacyContactInfo contact,
    required String platformName,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PrivacyPolicyIntroCard(introText: introSection.paragraphs.first),
        const SizedBox(height: 12),
        _buildControls(accordionSections),
        const SizedBox(height: 8),
        PrivacyPolicyAccordion(
          sections: accordionSections,
          expandedIds: _expandedIds,
          onToggle: _toggleSection,
          extraForSection: (section) {
            if (section.id != 'account_deletion') {
              return null;
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: DeleteAccountButton(onPressed: _openDeleteAccount),
            );
          },
        ),
        const SizedBox(height: 12),
        PrivacyPolicyFooter(
          platformName: platformName,
          version: document.version,
          lastUpdated: document.lastUpdated,
          onDeleteAccount: _openDeleteAccount,
          onPrivacyContact: () => _contactPrivacy(contact.privacyEmail),
        ),
      ],
    );
  }

  Widget _buildTabletLayout({
    required PrivacyPolicyDocument document,
    required PrivacyPolicySectionData introSection,
    required List<PrivacyPolicySectionData> accordionSections,
    required PrivacyContactInfo contact,
    required String platformName,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PrivacyPolicyIntroCard(introText: introSection.paragraphs.first),
        const SizedBox(height: 12),
        _buildControls(accordionSections),
        const SizedBox(height: 8),
        PrivacyPolicyAccordion(
          sections: accordionSections,
          expandedIds: _expandedIds,
          onToggle: _toggleSection,
          extraForSection: (section) {
            if (section.id != 'account_deletion') {
              return null;
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: DeleteAccountButton(onPressed: _openDeleteAccount),
            );
          },
        ),
        const SizedBox(height: 12),
        PrivacyPolicyFooter(
          platformName: platformName,
          version: document.version,
          lastUpdated: document.lastUpdated,
          onDeleteAccount: _openDeleteAccount,
          onPrivacyContact: () => _contactPrivacy(contact.privacyEmail),
        ),
      ],
    );
  }

  Widget _buildControls(List<PrivacyPolicySectionData> sections) {
    final allExpanded = sections.every((s) => _expandedIds.contains(s.id));

    return Row(
      children: [
        Text(
          'الأقسام',
          style: AppTextStyles.subtitleOf(context).copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.of(context).primary,
          ),
        ),
        const Spacer(),
        TextButton(
          onPressed: () => _expandAll(sections),
          child: const Text('فتح جميع الأقسام'),
        ),
        TextButton(
          onPressed: allExpanded ? _collapseAll : null,
          child: const Text('إغلاق جميع الأقسام'),
        ),
      ],
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner({required this.isLocal});

  final bool isLocal;

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
            isLocal ? Icons.article_outlined : Icons.cloud_off_outlined,
            color: AppColors.of(context).darkGold,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isLocal
                  ? 'يتم عرض النسخة المحلية من سياسة الخصوصية.'
                  : 'تعذر الاتصال — يتم عرض النسخة المحلية الاحتياطية.',
              style: AppTextStyles.bodyOf(context).copyWith(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
