import 'package:dio/dio.dart';

import '../../log/app_log.dart';

/// 简单的指数退避重试，针对超时 / 连接错误。
///
/// 注意：[dio] 必须是发起原请求的同一个 [Dio] 实例（即 `DioClient.raw`），
/// 否则重试请求会绕过 `DioClient` 上注册的其它拦截器（如 `AuthInterceptor`）。
/// 推荐通过 `DioClient.enableRetry(...)` 启用，以避免传错实例。
class RetryInterceptor extends Interceptor {
  RetryInterceptor({
    required this.dio,
    this.maxRetries = 2,
    this.initialDelay = const Duration(milliseconds: 500),
  });

  /// 用于重发请求的 dio 实例，应与原请求所在的 `DioClient.raw` 相同。
  final Dio dio;

  /// 最大重试次数（不含首发）。
  final int maxRetries;

  /// 首次退避时间，第 N 次重试为 `initialDelay * 2^(N-1)`。
  final Duration initialDelay;

  static const _retryCountKey = '_flutter_app_scaffold_retry_count';

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
