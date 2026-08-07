import 'package:flutter_test/flutter_test.dart';

import 'package:rshd/features/subjects/data/models/video_model.dart';
import 'package:rshd/features/subjects/presentation/subjects_controller.dart';
import 'package:rshd/core/network/api_exception.dart';

void main() {
  group('VideoPlaybackModel', () {
    test('parses playback url and expiry', () {
      final playback = VideoPlaybackModel.fromJson({
        'url': 'https://example.com/stream?token=abc',
        'expires_at': '2026-08-07T12:00:00.000000Z',
      });

      expect(playback.url, contains('token=abc'));
      expect(playback.expiresAt, isNotNull);
      expect(playback.type, 'hls');
    });

    test('parses embed playback type', () {
      final playback = VideoPlaybackModel.fromJson({
        'url': 'https://iframe.mediadelivery.net/embed/123/guid?autoplay=true',
        'expires_at': '2026-08-07T12:00:00.000000Z',
        'type': 'embed',
      });

      expect(playback.isEmbed, isTrue);
      expect(playback.url, contains('iframe.mediadelivery.net'));
    });

    test('detects expired playback', () {
      final playback = VideoPlaybackModel(
        url: 'https://example.com/stream',
        expiresAt: DateTime.now().subtract(const Duration(minutes: 1)),
      );

      expect(playback.isExpired, isTrue);
      expect(playback.shouldRefreshSoon, isTrue);
    });
  });

  group('VideoModel', () {
    test('parses secure playback response without permanent url', () {
      final video = VideoModel.fromJson({
        'id': 15,
        'lesson_id': 3,
        'title': 'درس 1',
        'duration_seconds': 300,
        'status': 'ready',
        'is_free': false,
        'is_locked': false,
        'playback': {
          'url': 'https://api.test/api/v1/videos/15/stream?token=signed',
          'expires_at': DateTime.now()
              .add(const Duration(minutes: 10))
              .toIso8601String(),
        },
      });

      expect(video.canPlay, isTrue);
      expect(video.playback?.url, contains('/stream'));
    });

    test('locked video has no playable url', () {
      final video = VideoModel.fromJson({
        'id': 15,
        'lesson_id': 3,
        'title': 'درس 1',
        'is_locked': true,
        'playback': null,
      });

      expect(video.canPlay, isFalse);
    });

    test('copyWith keeps playback in memory only through model updates', () {
      const video = VideoModel(
        id: 1,
        lessonId: 2,
        title: 'Test',
        playback: VideoPlaybackModel(url: 'https://old.example/stream'),
      );

      final refreshed = video.copyWith(
        playback: const VideoPlaybackModel(url: 'https://new.example/stream'),
      );

      expect(refreshed.playback?.url, contains('new.example'));
    });
  });

  group('mapContentError', () {
    test('returns enrollment message for forbidden video access', () {
      final message = mapContentError(
        ApiException(message: 'Forbidden', statusCode: 403),
        videoContext: true,
      );

      expect(message, contains('انتهت صلاحية الوصول'));
    });
  });
}
