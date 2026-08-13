import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_client.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  static const _pageCount = 3;
  static const _pageDuration = Duration(milliseconds: 300);

  final PageController _pageController = PageController(keepPage: false);
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _markOnboardingCompleted() {
    return ref.read(secureStorageProvider).markOnboardingCompleted();
  }

  Future<void> _skip() async {
    await _markOnboardingCompleted();
    if (!mounted) {
      return;
    }
    context.go(AppRoutes.login);
  }

  Future<void> _start() async {
    await _markOnboardingCompleted();
    if (!mounted) {
      return;
    }
    context.go(AppRoutes.register);
  }

  Future<void> _login() async {
    await _markOnboardingCompleted();
    if (!mounted) {
      return;
    }
    context.go(AppRoutes.login);
  }

  Future<void> _next() async {
    if (_currentPage >= _pageCount - 1) {
      return;
    }

    await _pageController.nextPage(
      duration: _pageDuration,
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentPage == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop || _currentPage == 0) {
          return;
        }

        _pageController.previousPage(
          duration: _pageDuration,
          curve: Curves.easeInOutCubic,
        );
      },
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: PageView(
              controller: _pageController,
              onPageChanged: (page) => setState(() => _currentPage = page),
              children: [
                OnboardingLearningPage(
                  currentPage: _currentPage,
                  onSkip: _skip,
                  onNext: _next,
                ),
                OnboardingStudyToolsPage(
                  currentPage: _currentPage,
                  onSkip: _skip,
                  onNext: _next,
                ),
                OnboardingProgressPage(
                  currentPage: _currentPage,
                  onSkip: _skip,
                  onStart: _start,
                  onLogin: _login,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class OnboardingLearningPage extends StatelessWidget {
  const OnboardingLearningPage({
    super.key,
    required this.currentPage,
    required this.onSkip,
    required this.onNext,
  });

  static const illustrationAsset =
      'assets/images/onboarding/onboarding_learning.png';
  static const logoAsset = 'assets/images/rshd_logo_no_bg.png';

  final int currentPage;
  final VoidCallback onSkip;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 680;
        final horizontalPadding = constraints.maxWidth < 380 ? 20.0 : 28.0;

        return Padding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            compact ? 4 : 8,
            horizontalPadding,
            compact ? 12 : 20,
          ),
          child: Column(
            children: [
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Semantics(
                  button: true,
                  label: 'تخطي صفحات التعريف',
                  child: TextButton(
                    onPressed: onSkip,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      minimumSize: const Size(64, 48),
                      textStyle: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: const Text('تخطي'),
                  ),
                ),
              ),
              SizedBox(height: compact ? 0 : 2),
              ExcludeSemantics(
                child: Image.asset(
                  logoAsset,
                  height: compact ? 62 : 78,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                ),
              ),
              const SizedBox(height: 2),
              const Directionality(
                textDirection: TextDirection.ltr,
                child: Text(
                  'LEARN | ACHIEVE | GROW',
                  maxLines: 1,
                  style: TextStyle(
                    color: AppColors.darkGold,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.15,
                  ),
                ),
              ),
              SizedBox(height: compact ? 8 : 14),
              Text(
                'تعلّم بطريقة أذكى',
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: compact ? 27 : 31,
                  height: 1.16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: compact ? 4 : 7),
              Text(
                'دروسك، ملفاتك ومتابعة تقدّمك في مكان واحد.',
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  color: AppColors.secondaryNavy,
                  fontSize: compact ? 15 : 16.5,
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: compact ? 5 : 10),
              Expanded(
                child: Semantics(
                  image: true,
                  label:
                      'طالب يتعلّم باستخدام جهاز لوحي أمام منصة رشد التعليمية',
                  child: _LearningIllustration(
                    asset: illustrationAsset,
                    availableWidth: media.size.width,
                  ),
                ),
              ),
              SizedBox(height: compact ? 5 : 9),
              OnboardingPageIndicator(pageCount: 3, currentPage: currentPage),
              SizedBox(height: compact ? 11 : 18),
              Semantics(
                button: true,
                label: 'الانتقال إلى صفحة التعريف التالية',
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(17),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x2EB88A32),
                          blurRadius: 18,
                          offset: Offset(0, 7),
                        ),
                      ],
                    ),
                    child: FilledButton(
                      onPressed: onNext,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(17),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      child: const Text('التالي'),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class OnboardingStudyToolsPage extends StatelessWidget {
  const OnboardingStudyToolsPage({
    super.key,
    required this.currentPage,
    required this.onSkip,
    required this.onNext,
  });

  static const illustrationAsset =
      'assets/images/onboarding/onboarding_study_tools.png';

  final int currentPage;
  final VoidCallback onSkip;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 680;
        final horizontalPadding = constraints.maxWidth < 380 ? 20.0 : 28.0;
        final allowScroll =
            compact && MediaQuery.textScalerOf(context).scale(1) > 1.15;
        final illustrationHeight = (constraints.maxHeight * 0.42).clamp(
          180.0,
          360.0,
        );

        final header = Column(
          children: [
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Semantics(
                button: true,
                label: 'تخطي المقدمة',
                child: TextButton(
                  onPressed: onSkip,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    minimumSize: const Size(64, 48),
                    textStyle: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: const Text('تخطي'),
                ),
              ),
            ),
            SizedBox(height: compact ? 0 : 2),
            ExcludeSemantics(
              child: Image.asset(
                OnboardingLearningPage.logoAsset,
                height: compact ? 62 : 78,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              ),
            ),
            const SizedBox(height: 2),
            const Directionality(
              textDirection: TextDirection.ltr,
              child: Text(
                'LEARN | ACHIEVE | GROW',
                maxLines: 1,
                style: TextStyle(
                  color: AppColors.darkGold,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.15,
                ),
              ),
            ),
            SizedBox(height: compact ? 8 : 14),
            Text(
              'كل أدواتك للدراسة… بمكان واحد',
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              style: TextStyle(
                color: AppColors.primary,
                fontSize: compact ? 26 : 30,
                height: 1.18,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: compact ? 4 : 7),
            Text(
              'شاهد، اقرأ، ظلّل ودوّن ملاحظاتك، وكمّل تعلّمك بالطريقة اللي تناسبك.',
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              style: TextStyle(
                color: AppColors.secondaryNavy,
                fontSize: compact ? 15 : 16.5,
                height: 1.45,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: compact ? 5 : 10),
          ],
        );

        final illustration = allowScroll
            ? SizedBox(
                height: illustrationHeight,
                child: Semantics(
                  image: true,
                  label:
                      'طالب يستخدم أدوات RSHD للدراسة ومشاهدة الدروس وتدوين الملاحظات',
                  child: _StudyToolsIllustration(
                    asset: illustrationAsset,
                    availableWidth: media.size.width,
                  ),
                ),
              )
            : Expanded(
                child: Semantics(
                  image: true,
                  label:
                      'طالب يستخدم أدوات RSHD للدراسة ومشاهدة الدروس وتدوين الملاحظات',
                  child: _StudyToolsIllustration(
                    asset: illustrationAsset,
                    availableWidth: media.size.width,
                  ),
                ),
              );

        return Padding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            compact ? 4 : 8,
            horizontalPadding,
            compact ? 12 : 20,
          ),
          child: Column(
            children: [
              if (allowScroll)
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        header,
                        illustration,
                      ],
                    ),
                  ),
                )
              else ...[
                header,
                illustration,
              ],
              SizedBox(height: compact ? 5 : 9),
              OnboardingPageIndicator(pageCount: 3, currentPage: currentPage),
              SizedBox(height: compact ? 11 : 18),
              Semantics(
                button: true,
                label: 'الانتقال إلى صفحة التعريف التالية',
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(17),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x2EB88A32),
                          blurRadius: 18,
                          offset: Offset(0, 7),
                        ),
                      ],
                    ),
                    child: FilledButton(
                      onPressed: onNext,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(17),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      child: const Text('التالي'),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StudyToolsIllustration extends StatelessWidget {
  const _StudyToolsIllustration({
    required this.asset,
    required this.availableWidth,
  });

  static const _sourceWidth = 1024.0;
  static const _sourceHeight = 682.0;

  final String asset;
  final double availableWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = [
          constraints.maxWidth / _sourceWidth,
          constraints.maxHeight / _sourceHeight,
          availableWidth / _sourceWidth,
        ].reduce((a, b) => a < b ? a : b);
        final width = _sourceWidth * scale;
        final height = _sourceHeight * scale;

        return Center(
          child: SizedBox(
            width: width,
            height: height,
            child: Image.asset(
              asset,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
              gaplessPlayback: true,
            ),
          ),
        );
      },
    );
  }
}

class _LearningIllustration extends StatelessWidget {
  const _LearningIllustration({
    required this.asset,
    required this.availableWidth,
  });

  static const _sourceWidth = 877.0;
  static const _sourceHeight = 794.0;

  final String asset;
  final double availableWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = [
          constraints.maxWidth / _sourceWidth,
          constraints.maxHeight / _sourceHeight,
          availableWidth / _sourceWidth,
        ].reduce((a, b) => a < b ? a : b);
        final width = _sourceWidth * scale;
        final height = _sourceHeight * scale;

        return Center(
          child: SizedBox(
            width: width,
            height: height,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: Image.asset(
                    asset,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                    gaplessPlayback: true,
                  ),
                ),
                _IllustrationBadgeLabel(
                  text: 'محاضرات',
                  left: 0,
                  top: 139 * scale,
                  width: 180 * scale,
                ),
                _IllustrationBadgeLabel(
                  text: 'ملفات تعليمية',
                  left: 0,
                  top: 319 * scale,
                  width: 190 * scale,
                ),
                _IllustrationBadgeLabel(
                  text: 'واجبات',
                  left: 697 * scale,
                  top: 205 * scale,
                  width: 180 * scale,
                ),
                _IllustrationBadgeLabel(
                  text: 'اختبارات\nودرجات',
                  left: 697 * scale,
                  top: 405 * scale,
                  width: 180 * scale,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _IllustrationBadgeLabel extends StatelessWidget {
  const _IllustrationBadgeLabel({
    required this.text,
    required this.left,
    required this.top,
    required this.width,
  });

  final String text;
  final double left;
  final double top;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      top: top,
      width: width,
      child: Text(
        text,
        maxLines: 2,
        textAlign: TextAlign.center,
        textDirection: TextDirection.rtl,
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 12,
          height: 1.1,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class OnboardingPageIndicator extends StatelessWidget {
  const OnboardingPageIndicator({
    super.key,
    required this.pageCount,
    required this.currentPage,
  });

  final int pageCount;
  final int currentPage;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'صفحة ${currentPage + 1} من $pageCount',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        textDirection: TextDirection.ltr,
        children: List.generate(pageCount, (index) {
          final active = index == currentPage;
          return AnimatedContainer(
            key: ValueKey('onboarding-indicator-$index'),
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.symmetric(horizontal: 5),
            width: active ? 13 : 11,
            height: active ? 13 : 11,
            decoration: BoxDecoration(
              color: active ? AppColors.accent : Colors.transparent,
              shape: BoxShape.circle,
              border: active
                  ? null
                  : Border.all(color: AppColors.secondary, width: 1.25),
            ),
          );
        }),
      ),
    );
  }
}

class OnboardingProgressPage extends StatelessWidget {
  const OnboardingProgressPage({
    super.key,
    required this.currentPage,
    required this.onSkip,
    required this.onStart,
    required this.onLogin,
  });

  static const illustrationAsset =
      'assets/images/onboarding/onboarding_progress_success.png';

  final int currentPage;
  final VoidCallback onSkip;
  final VoidCallback onStart;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 680;
        final horizontalPadding = constraints.maxWidth < 380 ? 20.0 : 28.0;
        final allowScroll =
            compact && MediaQuery.textScalerOf(context).scale(1) > 1.15;
        final illustrationHeight = (constraints.maxHeight * 0.44).clamp(
          170.0,
          360.0,
        );

        final header = Column(
          children: [
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Semantics(
                button: true,
                label: 'تخطي المقدمة',
                child: TextButton(
                  onPressed: onSkip,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    minimumSize: const Size(64, 48),
                    textStyle: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: const Text('تخطي'),
                ),
              ),
            ),
            SizedBox(height: compact ? 0 : 2),
            ExcludeSemantics(
              child: Image.asset(
                OnboardingLearningPage.logoAsset,
                height: compact ? 62 : 78,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              ),
            ),
            const SizedBox(height: 2),
            const Directionality(
              textDirection: TextDirection.ltr,
              child: Text(
                'LEARN | ACHIEVE | GROW',
                maxLines: 1,
                style: TextStyle(
                  color: AppColors.darkGold,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.15,
                ),
              ),
            ),
            SizedBox(height: compact ? 8 : 14),
            Text(
              'تقدّمك قدامك… وهدفك أقرب',
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              style: TextStyle(
                color: AppColors.primary,
                fontSize: compact ? 26 : 30,
                height: 1.18,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: compact ? 4 : 7),
            Text(
              'تابع إنجازك، اختباراتك ودرجاتك، وخليك دائمًا عارف وين وصلت.',
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              style: TextStyle(
                color: AppColors.secondaryNavy,
                fontSize: compact ? 15 : 16.5,
                height: 1.45,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: compact ? 5 : 10),
          ],
        );

        final illustration = allowScroll
            ? SizedBox(
                height: illustrationHeight,
                child: Semantics(
                  image: true,
                  label:
                      'طالب يتابع تقدمه الدراسي وإنجازاته في RSHD',
                  child: _ProgressIllustration(
                    asset: illustrationAsset,
                    availableWidth: media.size.width,
                  ),
                ),
              )
            : Expanded(
                child: Semantics(
                  image: true,
                  label:
                      'طالب يتابع تقدمه الدراسي وإنجازاته في RSHD',
                  child: _ProgressIllustration(
                    asset: illustrationAsset,
                    availableWidth: media.size.width,
                  ),
                ),
              );

        return Padding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            compact ? 4 : 8,
            horizontalPadding,
            compact ? 12 : 20,
          ),
          child: Column(
            children: [
              if (allowScroll)
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        header,
                        illustration,
                      ],
                    ),
                  ),
                )
              else ...[
                header,
                illustration,
              ],
              SizedBox(height: compact ? 5 : 9),
              OnboardingPageIndicator(pageCount: 3, currentPage: currentPage),
              SizedBox(height: compact ? 11 : 16),
              Semantics(
                button: true,
                label: 'ابدأ الآن',
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(17),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x2EB88A32),
                          blurRadius: 18,
                          offset: Offset(0, 7),
                        ),
                      ],
                    ),
                    child: FilledButton(
                      onPressed: onStart,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(17),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      child: const Text('ابدأ الآن'),
                    ),
                  ),
                ),
              ),
              SizedBox(height: compact ? 6 : 10),
              Semantics(
                button: true,
                label: 'تسجيل الدخول',
                child: TextButton(
                  onPressed: onLogin,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.secondaryNavy,
                    minimumSize: const Size(64, 44),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        'لديك حساب؟ ',
                        style: TextStyle(
                          fontSize: compact ? 14 : 15,
                          color: AppColors.textMuted.withValues(alpha: 0.95),
                        ),
                      ),
                      const Text(
                        'تسجيل الدخول',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.darkGold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ProgressIllustration extends StatelessWidget {
  const _ProgressIllustration({
    required this.asset,
    required this.availableWidth,
  });

  static const _sourceWidth = 1024.0;
  static const _sourceHeight = 682.0;

  final String asset;
  final double availableWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = [
          constraints.maxWidth / _sourceWidth,
          constraints.maxHeight / _sourceHeight,
          availableWidth / _sourceWidth,
        ].reduce((a, b) => a < b ? a : b);
        final width = _sourceWidth * scale;
        final height = _sourceHeight * scale;

        return Center(
          child: SizedBox(
            width: width,
            height: height,
            child: Image.asset(
              asset,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
              gaplessPlayback: true,
            ),
          ),
        );
      },
    );
  }
}
