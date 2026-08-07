import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rshd/core/platform/platform_settings.dart';
import 'package:rshd/core/platform/platform_settings_controller.dart';
import 'package:rshd/features/contact/data/contact_channels.dart';
import 'package:rshd/features/contact/presentation/contact_us_screen.dart';
import 'package:rshd/features/contact/widgets/contact_channel_card.dart';

void main() {
  testWidgets('ContactUsScreen shows all channels with placeholders', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          platformSettingsProvider.overrideWith(
            () => _StaticPlatformSettingsController(
              PlatformSettings(
                platformName: 'RSHD',
                maintenanceMode: false,
                maintenanceMessage: '',
                studentRegistrationEnabled: true,
                paymentInstructions: '',
                assignmentMaxFileSizeMb: 10,
                assignmentAllowedFileTypes: const ['pdf'],
                currencySymbol: 'د.أ',
                contact: const ContactChannels(),
              ),
            ),
          ),
        ],
        child: const MaterialApp(
          home: ContactUsScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('تواصل معنا'), findsOneWidget);
    expect(find.text('لم يضاف بعد'), findsNWidgets(8));
    expect(find.byType(ContactChannelCard), findsNWidgets(8));
    expect(find.text('رابط الموقع'), findsOneWidget);
    expect(find.text('يوتيوب'), findsOneWidget);
    expect(find.text('لينكدإn'), findsNothing);
    expect(find.text('لينكدإن'), findsOneWidget);
  });

  testWidgets('ContactUsScreen enables cards when admin values exist', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          platformSettingsProvider.overrideWith(
            () => _StaticPlatformSettingsController(
              PlatformSettings(
                platformName: 'RSHD',
                maintenanceMode: false,
                maintenanceMessage: '',
                studentRegistrationEnabled: true,
                paymentInstructions: '',
                assignmentMaxFileSizeMb: 10,
                assignmentAllowedFileTypes: const ['pdf'],
                currencySymbol: 'د.أ',
                contact: const ContactChannels(
                  email: 'admin@test.com',
                  phone: '0799000000',
                  websiteUrl: 'https://rshd.com',
                  instagramUrl: 'https://www.instagram.com/test/',
                  facebookUrl: 'https://facebook.com/test',
                  youtubeUrl: 'https://youtube.com/@rshd',
                  linkedinUrl: 'https://linkedin.com/company/rshd',
                  whatsappNumber: '962790000000',
                ),
              ),
            ),
          ),
        ],
        child: const MaterialApp(
          home: ContactUsScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('admin@test.com'), findsOneWidget);
    expect(find.text('@test'), findsOneWidget);
    expect(find.text('rshd.com'), findsOneWidget);
    expect(find.text('youtube.com/@rshd'), findsOneWidget);
    expect(find.text('linkedin.com/company/rshd'), findsOneWidget);
    expect(find.text('لم يضاف بعد'), findsNothing);
    expect(find.byType(ContactChannelCard), findsNWidgets(8));
  });
}

class _StaticPlatformSettingsController extends PlatformSettingsController {
  _StaticPlatformSettingsController(this.value);

  final PlatformSettings value;

  @override
  Future<PlatformSettings> build() async => value;
}
