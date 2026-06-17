import 'package:flutter_app_scaffold/flutter_app_scaffold.dart';

import '../domain/auth_repository.dart';
import '../domain/auth_user.dart';
import 'auth_api.dart';
import 'dto/login_response_dto.dart';
import 'token_storage.dart';

/// DTO → Entity 转换下沉在 data 层,避免 domain 反向依赖 data/dto。
AuthUser _toAuthUser(LoginResponseDto dto) => AuthUser(
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

/// [AuthRepository] 的实际实现(data 层)。
///
/// 协调三件事:
/// 1. 调用 [AuthApi] 拿后端 DTO;
/// 2. 通过 [TokenStorage] 持久化(key、序列化都封装在 storage 内部);
/// 3. DTO → Entity 转换。
///
/// **不直接操作 secureStorage / 不持有任何 storage key** ——
/// 所有持久化细节都在 [TokenStorage] 里。换存储方案时只改那一个类。
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({required this.api, required this.tokens});

  final AuthApi api;
  final TokenStorage tokens;

  @override
  Future<AuthUser> login({required String phone, required String code}) async {
    final dto = await api.login(phone: phone, code: code);
    final user = _toAuthUser(dto);
    if (!user.token.isNullOrEmpty && !user.refreshToken.isNullOrEmpty) {
      await tokens.saveUser(user);
    }
    return user;
  }

  @override
  Future<void> logout() async {
    try {
      await api.logout();
    } catch (e) {
      // 登出请求即便失败,也要清掉本地凭证 —— 让用户能登出。
      AppLog.w('[auth] logout api failed, clear local anyway: $e');
    }
    await tokens.clear();
  }

  @override
  Future<AuthUser?> restore() async {
    final user = await tokens.readUser();
    if (user == null) return null;
    if (user.token.isNullOrEmpty || user.refreshToken.isNullOrEmpty) return null;
    return user;
  }
}

/// 仓库 Provider:类型暴露为 domain 接口 [AuthRepository],
/// 调用方拿不到 Impl 类。测试时 `overrideWith((_) => FakeAuthRepository())` 即可注入假实现。
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    api: ref.read(authApiProvider),
    tokens: ref.read(tokenStorageProvider),
  );
});
