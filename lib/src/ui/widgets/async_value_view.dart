import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'empty_view.dart';
import 'error_view.dart';
import 'loading_view.dart';

/// 把 [AsyncValue] 直接渲染成 loading / error / empty / data 四态。
class AsyncValueView<T> extends StatelessWidget {
  const AsyncValueView({
    super.key,
    required this.value,
    required this.dataBuilder,
    this.loadingBuilder,
    this.errorBuilder,
    this.emptyBuilder,
    this.isEmpty,
    this.onRetry,
  });

  final AsyncValue<T> value;
  final Widget Function(T data) dataBuilder;
  final WidgetBuilder? loadingBuilder;
  final Widget Function(Object error, StackTrace? stack)? errorBuilder;
  final WidgetBuilder? emptyBuilder;
  final bool Function(T data)? isEmpty;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return value.when(
      skipLoadingOnReload: true,
      skipLoadingOnRefresh: true,
      data: (data) {
        if (isEmpty?.call(data) ?? false) {
          return emptyBuilder?.call(context) ?? const EmptyView();
        }
        return dataBuilder(data);
      },
      error: (e, st) {
        return errorBuilder?.call(e, st) ??
            ErrorView(message: e.toString(), onRetry: onRetry);
      },
      loading: () => loadingBuilder?.call(context) ?? const LoadingView(),
    );
  }
}
