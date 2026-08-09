import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../data/models/announcement_model.dart';

class AnnouncementImageCarousel extends StatefulWidget {
  const AnnouncementImageCarousel({
    super.key,
    required this.announcements,
    this.leadingAssetPath,
  });

  static const aspectRatio = 2 / 1;

  final List<AnnouncementModel> announcements;
  final String? leadingAssetPath;

  @override
  State<AnnouncementImageCarousel> createState() =>
      _AnnouncementImageCarouselState();
}

class _AnnouncementImageCarouselState extends State<AnnouncementImageCarousel> {
  late final PageController _pageController;
  Timer? _autoPlayTimer;
  int _currentIndex = 0;

  int get _slideCount {
    final leading = widget.leadingAssetPath != null ? 1 : 0;
    return leading + widget.announcements.length;
  }

  bool get _hasLeadingAsset => widget.leadingAssetPath != null;

  bool _isLeadingAssetSlide(int index) => _hasLeadingAsset && index == 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _startAutoPlay();
  }

  @override
  void didUpdateWidget(covariant AnnouncementImageCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.announcements.length != widget.announcements.length ||
        oldWidget.leadingAssetPath != widget.leadingAssetPath) {
      _currentIndex = 0;
      if (_pageController.hasClients) {
        _pageController.jumpToPage(0);
      }
      _restartAutoPlay();
    }
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoPlay() {
    _autoPlayTimer?.cancel();
    if (_slideCount <= 1) {
      return;
    }

    _autoPlayTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || _slideCount <= 1) {
        return;
      }

      _currentIndex = (_currentIndex + 1) % _slideCount;
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentIndex,
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _restartAutoPlay() {
    _autoPlayTimer?.cancel();
    _startAutoPlay();
  }

  AnnouncementModel? _announcementAt(int index) {
    if (_isLeadingAssetSlide(index)) {
      return null;
    }
    final announcementIndex = index - (_hasLeadingAsset ? 1 : 0);
    return widget.announcements[announcementIndex];
  }

  @override
  Widget build(BuildContext context) {
    final slideCount = _slideCount;
    if (slideCount == 0) {
      return const SizedBox.shrink();
    }

    final currentAnnouncement = _announcementAt(_currentIndex);

    return AspectRatio(
      aspectRatio: AnnouncementImageCarousel.aspectRatio,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.accent.withValues(alpha: 0.35)),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            fit: StackFit.expand,
            children: [
              PageView.builder(
                controller: _pageController,
                itemCount: slideCount,
                onPageChanged: (index) {
                  setState(() => _currentIndex = index);
                },
                itemBuilder: (context, index) {
                  if (_isLeadingAssetSlide(index)) {
                    return _AssetCarouselSlide(
                      assetPath: widget.leadingAssetPath!,
                    );
                  }
                  return _CarouselSlide(
                    announcement: widget
                        .announcements[index - (_hasLeadingAsset ? 1 : 0)],
                  );
                },
              ),
              if (currentAnnouncement != null)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _CarouselOverlay(announcement: currentAnnouncement),
                ),
              if (slideCount > 1)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 44,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(slideCount, (index) {
                      final isActive = index == _currentIndex;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: isActive ? 18 : 7,
                        height: 7,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppColors.accent
                              : Colors.white.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      );
                    }),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AssetCarouselSlide extends StatelessWidget {
  const _AssetCarouselSlide({required this.assetPath});

  final String assetPath;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.primary,
      child: Image.asset(
        assetPath,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        alignment: Alignment.center,
        filterQuality: FilterQuality.high,
      ),
    );
  }
}

class _CarouselSlide extends StatelessWidget {
  const _CarouselSlide({required this.announcement});

  final AnnouncementModel announcement;

  @override
  Widget build(BuildContext context) {
    final imageUrl = announcement.resolvedImageUrl;

    return ColoredBox(
      color: AppColors.cardWhite,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (imageUrl != null)
            Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return _PlaceholderSlide(title: announcement.title);
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) {
                  return child;
                }
                return const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.darkGold,
                    strokeWidth: 2,
                  ),
                );
              },
            )
          else
            _PlaceholderSlide(title: announcement.title),
        ],
      ),
    );
  }
}

class _PlaceholderSlide extends StatelessWidget {
  const _PlaceholderSlide({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_outlined,
            size: 42,
            color: AppColors.darkGold.withValues(alpha: 0.8),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: AppTextStyles.subtitle.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _CarouselOverlay extends StatelessWidget {
  const _CarouselOverlay({required this.announcement});

  final AnnouncementModel announcement;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 20, 14, 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            AppColors.primary.withValues(alpha: 0.82),
          ],
        ),
      ),
      child: Text(
        announcement.title,
        style: AppTextStyles.subtitle.copyWith(
          color: AppColors.white,
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
      ),
    );
  }
}
