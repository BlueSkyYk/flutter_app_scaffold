import 'package:flutter/widgets.dart';

/// 全局 RouteObserver，用于让页面通过 RouteAware 监听 push/pop 切换。
/// 在 MaterialApp.navigatorObservers / GoRouter.observers 中注册。
final RouteObserver<ModalRoute<void>> appRouteObserver =
    RouteObserver<ModalRoute<void>>();
