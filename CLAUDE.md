# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository purpose

`flutter_app_scaffold` is a single-package Flutter application scaffold that bundles bootstrap, networking, storage, routing, theming, error handling, and page lifecycle. Business apps depend on it as a path or git package and import everything via the single barrel file `package:flutter_app_scaffold/flutter_app_scaffold.dart`.

The `example/` directory is a working consumer app (login → home, jsonplaceholder API) used as both demo and integration sandbox. README.md (Chinese) is the canonical user-facing documentation.

## Common commands

Run from the package root unless noted.

```bash
# Install / refresh deps for the package
flutter pub get

# Static analysis (very_good_analysis, with overrides in analysis_options.yaml)
flutter analyze

# Format
dart format lib test example/lib

# Run all tests
flutter test

# Run a single test file
flutter test test/flutter_app_scaffold_test.dart

# Run the example app
cd example && flutter pub get && flutter run
```

`example/` is a separate Flutter project; its `pubspec.yaml` resolves the scaffold via `path: ../`. After changing scaffold sources, restart (not just hot-reload) the example to pick up exported symbol changes.

## Architecture

### The barrel + re-export contract

`lib/flutter_app_scaffold.dart` is the **only** public entry point. It re-exports:
- All `src/` public APIs.
- Selected `dio` symbols (`Dio`, `Options`, `Response`, `CancelToken`, `RequestOptions`).
- All of `flutter_riverpod` and `go_router`.

Consumers should never import `package:dio/dio.dart`, `flutter_riverpod`, or `go_router` directly. When adding a new public symbol under `lib/src/`, also add an export line in this file — otherwise it's invisible to consumers.

### Startup pipeline (`AppBootstrap.run`)

Defined in `lib/src/bootstrap/app_bootstrap.dart`. Order matters and is load-bearing:

1. `WidgetsFlutterBinding.ensureInitialized()`
2. Bind the singleton `AppConfig.bind(config)` — anything reading `AppConfig.I` before this throws.
3. Install `GlobalErrorHandler` (FlutterError + PlatformDispatcher + runZonedGuarded).
4. `PrefsStorage.init()` (skippable via `autoInitPrefs: false`).
5. Run user `AppInitializer`s sequentially. A failure in a `critical: true` initializer rethrows and aborts startup; non-critical failures are logged and swallowed.
6. `runApp(...)` inside the guarded zone.

The whole call is wrapped in `GlobalErrorHandler.run`, so async errors during boot also flow to the reporter.

### Singleton conventions

`AppConfig`, `PrefsStorage`, `SecureStorage`, `AppLog` use a `.I` (instance) accessor. They are bound once at startup and read everywhere. Tests that touch these need to bind/configure them in `setUp` — there is no automatic reset between tests yet.

### Network layer

`DioClient` (`lib/src/network/dio_client.dart`) wraps `dio` with two flavors of API:

- `request/get/post/put/delete` — throw `ApiException` (sealed class in `api_exception.dart`).
- `safeRequest` — returns `ApiResult<T>` (success/failure). Prefer this in repositories so callers can pattern-match without try/catch.

`mapDioException` is the single conversion point from `DioException` to the sealed exception hierarchy. When extending the network layer, route every error through it so the sealed switch in callers stays exhaustive.

`enableNetworkLog` in `AppConfig` toggles the built-in `AppLogInterceptor`. Other interceptors (`AuthInterceptor`, `RetryInterceptor`) are opt-in via `client.addInterceptor(...)`.

### Page lifecycle (replaces GetX)

`BasePage` / `BasePageState` (`lib/src/ui/base/base_page.dart`) combines `RouteAware` (via `appRouteObserver`) with `WidgetsBindingObserver` to expose four hooks: `onPageShow`, `onPageHide`, `onAppForeground`, `onAppBackground`.

This only works if the app's router was created via `AppRouter.create`, which auto-attaches `appRouteObserver`. If a consumer constructs `GoRouter` manually they must add `observers: [appRouteObserver]` themselves — otherwise `BasePage` callbacks silently never fire.

The `_isCurrent` / `_isAppForeground` flags coordinate the two observer streams so that backgrounding a covered page doesn't double-fire `onPageHide`. Preserve this invariant when modifying the class.

### Error handling

`GlobalErrorHandler` is the only place that installs `FlutterError.onError`, `PlatformDispatcher.instance.onError`, and `runZonedGuarded`. Never install these elsewhere — the reporter contract assumes a single sink. Consumers plug in their own `ErrorReporter` (e.g., Sentry) at boot.

## Linting notes

`analysis_options.yaml` extends `very_good_analysis` but disables several rules that conflict with this codebase's style: `public_member_api_docs`, `lines_longer_than_80_chars`, `always_use_package_imports` (relative imports inside `lib/src/` are intentional), `sort_pub_dependencies` (deps are grouped semantically), and a few others. Don't re-enable these without discussion.

Generated files (`**/*.g.dart`, `**/*.freezed.dart`, `lib/generated/**`) are excluded from analysis.

## Versioning

Dart SDK `^3.11.5`, Flutter `>=3.24.0`. The package does not depend on `get`/`getx` — page lifecycle is intentionally implemented with platform primitives.