import 'package:flutter_app_scaffold/flutter_app_scaffold.dart';
import 'package:flutter/material.dart';

import '../../auth/auth.dart';

/// 首页。展示当前登录用户,顶部按钮触发登出。
///
/// 不需要本地 state、不需要页面生命周期,所以选 [ConsumerWidget] —— 单一类、
/// 一个 build 方法、ref 直接通过参数拿到,这是 Riverpod 页面最简形态。
///
/// 如果以后需要"页面被覆盖时打日志 / 暂停定时器",再升级成
/// `ConsumerStatefulWidget` + `PageLifecycleMixin`(参考 LoginPage)。
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).dataOrNull;
    return Scaffold(
      appBar: AppBar(
        title: const Text('首页'),
        actions: [
          IconButton(
            tooltip: '退出登录',
            icon: const Icon(Icons.logout),
            onPressed: () =>
                ref.read(authControllerProvider.notifier).logout(),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle_outline,
              size: 64,
              color: Colors.green,
            ),
            const SizedBox(height: 12),
            Text(
              '已登录：${user?.username ?? '-'}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'token: ${user?.token ?? '-'}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
