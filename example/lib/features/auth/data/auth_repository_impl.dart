import 'package:flutter_app_scaffold/flutter_app_scaffold.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/storage/secure_storage_provider.dart';
import '../domain/auth_repository.dart';
import '../domain/auth_user.dart';
import 'auth_api.dart';
import 'dto/login_response_dto.dart';

/// [AuthRepository] 的实际实现(data 层)。
///
/// 协调三件事:
/// 1. 调用 [AuthApi] 拿后端 DTO;
/// 2. 持久化到本地(secureStorage);
/// 3. DTO → Entity 转换,把后端字段过滤成 domain 关心的纯净对象。
///
/// API 类只负责单次 HTTP 调用;Repository 负责"完整业务流"
/// (login = 调网络 + 写本地 + 返回 entity)。
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({required this.api, required this.secureStorage});

  final AuthApi api;
  final FlutterSecureStorage secureStorage;

  static const _tokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _userIdKey = 'user_id';
  static const _usernameKey = 'username';

  @override
  Future<AuthUser> login({
    required String username,
    required String password,
  }) async {
    final dto = await api.login(username: username, password: password);
    await _persist(dto);
    return _toEntity(dto);
  }

  @override
  Future<void> logout() async {
    try {
      await api.logout();
    } catch (e) {
      // 登出请求即便失败,也要清掉本地凭证 —— 让用户能登出。
      AppLog.w('[auth] logout api failed, clear local anyway: $e');
    }
    await _clear();
  }

  @override
  Future<AuthUser?> restore() async {
    final token = await secureStorage.read(key: _tokenKey);
    final id = await secureStorage.read(key: _userIdKey);
    final username = await secureStorage.read(key: _usernameKey);
    if (token == null || id == null || username == null) return null;
    return AuthUser(id: id, username: username, token: token);
  }

  // ── 私有辅助:持久化 / DTO 转换 ──────────────────────────────

  Future<void> _persist(LoginResponseDto dto) async {
    await secureStorage.write(key: _tokenKey, value: dto.accessToken);
    await secureStorage.write(key: _userIdKey, value: dto.userId);
    await secureStorage.write(key: _usernameKey, value: dto.username);
    if (dto.refreshToken != null) {
      await secureStorage.write(key: _refreshTokenKey, value: dto.refreshToken);
    }
  }

  Future<void> _clear() async {
    await secureStorage.delete(key: _tokenKey);
    await secureStorage.delete(key: _refreshTokenKey);
    await secureStorage.delete(key: _userIdKey);
    await secureStorage.delete(key: _usernameKey);
  }

  /// DTO → Entity:只保留 domain 需要的字段。
  /// refreshToken 是 data 层细节(用于刷新流程),domain 不暴露。
  AuthUser _toEntity(LoginResponseDto dto) {
    return AuthUser(
      id: dto.userId,
      username: dto.username,
      token: dto.accessToken,
    );
  }
}

/// 仓库 Provider:类型暴露为 domain 接口 [AuthRepository],
/// 调用方拿不到 Impl 类。测试时 `overrideWith((_) => FakeAuthRepository())` 即可注入假实现。
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    api: ref.read(authApiProvider),
    secureStorage: ref.read(secureStorageProvider),
  );
});
