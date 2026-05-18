import 'app_env.dart';

class AppConfig {
  const AppConfig({
    required this.env,
    required this.apiBaseUrl,
    this.connectTimeout = const Duration(seconds: 10),
    this.receiveTimeout = const Duration(seconds: 15),
    this.sendTimeout = const Duration(seconds: 15),
    this.enableNetworkLog = true,
    this.extra = const {},
  });

  final AppEnv env;
  final String apiBaseUrl;
  final Duration connectTimeout;
  final Duration receiveTimeout;
  final Duration sendTimeout;
  final bool enableNetworkLog;
  final Map<String, Object?> extra;

  static AppConfig? _instance;

  static AppConfig get I {
    final ins = _instance;
    if (ins == null) {
      throw StateError('AppConfig 未初始化，请先调用 AppConfig.bind()');
    }
    return ins;
  }

  static void bind(AppConfig config) => _instance = config;
}
