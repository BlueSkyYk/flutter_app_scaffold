import 'dart:async';

import 'package:dio/dio.dart';

/// token 注入 + 401 兜底。具体 token 来源由调用方提供。
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required this.tokenProvider,
    this.headerName = 'Authorization',
    this.tokenScheme = 'Bearer',
    this.onUnauthorized,
  });

  /// 异步取 token；返回 null 表示未登录，不注入。
  final FutureOr<String?> Function() tokenProvider;
  final String headerName;
  final String tokenScheme;

  /// 收到 401 时的回调，可在此跳转登录页 / 触发刷新 token。
  final FutureOr<void> Function()? onUnauthorized;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await tokenProvider();
    if (token != null && token.isNotEmpty) {
      options.headers[headerName] =
          tokenScheme.isEmpty ? token : '$tokenScheme $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      await onUnauthorized?.call();
    }
    handler.next(err);
  }
}
