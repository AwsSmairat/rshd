/// Applies student playback preferences to a signed or embed video URL.
String playbackUrlWithPreferences(
  String url, {
  required bool autoPlay,
  required bool rememberPosition,
  String quality = 'auto',
}) {
  final uri = Uri.tryParse(url);
  if (uri == null || !uri.hasScheme) {
    return url;
  }

  final params = Map<String, String>.from(uri.queryParameters);
  params['autoplay'] = autoPlay ? 'true' : 'false';
  params['preload'] = 'true';
  if (rememberPosition) {
    params['rememberPosition'] = 'true';
  } else {
    params.remove('rememberPosition');
  }

  switch (quality) {
    case 'low':
      params['resolution'] = '360p';
    case 'medium':
      params['resolution'] = '480p';
    case 'high':
      params['resolution'] = '720p';
    default:
      params.remove('resolution');
  }

  return uri.replace(queryParameters: params).toString();
}
