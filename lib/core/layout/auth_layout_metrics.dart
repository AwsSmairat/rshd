import 'package:flutter/material.dart';

import 'app_layout_metrics.dart';

/// Auth-specific sizing built on top of [AppLayoutMetrics].
class AuthLayoutMetrics {
  const AuthLayoutMetrics._(this._base);

  factory AuthLayoutMetrics.of(BuildContext context) {
    return AuthLayoutMetrics._(AppLayoutMetrics.of(context));
  }

  final AppLayoutMetrics _base;

  Size get size => _base.size;

  EdgeInsets get padding => _base.padding;

  double get shortestSide => _base.shortestSide;

  bool get isTablet => _base.isTablet;

  bool get isLargeTablet => _base.isLargeTablet;

  double get contentMaxWidth => _base.contentMaxWidth;

  double get shellHorizontalPadding {
    if (!isTablet) {
      return 0;
    }
    return isLargeTablet ? 48 : 32;
  }

  double get cardHorizontalPadding => isLargeTablet ? 12 : isTablet ? 8 : 20;

  double get cardInnerPadding => isLargeTablet ? 32 : isTablet ? 26 : 22;

  double get cardVerticalPadding => isLargeTablet ? 28 : isTablet ? 24 : 24;

  double get headerLogoHeight => isLargeTablet ? 160 : isTablet ? 140 : 120;

  double get headerTopPadding =>
      padding.top + (isLargeTablet ? 28 : isTablet ? 24 : 20);

  double get headerBottomPadding => isLargeTablet ? 58 : isTablet ? 50 : 44;

  double get headerIconSize => isLargeTablet ? 128 : isTablet ? 118 : 110;

  double get headerBadgeSize => isLargeTablet ? 88 : isTablet ? 80 : 72;

  double get titleFontSize => isLargeTablet ? 26 : isTablet ? 24 : 22;

  double get subtitleFontSize => isLargeTablet ? 15 : isTablet ? 14 : 13;

  double get bottomSpacing => isLargeTablet ? 28 : isTablet ? 22 : 16;

  double get sectionSpacing => isLargeTablet ? 28 : isTablet ? 24 : 22;

  double get fieldSpacing => isLargeTablet ? 20 : isTablet ? 18 : 16;
}
