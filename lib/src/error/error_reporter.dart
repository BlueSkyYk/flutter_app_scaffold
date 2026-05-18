/// 错误上报抽象。可以接 Sentry / Crashlytics / 自建后端。
abstract class ErrorReporter {
  Future<void> report(
    Object error,
    StackTrace stackTrace, {
    Map<String, Object?>? context,
    bool fatal = false,
  });
}

/// 默认实现：什么也不做。
class NoopErrorReporter implements ErrorReporter {
  const NoopErrorReporter();

  @override
  Future<void> report(
    Object error,
    StackTrace stackTrace, {
    Map<String, Object?>? context,
    bool fatal = false,
  }) async {}
}
