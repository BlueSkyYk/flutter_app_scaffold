/// 当前 token 的只读视图(domain 层抽象)。
///
/// 用途:让"需要读 token 的跨层消费方"(典型的是 dio 拦截器)
/// 通过这个抽象拿到 token,**而不需要知道 token 是怎么持久化的、key 叫什么、
/// 是单 key 还是嵌在 user JSON 里**。
///
/// 设计目的:
/// 1. 把"存储细节"(key 命名、序列化方式、用 secureStorage 还是 Hive)
///    完全锁在 auth/data 内部,跨层消费方拿不到也不应该关心。
/// 2. 切换持久化方案(secureStorage → Hive)时,只改 data 层 Impl,
///    dio_provider 等消费方零改动。
/// 3. 测试时可以注入 fake `TokenSource`,不依赖真实 secureStorage。
///
/// 实现见 `data/token_storage.dart` 的 [TokenStorage]。
abstract class TokenSource {
  /// 当前用户的 access token。未登录 / 未 restore 时返回 null。
  Future<String?> currentAccessToken();

  /// 当前用户的 refresh token。如果未配置 refresh 流程,返回 null。
  Future<String?> currentRefreshToken();
}
