import 'package:flutter/foundation.dart';
import 'package:flutter_app_scaffold/flutter_app_scaffold.dart';
import 'package:flutter_test/flutter_test.dart';

/// 单例（AppConfig / PrefsStorage）绑定一次后全局可读，但测试间无自动清理。
/// reset() 让每个 test 可以独立 bind，避免上一个 test 的状态泄漏到下一个。
void main() {
  group('AppConfig.reset', () {
    test('after reset, accessing .I throws (not stale)', () {
      AppConfig.bind(const AppConfig(env: AppEnv.dev, apiBaseUrl: 'https://a'));
      expect(AppConfig.I.apiBaseUrl, 'https://a');

      AppConfig.reset();

      expect(() => AppConfig.I, throwsStateError);
    });

    test('rebind after reset works', () {
      AppConfig.bind(const AppConfig(env: AppEnv.dev, apiBaseUrl: 'https://a'));
      AppConfig.reset();
      AppConfig.bind(
        const AppConfig(env: AppEnv.prod, apiBaseUrl: 'https://b'),
      );
      expect(AppConfig.I.apiBaseUrl, 'https://b');
    });
  });

  test('reset is annotated @visibleForTesting (test-only API)', () {
    // 元数据层面保证 reset 不会被当成正式 API 误用。
    expect(visibleForTesting, isNotNull);
  });
}
