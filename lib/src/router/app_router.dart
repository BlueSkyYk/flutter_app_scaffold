import 'package:go_router/go_router.dart';

import 'app_route_observer.dart';

/// go_router 的薄封装。提供一个工厂，自动挂上 [appRouteObserver]，
/// 让 BasePage 的生命周期能感知到路由切换。
class AppRouter {
  AppRouter._();

  static GoRouter create({
    required List<RouteBase> routes,
    String initialLocation = '/',
    GoRouterRedirect? redirect,
    GoExceptionHandler? onException,
    bool debugLogDiagnostics = false,
  }) {
    return GoRouter(
      initialLocation: initialLocation,
      routes: routes,
      redirect: redirect,
      onException: onException,
      debugLogDiagnostics: debugLogDiagnostics,
      observers: [appRouteObserver],
    );
  }
}
