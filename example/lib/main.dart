import 'package:app_scaffold/app_scaffold.dart';
import 'package:flutter/material.dart';

import 'features/auth/auth_controller.dart';
import 'features/auth/login_page.dart';
import 'features/home/home_page.dart';

void main() {
  AppBootstrap.run(
    config: const AppConfig(
      env: AppEnv.dev,
      apiBaseUrl: 'https://jsonplaceholder.typicode.com',
    ),
    app: () => const ProviderScope(child: ExampleApp()),
  );
}

class ExampleApp extends ConsumerWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = AppRouter.create(
      initialLocation: '/login',
      routes: [
        GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
        GoRoute(path: '/home', builder: (context, state) => const HomePage()),
      ],
      redirect: (context, state) {
        final logged = ref.read(authControllerProvider).dataOrNull != null;
        final goingToLogin = state.matchedLocation == '/login';
        if (!logged && !goingToLogin) return '/login';
        if (logged && goingToLogin) return '/home';
        return null;
      },
    );

    // 登录状态变化时强制刷新路由（触发 redirect）
    ref.listen(authControllerProvider, (prev, next) => router.refresh());

    return MaterialApp.router(
      title: 'app_scaffold example',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      routerConfig: router,
    );
  }
}
