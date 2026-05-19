import 'package:dio/dio.dart';

import '../api_exception.dart';
import '../ui_feedback.dart';

/// 把 [UiFeedback] 的回调串到 dio 请求链上的拦截器。
///
/// 行为：
/// - `onRequest`：按生效后的 `showLoading` 维护计数器；0→1 时触发 `onLoadingStart`。
/// - `onResponse`：维护计数器；若 [UiFeedback.detectBusinessError] 返回非 null，
///   reject 成带 [ApiException] 的 [DioException]，让业务侧的 `safeRequest` 能拿到。
/// - `onError`：维护计数器；按 `showErrorToast` 触发 `onError` 回调。
///
/// 通过 `extra` 中的 [_kCountedKey] 标记防止 onResponse 拒绝后 onError 二次扣计数 / 二次 toast。
class UiFeedbackInterceptor extends Interceptor {
  UiFeedbackInterceptor(this.config);

  final UiFeedback config;

  /// 在飞的"需要展示 loading"的请求计数。
  int _loadingCount = 0;

  /// 标记 onResponse 已对该请求做过计数器/toast 处理，避免后续 onError 重复处理。
  static const String _kCountedKey = '_flutter_app_scaffold_ui_counted';
  static const String _kToastedKey = '_flutter_app_scaffold_ui_toasted';

  bool _showLoading(RequestOptions options) {
    final ov = options.extra[kUiFeedbackOverrideKey] as UiOverride?;
    return ov?.showLoading ?? config.defaultShowLoading;
  }

  bool _showErrorToast(RequestOptions options) {
    final ov = options.extra[kUiFeedbackOverrideKey] as UiOverride?;
    return ov?.showErrorToast ?? config.defaultShowErrorToast;
  }

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    if (_showLoading(options)) {
      _loadingCount++;
      if (_loadingCount == 1) config.onLoadingStart?.call();
    }
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    final opts = response.requestOptions;
    _decrementLoading(opts);

    final detect = config.detectBusinessError;
    if (detect != null) {
      final bizErr = detect(response);
      if (bizErr != null) {
        if (_showErrorToast(opts)) {
          opts.extra[_kToastedKey] = true;
          config.onError?.call(bizErr);
        }
        handler.reject(
          DioException(
            requestOptions: opts,
            response: response,
            error: bizErr,
            // 用 unknown 类型承载，mapDioException 会优先看 error 字段。
            type: DioExceptionType.unknown,
          ),
        );
        return;
      }
    }
    handler.next(response);
  }

  @override
  void onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) {
    final opts = err.requestOptions;
    _decrementLoading(opts);

    if (_showErrorToast(opts) && opts.extra[_kToastedKey] != true) {
      opts.extra[_kToastedKey] = true;
      final apiErr =
          err.error is ApiException ? err.error! as ApiException : mapDioException(err);
      config.onError?.call(apiErr);
    }
    handler.next(err);
  }

  void _decrementLoading(RequestOptions options) {
    if (options.extra[_kCountedKey] == true) return;
    options.extra[_kCountedKey] = true;
    if (_showLoading(options) && _loadingCount > 0) {
      _loadingCount--;
      if (_loadingCount == 0) config.onLoadingEnd?.call();
    }
  }
}
