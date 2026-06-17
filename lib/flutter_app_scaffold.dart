/// flutter_app_scaffold —— Flutter 应用脚手架。
///
/// 使用方只需 `import 'package:flutter_app_scaffold/flutter_app_scaffold.dart';` 即可拿到：
/// - 启动编排（AppBootstrap / AppInitializer）
/// - 配置（AppConfig / AppEnv）
/// - 日志（AppLog）
/// - 存储（KvStorage / PrefsStorage）
/// - 网络（DioClient / ApiResult / ApiException / 拦截器）
/// - 路由（AppRouter / appRouteObserver）
/// - 通用 UI（LoadingView / EmptyView / ErrorView / AsyncValueView / KeepAliveWrapper）
/// - 页面基类（BasePage / BasePageState）
/// - 错误兜底（GlobalErrorHandler / ErrorReporter）
library;

// 第三方常用 re-export
export 'package:dio/dio.dart'
    show CancelToken, Dio, Options, RequestOptions, Response;
export 'package:flutter_riverpod/flutter_riverpod.dart';
export 'package:flutter_screenutil/flutter_screenutil.dart';
export 'package:go_router/go_router.dart';

// Bootstrap
export 'src/bootstrap/app_bootstrap.dart';
export 'src/bootstrap/app_initializer.dart';

// Config
export 'src/config/app_config.dart';
export 'src/config/app_env.dart';

// Error
export 'src/error/error_reporter.dart';
export 'src/error/global_error_handler.dart';

// Log
export 'src/log/app_log.dart';

// Network
export 'src/network/api_exception.dart';
export 'src/network/api_result.dart';
export 'src/network/dio_client.dart';
export 'src/network/interceptors/auth_interceptor.dart';
export 'src/network/interceptors/log_interceptor.dart';
export 'src/network/interceptors/retry_interceptor.dart';
export 'src/network/interceptors/ui_feedback_interceptor.dart';
export 'src/network/ui_feedback.dart';

// Router
export 'src/router/app_route_observer.dart';
export 'src/router/app_router.dart';

// State
export 'src/state/async_value_x.dart';

// Storage
export 'src/storage/kv_storage.dart';
export 'src/storage/prefs_storage.dart';

// UI
export 'src/ui/base/base_page.dart';
export 'src/ui/widgets/async_value_view.dart';
export 'src/ui/widgets/empty_view.dart';
export 'src/ui/widgets/error_view.dart';
export 'src/ui/widgets/keep_alive_wrapper.dart';
export 'src/ui/widgets/loading_view.dart';

// Utils
export 'src/utils/string_utils.dart';
