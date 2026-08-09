/// Validates external URLs before launching outside the app.
class SafeExternalUrl {
  SafeExternalUrl._();

  static const blockedSchemes = {'javascript', 'file', 'data', 'content'};

  static const allowedSchemes = {'https', 'http', 'mailto', 'tel'};

  static bool isLaunchAllowed(Uri uri, {bool allowHttp = false}) {
    final scheme = uri.scheme.toLowerCase();
    if (scheme.isEmpty || blockedSchemes.contains(scheme)) {
      return false;
    }

    if (scheme == 'http' && !allowHttp) {
      return false;
    }

    return allowedSchemes.contains(scheme);
  }

  static bool isWebViewNavigationAllowed(Uri uri) {
    final scheme = uri.scheme.toLowerCase();
    if (scheme == 'about') {
      return uri.toString() == 'about:blank';
    }

    if (scheme != 'https') {
      return false;
    }

    final host = uri.host.toLowerCase();
    return host.endsWith('mediadelivery.net') ||
        host.endsWith('bunny.net') ||
        host.endsWith('b-cdn.net');
  }
}
