import 'package:dio/dio.dart';

import '../../log/app_log.dart';

/// 简单的指数退避重试，针对超时 / 连接错误。
class RetryInterceptor extends Interceptor {
  RetryInterceptor({
    required this.dio,
    this.maxRetries = 2,
    this.initialDelay = const Duration(milliseconds: 500),
  });

  final Dio dio;
  final int maxRetries;
  final Duration initialDelay;

  static const _retryCountKey = '_app_scaffold_retry_count';

  bool _shouldRetry(DioException err) {
    return err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError;
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final opts = err.requestOptions;
    final retried = (opts.extra[_retryCountKey] as int?) ?? 0;

    if (!_shouldRetry(err) || retried >= maxRetries) {
      return handler.next(err);
    }

    final next = retried + 1;
    final delay = initialDelay * (1 << retried);
    AppLog.w('retry $next/$maxRetries after $delay → ${opts.uri}');
    await Future<void>.delayed(delay);

    opts.extra[_retryCountKey] = next;
    try {
      final response = await dio.fetch<dynamic>(opts);
      handler.resolve(response);
    } on DioException catch (e) {
      handler.next(e);
    }
  }
}
