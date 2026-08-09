import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/platform/platform_settings_controller.dart';
import 'core/router/app_router.dart';
import 'core/startup/startup_coordinator.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/liquid_glass_background.dart';

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

    return MaterialApp.router(
      title: 'RSHD',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: LiquidGlassBackground(child: child ?? const SizedBox.shrink()),
        );
      },
      routerConfig: router,
    );
  }
}
