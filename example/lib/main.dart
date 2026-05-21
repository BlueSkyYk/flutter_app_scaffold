import 'package:flutter_app_scaffold/flutter_app_scaffold.dart';

import 'app/app.dart';

void main() {
  AppBootstrap.run(
    config: const AppConfig(
      env: AppEnv.dev,
      apiBaseUrl: 'http://10.42.0.135:8085/dev/api',
    ),
    app: () => const ProviderScope(child: ExampleApp()),
  );
}
