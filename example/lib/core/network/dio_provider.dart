import 'package:flutter_app_scaffold/flutter_app_scaffold.dart';

import '../storage/secure_storage_provider.dart';

/// 全局 [DioClient] Provider。
///
/// 所有 feature 的 API 类都通过这个 Provider 拿到同一个 Dio 实例,
/// 拦截器配置只在这一个文件做 —— 别的地方不需要也不应该再 enableX。
///
/// 推荐添加顺序:enableUiFeedback → enableAuth → enableRetry,
/// 这样 UI 反馈在最外圈,看到的是鉴权刷新 / 重试之后的最终结果。
final dioProvider = Provider<DioClient>((ref) {
  final storage = ref.read(secureStorageProvider);

  final client = DioClient()
    // ① UI 反馈(loading / 错误 toast):需要业务工程实现 UiFeedback 接口,
    //   实现后取消下行注释即可。
    // ..enableUiFeedback(MyUiFeedback())

    // ② 鉴权:每次请求自动注入 Bearer token。
    //   refreshToken 暂不接,401 时返回 onUnauthorized 让上层(controller / router)
    //   自行处理(例如清空登录态、跳登录页)。真实接刷新时取消下面 refreshToken 的注释。
    ..enableAuth(
      tokenProvider: () => storage.read(key: 'access_token'),
      // refreshToken: () async {
      //   final newToken = await ref.read(authApiProvider).refresh();
      //   await storage.write(key: 'access_token', value: newToken);
      //   return newToken;
      // },
    )

    // ③ 重试:仅对超时 / 连接错误生效,业务错误不重试。
    ..enableRetry();

  return client;
});
