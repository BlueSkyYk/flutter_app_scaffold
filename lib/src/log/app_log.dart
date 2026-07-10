import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// 全局日志门面。所有业务日志都走这里，便于按 release/debug 切换。
class AppLog {
  AppLog._();

  static Logger _logger = _defaultLogger(
    kReleaseMode ? Level.warning : Level.debug,
  );

  /// 替换默认 logger（如自定义 printer / output）。
  static void configure(Logger logger) {
    _logger = logger;
  }

  /// 使用脚手架默认 logger 配置,仅控制是否输出日志。
  ///
  /// 开启时使用 [enabledLevel],默认 debug 级别,适合临时 release 调试。
  /// 关闭时使用 [Level.off],不会输出任何等级的日志。
  static void configureEnabled(
    bool enabled, {
    Level enabledLevel = Level.debug,
  }) {
    _logger = _defaultLogger(enabled ? enabledLevel : Level.off);
  }

  static void d(Object? msg, {Object? error, StackTrace? stackTrace}) =>
      _logger.d(msg, error: error, stackTrace: stackTrace);

  static void i(Object? msg, {Object? error, StackTrace? stackTrace}) =>
      _logger.i(msg, error: error, stackTrace: stackTrace);

  static void w(Object? msg, {Object? error, StackTrace? stackTrace}) =>
      _logger.w(msg, error: error, stackTrace: stackTrace);

  static void e(Object? msg, {Object? error, StackTrace? stackTrace}) =>
      _logger.e(msg, error: error, stackTrace: stackTrace);

  static Logger _defaultLogger(Level level) {
    return Logger(
      printer: PrettyPrinter(
        methodCount: 0,
        errorMethodCount: 8,
        lineLength: 100,
        colors: true,
        printEmojis: false,
        dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
      ),
      level: level,
    );
  }
}
