import 'package:flutter_test/flutter_test.dart';

import 'package:rshd/core/preferences/app_display_preferences.dart';
import 'package:rshd/features/subjects/utils/playback_url_preferences.dart';

void main() {
  test('maps font preference to a visible text scale', () {
    expect(const AppDisplayPreferences(fontSize: 'small').textScale, 0.88);
    expect(const AppDisplayPreferences().textScale, 1.0);
    expect(const AppDisplayPreferences(fontSize: 'large').textScale, 1.18);
    expect(
      const AppDisplayPreferences(fontSize: 'large').resolvedTextScale(2.0),
      1.5,
    );
  });

  test('applies autoplay and quality to an embed playback url', () {
    final url = playbackUrlWithPreferences(
      'https://iframe.mediadelivery.net/embed/1/abc',
      autoPlay: true,
      rememberPosition: true,
      quality: 'high',
    );

    final uri = Uri.parse(url);
    expect(uri.queryParameters['autoplay'], 'true');
    expect(uri.queryParameters['rememberPosition'], 'true');
    expect(uri.queryParameters['resolution'], '720p');
  });

  test('clears rememberPosition when saving watch progress is off', () {
    final url = playbackUrlWithPreferences(
      'https://iframe.mediadelivery.net/embed/1/abc?rememberPosition=true',
      autoPlay: false,
      rememberPosition: false,
    );

    final uri = Uri.parse(url);
    expect(uri.queryParameters['autoplay'], 'false');
    expect(uri.queryParameters.containsKey('rememberPosition'), isFalse);
  });
}
