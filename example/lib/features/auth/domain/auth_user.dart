/// 登录后的用户实体。
///
/// 纯 Dart 类,不依赖 Flutter / Riverpod / Dio —— 这是 domain 层的硬约束:
/// 任何业务实体都应该能被单元测试单独实例化、不需要 mock 任何框架。
///
/// 如果将来这个实体被多个无关业务域共享(profile / order / social 都要用),
/// 应该提到 core/domain/ 或独立成 user/ 域,而不是各自定义同名类。
class AuthUser {
  const AuthUser({
    required this.id,
    required this.username,
    required this.token,
  });

  final String id;
  final String username;
  final String token;
}
