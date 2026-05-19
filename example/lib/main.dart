import 'package:flutter_app_scaffold/flutter_app_scaffold.dart';

import 'app/app.dart';

void main() {
  AppBootstrap.run(
    config: const AppConfig(
      env: AppEnv.dev,
      apiBaseUrl: 'https://dev.sparktechapps.com/omflo',
    ),
    app: () => const ProviderScope(child: ExampleApp()),
  );
}
