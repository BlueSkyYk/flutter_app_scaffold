import 'package:app_scaffold/app_scaffold.dart';
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
}
