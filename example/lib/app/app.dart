import 'package:flutter_app_scaffold/flutter_app_scaffold.dart';
import 'package:flutter/material.dart';

import 'router.dart';

/// 应用根 widget。
///
/// 只装配 MaterialApp.router + 主题；路由策略全部下沉到 [routerProvider]。
///
/// 主题由业务方自行实现（脚手架不内置主题模块）。这里用原生
/// [ThemeData] + [ColorScheme.fromSeed] 给一个最小可用外观。
class ExampleApp extends ConsumerWidget {
  const ExampleApp({super.key});

  static const Color _seed = Color(0xFF1677FF);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'flutter_app_scaffold example',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: _seed),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _seed,
          brightness: Brightness.dark,
        ),
      ),
      routerConfig: ref.watch(routerProvider),
    );
  }
}
