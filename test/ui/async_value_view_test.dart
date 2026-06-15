import 'package:flutter/material.dart';
import 'package:flutter_app_scaffold/flutter_app_scaffold.dart';
import 'package:flutter_test/flutter_test.dart';

/// `AsyncValueView` 默认错误态应展示可读的 [ApiException.message]，
/// 而不是 `e.toString()`（如 `NetworkException(网络超时)` 这种 runtimeType 形式）。
void main() {
  testWidgets('default error view shows ApiException.message', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AsyncValueView<int>(
          value: AsyncValue<int>.error(
            const NetworkException('网络超时'),
            StackTrace.current,
          ),
          dataBuilder: (_) => const SizedBox.shrink(),
        ),
      ),
    );

    expect(find.text('网络超时'), findsOneWidget);
    expect(
      find.textContaining('NetworkException'),
      findsNothing,
      reason: '不应把 runtimeType 形式抛给用户',
    );
  });

  testWidgets('custom errorBuilder overrides default', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AsyncValueView<int>(
          value: AsyncValue<int>.error(
            const NetworkException('x'),
            StackTrace.current,
          ),
          dataBuilder: (_) => const SizedBox.shrink(),
          errorBuilder: (e, st) => const Text('custom-error'),
        ),
      ),
    );

    expect(find.text('custom-error'), findsOneWidget);
  });
}
