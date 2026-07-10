import 'package:dio/dio.dart';

import '../../log/app_log.dart';
import '../network_log_config.dart';

class AppLogInterceptor extends Interceptor {
  AppLogInterceptor({
    NetworkLogConfig config = const NetworkLogConfig(),
    bool? logRequestBody,
    bool? logResponseBody,
  }) : config = NetworkLogConfig(
         logRequest: config.logRequest,
         logRequestHeaders: config.logRequestHeaders,
         logRequestBody: logRequestBody ?? config.logRequestBody,
         logResponse: config.logResponse,
         logResponseBody: logResponseBody ?? config.logResponseBody,
         logError: config.logError,
         logErrorResponseBody: config.logErrorResponseBody,
         chunkSize: config.chunkSize,
         requestFormatter: config.requestFormatter,
         responseFormatter: config.responseFormatter,
         errorFormatter: config.errorFormatter,
       );

  final NetworkLogConfig config;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (config.logRequest) {
      _logChunks(
        config.requestFormatter?.call(options) ?? _formatRequest(options),
        AppLog.d,
      );
    }
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    if (config.logResponse) {
      _logChunks(
        config.responseFormatter?.call(response) ?? _formatResponse(response),
        AppLog.d,
      );
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (config.logError) {
      _logChunks(
        config.errorFormatter?.call(err) ?? _formatError(err),
        AppLog.w,
      );
    }
    handler.next(err);
  }

  String _formatRequest(RequestOptions options) {
    return '──> ${options.method} ${options.uri}'
        '${config.logRequestHeaders ? '\nheaders: ${options.headers}' : ''}'
        '${config.logRequestBody && options.data != null ? '\nbody: ${options.data}' : ''}';
  }

  String _formatResponse(Response<dynamic> response) {
    final opts = response.requestOptions;
    return '<── ${response.statusCode} ${opts.method} ${opts.uri}'
        '${config.logResponseBody ? '\ndata: ${response.data}' : ''}';
  }

  String _formatError(DioException err) {
    final opts = err.requestOptions;
    return '<── ERR ${err.response?.statusCode ?? '-'} ${opts.method} ${opts.uri}\n'
        'type: ${err.type}\nmessage: ${err.message}'
        '${config.logErrorResponseBody && err.response?.data != null ? '\ndata: ${err.response?.data}' : ''}';
  }

  void _logChunks(String message, void Function(Object? message) log) {
    final chunkSize = config.chunkSize;
    if (chunkSize == null || chunkSize <= 0 || message.length <= chunkSize) {
      log(message);
      return;
    }

    final total = (message.length / chunkSize).ceil();
    for (var part = 0; part < total; part++) {
      final start = part * chunkSize;
      final end = (start + chunkSize).clamp(0, message.length);
      log(
        '[network-log ${part + 1}/$total]\n'
        '${message.substring(start, end)}',
      );
    }
  }
}
