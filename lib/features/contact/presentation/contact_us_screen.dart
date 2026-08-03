import 'package:flutter/material.dart';

import '../../../core/config/contact_settings.dart';
import '../../../core/layout/app_layout_metrics.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/responsive_content.dart';
import '../contact_launcher.dart';
import '../widgets/contact_channel_card.dart';
import '../widgets/contact_us_header.dart';

class ContactChannelDefinition {
  const ContactChannelDefinition({
    required this.title,
    required this.value,
    required this.icon,
    required this.onTap,
    this.iconColor,
  });

  final String title;
  final String value;
  final IconData icon;
  final Future<void> Function(BuildContext context) onTap;
  final Color? iconColor;
}

/// Builds contact cards from [ContactSettings] — no duplicated contact data.
List<ContactChannelDefinition> buildContactChannels() {
  return [
    ContactChannelDefinition(
      title: 'البريد الإلكتروني',
      value: ContactSettings.supportEmail,
      icon: Icons.email_outlined,
      onTap: ContactLauncher.openEmail,
    ),
    ContactChannelDefinition(
      title: 'إنستغرام',
      value: ContactSettings.instagramUsername,
      icon: Icons.camera_alt_outlined,
      onTap: ContactLauncher.openInstagram,
    ),
    ContactChannelDefinition(
      title: 'فيسبوك',
      value: ContactSettings.facebookDisplayName,
      icon: Icons.facebook_outlined,
      onTap: ContactLauncher.openFacebook,
    ),
    ContactChannelDefinition(
      title: 'اتصل بنا',
      value: ContactSettings.phoneDisplay,
      icon: Icons.phone_outlined,
      onTap: ContactLauncher.openPhone,
    ),
    ContactChannelDefinition(
      title: 'واتساب',
      value: ContactSettings.phoneDisplay,
      icon: Icons.chat_outlined,
      onTap: ContactLauncher.openWhatsApp,
      iconColor: const Color(0xFF25D366),
    ),
  ];
}

class ContactUsScreen extends StatelessWidget {
  const ContactUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final metrics = AppLayoutMetrics.of(context);
    final channels = buildContactChannels();
    final columns = metrics.isTablet ? 2 : 1;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
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
                    style: AppTextStyles.subtitle.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'اضغط على أي بطاقة للتواصل مع فريق RSHD',
                    style: AppTextStyles.body.copyWith(
                      fontSize: 13,
                      color: AppColors.textMuted,
                    ),
                  ),
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
                              onTap: () => channel.onTap(context),
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
    );
  }
}
