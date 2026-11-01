import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:rshd/core/l10n/app_locale_controller.dart';
import 'package:rshd/core/l10n/app_strings.dart';
import 'package:rshd/core/platform/platform_settings.dart';
import 'package:rshd/core/platform/platform_settings_controller.dart';
import 'package:rshd/core/theme/app_theme.dart';
import 'package:rshd/features/auth/data/auth_repository.dart';
import 'package:rshd/features/settings/data/models/student_settings_model.dart';
import 'package:rshd/features/settings/data/settings_repository.dart';
import 'package:rshd/features/settings/presentation/student_settings_controller.dart';
import 'package:rshd/features/settings/presentation/student_settings_screen.dart';
import 'package:rshd/features/settings/widgets/settings_section_cards.dart';
import 'package:rshd/features/settings/widgets/settings_shared_widgets.dart';
import 'package:rshd/features/subjects/presentation/subjects_controller.dart';

final _settings = StudentSettingsModel.fromJson({
  'profile': {
    'id': 1,
    'name': 'أحمد الخطيب',
    'email': 'ahmad@rshdacademy.com',
    'phone': '0790000000',
    'birth_date': '2002-04-21',
    'gender': 'male',
    'country': 'الأردن',
    'student_number': '1001',
    'role': 'student',
    'status': 'active',
    'avatar_url': null,
    'password_set_at': '2026-09-12T10:00:00Z',
  },
  'preferences': {'language': 'ar', 'notify_grades': false},
  'devices': [],
});

class _NoopRepository implements SettingsRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _NoopAuthRepository implements AuthRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Serves fixed settings and never touches the network.
class _LoadedController extends StudentSettingsController {
  _LoadedController() : super(_NoopRepository()) {
    state = StudentSettingsState(
      status: FeatureLoadStatus.loaded,
      settings: _settings,
    );
  }

  @override
  Future<void> load({bool refresh = false}) async {}
}

class _FakePlatformSettings extends PlatformSettingsController {
  @override
  Future<PlatformSettings> build() async => PlatformSettings.fallback;
}

Future<void> _loadFont(String family, String path) async {
  final loader = FontLoader(family)
    ..addFont(Future.value(ByteData.sublistView(File(path).readAsBytesSync())));
  await loader.load();
}

/// Real glyphs instead of the test font's boxes, so a rendered PNG is
/// actually reviewable. Skipped silently where the files are missing.
Future<void> _loadRealFonts() async {
  final candidates = {
    'NotoNaskhArabic': 'assets/fonts/NotoNaskhArabic-Regular.ttf',
    'Arial': '/System/Library/Fonts/Supplemental/Arial.ttf',
    'MaterialIcons':
        '/opt/homebrew/share/flutter/bin/cache/artifacts/material_fonts/'
        'MaterialIcons-Regular.otf',
  };
  for (final entry in candidates.entries) {
    if (File(entry.value).existsSync()) {
      await _loadFont(entry.key, entry.value);
    }
  }
}

final _boundary = GlobalKey();

Future<void> _pump(WidgetTester tester, {required bool dark}) async {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = const Size(430, 2300);
  addTearDown(tester.view.reset);

  ThemeData withFonts(ThemeData base) => base.copyWith(
    textTheme: base.textTheme.apply(
      fontFamily: 'NotoNaskhArabic',
      fontFamilyFallback: const ['Arial'],
    ),
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        studentSettingsControllerProvider.overrideWith(
          (ref) => _LoadedController(),
        ),
        platformSettingsProvider.overrideWith(_FakePlatformSettings.new),
        authRepositoryProvider.overrideWithValue(_NoopAuthRepository()),
      ],
      child: RepaintBoundary(
        key: _boundary,
        child: AppStringsScope(
          strings: const AppStrings(appLocaleArabic),
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            locale: const Locale('ar'),
            supportedLocales: const [Locale('ar'), Locale('en')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            theme: withFonts(AppTheme.light),
            darkTheme: withFonts(AppTheme.dark),
            themeMode: dark ? ThemeMode.dark : ThemeMode.light,
            home: const StudentSettingsScreen(),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Writes the current frame to $RENDER_DIR when set; a no-op in CI.
Future<void> _maybeSave(WidgetTester tester, String name) async {
  final dir = Platform.environment['RENDER_DIR'];
  if (dir == null) {
    return;
  }
  await tester.runAsync(() async {
    final boundary =
        _boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    File('$dir/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}

void main() {
  setUpAll(() async {
    PackageInfo.setMockInitialValues(
      appName: 'RSHD',
      packageName: 'com.rshdacademy.rshd',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
    await _loadRealFonts();
  });

  testWidgets('settings opens on the profile hero with every group visible', (
    tester,
  ) async {
    await _pump(tester, dark: false);

    expect(find.byType(SettingsProfileHero), findsOneWidget);
    expect(find.text('أحمد الخطيب'), findsOneWidget);

    // Groups are always open: their rows are on screen without any tapping.
    expect(find.text('تغيير كلمة المرور'), findsOneWidget);
    expect(find.text('اللغة'), findsOneWidget);
    expect(find.text('مركز المساعدة'), findsOneWidget);
    expect(find.byType(SettingsLogoutButton), findsOneWidget);

    // Notifications: a master switch, details tucked behind one row.
    expect(find.text('جميع الإشعارات'), findsOneWidget);
    final p = _settings.preferences;
    final on = [
      p.notifyLessons,
      p.notifyAssignments,
      p.notifyAssignmentReminders,
      p.notifyQuizzes,
      p.notifyQuizReminders,
      p.notifyGrades,
      p.notifyMessages,
      p.notifyAnnouncements,
      p.notifyPlatformUpdates,
      p.notificationSound,
      p.notificationVibration,
    ].where((f) => f).length;
    expect(find.text('$on من 11'), findsOneWidget);
    expect(on, lessThan(11), reason: 'fixture turns grades off');
    expect(find.text('إشعارات الدرجات'), findsNothing);

    await _maybeSave(tester, 'settings_light');
  });

  testWidgets('notification details expand in place', (tester) async {
    await _pump(tester, dark: false);

    await tester.tap(find.text('تخصيص الإشعارات'));
    await tester.pumpAndSettle();

    expect(find.text('إشعارات الدرجات'), findsOneWidget);
    expect(find.byType(SettingsSwitchTile), findsAtLeastNWidgets(13));

    await _maybeSave(tester, 'settings_notifications_open');
  });

  testWidgets('renders cleanly in dark mode', (tester) async {
    await _pump(tester, dark: true);
    expect(tester.takeException(), isNull);
    await _maybeSave(tester, 'settings_dark');
  });
}
