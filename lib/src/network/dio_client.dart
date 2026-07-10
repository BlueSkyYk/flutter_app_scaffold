import 'dart:async';

import 'package:dio/dio.dart';

import '../config/app_config.dart';
import 'api_exception.dart';
import 'api_result.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/log_interceptor.dart';
import 'interceptors/retry_interceptor.dart';
import 'interceptors/ui_feedback_interceptor.dart';
import 'network_log_config.dart';
import 'ui_feedback.dart';

/// dio 封装。提供 [request]/[get]/[post] 等方法，自动把异常映射成 [ApiException]，
/// 并提供基于 [ApiResult] 的 safe-API。
class DioClient {
  DioClient({Dio? dio, AppConfig? config}) {
    final cfg = config ?? AppConfig.I;
    _dio =
        dio ??
        Dio(
          BaseOptions(
            baseUrl: cfg.apiBaseUrl,
            connectTimeout: cfg.connectTimeout,
            receiveTimeout: cfg.receiveTimeout,
            sendTimeout: cfg.sendTimeout,
            contentType: 'application/json; charset=utf-8',
            responseType: ResponseType.json,
          ),
        );
    if (cfg.enableNetworkLog) {
      _dio.interceptors.add(AppLogInterceptor(config: cfg.networkLogConfig));
    }
  }

  late final Dio _dio;

  /// 暴露底层 [Dio] 实例。仅在需要直接操作 dio API（如自定义 Adapter）时使用。
  Dio get raw => _dio;

  /// 追加一个拦截器。注意拦截器顺序：先添加的先处理 request、后处理 response。
  void addInterceptor(Interceptor interceptor) {
    _dio.interceptors.add(interceptor);
  }

  /// 启用网络日志拦截器。
  ///
  /// 构造函数会在 [AppConfig.enableNetworkLog] 为 true 时自动启用一次。
  /// 如果业务需要控制拦截器位置（例如先打印原始响应、再在鉴权后打印最终请求头），
  /// 可以把全局自动开关设为 false，再在合适的位置手动调用本方法。
  void enableNetworkLog({
    bool enabled = true,
    NetworkLogConfig config = const NetworkLogConfig(),
  }) {
    if (!enabled) return;
    addInterceptor(AppLogInterceptor(config: config));
  }

  /// 启用重试拦截器。内部自动绑定到当前 [Dio] 实例，避免外部传错。
  void enableRetry({
    int maxRetries = 2,
    Duration initialDelay = const Duration(milliseconds: 500),
  }) {
    addInterceptor(
      RetryInterceptor(
        dio: _dio,
        maxRetries: maxRetries,
        initialDelay: initialDelay,
      ),
    );
  }

  /// 启用 UI 反馈拦截器：把 loading / 错误 toast 的展示从每个调用点抽走，
  /// 由业务在启动时一次性注入回调。
  ///
  /// 单次请求可用 `Options().ui(loading: true, errorToast: false)` 覆盖默认值，
  /// 或 `Options().silent()` 静默后台请求。
  ///
  /// 推荐添加顺序：先 `enableUiFeedback`，再 `enableAuth` / `enableRetry`，
  /// 这样 UI 反馈位于拦截器链的"外圈"，能正确捕获最终结果（鉴权刷新成功视为成功，
  /// 重试穷尽后视为失败）。
  void enableUiFeedback(UiFeedback feedback) {
    addInterceptor(UiFeedbackInterceptor(feedback));
  }

  /// 启用鉴权拦截器（token 注入 + 401 兜底 + 可选的刷新-重试）。
  ///
  /// - [tokenProvider]：每次请求前异步取当前 token。
  /// - [refreshToken]：（可选）传入即开启"刷新 + 重发原请求"。回调内需把新 token 持久化，
  ///   使 [tokenProvider] 下次能拿到。并发 401 会共用同一次刷新结果。
  /// - [shouldRefresh]：（可选）自定义触发刷新的判断；默认 `statusCode == 401`。
  /// - [onUnauthorized]：（可选）刷新失败 / 未配置 [refreshToken] 时的兜底，常用于跳登录页。
  void enableAuth({
    required FutureOr<String?> Function() tokenProvider,
    FutureOr<String?> Function()? refreshToken,
    bool Function(DioException err)? shouldRefresh,
    FutureOr<void> Function()? onUnauthorized,
    String headerName = 'Authorization',
    String tokenScheme = 'Bearer',
  }) {
    addInterceptor(
      AuthInterceptor(
        tokenProvider: tokenProvider,
        refreshToken: refreshToken,
        dio: refreshToken != null ? _dio : null,
        shouldRefresh: shouldRefresh,
        onUnauthorized: onUnauthorized,
        headerName: headerName,
        tokenScheme: tokenScheme,
      ),
    );
  }

  /// 抛异常版本。失败抛 [ApiException]，由调用方决定是否捕获。
  Future<Response<T>> request<T>(
    String path, {
    String method = 'GET',
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      return await _dio.request<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: (options ?? Options()).copyWith(method: method),
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
    } on DioException catch (e) {
      throw mapDioException(e);
    } on Object catch (e, st) {
      throw ParseException('请求异常: $e', cause: e, stackTrace: st);
    }
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) => request<T>(
    path,
    method: 'GET',
    queryParameters: queryParameters,
    options: options,
  );

  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) => request<T>(
    path,
    method: 'POST',
    data: data,
    queryParameters: queryParameters,
    options: options,
  );

  Future<Response<T>> put<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) => request<T>(
    path,
    method: 'PUT',
    data: data,
    queryParameters: queryParameters,
    options: options,
  );

  Future<Response<T>> delete<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) => request<T>(
    path,
    method: 'DELETE',
    data: data,
    queryParameters: queryParameters,
    options: options,
  );

  /// 安全版本：把成功 / 失败封装到 [ApiResult]。
  Future<ApiResult<T>> safeRequest<T>(
    Future<T> Function(DioClient client) block,
  ) async {
    try {
      final data = await block(this);
      return ApiResult.success(data);
    } on ApiException catch (e) {
      return ApiResult.failure(e);
    } on DioException catch (e) {
      return ApiResult.failure(mapDioException(e));
    } on Object catch (e, st) {
      return ApiResult.failure(
        ParseException('未知错误: $e', cause: e, stackTrace: st),
      );
    }
  }
}
