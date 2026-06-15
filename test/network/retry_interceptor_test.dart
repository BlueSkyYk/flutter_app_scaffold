import 'package:dio/dio.dart';
import 'package:flutter_app_scaffold/flutter_app_scaffold.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/stub_adapter.dart';

/// `RetryInterceptor` 的契约：仅对超时 / 连接错误做指数退避重试，
/// HTTP / 业务错误不重试；不超过 maxRetries；超时类型才进入重试。
void main() {
  Dio buildDio(StubAdapter adapter) =>
      Dio(BaseOptions(baseUrl: 'https://example.com'))
        ..httpClientAdapter = adapter;

  setUpAll(() {
    AppConfig.bind(
      const AppConfig(env: AppEnv.dev, apiBaseUrl: 'https://example.com'),
    );
  });

  test('retries up to maxRetries on connectionError then propagates failure',
      () async {
    final adapter = StubAdapter(List.filled(5, _connError()));
    final client = DioClient(dio: buildDio(adapter))
      ..enableRetry(
        maxRetries: 2,
        initialDelay: const Duration(milliseconds: 1),
      );

    await expectLater(
      () => client.get<String>('/x'),
      throwsA(isA<NetworkException>()),
    );
    // 首发 1 次 + 重试 2 次 = 3 次。
    expect(adapter.callCount, 3);
  });

  test('does NOT retry on badResponse (non-retryable type)', () async {
    final adapter = StubAdapter(List.filled(5, _badResponse(500)));
    final client = DioClient(dio: buildDio(adapter))
      ..enableRetry(
        maxRetries: 3,
        initialDelay: const Duration(milliseconds: 1),
      );

    await expectLater(
      () => client.get<String>('/x'),
      throwsA(isA<HttpStatusException>()),
    );
    // badResponse 不重试，只调一次。
    expect(adapter.callCount, 1);
  });

  test('succeeds when a later attempt returns 200', () async {
    final adapter = StubAdapter([
      _connError(),
      _connError(),
      okBody(200, '{"ok":1}'),
    ]);
    final client = DioClient(dio: buildDio(adapter))
      ..enableRetry(
        maxRetries: 5,
        initialDelay: const Duration(milliseconds: 1),
      );

    final res = await client.get<String>('/x');
    expect(res.statusCode, 200);
    expect(adapter.callCount, 3, reason: '两次失败 + 第三次成功');
  });

  test('maxRetries=0 disables retry entirely', () async {
    final adapter = StubAdapter([_connError(), okBody(200)]);
    final client = DioClient(dio: buildDio(adapter))
      ..enableRetry(maxRetries: 0);

    await expectLater(
      () => client.get<String>('/x'),
      throwsA(isA<NetworkException>()),
    );
    expect(adapter.callCount, 1, reason: 'maxRetries=0 不应发起重试');
  });
}

DioException _connError() => DioException(
      requestOptions: RequestOptions(path: '/x'),
      type: DioExceptionType.connectionError,
      message: 'boom',
    );

DioException _badResponse(int code) => DioException(
      requestOptions: RequestOptions(path: '/x'),
      type: DioExceptionType.badResponse,
      response: Response<dynamic>(
        requestOptions: RequestOptions(path: '/x'),
        statusCode: code,
      ),
    );
