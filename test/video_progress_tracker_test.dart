import 'package:flutter_test/flutter_test.dart';
import 'package:rshd/features/subjects/services/video_progress_tracker.dart';

void main() {
  test(
    'uses the duration reported by the player and saves on dispose',
    () async {
      final sent = <(int, int)>[];
      final tracker = VideoProgressTracker(
        // The API can report 0, which the screen turns into 1 second.
        durationSeconds: 1,
        onSync:
            ({
              required int currentPositionSeconds,
              required int durationSeconds,
              bool showSuccessMessage = false,
            }) async {
              sent.add((currentPositionSeconds, durationSeconds));
            },
      );

      tracker.durationSeconds = 600;
      tracker.updatePosition(const Duration(seconds: 600), isPlaying: true);
      expect(tracker.completionPercentage, 100);

      await tracker.dispose();
      expect(sent, [(600, 600)]);
    },
  );

  test('a tracker that never played sends nothing', () async {
    var calls = 0;
    final tracker = VideoProgressTracker(
      durationSeconds: 600,
      onSync:
          ({
            required int currentPositionSeconds,
            required int durationSeconds,
            bool showSuccessMessage = false,
          }) async {
            calls++;
          },
    );
    await tracker.dispose();
    expect(calls, 0);
  });
}
