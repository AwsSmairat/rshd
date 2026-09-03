import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/layout/app_layout_metrics.dart';
import '../../../core/platform/platform_settings_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/responsive_content.dart';
import '../contact_launcher.dart';
import '../data/contact_channels.dart';
import '../widgets/contact_channel_card.dart';
import '../widgets/contact_us_header.dart';

class ContactChannelDefinition {
  const ContactChannelDefinition({
    required this.title,
    required this.value,
    required this.icon,
    required this.isEnabled,
    this.onTap,
    this.iconColor,
  });

  final String title;
  final String value;
  final IconData icon;
  final bool isEnabled;
  final Future<void> Function(BuildContext context)? onTap;
  final Color? iconColor;
}

List<ContactChannelDefinition> buildContactChannels(ContactChannels channels) {
  final launcher = ContactLauncher(channels);

  return [
    ContactChannelDefinition(
      title: 'البريد الإلكتروني',
      value: channels.displayFor(channels.email),
      icon: Icons.email_outlined,
      isEnabled: channels.hasEmail,
      onTap: launcher.openEmail,
    ),
    ContactChannelDefinition(
      title: 'رابط الموقع',
      value: channels.websiteDisplay,
      icon: Icons.language_outlined,
      isEnabled: channels.hasWebsite,
      onTap: launcher.openWebsite,
    ),
    ContactChannelDefinition(
      title: 'فيسبوك',
      value: channels.facebookDisplay,
      icon: Icons.facebook_outlined,
      isEnabled: channels.hasFacebook,
      onTap: launcher.openFacebook,
    ),
    ContactChannelDefinition(
      title: 'إنستغرام',
      value: channels.instagramDisplay,
      icon: Icons.camera_alt_outlined,
      isEnabled: channels.hasInstagram,
      onTap: launcher.openInstagram,
    ),
    ContactChannelDefinition(
      title: 'يوتيوب',
      value: channels.youtubeDisplay,
      icon: Icons.play_circle_outline,
      isEnabled: channels.hasYoutube,
      onTap: launcher.openYoutube,
    ),
    ContactChannelDefinition(
      title: 'لينكدإن',
      value: channels.linkedinDisplay,
      icon: Icons.work_outline,
      isEnabled: channels.hasLinkedin,
      onTap: launcher.openLinkedin,
    ),
    ContactChannelDefinition(
      title: 'اتصل بنا',
      value: channels.phoneDisplay,
      icon: Icons.phone_outlined,
      isEnabled: channels.hasPhone,
      onTap: launcher.openPhone,
    ),
    ContactChannelDefinition(
      title: 'واتساب',
      value: channels.whatsappDisplay,
      icon: Icons.chat_outlined,
      isEnabled: channels.hasWhatsapp,
      onTap: launcher.openWhatsApp,
      iconColor: const Color(0xFF25D366),
    ),
  ];
}

class ContactUsScreen extends ConsumerStatefulWidget {
  const ContactUsScreen({super.key});

  @override
  ConsumerState<ContactUsScreen> createState() => _ContactUsScreenState();
}

class _ContactUsScreenState extends ConsumerState<ContactUsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(_refreshContactSettings);
  }

  Future<void> _refreshContactSettings() async {
    await ref.read(platformSettingsProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(platformSettingsProvider);
    final metrics = AppLayoutMetrics.of(context);
    final channels = settings.maybeWhen(
      data: (value) => buildContactChannels(value.contact),
      orElse: () => buildContactChannels(ContactChannels.empty),
    );
    final columns = metrics.isTablet ? 2 : 1;
    final isRefreshing = settings.isLoading;

    return Scaffold(
      backgroundColor: AppColors.of(context).background,
      body: RefreshIndicator(
        onRefresh: _refreshContactSettings,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            const SliverToBoxAdapter(child: ContactUsHeader()),
            SliverToBoxAdapter(
              child: ResponsiveContent(
                padding: EdgeInsets.fromLTRB(
                  metrics.outerHorizontalInset,
                  16,
                  metrics.outerHorizontalInset,
                  MediaQuery.paddingOf(context).bottom + 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'وسائل التواصل',
                      style: AppTextStyles.subtitleOf(context).copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.of(context).primary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'اضغط على أي بطاقة للتواصل مع فريق RSHD',
                      style: AppTextStyles.bodyOf(context).copyWith(
                        fontSize: 13,
                        color: AppColors.of(context).textMuted,
                      ),
                    ),
                    if (isRefreshing) ...[
                      const SizedBox(height: 12),
                      const LinearProgressIndicator(minHeight: 2),
                    ],
                    const SizedBox(height: 16),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final gap = 12.0;
                        final itemWidth = columns == 1
                            ? constraints.maxWidth
                            : (constraints.maxWidth - gap) / 2;

                        return Wrap(
                          spacing: gap,
                          runSpacing: gap,
                          children: channels.map((channel) {
                            return SizedBox(
                              width: itemWidth,
                              child: ContactChannelCard(
                                title: channel.title,
                                value: channel.value,
                                icon: channel.icon,
                                iconColor: channel.iconColor,
                                isEnabled: channel.isEnabled,
                                onTap:
                                    channel.isEnabled && channel.onTap != null
                                    ? () => channel.onTap!(context)
                                    : null,
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
