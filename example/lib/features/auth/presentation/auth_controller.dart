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

  Future<void> login({
    required String username,
    required String password,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _repo.login(username: username, password: password),
    );
  }

  Future<void> logout() async {
    await _repo.logout();
    state = const AsyncData(null);
  }
}

final authControllerProvider =
    AsyncNotifierProvider<AuthController, AuthUser?>(AuthController.new);
