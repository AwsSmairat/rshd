import 'package:dio/dio.dart';

import '../security/sensitive_data_redactor.dart';

/// Debug-only network logger that redacts tokens and signed URL parameters.
class RedactedLogInterceptor extends Interceptor {
  RedactedLogInterceptor({this.logPrint = print});

  final void Function(Object object) logPrint;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    logPrint('[DIO] --> ${options.method} ${_redactUrl(options.uri)}');
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    logPrint(
      '[DIO] <-- ${response.statusCode} ${_redactUrl(response.requestOptions.uri)}',
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    logPrint(
      '[DIO] xx ${err.response?.statusCode ?? 'ERR'} ${_redactUrl(err.requestOptions.uri)}',
    );
    handler.next(err);
  }

  String _redactUrl(Uri uri) {
    return SensitiveDataRedactor.redactString(uri.toString());
  }
}
