import 'package:flutter_app_scaffold/flutter_app_scaffold.dart';

import '../data/auth_repository_impl.dart';
import '../domain/auth_repository.dart';
import '../domain/auth_user.dart';

/// 全局登录态控制器(presentation 层)。
///
/// state 类型 = `AsyncValue<AuthUser?>`:
///   - data 非空 → 已登录
///   - data 为 null → 未登录
///   - loading / error → AsyncNotifier 自动管理三态
///
/// presentation 层只 import [AuthRepository] 抽象 + [AuthUser] 实体,
/// 不直接 import data 层的 Impl 类 —— 通过 [authRepositoryProvider]
/// 由 Riverpod 完成依赖注入。
class AuthController extends AsyncNotifier<AuthUser?> {
  late final AuthRepository _repo = ref.read(authRepositoryProvider);

  @override
  Future<AuthUser?> build() => _repo.restore();

  Future<void> login({required String phone, required String code}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repo.login(phone: phone, code: code));
  }

  Future<void> logout() async {
    await _repo.logout();
    state = const AsyncData(null);
  }
}

/// 不带 `retry:` —— **刻意**保留 Riverpod 3 默认重试。
///
/// 与 FeedController 关闭重试相反:这是「长生命周期、能自然恢复」的 provider
/// (本地 token restore)。`build()` 读本地存储,偶发失败时默认重试能让用户无感恢复,
/// 没有"用户手动点重试"的诉求,所以默认策略正合适。
/// 详见 README §10「何时保留 / 何时关闭 Riverpod 自动重试」。
final authControllerProvider = AsyncNotifierProvider<AuthController, AuthUser?>(
  AuthController.new,
);
