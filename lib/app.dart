import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/platform/platform_settings_controller.dart';
import 'core/router/app_router.dart';
import 'core/startup/startup_coordinator.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_theme_controller.dart';
import 'core/l10n/app_locale_controller.dart';
import 'core/l10n/app_strings.dart';
import 'core/preferences/app_display_preferences.dart';
import 'core/widgets/liquid_glass_background.dart';
import 'features/subjects/widgets/floating_video_overlay.dart';

class RshdApp extends ConsumerStatefulWidget {
  const RshdApp({super.key});

  @override
  ConsumerState<RshdApp> createState() => _RshdAppState();
}

class _RshdAppState extends ConsumerState<RshdApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(platformSettingsProvider);
      ref
          .read(startupCoordinatorProvider.notifier)
          .ensureAuthBootstrapStarted();
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    final themePreference = ref.watch(appThemeControllerProvider);
    final localePreference = ref.watch(appLocaleControllerProvider);
    final displayPreferences = ref.watch(appDisplayPreferencesProvider);
    final locale = localeFromPreference(localePreference);
    final textDirection = textDirectionFromPreference(localePreference);
    final strings = AppStrings(localePreference);

    return MaterialApp.router(
      title: 'RSHD',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeModeFromPreference(themePreference),
      locale: locale,
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        final systemFactor = mediaQuery.textScaler.scale(14) / 14;
        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: TextScaler.linear(
              displayPreferences.resolvedTextScale(systemFactor),
            ),
          ),
          child: Directionality(
            textDirection: textDirection,
            child: AppStringsScope(
              strings: strings,
              child: LiquidGlassBackground(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    child ?? const SizedBox.shrink(),
                    const FloatingVideoOverlay(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      routerConfig: router,
    );
  }
}
