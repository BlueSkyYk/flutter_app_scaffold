import 'dart:convert';

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

  static const _userJsonKey = 'user_json';

  @override
  Future<AuthUser> login({required String phone, required String code}) async {
    final dto = await api.login(phone: phone, code: code);
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
    final json = await secureStorage.read(key: _userJsonKey);
    if (json == null || json.isEmpty) {
      return null;
    }
    try {
      final user = AuthUser.fromJson(jsonDecode(json));
      if (!user.token.isNullOrEmpty && !user.refreshToken.isNullOrEmpty) {
        return user;
      }
    } catch (e) {
      AppLog.e('[auth] restore user json failed: $e');
    }
    return null;
  }

  // ── 私有辅助:持久化 / DTO 转换 ──────────────────────────────

  Future<void> _persist(LoginResponseDto dto) async {
    final user = AuthUser.fromDto(dto);
    if (!user.token.isNullOrEmpty && !user.refreshToken.isNullOrEmpty) {
      await secureStorage.write(
        key: _userJsonKey,
        value: jsonEncode(user.toJson()),
      );
    }
  }

  Future<void> _clear() async {
    await secureStorage.delete(key: _userJsonKey);
  }

  /// DTO → Entity:只保留 domain 需要的字段。
  /// refreshToken 是 data 层细节(用于刷新流程),domain 不暴露。
  AuthUser _toEntity(LoginResponseDto dto) {
    return AuthUser(
      avatar: dto.avatar,
      gender: dto.gender,
      birthday: dto.birthday,
      id: dto.id,
      nickname: dto.nickname,
      phone: dto.phone,
      playstyle: dto.playstyle,
      registerTime: dto.registerTime,
      selfIntroduction: dto.selfIntroduction,
      role: dto.role,
      status: dto.status,
      token: dto.token,
      refreshToken: dto.refreshToken,
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
