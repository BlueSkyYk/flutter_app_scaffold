import 'package:flutter_app_scaffold/flutter_app_scaffold.dart';
import 'package:flutter/material.dart';

import '../auth/auth_controller.dart';

class HomePage extends BasePage {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends BasePageState<HomePage> {
  @override
  void onPageShow() => AppLog.d('[HomePage] onPageShow');

  @override
  void onPageHide() => AppLog.d('[HomePage] onPageHide');

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
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
                const Icon(Icons.check_circle_outline,
                    size: 64, color: Colors.green),
                const SizedBox(height: 12),
                Text('已登录：${user?.username ?? '-'}',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text('token: ${user?.token ?? '-'}',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        );
      },
    );
  }
}
