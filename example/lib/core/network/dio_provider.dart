import 'package:example/app/configs.dart';
import 'package:flutter_app_scaffold/flutter_app_scaffold.dart';

import '../../features/auth/auth.dart';
import 'http_result.dart';

/// 全局 [DioClient] Provider。
///
/// 所有 feature 的 API 类都通过这个 Provider 拿到同一个 Dio 实例,
/// 拦截器配置只在这一个文件做 —— 别的地方不需要也不应该再 enableX。
///
/// 推荐添加顺序:enableUiFeedback → enableAuth → enableRetry,
/// 这样 UI 反馈在最外圈,看到的是鉴权刷新 / 重试之后的最终结果。
final dioProvider = Provider<DioClient>((ref) {
  // 通过 TokenSource 接口拿 token —— 不知道、也不应该知道 token 存在哪、key 叫什么。
  // 切换持久化方案(secureStorage → Hive)时,这里零改动;只改 features/auth/data/token_storage.dart。
  final tokens = ref.read(tokenSourceProvider);

  final client = DioClient()
    // ① UI 反馈(loading / 错误 toast):需要业务工程实现 UiFeedback 接口,
    //   实现后取消下行注释即可。
    ..enableUiFeedback(
      UiFeedback(
        onLoadingStart: () {},
        onLoadingEnd: () {},
        detectBusinessError: (response) {
          final body = response.data;
          if (body is! Map<String, dynamic>) return null;
          final envelope = HttpResult<dynamic>.fromJson(body);
          if (envelope.code == Configs.httpBusinessSuccessCode) {
            return null; // 业务成功,放行
          }
          return BusinessException(
            // 业务失败,抛异常
            envelope.message ?? '网络出错，请稍后再试',
            code: envelope.code ?? -1,
            data: envelope.data,
          );
        },
        defaultShowErrorToast: true,
        defaultShowLoading: true,
      ),
    )
    // ② 鉴权:每次请求自动注入 Bearer token。
    //   refreshToken 暂不接,401 时返回 onUnauthorized 让上层(controller / router)
    //   自行处理(例如清空登录态、跳登录页)。真实接刷新时取消下面 refreshToken 的注释。
    ..enableAuth(
      tokenProvider: tokens.currentAccessToken,
      // refreshToken: () async {
      //   final rt = await tokens.currentRefreshToken();
      //   if (rt == null) return null;
      //   final newToken = await ref.read(authApiProvider).refresh(rt);
      //   // 业务侧负责把新 token 写回:让 AuthRepository 暴露一个
      //   // updateAccessToken(newToken) 方法,这里调它。
      //   return newToken;
      // },
    )
    // ③ 重试:仅对超时 / 连接错误生效,业务错误不重试。
    ..enableRetry(maxRetries: 0);

  return client;
});