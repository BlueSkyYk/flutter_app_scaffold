import 'package:flutter_riverpod/flutter_riverpod.dart';

extension AsyncValueX<T> on AsyncValue<T> {
  /// 仅在有真实数据时取，loading/error 都返回 null。
  T? get dataOrNull => whenOrNull(data: (v) => v);

  /// 是否处于首次加载（无任何数据）。
  bool get isInitialLoading => isLoading && !hasValue;
}
