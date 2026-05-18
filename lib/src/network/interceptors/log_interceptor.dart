import 'package:dio/dio.dart';

import '../../log/app_log.dart';

class AppLogInterceptor extends Interceptor {
  AppLogInterceptor({this.logRequestBody = true, this.logResponseBody = true});

  final bool logRequestBody;
  final bool logResponseBody;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    AppLog.d(
      '──> ${options.method} ${options.uri}\n'
      'headers: ${options.headers}'
      '${logRequestBody && options.data != null ? '\nbody: ${options.data}' : ''}',
    );
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    final opts = response.requestOptions;
    AppLog.d(
      '<── ${response.statusCode} ${opts.method} ${opts.uri}'
      '${logResponseBody ? '\ndata: ${response.data}' : ''}',
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final opts = err.requestOptions;
    AppLog.w(
      '<── ERR ${err.response?.statusCode ?? '-'} ${opts.method} ${opts.uri}\n'
      'type: ${err.type}\nmessage: ${err.message}',
    );
    handler.next(err);
  }
}
