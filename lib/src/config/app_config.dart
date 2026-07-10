import 'package:flutter/widgets.dart';

import '../network/network_log_config.dart';
import 'app_env.dart';

class AppConfig {
  const AppConfig({
    required this.env,
    required this.apiBaseUrl,
    this.connectTimeout = const Duration(seconds: 10),
    this.receiveTimeout = const Duration(seconds: 15),
    this.sendTimeout = const Duration(seconds: 15),
    this.enableNetworkLog = true,
    this.networkLogConfig = const NetworkLogConfig(),
    this.designSize = const Size(375, 812),
    this.minTextAdapt = true,
    this.splitScreenMode = false,
    this.extra = const {},
  });

  final AppEnv env;
  final String apiBaseUrl;
  final Duration connectTimeout;
  final Duration receiveTimeout;
  final Duration sendTimeout;
  final bool enableNetworkLog;
  final NetworkLogConfig networkLogConfig;

  /// 设计稿尺寸（逻辑像素），用于 flutter_screenutil 等比缩放。
  ///
  /// 默认 `Size(375, 812)`（iPhone X / 13 mini 设计稿）。
  /// 改为设计稿实际尺寸后，业务侧可用 `.w` / `.h` / `.sp` / `.r` 后缀做适配。
  final Size designSize;

  /// 当宽高一方超出设计稿比例时，是否仍用较小的一边来缩放字号。
  /// 默认 `true`，避免横屏 / 平板上字号被异常放大。
  final bool minTextAdapt;

  /// 是否支持分屏（影响屏幕高度的获取方式）。
  /// 默认 `false`；平板分屏场景可置为 `true`。
  final bool splitScreenMode;

  final Map<String, Object?> extra;

  static AppConfig? _instance;

  static AppConfig get I {
    final ins = _instance;
    if (ins == null) {
      throw StateError('AppConfig 未初始化，请先调用 AppConfig.bind()');
    }
    return ins;
  }

  static void bind(AppConfig config) => _instance = config;

  /// 清除已绑定的实例。仅用于测试隔离，正式代码不要调用。
  @visibleForTesting
  static void reset() => _instance = null;
}
