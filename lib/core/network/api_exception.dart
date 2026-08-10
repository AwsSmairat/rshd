class ApiException implements Exception {
  ApiException({
    required this.message,
    this.statusCode,
    this.errors,
    this.data,
    this.errorCode,
  });

  final String message;
  final int? statusCode;
  final Map<String, dynamic>? errors;
  final Map<String, dynamic>? data;
  final String? errorCode;

  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isValidationError => statusCode == 422;

  bool get isDeviceMismatch => errorCode == 'device_mismatch';

  bool get requiresEmailVerification =>
      data?['requires_email_verification'] == true;

  String? get responseEmail => data?['email']?.toString();

  List<String> get fieldErrors {
    if (errors == null || errors!.isEmpty) {
      return const [];
    }

    final messages = <String>[];
    for (final entry in errors!.entries) {
      final value = entry.value;
      if (value is List) {
        for (final item in value) {
          messages.add(item.toString());
        }
      } else if (value != null) {
        messages.add(value.toString());
      }
    }
    return messages;
  }

  String? firstFieldError(String field) {
    final value = errors?[field];
    if (value is List && value.isNotEmpty) {
      return value.first.toString();
    }
    if (value != null) {
      return value.toString();
    }
    return null;
  }

  @override
  String toString() => 'ApiException($statusCode): $message';
}
