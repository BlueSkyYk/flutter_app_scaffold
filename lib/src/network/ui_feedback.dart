import 'package:dio/dio.dart';

import 'api_exception.dart';

/// `UiFeedback` 把"请求 ↔ UI 反馈"的所有回调聚到一处，业务侧在启动时
/// 通过 `DioClient.enableUiFeedback(...)` 注入。
///
/// 拦截器读到这些回调后，会按 [defaultShowLoading] / [defaultShowErrorToast]
/// 决定每个请求是否触发 loading / toast；单次请求可用 `Options.ui(...)` 覆盖默认。
///
/// 设计原则：
/// - 脚手架不绑定任何 UI 库（FlutterToast / FlushBar / 自家组件随意），只发信号。
/// - loading 用计数器，多并发请求只在 0→1 时调 [onLoadingStart]、N→0 时调 [onLoadingEnd]。
/// - [detectBusinessError] 把"HTTP 200 + 业务 code != 0"翻译成 [ApiException]，
///   让 `safeRequest` / try-catch 能拿到统一形态的错误。
class UiFeedback {
  const UiFeedback({
    this.onLoadingStart,
    this.onLoadingEnd,
    this.onError,
    this.detectBusinessError,
    this.defaultShowLoading = false,
    this.defaultShowErrorToast = true,
  });

  /// 计数器从 0 变 1 时调用——展示全屏遮罩 / 进度条。
  final void Function()? onLoadingStart;

  /// 计数器从 N 变 0 时调用——隐藏遮罩。
  final void Function()? onLoadingEnd;

  /// 请求失败（网络错误 / HTTP 错误 / 业务码错误）时调用。
  /// 仅当 `showErrorToast == true` 时触发。
  final void Function(ApiException error)? onError;

  /// 业务码错误检测：返回非 null 表示业务失败，会被包装成 [DioException] 走错误链。
  /// 返回 null 表示成功，正常往下走。
  final ApiException? Function(Response<dynamic> response)? detectBusinessError;

  /// 未在请求里显式指定时的默认值。
  final bool defaultShowLoading;
  final bool defaultShowErrorToast;
}

/// 单次请求的 UI 反馈策略覆盖。null 字段表示沿用 [UiFeedback] 的默认值。
class UiOverride {
  const UiOverride({this.showLoading, this.showErrorToast});

  final bool? showLoading;
  final bool? showErrorToast;
}

/// `Options.extra` 中存放 [UiOverride] 用的 key。
const String kUiFeedbackOverrideKey = '_flutter_app_scaffold_ui_override';

/// 给 [Options] 加一组类型安全的 UI 反馈语法糖，避免业务侧裸写 `extra` map。
extension UiOptionsX on Options {
  /// 标记本次请求的 UI 反馈策略。null 字段沿用 `enableUiFeedback` 中的默认值。
  ///
  /// ```dart
  /// await client.post('/login',
  ///   data: x,
  ///   options: Options().ui(loading: true),
  /// );
  /// ```
  Options ui({bool? loading, bool? errorToast}) {
    return copyWith(
      extra: {
        ...?extra,
        kUiFeedbackOverrideKey: UiOverride(
          showLoading: loading,
          showErrorToast: errorToast,
        ),
      },
    );
  }

  /// 等价于 `ui(loading: false, errorToast: false)`，用于心跳 / 埋点等后台请求。
  Options silent() => ui(loading: false, errorToast: false);
}
