/// 单步异步初始化器。AppBootstrap 会按注册顺序依次执行。
abstract class AppInitializer {
  String get name;

  /// 失败是否阻断后续启动；默认是。
  bool get critical => true;

  Future<void> init();
}

/// 用闭包快速创建一个 [AppInitializer]。
class FunctionalInitializer implements AppInitializer {
  FunctionalInitializer({
    required this.name,
    required Future<void> Function() init,
    this.critical = true,
  }) : _init = init;

  final Future<void> Function() _init;

  @override
  final String name;

  @override
  final bool critical;

  @override
  Future<void> init() => _init();
}
