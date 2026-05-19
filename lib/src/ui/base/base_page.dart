import 'package:flutter/material.dart';

import '../../router/app_route_observer.dart';

/// 业务页面基类。继承后可在 [BasePageState] 中重写四个生命周期：
/// - `onPageShow`：当前页变为顶层（首次进入 / 从下一页返回 / 从后台回前台）。
/// - `onPageHide`：当前页被遮挡（push 新页 / 进入后台）。
/// - `onAppForeground` / `onAppBackground`：应用前后台。
///
/// 使用前提：flutter_app_scaffold 提供的 [appRouteObserver] 已挂到 GoRouter / MaterialApp。
/// 通过 `AppRouter.create(...)` 构造的路由会自动挂载；如手动构造 GoRouter，
/// 需要自行 `observers: [appRouteObserver]`，否则页面回调不会触发。
abstract class BasePage extends StatefulWidget {
  const BasePage({super.key});
}

/// 与 [BasePage] 配套的 State 基类。
///
/// 内部用 [_isCurrent] / [_isAppForeground] 协调 [RouteAware] 与
/// [WidgetsBindingObserver] 两路事件，确保：
/// - 在已被覆盖的页面切换前后台时不会重复 fire `onPageHide`。
/// - 页面回到栈顶且 App 处于前台时才 fire `onPageShow`。
///
/// 注意：[dispose] 阶段不会再回调 [onPageHide]，请把资源清理写在子类的 [dispose] 里。
abstract class BasePageState<T extends BasePage> extends State<T>
    with WidgetsBindingObserver, RouteAware {
  bool _isCurrent = false;
  bool _isAppForeground = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      // RouteObserver.subscribe 内部会立刻补发一次 didPush，
      // 所以这里不需要手动触发首帧 onPageShow。
      appRouteObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // RouteAware --------------------------------------------------------------

  @override
  void didPush() {
    _isCurrent = true;
    onPageShow();
  }

  @override
  void didPopNext() {
    _isCurrent = true;
    onPageShow();
  }

  @override
  void didPushNext() {
    if (_isCurrent) {
      _isCurrent = false;
      onPageHide();
    }
  }

  @override
  void didPop() {
    if (_isCurrent) {
      _isCurrent = false;
      onPageHide();
    }
  }

  // App lifecycle -----------------------------------------------------------

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    final wasFg = _isAppForeground;
    final isFg = state == AppLifecycleState.resumed;
    if (wasFg == isFg) return;
    _isAppForeground = isFg;
    if (isFg) {
      onAppForeground();
      if (_isCurrent) onPageShow();
    } else {
      if (_isCurrent) onPageHide();
      onAppBackground();
    }
  }

  // Hooks -------------------------------------------------------------------

  /// 当前页可见。
  void onPageShow() {}

  /// 当前页被覆盖 / 退出。
  void onPageHide() {}

  /// 应用从后台回到前台。
  void onAppForeground() {}

  /// 应用进入后台。
  void onAppBackground() {}
}
