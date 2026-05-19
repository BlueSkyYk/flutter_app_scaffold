import 'dart:async';

import 'package:dio/dio.dart';

/// token 注入 + 401 兜底 + 可选的刷新-重试。
///
/// 行为：
/// 1. `onRequest`：调用 [tokenProvider] 拿当前 token，按 [headerName] / [tokenScheme] 注入。
/// 2. `onError`：命中 [shouldRefresh]（默认 `statusCode == 401`）后：
///    - 若未配置 [refreshToken]：直接走 [onUnauthorized]，把错误抛回。
///    - 若已配置 [refreshToken]：调用刷新（并发 401 共用同一次刷新），成功后用新 token
///      重发原请求并 `handler.resolve`；失败则走 [onUnauthorized] 抛回原错误。
///
/// [refreshToken] 回调内需要自行持久化新 token（比如写入业务侧的 secure storage），
/// 让下一次 [tokenProvider] 调用能取到最新值——拦截器本身不关心存储。
///
/// 推荐通过 `DioClient.enableAuth(...)` 启用，会自动把 [Dio] 实例绑定好。
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required this.tokenProvider,
    this.refreshToken,
    this.dio,
    this.shouldRefresh,
    this.headerName = 'Authorization',
    this.tokenScheme = 'Bearer',
    this.onUnauthorized,
  }) : assert(
          refreshToken == null || dio != null,
          'AuthInterceptor: 提供 refreshToken 时必须同时提供发起原请求的 dio 实例',
        );

  /// 异步取当前 token；返回 null 表示未登录，不注入。
  final FutureOr<String?> Function() tokenProvider;

  /// 刷新 token 回调。返回新 token；返回 null / 抛异常视为刷新失败。
  /// 业务实现内需把新 token 持久化，使 [tokenProvider] 下次返回新值。
  ///
  /// 注意：回调内部如果用同一个 `DioClient` 调刷新接口，刷新接口本身不应再走
  /// 401 → refresh 的循环（拦截器已用 `extra` 标记防止"重发后又 401"二次刷新，
  /// 但请确保刷新接口在服务端正常返回 401 时业务能区分"refresh token 也失效"）。
  final FutureOr<String?> Function()? refreshToken;

  /// 用于重发原请求的 dio 实例，应与原请求所在的 `DioClient.raw` 相同。
  /// 仅当配置 [refreshToken] 时必填。
  final Dio? dio;

  /// 自定义"何时尝试刷新"。默认：响应 status code 为 401。
  final bool Function(DioException err)? shouldRefresh;

  final String headerName;
  final String tokenScheme;

  /// 鉴权失败（无 refreshToken / 刷新失败 / 重发仍失败）时的回调，
  /// 一般用于跳登录页、清理本地登录态。
  final FutureOr<void> Function()? onUnauthorized;

  static const _retriedKey = '_flutter_app_scaffold_auth_retried';

  /// 单飞锁：并发请求同时遇到 401 时共用同一次刷新结果。
  Future<String?>? _refreshing;

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
    final isAuthError =
        shouldRefresh?.call(err) ?? err.response?.statusCode == 401;
    final alreadyRetried = err.requestOptions.extra[_retriedKey] == true;
    final canRefresh =
        isAuthError && refreshToken != null && dio != null && !alreadyRetried;

    if (!canRefresh) {
      if (isAuthError) await onUnauthorized?.call();
      return handler.next(err);
    }

    String? newToken;
    try {
      newToken = await (_refreshing ??= _runRefresh());
    } on Object {
      // 刷新本身抛异常，按未授权处理。
    }

    if (newToken == null || newToken.isEmpty) {
      await onUnauthorized?.call();
      return handler.next(err);
    }

    final opts = err.requestOptions
      ..headers[headerName] =
          tokenScheme.isEmpty ? newToken : '$tokenScheme $newToken'
      ..extra[_retriedKey] = true;

    try {
      final response = await dio!.fetch<dynamic>(opts);
      handler.resolve(response);
    } on DioException catch (e) {
      // 重发仍失败：若仍是 401，认为新 token 也无效，触发未授权。
      if (shouldRefresh?.call(e) ?? e.response?.statusCode == 401) {
        await onUnauthorized?.call();
      }
      handler.next(e);
    }
  }

  Future<String?> _runRefresh() async {
    try {
      return await refreshToken!();
    } finally {
      _refreshing = null;
    }
  }
}
