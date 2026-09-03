import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rshd/features/subjects/playback/floating_playback_controller.dart';

void main() {
  test('clamps the mini player inside the visible screen', () {
    final offset = clampFloatingOffset(
      offset: const Offset(-40, 900),
      screenSize: const Size(390, 844),
      playerSize: const Size(196, 146),
      padding: const EdgeInsets.fromLTRB(0, 47, 0, 34),
    );

    expect(offset.dx, 0);
    expect(offset.dy, lessThanOrEqualTo(844 - 146));
    expect(offset.dy, greaterThanOrEqualTo(47));
  });

  test('places the default mini player above the bottom safe area', () {
    final offset = defaultFloatingOffset(
      screenSize: const Size(390, 844),
      playerSize: const Size(196, 146),
      padding: const EdgeInsets.fromLTRB(0, 47, 0, 34),
    );

    expect(offset.dx, 12);
    expect(offset.dy, 844 - 146 - 34 - 24);
  });

  test('mini player size keeps a 16:9 video under the control bar', () {
    final size = floatingMiniPlayerSize(16 / 9);
    expect(size.width, floatingMiniPlayerWidth);
    expect(size.height, closeTo(floatingMiniPlayerWidth * 9 / 16, 0.01));
  });

  test('session copyWith can mark playback as minimized', () {
    const session = FloatingPlaybackSession(
      videoId: 7,
      title: 'درس',
      playbackUrl: 'https://example.com/video.m3u8',
      usesEmbed: false,
    );

    expect(session.minimized, isFalse);
    expect(session.copyWith(minimized: true).minimized, isTrue);
  });
}
