enum AppEnv {
  dev,
  staging,
  prod;

  bool get isProd => this == AppEnv.prod;
  bool get isDev => this == AppEnv.dev;

  static AppEnv fromString(String value) {
    return AppEnv.values.firstWhere(
      (e) => e.name == value,
      orElse: () => AppEnv.dev,
    );
  }
}
