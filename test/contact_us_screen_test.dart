import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rshd/core/config/contact_settings.dart';
import 'package:rshd/features/contact/presentation/contact_us_screen.dart';
import 'package:rshd/features/contact/widgets/contact_channel_card.dart';

void main() {
  testWidgets('ContactUsScreen shows all official contact channels', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ContactUsScreen(),
      ),
    );

    expect(find.text('تواصل معنا'), findsOneWidget);
    expect(find.text('وسائل التواصل'), findsOneWidget);
    expect(find.text(ContactSettings.supportEmail), findsOneWidget);
    expect(find.text(ContactSettings.instagramUsername), findsOneWidget);
    expect(find.text(ContactSettings.facebookDisplayName), findsOneWidget);
    expect(find.text(ContactSettings.phoneDisplay), findsNWidgets(2));
    expect(find.byType(ContactChannelCard), findsNWidgets(5));
  });
}
