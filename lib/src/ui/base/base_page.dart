import 'package:flutter/material.dart';

import '../../router/app_route_observer.dart';

/// 业务页面基类。继承后可重写四个生命周期：
/// - `onPageShow`：当前页变为顶层（首次进入 / 从下一页返回 / 从后台回前台）。
/// - `onPageHide`：当前页被遮挡（push 新页 / 进入后台）。
/// - `onAppForeground` / `onAppBackground`：应用前后台。
///
/// 使用前提：app_scaffold 提供的 [appRouteObserver] 已挂到 GoRouter / MaterialApp。
abstract class BasePage extends StatefulWidget {
  const BasePage({super.key});
}

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
      appRouteObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    if (_isCurrent) {
      _isCurrent = false;
      onPageHide();
    }
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
