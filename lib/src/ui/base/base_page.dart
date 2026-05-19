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
///
/// 仅当不需要 Riverpod `ref` 时使用 [BasePage] / [BasePageState]。
/// 同时需要 `ref` 与页面生命周期时，使用 [PageLifecycleMixin] 直接搭配
/// `ConsumerStatefulWidget` / `ConsumerState`，避免在 build 里再嵌一层 Consumer。
abstract class BasePage extends StatefulWidget {
  const BasePage({super.key});
}

/// 与 [BasePage] 配套的 State 基类。
///
/// 实现完全委托给 [PageLifecycleMixin]，自身不持有任何额外逻辑 ——
/// 仅作为常用搭配的简化命名保留，等价于：
/// ```dart
/// class _State extends State<MyPage> with PageLifecycleMixin<MyPage> {}
/// ```
abstract class BasePageState<T extends BasePage> extends State<T>
    with PageLifecycleMixin<T> {}

/// 页面生命周期 mixin。
///
/// 可应用到任意继承 [State] 的 State 类（包括 Riverpod 的 `ConsumerState`），
/// 提供与 [BasePageState] 相同的四个钩子：
/// `onPageShow / onPageHide / onAppForeground / onAppBackground`。
///
/// 内部实现要点：
/// - 通过实现 [RouteAware] 接收路由层的 push/pop 事件；
/// - 通过私有 [WidgetsBindingObserver] 委托接收 App 前后台事件，
///   因此宿主类**不需要**显式 `with WidgetsBindingObserver`；
/// - `_isCurrent` / `_isAppForeground` 协调两路事件，确保已被覆盖的页面
///   切换前后台时不会重复 fire `onPageHide`，避免重复触发；
/// - [dispose] 阶段不会再回调 [onPageHide]，资源清理写在子类自己的 dispose 里。
///
/// 用法（搭配 ConsumerStatefulWidget）：
/// ```dart
/// class _LoginPageState extends ConsumerState<LoginPage>
///     with PageLifecycleMixin<LoginPage> {
///   @override
///   Widget build(BuildContext context) {
///     final auth = ref.watch(authControllerProvider); // ref 直接可用
///     return Scaffold(...);
///   }
///
///   @override
///   void onPageShow() => AppLog.d('[LoginPage] show');
/// }
/// ```
mixin PageLifecycleMixin<T extends StatefulWidget> on State<T>
    implements RouteAware {
  bool _isCurrent = false;
  bool _isAppForeground = true;
  late final _AppLifecycleObserver _observer;

  @override
  void initState() {
    super.initState();
    _observer = _AppLifecycleObserver(_handleAppLifecycleChange);
    WidgetsBinding.instance.addObserver(_observer);
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
    WidgetsBinding.instance.removeObserver(_observer);
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

  void _handleAppLifecycleChange(AppLifecycleState state) {
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

/// 内部辅助：把 [WidgetsBindingObserver] 的能力封装成可被 mixin 持有的对象，
/// 这样 [PageLifecycleMixin] 不需要要求宿主类显式 `with WidgetsBindingObserver`。
class _AppLifecycleObserver with WidgetsBindingObserver {
  _AppLifecycleObserver(this._onChange);
  final void Function(AppLifecycleState) _onChange;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _onChange(state);
  }
}
