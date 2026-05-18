import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// 全局日志门面。所有业务日志都走这里，便于按 release/debug 切换。
class AppLog {
  AppLog._();

  static Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 8,
      lineLength: 100,
      colors: true,
      printEmojis: false,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
    level: kReleaseMode ? Level.warning : Level.debug,
  );

  /// 替换默认 logger（如自定义 printer / output）。
  static void configure(Logger logger) {
    _logger = logger;
  }

  static void d(Object? msg, {Object? error, StackTrace? stackTrace}) =>
      _logger.d(msg, error: error, stackTrace: stackTrace);

  static void i(Object? msg, {Object? error, StackTrace? stackTrace}) =>
      _logger.i(msg, error: error, stackTrace: stackTrace);

  static void w(Object? msg, {Object? error, StackTrace? stackTrace}) =>
      _logger.w(msg, error: error, stackTrace: stackTrace);

  static void e(Object? msg, {Object? error, StackTrace? stackTrace}) =>
      _logger.e(msg, error: error, stackTrace: stackTrace);
}
