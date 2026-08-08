class ScreenProtectionState {
  const ScreenProtectionState({
    this.activeScopeCount = 0,
    this.isScreenCaptured = false,
    this.showPrivacyOverlay = false,
  });

  final int activeScopeCount;
  final bool isScreenCaptured;
  final bool showPrivacyOverlay;

  bool get isProtectionActive => activeScopeCount > 0;

  /// Hide protected pixels while recording/mirroring or in App Switcher.
  bool get shouldHideContent =>
      isProtectionActive && (isScreenCaptured || showPrivacyOverlay);

  ScreenProtectionState copyWith({
    int? activeScopeCount,
    bool? isScreenCaptured,
    bool? showPrivacyOverlay,
  }) {
    return ScreenProtectionState(
      activeScopeCount: activeScopeCount ?? this.activeScopeCount,
      isScreenCaptured: isScreenCaptured ?? this.isScreenCaptured,
      showPrivacyOverlay: showPrivacyOverlay ?? this.showPrivacyOverlay,
    );
  }
}
