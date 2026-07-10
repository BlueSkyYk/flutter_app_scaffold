import 'package:dio/dio.dart';

typedef NetworkRequestLogFormatter = String Function(RequestOptions options);
typedef NetworkResponseLogFormatter =
    String Function(Response<dynamic> response);
typedef NetworkErrorLogFormatter = String Function(DioException error);

/// Network logging options used by the app log interceptor.
///
/// Defaults are intentionally useful for development while staying configurable
/// enough for app-specific response envelopes and long payloads.
class NetworkLogConfig {
  const NetworkLogConfig({
    this.logRequest = true,
    this.logRequestHeaders = true,
    this.logRequestBody = true,
    this.logResponse = true,
    this.logResponseBody = true,
    this.logError = true,
    this.logErrorResponseBody = true,
    this.chunkSize = 800,
    this.requestFormatter,
    this.responseFormatter,
    this.errorFormatter,
  });

  final bool logRequest;
  final bool logRequestHeaders;
  final bool logRequestBody;
  final bool logResponse;
  final bool logResponseBody;
  final bool logError;
  final bool logErrorResponseBody;

  /// Splits long log messages. Set to null or <= 0 to disable chunking.
  final int? chunkSize;

  /// Full override for request log formatting.
  final NetworkRequestLogFormatter? requestFormatter;

  /// Full override for response log formatting.
  final NetworkResponseLogFormatter? responseFormatter;

  /// Full override for error log formatting.
  final NetworkErrorLogFormatter? errorFormatter;
}
