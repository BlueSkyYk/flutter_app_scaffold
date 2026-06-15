import 'package:dio/dio.dart';
import 'package:flutter_app_scaffold/flutter_app_scaffold.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/stub_adapter.dart';

/// `AuthInterceptor` 的核心不变量（CLAUDE.md 里被反复强调为 load-bearing）：
/// 1. 并发 401 单飞：多个请求同时 401 只刷新一次。
/// 2. `noAuth` 请求即使 401 也不触发刷新 / onUnauthorized。
/// 3. 刷新成功后重发仍 401 时不会二次刷新（防死循环）。
/// 4. 刷新返回 null / 抛错视为失败，触发 onUnauthorized。
void main() {
  setUpAll(() {
    AppConfig.bind(
      const AppConfig(env: AppEnv.dev, apiBaseUrl: 'https://example.com'),
    );
  });

  Dio buildDio(StubAdapter adapter) =>
      Dio(BaseOptions(baseUrl: 'https://example.com'))
        ..httpClientAdapter = adapter;

  DioException unauthorized401(RequestOptions opts) => DioException(
        requestOptions: opts,
        type: DioExceptionType.badResponse,
        response: Response<dynamic>(requestOptions: opts, statusCode: 401),
      );

  test('concurrent 401s share a single refresh (single-flight)', () async {
    // 两个原始请求都 401，刷新一次后两个重发都 200。
    final adapter = StubAdapter([
      unauthorized401(RequestOptions(path: '/a')),
      unauthorized401(RequestOptions(path: '/b')),
      okBody(200),
      okBody(200),
    ]);

    var refreshCount = 0;
    final client = DioClient(dio: buildDio(adapter))..enableAuth(
      tokenProvider: () async => 'old-token',
      refreshToken: () async {
        refreshCount++;
        // 拉长刷新耗时，确保第二个 401 在刷新未完成时进入 onError，
        // 才能验证它复用同一个 in-flight refresh。
        await Future<void>.delayed(const Duration(milliseconds: 30));
        return 'new-token';
      },
    );

    // 并发发起，不 await 中间步骤。
    final results = await Future.wait([
      client.get<String>('/a'),
      client.get<String>('/b'),
    ]);

    expect(results.map((r) => r.statusCode), {200});
    expect(refreshCount, 1, reason: '并发 401 必须单飞，只刷新一次');
  });

  test('noAuth request: 401 does not trigger refresh nor onUnauthorized',
      () async {
    final adapter = StubAdapter([unauthorized401(RequestOptions(path: '/login'))]);

    var refreshCount = 0;
    var unauthCalled = 0;
    final client = DioClient(dio: buildDio(adapter))..enableAuth(
      tokenProvider: () async => 'ignored',
      refreshToken: () async {
        refreshCount++;
        return 'never';
      },
      onUnauthorized: () async => unauthCalled++,
    );

    // noAuth：401 直接抛回，不刷新、不走 onUnauthorized。
    await expectLater(
      () => client.get<String>('/login', options: Options().noAuth()),
      throwsA(isA<HttpStatusException>()),
    );
    expect(refreshCount, 0);
    expect(unauthCalled, 0);
  });

  test('retried request still 401 → no second refresh, calls onUnauthorized',
      () async {
    // 原始 401 → 刷新成功 → 重发仍 401。应只刷新一次，且触发 onUnauthorized。
    final adapter = StubAdapter([
      unauthorized401(RequestOptions(path: '/x')),
      unauthorized401(RequestOptions(path: '/x')),
    ]);

    var refreshCount = 0;
    var unauthCalled = 0;
    final client = DioClient(dio: buildDio(adapter))..enableAuth(
      tokenProvider: () async => 't',
      refreshToken: () async {
        refreshCount++;
        return 'new-token';
      },
      onUnauthorized: () async => unauthCalled++,
    );

    await expectLater(
      () => client.get<String>('/x'),
      throwsA(isA<HttpStatusException>()),
    );
    expect(refreshCount, 1, reason: '重发仍 401 不应二次刷新（防死循环）');
    expect(unauthCalled, 1, reason: '新 token 也失效时应触发 onUnauthorized');
  });

  test('refresh returning null triggers onUnauthorized', () async {
    final adapter = StubAdapter([unauthorized401(RequestOptions(path: '/x'))]);

    var unauthCalled = 0;
    final client = DioClient(dio: buildDio(adapter))..enableAuth(
      tokenProvider: () async => 't',
      refreshToken: () async => null,
      onUnauthorized: () async => unauthCalled++,
    );

    await expectLater(
      () => client.get<String>('/x'),
      throwsA(isA<HttpStatusException>()),
    );
    expect(unauthCalled, 1);
  });
}
