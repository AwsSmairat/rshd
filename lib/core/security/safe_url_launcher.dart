import 'package:url_launcher/url_launcher.dart';

import 'safe_external_url.dart';

/// Launches external URLs only when scheme/host policy allows it.
class SafeUrlLauncher {
  SafeUrlLauncher._();

  static Future<bool> launch(
    Uri uri, {
    LaunchMode mode = LaunchMode.platformDefault,
    bool allowHttp = false,
  }) async {
    if (!SafeExternalUrl.isLaunchAllowed(uri, allowHttp: allowHttp)) {
      return false;
    }

    if (!await canLaunchUrl(uri)) {
      return false;
    }

    return launchUrl(uri, mode: mode);
  }
}
