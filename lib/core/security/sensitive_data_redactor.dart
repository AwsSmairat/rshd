/// Redacts sensitive values before debug logging in Flutter.
class SensitiveDataRedactor {
  SensitiveDataRedactor._();

  static const _sensitiveKeys = [
    'authorization',
    'password',
    'secret',
    'token',
    'accesskey',
    'access_key',
    'signature',
    'cookie',
    'otp',
    'bearer',
    'refresh_token',
  ];

  static String redactString(String? value) {
    if (value == null || value.isEmpty) return value ?? '';

    var redacted = value;

    redacted = redacted.replaceAllMapped(
      RegExp(r'\bBearer\s+\S+', caseSensitive: false),
      (_) => 'Bearer [REDACTED]',
    );

    for (final key in _sensitiveKeys) {
      redacted = redacted.replaceAllMapped(
        RegExp('($key\\s*[=:]\\s*)(\\S+)', caseSensitive: false),
        (match) => '${match.group(1)}[REDACTED]',
      );
    }

    redacted = redacted.replaceAllMapped(
      RegExp(
        r'([?&](?:token|signature|expires|accesskey|access_key)=)[^&\s"]+',
        caseSensitive: false,
      ),
      (match) => '${match.group(1)}[REDACTED]',
    );

    return redacted;
  }

  static Object? redactValue(Object? value) {
    if (value is String) return redactString(value);
    return value;
  }
}
