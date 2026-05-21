import 'auth_user.dart';

/// 鉴权仓库的契约接口(domain 层)。
///
/// presentation 层(controller)只依赖这个抽象,不感知具体数据来源。
/// 数据源切换(本地 mock / 远端 API / 缓存层叠)只需要换 data 层实现,
/// controller 完全不用动 —— 这是 DDD/Clean Architecture 的核心收益。
abstract class AuthRepository {
  Future<AuthUser> login({
    required String phone,
    required String code,
  });

  Future<void> logout();

  /// 从本地恢复登录态(应用冷启动时调用)。
  /// 返回 null 表示未登录。
  Future<AuthUser?> restore();
}
