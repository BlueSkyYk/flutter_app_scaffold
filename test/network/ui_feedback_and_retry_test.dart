import 'package:dio/dio.dart';
import 'package:flutter_app_scaffold/flutter_app_scaffold.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/stub_adapter.dart';

/// 脚手架的拦截器通过共享 `RequestOptions.extra` 上的标记互相交互：
/// UI 反馈用 `_kCountedKey`/`_kToastedKey`，重试用 `_retryCountKey`。
/// `RetryInterceptor` 重试时复用**同一个** RequestOptions 对象，
/// 这些标记是否会被正确清理，决定了 loading 计数器在「失败→重试→成功」
/// 的路径上能否平衡。这组测试钉死该交互的正确性。
void main() {
  setUpAll(() {
    AppConfig.bind(
      const AppConfig(env: AppEnv.dev, apiBaseUrl: 'https://example.com'),
    );
  });

  test(
    'loading counter balances when a request fails then retries successfully',
    () async {
      // 脚本：首发连接错误 → 重试成功。maxRetries=1，所以只重试一次。
      final adapter = StubAdapter([
        DioException(
          requestOptions: RequestOptions(path: '/x'),
          type: DioExceptionType.connectionError,
          message: 'boom',
        ),
        okBody(200),
      ]);

      final dio = Dio(BaseOptions(baseUrl: 'https://example.com'))
        ..httpClientAdapter = adapter;

      var startCount = 0;
      var endCount = 0;
      final client = DioClient(dio: dio)
        ..enableUiFeedback(
          UiFeedback(
            onLoadingStart: () => startCount++,
            onLoadingEnd: () => endCount++,
            defaultShowLoading: true,
          ),
        )
        ..enableRetry(
          maxRetries: 1,
          initialDelay: const Duration(milliseconds: 1),
        );

      final res = await client.get<String>('/x');
      expect(res.statusCode, 200);
      expect(adapter.callCount, 2, reason: '首发失败 + 一次重试');

      // 计数器必须平衡：开始几次，结束就该几次，否则全屏 loading 卡死。
      expect(startCount, endCount,
          reason: 'loading start/end 计数不平衡：start=$startCount end=$endCount');
      expect(startCount, greaterThan(0), reason: '至少触发过一次 onLoadingStart');
    },
  );
}
