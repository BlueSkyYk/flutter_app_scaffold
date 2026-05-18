import 'package:flutter_app_scaffold/flutter_app_scaffold.dart';

class AuthUser {
  const AuthUser({required this.id, required this.username, required this.token});
  final String id;
  final String username;
  final String token;
}

/// 模拟登录仓库。真实项目里换成 DioClient 调后端。
class AuthRepository {
  AuthRepository({required this.secureStorage});

  final SecureStorage secureStorage;

  static const _tokenKey = 'access_token';
  static const _userKey = 'username';

  Future<AuthUser> login({
    required String username,
    required String password,
  }) async {
    AppLog.i('[auth] login attempt: $username');
    await Future<void>.delayed(const Duration(seconds: 1));

    if (username == 'demo' && password == 'demo123') {
      final user = AuthUser(
        id: '1',
        username: username,
        token: 'mock-token-${DateTime.now().millisecondsSinceEpoch}',
      );
      await secureStorage.write(_tokenKey, user.token);
      await secureStorage.write(_userKey, user.username);
      return user;
    }
    throw const BusinessException('账号或密码错误', code: 4001);
  }

  Future<void> logout() async {
    await secureStorage.delete(_tokenKey);
    await secureStorage.delete(_userKey);
  }

  Future<AuthUser?> restore() async {
    final token = await secureStorage.read(_tokenKey);
    final username = await secureStorage.read(_userKey);
    if (token == null || username == null) return null;
    return AuthUser(id: '1', username: username, token: token);
  }
}
