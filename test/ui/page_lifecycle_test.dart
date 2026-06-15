import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_app_scaffold/flutter_app_scaffold.dart';
import 'package:flutter_test/flutter_test.dart';

/// `PageLifecycleMixin` 把 RouteAware + WidgetsBindingObserver 两路事件
/// 协调成 onPageShow / onPageHide 四个钩子。这里钉死路由侧的协调不变量
/// （CLAUDE.md 标记为 load-bearing）：
/// 1. 初始路由只 onPageShow 一次，不重复 fire。
/// 2. push 新页 → 旧页 onPageHide；pop 回来 → onPageShow。
/// 3. 自身 pop → onPageHide。
void main() {
  testWidgets('initial route fires onPageShow exactly once', (tester) async {
    final shows = <int>[];
    final hides = <int>[];

    await tester.pumpWidget(
      MaterialApp(
        navigatorObservers: [appRouteObserver],
        home: _LifecyclePage(
          tag: 'home',
          onShow: () => shows.add(1),
          onHide: () => hides.add(1),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // RouteObserver.subscribe 注册时补发一次 didPush → onPageShow。
    // 不应额外手动补发导致双触发。
    expect(shows.length, 1);
    expect(hides.length, 0);
  });

  testWidgets('push next fires onPageHide, pop back fires onPageShow',
      (tester) async {
    final shows = <int>[];
    final hides = <int>[];

    await tester.pumpWidget(
      MaterialApp(
        navigatorObservers: [appRouteObserver],
        home: _LifecyclePage(
          tag: 'home',
          onShow: () => shows.add(1),
          onHide: () => hides.add(1),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(shows.length, 1);

    final ctx = tester.element(find.byType(_LifecyclePage));
    await tester.pump();
    unawaited(
      Navigator.of(ctx).push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('page2')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // home 被覆盖 → didPushNext → onPageHide。
    expect(hides.length, 1, reason: 'push 覆盖应触发 onPageHide');

    Navigator.of(ctx).pop();
    await tester.pumpAndSettle();

    // 回到 home → didPopNext → onPageShow。
    expect(shows.length, 2, reason: 'pop 回来应触发 onPageShow');
  });

  testWidgets('popping self fires onPageHide (didPop path)', (tester) async {
    final shows = <int>[];
    final hides = <int>[];

    await tester.pumpWidget(
      MaterialApp(
        navigatorObservers: [appRouteObserver],
        home: const Scaffold(body: Text('root')),
      ),
    );
    await tester.pumpAndSettle();

    final rootCtx = tester.element(find.text('root'));
    unawaited(
      Navigator.of(rootCtx).push(
        MaterialPageRoute<void>(
          builder: (_) => _LifecyclePage(
            tag: 'top',
            onShow: () => shows.add(1),
            onHide: () => hides.add(1),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(shows.length, 1);

    // pop 自身 → didPop → onPageHide。
    final topCtx = tester.element(find.byType(_LifecyclePage));
    Navigator.of(topCtx).pop();
    await tester.pumpAndSettle();

    expect(hides.length, 1, reason: '自身 pop 应触发 onPageHide');
  });
}

class _LifecyclePage extends StatefulWidget {
  const _LifecyclePage({
    required this.tag,
    required this.onShow,
    required this.onHide,
  });

  final String tag;
  final VoidCallback onShow;
  final VoidCallback onHide;

  @override
  State<_LifecyclePage> createState() => _LifecyclePageState();
}

class _LifecyclePageState extends State<_LifecyclePage>
    with PageLifecycleMixin<_LifecyclePage> {
  @override
  void onPageShow() => widget.onShow();

  @override
  void onPageHide() => widget.onHide();

  @override
  Widget build(BuildContext context) => Scaffold(body: Text(widget.tag));
}
