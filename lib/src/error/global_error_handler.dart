import 'dart:async';

import 'package:flutter/foundation.dart';

import '../log/app_log.dart';
import 'error_reporter.dart';

class GlobalErrorHandler {
  GlobalErrorHandler._();

  static ErrorReporter _reporter = const NoopErrorReporter();

  /// 安装全局错误处理。需在 runApp 之前调用，且整个 runApp 包在 [run] 内。
  static void install({ErrorReporter? reporter}) {
    if (reporter != null) _reporter = reporter;

    FlutterError.onError = (details) {
      AppLog.e(
        'FlutterError: ${details.exceptionAsString()}',
        error: details.exception,
        stackTrace: details.stack,
      );
      _reporter.report(
        details.exception,
        details.stack ?? StackTrace.current,
        context: {'library': details.library},
      );
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      AppLog.e('Uncaught error', error: error, stackTrace: stack);
      _reporter.report(error, stack, fatal: true);
      return true;
    };
  }

  /// 用 runZonedGuarded 包裹 runApp 的便捷方法。
  static Future<void> run(FutureOr<void> Function() body) {
    return runZonedGuarded<Future<void>>(() async {
      await body();
    }, (error, stack) {
      AppLog.e('Zone error', error: error, stackTrace: stack);
      _reporter.report(error, stack, fatal: true);
    }) ?? Future.value();
  }
}
