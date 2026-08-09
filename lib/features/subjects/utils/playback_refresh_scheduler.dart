/// When playback should be refreshed relative to signed URL expiry.
Duration? playbackRefreshDelay(
  DateTime? expiresAt, {
  DateTime? now,
  Duration leadTime = const Duration(seconds: 60),
}) {
  if (expiresAt == null) {
    return null;
  }

  final refreshAt = expiresAt.subtract(leadTime);
  final delay = refreshAt.difference(now ?? DateTime.now());

  if (delay.isNegative) {
    return Duration.zero;
  }

  return delay;
}
