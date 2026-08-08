import 'package:flutter_test/flutter_test.dart';

import 'package:rshd/features/subjects/utils/playback_refresh_scheduler.dart';

void main() {
  group('playbackRefreshDelay', () {
    test('returns 60 seconds before expiry for ttl=120', () {
      final now = DateTime.utc(2026, 8, 8, 12, 0, 0);
      final expiry = now.add(const Duration(seconds: 120));

      final delay = playbackRefreshDelay(expiry, now: now);

      expect(delay, const Duration(seconds: 60));
    });

    test('returns zero when refresh window already passed', () {
      final now = DateTime.utc(2026, 8, 8, 12, 0, 0);
      final expiry = now.add(const Duration(seconds: 30));

      final delay = playbackRefreshDelay(expiry, now: now);

      expect(delay, Duration.zero);
    });

    test('returns null when expiry is missing', () {
      expect(playbackRefreshDelay(null), isNull);
    });
  });
}
