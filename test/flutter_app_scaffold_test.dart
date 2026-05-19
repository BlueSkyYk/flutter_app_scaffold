import 'package:dio/dio.dart' show DioException, DioExceptionType;
import 'package:flutter_app_scaffold/flutter_app_scaffold.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ApiResult', () {
    test('success exposes data', () {
      const r = ApiResult<int>.success(42);
      expect(r.isSuccess, true);
      expect(r.dataOrNull, 42);
      expect(r.errorOrNull, isNull);
    });

    test('failure exposes error', () {
      const r = ApiResult<int>.failure(NetworkException('boom'));
      expect(r.isFailure, true);
      expect(r.dataOrNull, isNull);
      expect(r.errorOrNull, isA<NetworkException>());
    });

    test('map transforms only success', () {
      const ok = ApiResult<int>.success(2);
      expect(ok.map((v) => v * 10).dataOrNull, 20);

      const fail = ApiResult<int>.failure(NetworkException('x'));
      expect(fail.map((v) => v * 10).isFailure, true);
    });

    test('when dispatches branches', () {
      final r1 = const ApiResult<int>.success(1).when(
        success: (v) => 'ok-$v',
        failure: (e) => 'err',
      );
      expect(r1, 'ok-1');

      final r2 = const ApiResult<int>.failure(NetworkException('x')).when(
        success: (v) => 'ok',
        failure: (e) => 'err-${e.message}',
      );
      expect(r2, 'err-x');
    });
  });

  group('AppEnv', () {
    test('fromString matches name', () {
      expect(AppEnv.fromString('prod'), AppEnv.prod);
      expect(AppEnv.fromString('staging'), AppEnv.staging);
      expect(AppEnv.fromString('unknown'), AppEnv.dev);
    });
  });

  group('mapDioException', () {
    test('passes through ApiException carried in DioException.error', () {
      const biz = BusinessException('biz fail', code: 4001);
      final e = DioException(
        requestOptions: RequestOptions(path: '/x'),
        error: biz,
        type: DioExceptionType.unknown,
      );
      expect(mapDioException(e), same(biz));
    });

    test('falls back by type when error is not ApiException', () {
      final e = DioException(
        requestOptions: RequestOptions(path: '/x'),
        type: DioExceptionType.connectionTimeout,
      );
      expect(mapDioException(e), isA<NetworkException>());
    });
  });

  group('UiOptions extension', () {
    test('ui() puts UiOverride into extra', () {
      final opts = Options().ui(loading: true, errorToast: false);
      final ov = opts.extra?[kUiFeedbackOverrideKey] as UiOverride?;
      expect(ov, isNotNull);
      expect(ov!.showLoading, true);
      expect(ov.showErrorToast, false);
    });

    test('silent() disables both loading and toast', () {
      final opts = Options().silent();
      final ov = opts.extra?[kUiFeedbackOverrideKey] as UiOverride?;
      expect(ov!.showLoading, false);
      expect(ov.showErrorToast, false);
    });

    test('ui() preserves existing extra entries', () {
      final opts =
          Options(extra: {'foo': 1}).ui(loading: true);
      expect(opts.extra?['foo'], 1);
      expect(opts.extra?[kUiFeedbackOverrideKey], isA<UiOverride>());
    });
  });
}
