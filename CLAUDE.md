# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository purpose

`flutter_app_scaffold` is a single-package Flutter application scaffold that bundles bootstrap, networking, storage, routing, theming, error handling, and page lifecycle. Business apps depend on it as a path or git package and import everything via the single barrel file `package:flutter_app_scaffold/flutter_app_scaffold.dart`.

The `example/` directory is a working consumer app (login → home, jsonplaceholder API) used as both demo and integration sandbox. README.md (Chinese) is the canonical user-facing documentation.

## Documentation policy

`README.md` is a **usage document**, not a change log. After any code change, update README and the relevant dartdoc to reflect the **current** state of the API — usage examples, configuration options, behavior contracts. **Do not** add per-change history sections, "what changed" callouts, or migration notes; readers should be able to use the README without knowing what version preceded it. There is no `CHANGELOG.md` in this repo by design.

`CLAUDE.md` (this file) is for engineering rules and load-bearing invariants — keep it current too, but in the same style: rules, not history.

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
- All of `flutter_riverpod`, `go_router`, and `flutter_screenutil`.

Consumers should never import `package:dio/dio.dart`, `flutter_riverpod`, `go_router`, or `flutter_screenutil` directly. When adding a new public symbol under `lib/src/`, also add an export line in this file — otherwise it's invisible to consumers.

### Startup pipeline (`AppBootstrap.run`)

Defined in `lib/src/bootstrap/app_bootstrap.dart`. Order matters and is load-bearing:

1. `WidgetsFlutterBinding.ensureInitialized()`
2. Bind the singleton `AppConfig.bind(config)` — anything reading `AppConfig.I` before this throws.
3. Install `GlobalErrorHandler` (FlutterError + PlatformDispatcher + runZonedGuarded).
4. `PrefsStorage.init()` (skippable via `autoInitPrefs: false`).
5. Run user `AppInitializer`s sequentially. A failure in a `critical: true` initializer rethrows and aborts startup; non-critical failures are logged and swallowed.
6. `runApp(...)` inside the guarded zone, with the user widget wrapped in `ScreenUtilInit(designSize: config.designSize, ...)`. This is the single ScreenUtil init point — consumers must NOT add their own `ScreenUtilInit` (nested init causes redundant LayoutBuilder rebuilds and silent designSize drift).

The whole call is wrapped in `GlobalErrorHandler.run`, so async errors during boot also flow to the reporter.

### Singleton conventions

`AppConfig`, `PrefsStorage`, `AppLog` use a `.I` (instance) accessor. They are bound once at startup and read everywhere. Tests that touch these need to bind/configure them in `setUp` — there is no automatic reset between tests, but each singleton exposes a `@visibleForTesting static void reset()` (`AppConfig.reset()` / `PrefsStorage.reset()`) for explicit teardown. Network tests typically just `AppConfig.bind(...)` in `setUpAll`.

### Dependency boundary

The scaffold deliberately excludes plugins that require project-level native config (Android `minSdkVersion`, iOS entitlements, AndroidManifest permissions). Examples that do **not** belong in this package: `flutter_secure_storage`, `connectivity_plus`, `package_info_plus`, push/location/camera plugins. Business apps add these to their own `pubspec.yaml`. This rule prevents the scaffold's release cadence from being held hostage by a single business app's native config.

### Network layer

`DioClient` (`lib/src/network/dio_client.dart`) wraps `dio` with two flavors of API:

- `request/get/post/put/delete` — throw `ApiException` (sealed class in `api_exception.dart`).
- `safeRequest` — returns `ApiResult<T>` (success/failure). Prefer this in repositories so callers can pattern-match without try/catch.

`mapDioException` is the single conversion point from `DioException` to the sealed exception hierarchy. When extending the network layer, route every error through it so the sealed switch in callers stays exhaustive.

`enableNetworkLog` in `AppConfig` toggles the built-in `AppLogInterceptor`. Other interceptors are opt-in via convenience methods on `DioClient` that auto-bind to the same `Dio` instance:

- `client.enableUiFeedback(UiFeedback)` — loading-counter + error-toast + business-code detection. Per-request override via `Options().ui(loading:?, errorToast:?)` or `Options().silent()`, stored under `kUiFeedbackOverrideKey` in `extra`. The interceptor uses `_kCountedKey` / `_kToastedKey` extra flags to prevent double-decrement / double-toast when an `onResponse` rejection cascades to `onError`. **`onRequest` clears `_kCountedKey`** so that when `RetryInterceptor` reuses the same `RequestOptions` for a new fetch, each fetch's counter increment/decrement stays balanced — without this, a failed-then-retried request leaks +1 on the loading counter and the global mask never hides (pinned by `test/network/ui_feedback_and_retry_test.dart`).
- `client.enableAuth(tokenProvider, refreshToken?, shouldRefresh?, onUnauthorized?)` — token injection + 401 refresh-and-retry. Concurrent 401s share a single refresh via the `_refreshing` future field on `AuthInterceptor`. The `_retriedKey` extra marker prevents re-refresh after a retried request still returns 401 (avoids infinite loops). Per-request opt-out: `Options().noAuth()` (or raw `extra: {kAuthSkipKey: true}`) skips token injection AND suppresses the 401 → refresh / onUnauthorized chain — required for endpoints like `/login` whose 401 means "wrong credentials" rather than "session expired". When a retried request still returns 401, the retry's inner `onError` re-enters `AuthInterceptor` with `_retriedKey=true`; that re-entry must **not** call `onUnauthorized` — the outer retry's catch block owns that single call. Skipping `onUnauthorized` when `alreadyRetried` prevents a double-call (pinned by `test/network/auth_interceptor_test.dart`).
- `client.enableRetry(maxRetries, initialDelay)` — exponential-backoff retry for timeout / connection errors only.

**Recommended add-order**: `enableUiFeedback()` → `enableAuth()` → `enableRetry()`. UI feedback sits on the outermost layer of the chain so it sees final outcomes (auth refresh success treated as success; retry exhaustion treated as failure).

`UiFeedbackInterceptor.onResponse` rejects with `DioException(error: BusinessException, type: unknown)` when `detectBusinessError` returns non-null. `mapDioException` therefore checks `e.error is ApiException` first and passes it through verbatim — without that, the business code error would be silently downgraded to `NetworkException` by the type-based switch. Preserve this unwrap when extending the exception mapping.

Manual `client.addInterceptor(AuthInterceptor(..., dio: client.raw))` is still supported but error-prone — prefer the `enableX` methods. When extending `AuthInterceptor`, preserve the single-flight invariant (the `_refreshing` future) and the retry marker semantics; both are load-bearing for correctness under concurrency.

### Page lifecycle (replaces GetX)

`BasePage` / `BasePageState` (`lib/src/ui/base/base_page.dart`) combines `RouteAware` (via `appRouteObserver`) with `WidgetsBindingObserver` to expose four hooks: `onPageShow`, `onPageHide`, `onAppForeground`, `onAppBackground`.

This only works if the app's router was created via `AppRouter.create`, which auto-attaches `appRouteObserver`. If a consumer constructs `GoRouter` manually they must add `observers: [appRouteObserver]` themselves — otherwise `BasePage` callbacks silently never fire.

The `_isCurrent` / `_isAppForeground` flags coordinate the two observer streams so that backgrounding a covered page doesn't double-fire `onPageHide`. Preserve this invariant when modifying the class.

`RouteObserver.subscribe` internally fires `didPush` once on registration, so the initial route (e.g. `initialLocation` of GoRouter) does receive `onPageShow` even though the actual push happened before `didChangeDependencies` ran. **Do not** add manual `route.isCurrent` re-firing — it would double-fire `onPageShow` on the initial route.

`dispose()` does **not** call `onPageHide` (the page is already unmounted; `setState` / `context` use would throw). Subclasses must do their own cleanup in `dispose`. The normal pop path fires `onPageHide` via `didPop` before `dispose`.

### Error handling

`GlobalErrorHandler` is the only place that installs `FlutterError.onError`, `PlatformDispatcher.instance.onError`, and `runZonedGuarded`. Never install these elsewhere — the reporter contract assumes a single sink. Consumers plug in their own `ErrorReporter` (e.g., Sentry) at boot.

### Riverpod `autoDispose` lifecycle

`autoDispose` providers are reference-counted: each `ref.watch` / `ref.listen` adds a listener, each unmount removes one. When the count hits zero the provider is disposed on the next frame and recreated on next watch. `ref.read` does **not** count — using `ref.read` in `initState` does not keep an autoDispose provider alive.

Conventions for this codebase:

- **Page-scoped state** (lists, details, forms, search results) → use `autoDispose`. Memory frees on navigation pop. Cross-page sharing still works because the source page stays mounted while its detail is on top of the stack.
- **Long-lived global state** (auth, theme, current user, singletons like `DioClient` / `FlutterSecureStorage`) → plain `Provider` / `NotifierProvider`, never autoDispose.
- **External resources** (Timer, StreamSubscription, WebSocket) acquired inside `build()` must be released in `ref.onDispose(() { ... })` — not doing so leaks the resource across rebuilds.

Two load-bearing pitfalls to know about:

1. **Async-after-pop crashes**: if a method writes to `state` after an `await` that completes after the page popped, the notifier is already disposed and the assignment throws. Always guard with `if (!ref.mounted) return;` between `await` and `state = ...`.
2. **`ref.keepAlive()` opt-out**: returns a `KeepAliveLink` that suspends auto-disposal until `link.close()` is called. Use for "cache N minutes" / "don't dispose mid-save" semantics. Don't reach for it as a default — defeating autoDispose by reflex causes silent memory growth.

`autoDispose` providers depending on each other via `ref.watch` can create dispose-recreate cycles; prefer `ref.read` for cross-provider lookups inside autoDispose providers, or accept that the dependency keeps the upstream alive as long as the downstream lives.

### Riverpod 3 auto-retry (load-bearing gotcha)

Riverpod 3 enables **automatic exponential-backoff retry** by default on all async providers (`AsyncNotifierProvider`, `FutureProvider`, `StreamProvider`). When `build()` throws an `Exception` (not `Error`), Riverpod silently retries up to **10 times** with delays 200ms → 6.4s, totalling ~38s before giving up. Source: `riverpod/lib/src/core/provider_container.dart` `defaultRetry`.

This is **not** a scaffold-level retry — it's framework default. It stacks on top of `DioClient.enableRetry()` (which does HTTP-level retry on timeout/connection errors). Worst case, a single logical failure can cause `(1 + dio.maxRetries) × (1 + 10)` HTTP requests over multiple minutes.

Convention for this codebase:
- **List / pagination / detail screens** with a manual "retry" button: disable per-provider with `retry: (_, _) => null`. Users get immediate error feedback.
- **Long-lived global providers** (token restore, config fetch): keep the default — these benefit from transient-failure recovery.
- **Never** rely on Riverpod retry as a substitute for proper error handling — it just delays the failure UI by 30+ seconds.

When writing a new `AsyncNotifierProvider`, decide explicitly whether retry is desired and pass the `retry:` argument accordingly. Treating it as "don't think about it, defaults are fine" leads to confusing UX (long loading → eventual error).

## Linting notes

`analysis_options.yaml` extends `very_good_analysis` but disables several rules that conflict with this codebase's style: `public_member_api_docs`, `lines_longer_than_80_chars`, `always_use_package_imports` (relative imports inside `lib/src/` are intentional), `sort_pub_dependencies` (deps are grouped semantically), and a few others. Don't re-enable these without discussion.

Generated files (`**/*.g.dart`, `**/*.freezed.dart`, `lib/generated/**`) are excluded from analysis.

## Versioning

Dart SDK `^3.11.5`, Flutter `>=3.24.0`. The package does not depend on `get`/`getx` — page lifecycle is intentionally implemented with platform primitives.