import '../../../core/network/api_exception.dart';

/// Privacy and terms should stay readable even when the API has no published
/// document (404) or the server is unreachable.
bool shouldUseLegalLocalFallback(ApiException error) {
  final code = error.statusCode;
  return code != 401 && code != 403;
}
