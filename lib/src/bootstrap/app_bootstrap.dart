import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../config/app_config.dart';
import '../error/error_reporter.dart';
import '../error/global_error_handler.dart';
import '../log/app_log.dart';
import '../storage/prefs_storage.dart';
import 'app_initializer.dart';

/// 应用启动编排。
///
/// 典型用法：
/// ```dart
/// void main() {
///   AppBootstrap.run(
///     config: AppConfig(env: AppEnv.dev, apiBaseUrl: 'https://api.example.com'),
///     initializers: [/* ... */],
///     app: () => const ProviderScope(child: MyApp()),
///   );
/// }
/// ```
class AppBootstrap {
  AppBootstrap._();

  /// 启动入口。封装了：
  /// 1) WidgetsFlutterBinding.ensureInitialized
  /// 2) 绑定 AppConfig
  /// 3) 安装全局错误兜底
  /// 4) 初始化默认存储 + 用户提供的 initializers
  /// 5) runApp（包在 runZonedGuarded 中）
  static Future<void> run({
    required AppConfig config,
    required Widget Function() app,
    List<AppInitializer> initializers = const [],
    ErrorReporter? errorReporter,
    bool autoInitPrefs = true,
  }) async {
    await GlobalErrorHandler.run(() async {
      WidgetsFlutterBinding.ensureInitialized();

      AppConfig.bind(config);
      GlobalErrorHandler.install(reporter: errorReporter);

      if (autoInitPrefs) {
        await PrefsStorage.init();
      }

      for (final initializer in initializers) {
        try {
          AppLog.i('[bootstrap] init "${initializer.name}"');
          await initializer.init();
        } catch (e, st) {
          AppLog.e(
            '[bootstrap] init "${initializer.name}" failed',
            error: e,
            stackTrace: st,
          );
          if (initializer.critical) rethrow;
        }
      }

      runApp(
        ScreenUtilInit(
          designSize: config.designSize,
          minTextAdapt: config.minTextAdapt,
          splitScreenMode: config.splitScreenMode,
          builder: (_, child) => child!,
          child: app(),
        ),
      );
    });
  }
}
