import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/settings/presentation/student_settings_controller.dart';
import '../../features/subjects/presentation/subjects_controller.dart'
    show FeatureLoadStatus;

import '../l10n/app_locale_controller.dart';
import '../l10n/app_strings.dart';
import '../preferences/app_display_preferences.dart';
import '../theme/app_theme_controller.dart';
import '../theme/app_colors.dart';

/// Frame around the five top-level tabs: the active tab above, the bottom
/// navigation bar below. Detail screens are pushed over the whole shell.
class StudentShell extends ConsumerStatefulWidget {
  const StudentShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<StudentShell> createState() => _StudentShellState();
}

class _StudentShellState extends ConsumerState<StudentShell> {
  StatefulNavigationShell get navigationShell => widget.navigationShell;

  @override
  void initState() {
    super.initState();
    // Fetch the Account tab's data once the home screen has settled, so
    // opening that tab shows the page at once instead of a loading screen.
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      final settings = ref.read(studentSettingsControllerProvider);
      if (settings.status == FeatureLoadStatus.initial) {
        ref.read(studentSettingsControllerProvider.notifier).load();
      }
    });
  }

  void _onTabSelected(int index) {
    HapticFeedback.selectionClick();
    // Tapping the tab you are on returns it to its first screen.
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Apply the account's saved theme, language and display preferences
    // whenever they load or change. This lives on the shell, which is always
    // on screen, so it also covers the background fetch above.
    ref.listen(studentSettingsControllerProvider, (previous, next) {
      final prefs = next.settings?.preferences;
      final previousPrefs = previous?.settings?.preferences;
      if (prefs != null &&
          (previousPrefs == null ||
              prefs.theme != previousPrefs.theme ||
              prefs.language != previousPrefs.language ||
              prefs.fontSize != previousPrefs.fontSize ||
              prefs.autoPlayVideo != previousPrefs.autoPlayVideo ||
              prefs.saveWatchPosition != previousPrefs.saveWatchPosition ||
              prefs.defaultVideoQuality != previousPrefs.defaultVideoQuality)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) {
            return;
          }
          if (prefs.theme != previousPrefs?.theme) {
            ref.read(appThemeControllerProvider.notifier).setTheme(prefs.theme);
          }
          if (prefs.language != previousPrefs?.language) {
            ref
                .read(appLocaleControllerProvider.notifier)
                .setLocale(prefs.language);
          }
          ref
              .read(appDisplayPreferencesProvider.notifier)
              .applyFromSettings(
                fontSize: prefs.fontSize,
                autoPlayVideo: prefs.autoPlayVideo,
                saveWatchPosition: prefs.saveWatchPosition,
                videoQuality: prefs.defaultVideoQuality,
              );
        });
      }
    });

    return Scaffold(
      backgroundColor: AppColors.of(context).background,
      body: navigationShell,
      bottomNavigationBar: StudentBottomNavBar(
        currentIndex: navigationShell.currentIndex,
        onSelected: _onTabSelected,
      ),
    );
  }
}

/// Cross-fades between tabs with a short slide toward the side the tab sits
/// on in the bar, so switching tabs reads as moving sideways.
class AnimatedTabSwitcher extends StatelessWidget {
  const AnimatedTabSwitcher({
    super.key,
    required this.currentIndex,
    required this.children,
  });

  final int currentIndex;
  final List<Widget> children;

  static const _enter = Duration(milliseconds: 280);
  static const _exit = Duration(milliseconds: 160);

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return Stack(
      fit: StackFit.expand,
      children: [
        for (var i = 0; i < children.length; i++)
          _TabLayer(
            active: i == currentIndex,
            // Inactive tabs wait just off-centre on their own side.
            offset: i == currentIndex
                ? Offset.zero
                : Offset(
                    (i < currentIndex ? -0.04 : 0.04) * (isRtl ? -1 : 1),
                    0,
                  ),
            enter: reduceMotion ? Duration.zero : _enter,
            exit: reduceMotion ? Duration.zero : _exit,
            child: children[i],
          ),
      ],
    );
  }
}

class _TabLayer extends StatelessWidget {
  const _TabLayer({
    required this.active,
    required this.offset,
    required this.enter,
    required this.exit,
    required this.child,
  });

  final bool active;
  final Offset offset;
  final Duration enter;
  final Duration exit;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // TickerMode wraps only the tab's content: muting it above the fade
    // would also freeze the fade-out, leaving the old tab painted on top.
    return IgnorePointer(
      ignoring: !active,
      child: ExcludeSemantics(
        excluding: !active,
        child: AnimatedOpacity(
          opacity: active ? 1 : 0,
          duration: active ? enter : exit,
          curve: active ? Curves.easeOut : Curves.easeIn,
          child: AnimatedSlide(
            offset: offset,
            duration: active ? enter : exit,
            curve: Curves.easeOutCubic,
            child: TickerMode(enabled: active, child: child),
          ),
        ),
      ),
    );
  }
}

class _TabSpec {
  const _TabSpec(this.label, this.icon, this.activeIcon);

  final String label;
  final IconData icon;
  final IconData activeIcon;
}

/// Floating bar with a navy pill that glides to the selected tab.
class StudentBottomNavBar extends StatelessWidget {
  const StudentBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onSelected,
  });

  final int currentIndex;
  final ValueChanged<int> onSelected;

  static const _barHeight = 66.0;
  static const _pillInset = 6.0;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final colors = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    final tabs = [
      _TabSpec(strings.navHome, Icons.home_outlined, Icons.home_rounded),
      _TabSpec(
        strings.navSubjects,
        Icons.auto_stories_outlined,
        Icons.auto_stories_rounded,
      ),
      _TabSpec(
        strings.navAssignments,
        Icons.assignment_outlined,
        Icons.assignment_rounded,
      ),
      _TabSpec(strings.navQuizzes, Icons.quiz_outlined, Icons.quiz_rounded),
      _TabSpec(
        strings.navAccount,
        Icons.person_outline_rounded,
        Icons.person_rounded,
      ),
    ];

    // Navy pill with white content in light mode; gold with navy in dark,
    // where a navy pill would vanish into the surface.
    final pillColor = isDark ? colors.accent : colors.primary;
    final activeColor = isDark ? const Color(0xFF0B1F3A) : Colors.white;
    final inactiveColor = colors.textMuted;

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 6, 14, 0),
        child: Container(
          height: _barHeight,
          decoration: BoxDecoration(
            color: colors.cardWhite,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: colors.primary.withValues(alpha: isDark ? 0.18 : 0.06),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0B1F3A).withValues(alpha: 0.10),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = constraints.maxWidth / tabs.length;
              return Stack(
                children: [
                  AnimatedPositionedDirectional(
                    duration: reduceMotion
                        ? Duration.zero
                        : const Duration(milliseconds: 340),
                    curve: Curves.easeOutBack,
                    start: itemWidth * currentIndex + _pillInset,
                    top: _pillInset,
                    bottom: _pillInset,
                    width: itemWidth - _pillInset * 2,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: pillColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: pillColor.withValues(alpha: 0.30),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      for (var i = 0; i < tabs.length; i++)
                        Expanded(
                          child: _NavItem(
                            spec: tabs[i],
                            selected: i == currentIndex,
                            activeColor: activeColor,
                            inactiveColor: inactiveColor,
                            reduceMotion: reduceMotion,
                            onTap: () => onSelected(i),
                          ),
                        ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.spec,
    required this.selected,
    required this.activeColor,
    required this.inactiveColor,
    required this.reduceMotion,
    required this.onTap,
  });

  final _TabSpec spec;
  final bool selected;
  final Color activeColor;
  final Color inactiveColor;
  final bool reduceMotion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final duration = reduceMotion
        ? Duration.zero
        : const Duration(milliseconds: 240);
    final color = selected ? activeColor : inactiveColor;

    return Semantics(
      button: true,
      selected: selected,
      label: spec.label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              scale: selected ? 1.08 : 1,
              duration: duration,
              curve: Curves.easeOutBack,
              child: AnimatedSwitcher(
                duration: duration,
                child: Icon(
                  selected ? spec.activeIcon : spec.icon,
                  key: ValueKey(selected),
                  size: 23,
                  color: color,
                ),
              ),
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: duration,
              style: TextStyle(
                fontFamily: DefaultTextStyle.of(context).style.fontFamily,
                fontSize: 11,
                height: 1.2,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
              child: Text(
                spec.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
