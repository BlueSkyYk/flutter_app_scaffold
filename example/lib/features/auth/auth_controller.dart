import 'package:flutter_app_scaffold/flutter_app_scaffold.dart';

import 'auth_repository.dart';

export 'auth_repository.dart' show AuthUser;

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(secureStorage: SecureStorage.I);
});

/// 全局登录状态。data 非空表示已登录。
class AuthController extends AsyncNotifier<AuthUser?> {
  late final AuthRepository _repo = ref.read(authRepositoryProvider);

  @override
  Future<AuthUser?> build() async {
    return _repo.restore();
  }

  Future<void> login({required String username, required String password}) async {
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
