import 'package:flutter_app_scaffold/flutter_app_scaffold.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthUser {
  const AuthUser({required this.id, required this.username, required this.token});
  final String id;
  final String username;
  final String token;
}

/// 模拟登录仓库。真实项目里换成 DioClient 调后端。
///
/// 业务侧直接使用 [FlutterSecureStorage]：脚手架不内置安全存储 facade，
/// 因为它涉及 Android `minSdkVersion` / iOS Keychain entitlement 等项目级配置，
/// 由业务在自己的 pubspec / 原生工程里按需引入更合适。
class AuthRepository {
  AuthRepository({required this.secureStorage});

  final FlutterSecureStorage secureStorage;

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
      await secureStorage.write(key: _tokenKey, value: user.token);
      await secureStorage.write(key: _userKey, value: user.username);
      return user;
    }
    throw const BusinessException('账号或密码错误', code: 4001);
  }

  Future<void> logout() async {
    await secureStorage.delete(key: _tokenKey);
    await secureStorage.delete(key: _userKey);
  }

  Future<AuthUser?> restore() async {
    final token = await secureStorage.read(key: _tokenKey);
    final username = await secureStorage.read(key: _userKey);
    if (token == null || username == null) return null;
    return AuthUser(id: '1', username: username, token: token);
  }
}
