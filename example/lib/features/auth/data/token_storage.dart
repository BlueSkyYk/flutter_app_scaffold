import 'dart:convert';

import 'package:flutter_app_scaffold/flutter_app_scaffold.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/storage/secure_storage_provider.dart';
import '../domain/auth_user.dart';
import '../domain/token_source.dart';

/// 鉴权信息的本地持久化(data 层细节)。
///
/// 同时实现 [TokenSource] 接口,允许跨层消费方(如 `dio_provider`)
/// 通过 [tokenSourceProvider] 拿到只读视图。
///
/// **存储 key 完全在这个类内部,不向外泄漏**。需要更换持久化方案
/// (secureStorage → Hive / 内存 / SQLite)时,只改这一个类。
class TokenStorage implements TokenSource {
  TokenStorage(this._storage);

  final FlutterSecureStorage _storage;

  /// 整个用户对象序列化后的 key。
  /// 加 `auth.` 前缀,避免和其它 feature 的 key 命名冲突。
  static const _userJsonKey = 'auth.user_json';

  // ── TokenSource(只读)──────────────────────────────

  @override
  Future<String?> currentAccessToken() async {
    final user = await readUser();
    return user?.token;
  }

  @override
  Future<String?> currentRefreshToken() async {
    final user = await readUser();
    return user?.refreshToken;
  }

  // ── 完整 user 读写(repository 内部用)─────────────

  /// 读取持久化的 user 对象。解析失败 / 没存过都返回 null。
  Future<AuthUser?> readUser() async {
    final json = await _storage.read(key: _userJsonKey);
    if (json == null || json.isEmpty) return null;
    try {
      return AuthUser.fromJson(jsonDecode(json));
    } catch (e) {
      AppLog.e('[auth] read cached user failed: $e');
      return null;
    }
  }

  /// 持久化整个 user 对象(包含 token、refreshToken、用户基本资料)。
  Future<void> saveUser(AuthUser user) async {
    await _storage.write(
      key: _userJsonKey,
      value: jsonEncode(user.toJson()),
    );
  }

  /// 清空登录态(登出 / 鉴权失败时调)。
  Future<void> clear() async {
    await _storage.delete(key: _userJsonKey);
  }
}

/// 完整能力的存储 Provider,**仅给 auth/data 内部使用**(repository 实现)。
///
/// 不要在 auth feature 之外读这个 provider —— 跨层消费方应该用
/// [tokenSourceProvider],拿到的是只读视图,不会暴露 saveUser / clear。
final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return TokenStorage(ref.read(secureStorageProvider));
});

/// 跨层只读视图,暴露给 `dio_provider` 等不应该接触鉴权写入逻辑的消费方。
///
/// 类型暴露成 [TokenSource] 接口,调用方拿不到 saveUser / clear 等写入方法。
/// 底层复用 [TokenStorage] 实例,保证读写共用同一份持久化数据。
final tokenSourceProvider = Provider<TokenSource>((ref) {
  return ref.read(tokenStorageProvider);
});
