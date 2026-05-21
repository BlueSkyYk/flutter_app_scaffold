import 'package:flutter_app_scaffold/flutter_app_scaffold.dart';

import '../features/auth/auth.dart';
import '../features/feed/feed.dart';
import '../features/home/home.dart';

/// 全局路由 Provider。
///
/// 集中管理三件事:路由表、redirect 守卫、登录态变化时的刷新。
/// 后续要加权限、深链、未读消息提示之类的策略,都在这一个文件里扩展。
final routerProvider = Provider<GoRouter>((ref) {
  final router = AppRouter.create(
    initialLocation: '/login',
    routes: [
      GoRoute(path: '/login', builder: (_, _) => const LoginPage()),
      GoRoute(path: '/home', builder: (_, _) => const HomePage()),
      GoRoute(path: '/feed', builder: (_, _) => const FeedPage()),
    ],
    // 路由守卫:未登录强制去 /login;已登录访问 /login 自动跳 /home。
    redirect: (context, state) {
      final logged = ref.read(authControllerProvider).dataOrNull != null;
      final goingToLogin = state.matchedLocation == '/login';
      if (!logged && !goingToLogin) return '/login';
      if (logged && goingToLogin) return '/home';
      return null;
    },
  );
  // 登录态变化(login/logout)时刷新路由,触发 redirect 重新评估。
  ref.listen(authControllerProvider, (_, _) => router.refresh());
  return router;
});
