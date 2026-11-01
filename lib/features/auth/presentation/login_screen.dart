import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import 'widgets/auth_mode_tabs.dart';
import 'widgets/login_hero_header.dart';
import 'widgets/register_form.dart';
import 'widgets/sign_in_form.dart';

/// Unified authentication screen.
///
/// A full-bleed photograph sits behind a floating, frosted glass panel that
/// carries both forms. Sign-in and create-account share this one route:
/// switching tabs swaps the form in place and never pushes a page, so the
/// photo, the logo and the panel all stay mounted across the transition.
///
/// `/register` resolves here with [initialTab] set to [AuthTab.register],
/// which keeps existing deep links and the onboarding hand-off working.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({
    super.key,
    this.initialEmail,
    this.initialTab = AuthTab.signIn,
  });

  final String? initialEmail;
  final AuthTab initialTab;

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entranceController;
  late AuthTab _tab;

  /// Which tab produced the error currently held by the auth controller.
  ///
  /// The controller exposes one shared error slot, so this guards against a
  /// failed sign-in painting its message over the register form.
  AuthTab? _errorOwner;

  static const _switchDuration = Duration(milliseconds: 300);

  /// How far the floating panel rides over the photo band above it.
  static const _panelOverlap = 26.0;

  @override
  void initState() {
    super.initState();
    _tab = widget.initialTab;
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 820),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _entranceController.forward();
    });
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  void _selectTab(AuthTab tab) {
    if (tab == _tab) {
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _tab = tab;
      // Errors belong to the form that produced them.
      _errorOwner = null;
    });
  }

  void _claimErrors(AuthTab tab) {
    if (_errorOwner != tab) {
      setState(() => _errorOwner = tab);
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final keyboardInset = media.viewInsets.bottom;
    final isTablet = media.size.shortestSide >= 600;

    // Fixed for the lifetime of the screen: neither the selected tab nor the
    // keyboard may resize the photo band, the logo or the headline. Anything
    // that varies here makes the brand mark jump, so the keyboard is absorbed
    // by scrolling instead (see the scroll padding below).
    final compactCopy = media.size.height < 700;

    // The photo is a band across the top, not a full-screen backdrop: the
    // plate is near-square, so covering a 19.5:9 screen would crop away the
    // flag and the columns. The glass panel then floats over its lower edge.
    // Sized so the panel's lower edge lands just above the home indicator:
    // a taller band for the short sign-in form, a shorter one for the long
    // register form (which scrolls anyway).
    final bandHeight = (media.size.height * (compactCopy ? 0.42 : 0.52)).clamp(
      240.0,
      isTablet ? 520.0 : 520.0,
    );

    final hPad = isTablet ? 40.0 : 18.0;
    final bottomPad = media.padding.bottom + 18 + keyboardInset;

    // Where the panel normally starts: just over the photo band's lower edge.
    final restingTop = bandHeight - _panelOverlap;

    // The panel is anchored to the bottom and sized by its own content, so it
    // grows *upward* over the photo when the content needs more room — an
    // error banner, the longer register form, or the keyboard. Pinning its
    // top instead would clip the submit button, which is what used to happen
    // the moment a server error appeared.
    // The panel may rise all the way up to just under the status bar, so the
    // register form opens at its full height with every field visible rather
    // than scrolling inside a capped card. It only scrolls internally on
    // screens too short to hold it.
    final ceiling = media.padding.top + 10;
    final maxPanelHeight = math.max(
      240.0,
      media.size.height - bottomPad - ceiling,
    );

    return Scaffold(
      // The backdrop is the background; the Scaffold must not paint over it.
      backgroundColor: Colors.transparent,
      // The page itself neither scrolls nor resizes. Only the floating
      // panel's contents scroll, inside the panel.
      resizeToAvoidBottomInset: false,
      body: Stack(
        fit: StackFit.expand,
        children: [
          HeroBackdrop(bandHeight: bandHeight),

          // Fixed layer: pinned for the lifetime of the screen.
          SafeArea(
            bottom: false,
            child: Align(
              alignment: Alignment.topCenter,
              child: HeroWelcomeCopy(
                // The backdrop starts behind the status bar while the copy
                // lives inside SafeArea, so trim the inset to keep the copy
                // aligned with the band's base.
                bandHeight: restingTop - media.padding.top,
                compact: compactCopy,
              ),
            ),
          ),

          // Floating layer: the only thing that moves or scrolls.
          Positioned(
            left: hPad,
            right: hPad,
            bottom: bottomPad,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 460,
                  maxHeight: maxPanelHeight,
                  // Keeps the resting composition: with the short sign-in
                  // form the panel still meets the photo's lower edge.
                  minHeight: math.min(
                    maxPanelHeight,
                    media.size.height - bottomPad - restingTop,
                  ),
                ),
                child: _GlassPanel(
                  animation: _entranceController,
                  child: _AuthPanelContent(
                    tab: _tab,
                    errorOwner: _errorOwner,
                    initialEmail: widget.initialEmail,
                    onTabChanged: _selectTab,
                    onSubmitStarted: _claimErrors,
                    switchDuration: _switchDuration,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Frosted, floating card that carries the auth forms.
class _GlassPanel extends StatelessWidget {
  const _GlassPanel({required this.child, required this.animation});

  final Widget child;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final curved = CurvedAnimation(
      parent: animation,
      curve: const Interval(0.25, 1.0, curve: Curves.easeOutCubic),
    );

    final radius = BorderRadius.circular(32);

    return AnimatedBuilder(
      animation: curved,
      builder: (context, child) => Opacity(
        opacity: curved.value,
        child: Transform.translate(
          offset: Offset(0, 26 * (1 - curved.value)),
          child: child,
        ),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: colors.primary.withValues(alpha: isDark ? 0.5 : 0.14),
              blurRadius: 34,
              spreadRadius: -6,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: radius,
                // Translucent enough that the photograph still reads through
                // the panel, opaque enough for text contrast.
                color: isDark
                    ? colors.background.withValues(alpha: 0.62)
                    : Colors.white.withValues(alpha: 0.58),
                border: Border.all(
                  color: isDark
                      ? colors.white.withValues(alpha: 0.12)
                      : Colors.white.withValues(alpha: 0.65),
                  width: 1,
                ),
              ),
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 22),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthPanelContent extends StatelessWidget {
  const _AuthPanelContent({
    required this.tab,
    required this.errorOwner,
    required this.initialEmail,
    required this.onTabChanged,
    required this.onSubmitStarted,
    required this.switchDuration,
  });

  final AuthTab tab;
  final AuthTab? errorOwner;
  final String? initialEmail;
  final ValueChanged<AuthTab> onTabChanged;
  final ValueChanged<AuthTab> onSubmitStarted;
  final Duration switchDuration;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Tabs stay pinned at the top of the panel.
        _PanelGreeting(tab: tab, duration: switchDuration),
        const SizedBox(height: 14),
        AuthModeTabs(selected: tab, onChanged: onTabChanged),
        const SizedBox(height: 22),

        // Flexible + a scroll view: the panel hugs the form while it fits and
        // scrolls *inside itself* once it does not. The page never scrolls.
        Flexible(
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: AnimatedSize(
              duration: switchDuration,
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: AnimatedSwitcher(
                duration: switchDuration,
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                // The default layout centres children, which fights AnimatedSize
                // while the two forms differ in height; align to the top instead.
                layoutBuilder: (currentChild, previousChildren) => Stack(
                  alignment: Alignment.topCenter,
                  children: [...previousChildren, ?currentChild],
                ),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.035),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                ),
                child: switch (tab) {
                  AuthTab.signIn => SignInForm(
                    key: const ValueKey(AuthTab.signIn),
                    initialEmail: initialEmail,
                    showErrors: errorOwner == AuthTab.signIn,
                    onSubmitStarted: () => onSubmitStarted(AuthTab.signIn),
                  ),
                  AuthTab.register => RegisterForm(
                    key: const ValueKey(AuthTab.register),
                    showErrors: errorOwner == AuthTab.register,
                    onSubmitStarted: () => onSubmitStarted(AuthTab.register),
                  ),
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Headline at the top of the panel; it changes with the selected tab.
///
/// Returning students are welcomed back; on the register tab the copy greets
/// someone new to the platform instead.
class _PanelGreeting extends StatelessWidget {
  const _PanelGreeting({required this.tab, required this.duration});

  final AuthTab tab;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final strings = AppStrings.of(context);
    final isSignIn = tab == AuthTab.signIn;

    final titleStyle = TextStyle(
      fontFamily: 'Tajawal',
      fontSize: 27,
      fontWeight: FontWeight.w700,
      height: 1.25,
      letterSpacing: strings.isEnglish ? -0.4 : 0,
      // In dark mode `primary` is itself gold, which would swallow the gold
      // accent word; ivory keeps the two-tone headline.
      color: Theme.of(context).brightness == Brightness.dark
          ? colors.text
          : colors.primary,
    );

    final Widget content = isSignIn
        ? Text.rich(
            TextSpan(
              children: [
                TextSpan(text: strings.isEnglish ? 'Welcome ' : 'أهلاً '),
                TextSpan(
                  text: strings.isEnglish ? 'back' : 'بعودتك',
                  style: TextStyle(color: colors.darkGold),
                ),
              ],
            ),
            textAlign: TextAlign.center,
            style: titleStyle,
          )
        : Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: strings.isEnglish ? 'Welcome to ' : 'مرحباً بك في ',
                    ),
                    TextSpan(
                      text: strings.isEnglish ? 'RSHD' : 'رشد',
                      style: TextStyle(color: colors.darkGold),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
                style: titleStyle,
              ),
              const SizedBox(height: 6),
              Text(
                strings.registerGreetingSubtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                  color: colors.textMuted,
                ),
              ),
            ],
          );

    return AnimatedSize(
      duration: duration,
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(
        duration: duration,
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        layoutBuilder: (current, previous) => Stack(
          alignment: Alignment.topCenter,
          children: [...previous, ?current],
        ),
        transitionBuilder: (child, animation) =>
            FadeTransition(opacity: animation, child: child),
        child: KeyedSubtree(
          key: ValueKey(tab),
          child: SizedBox(width: double.infinity, child: content),
        ),
      ),
    );
  }
}
