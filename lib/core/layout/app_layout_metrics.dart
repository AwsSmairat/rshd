import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Responsive layout breakpoints tuned for iPhone and all iPad sizes.
class AppLayoutMetrics {
  const AppLayoutMetrics._({required this.size, required this.padding});

  factory AppLayoutMetrics.of(BuildContext context) {
    return AppLayoutMetrics._(
      size: MediaQuery.sizeOf(context),
      padding: MediaQuery.paddingOf(context),
    );
  }

  final Size size;
  final EdgeInsets padding;

  double get width => size.width;

  double get height => size.height;

  double get shortestSide => size.shortestSide;

  double get longestSide => size.longestSide;

  bool get isPhone => shortestSide < 600;

  bool get isTablet => shortestSide >= 600;

  bool get isLargeTablet => shortestSide >= 768;

  bool get isExtraLargeTablet => shortestSide >= 1024;

  /// Maximum width for page content. Tablets use the whole screen (minus
  /// the page margins); only very wide screens are capped so lines of text
  /// don't stretch across the full width.
  double get contentMaxWidth {
    if (isPhone) {
      return width;
    }
    return math.min(width, 1280);
  }

  /// Columns for image cards (courses): two once the content is wide enough
  /// that a single card would stretch edge to edge.
  int get cardColumns => width - horizontalPadding * 2 >= 880 ? 2 : 1;

  /// Inner padding inside the content column.
  double get horizontalPadding {
    if (isPhone) {
      return 20;
    }
    if (isExtraLargeTablet) {
      return 40;
    }
    if (isLargeTablet) {
      return 32;
    }
    return 28;
  }

  /// Horizontal inset that centers content on tablet screens.
  double get outerHorizontalInset {
    if (isPhone) {
      return horizontalPadding;
    }
    return math.max(horizontalPadding, (width - contentMaxWidth) / 2);
  }

  EdgeInsets pagePadding({double top = 8, double bottom = 32}) {
    return EdgeInsets.fromLTRB(
      outerHorizontalInset,
      top,
      outerHorizontalInset,
      bottom,
    );
  }

  EdgeInsets sectionPadding({double vertical = 0}) {
    return EdgeInsets.fromLTRB(
      outerHorizontalInset,
      vertical,
      outerHorizontalInset,
      vertical,
    );
  }

  double get sectionSpacing => isExtraLargeTablet
      ? 20
      : isLargeTablet
      ? 16
      : isTablet
      ? 14
      : 12;

  int get quickActionColumns => 4;

  double get quickActionCellHeight {
    if (isExtraLargeTablet) {
      return 136;
    }
    if (isLargeTablet) {
      return 128;
    }
    if (isTablet) {
      return 120;
    }
    return 112;
  }

  double get quickActionIconContainerSize {
    if (isExtraLargeTablet) {
      return 64;
    }
    if (isLargeTablet) {
      return 58;
    }
    if (isTablet) {
      return 52;
    }
    return 46;
  }

  double get quickActionIconSize {
    if (isExtraLargeTablet) {
      return 30;
    }
    if (isLargeTablet) {
      return 28;
    }
    if (isTablet) {
      return 26;
    }
    return 24;
  }

  double get quickActionLabelFontSize {
    if (isExtraLargeTablet) {
      return 14;
    }
    if (isLargeTablet) {
      return 13;
    }
    if (isTablet) {
      return 12;
    }
    return 11;
  }

  int get listGridColumns {
    if (isExtraLargeTablet) {
      return 3;
    }
    if (isTablet) {
      return 2;
    }
    return 1;
  }

  int get subjectGridColumns => isExtraLargeTablet
      ? 3
      : isLargeTablet
      ? 2
      : 1;

  bool get useDepartmentRow => isTablet;

  bool get useSubjectGrid => isTablet;

  bool get useDashboardSummaryRow => isTablet || width >= 560;

  double get headerTitleFontSize => isExtraLargeTablet
      ? 30
      : isLargeTablet
      ? 28
      : isTablet
      ? 26
      : 26;

  double get pageHeaderTitleFontSize => isExtraLargeTablet
      ? 24
      : isLargeTablet
      ? 22
      : 20;

  double get sectionTitleFontSize => isTablet ? 20 : 18;

  double get dialogMaxWidth =>
      isTablet ? math.min(520, contentMaxWidth) : width - 48;
}
