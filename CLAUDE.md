# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository purpose

`flutter_app_scaffold` is a single-package Flutter application scaffold that bundles bootstrap, networking, storage, routing, theming, error handling, and page lifecycle. Business apps depend on it as a path or git package and import everything via the single barrel file `package:flutter_app_scaffold/flutter_app_scaffold.dart`.

The `example/` directory is a working consumer app (login → home, jsonplaceholder API) used as both demo and integration sandbox. README.md (Chinese) is the canonical user-facing documentation.

## Documentation policy

`README.md` is a **usage document**, not a change log. After any code change, update README and the relevant dartdoc to reflect the **current** state of the API — usage examples, configuration options, behavior contracts. **Do not** add per-change history sections, "what changed" callouts, or migration notes; readers should be able to use the README without knowing what version preceded it. There is no `CHANGELOG.md` in this repo by design.

`CLAUDE.md` (this file) is for engineering rules specific to *maintaining* this repo — keep it current too, but in the same style: rules, not history.

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

**The detailed, single-source-of-truth engineering invariants live in `README.md` §九「工程不变量与陷阱」** — barrel + re-export contract, startup pipeline order, singleton conventions, network-layer load-bearing details (incl. the `_kCountedKey` / `_retriedKey` / single-flight refresh invariants and the two fixes that pin them), page-lifecycle coordination (`_isCurrent` / `_isAppForeground`, the `didPush` re-fire rule), error-handler single-sink, and Riverpod autoDispose + auto-retry. The invariants are stated there in full so a consumer or AI agent can read one file.

When you change scaffold source — especially interceptors, bootstrap, or page lifecycle — read README §九 first. Each invariant is pinned by a test under `test/network/` or `test/ui/`; keep those green when refactoring. This file keeps only what is specific to *maintaining* this repo.

### Dependency boundary (maintainer rule)

The scaffold deliberately excludes plugins that require project-level native config (Android `minSdkVersion`, iOS entitlements, AndroidManifest permissions). Examples that do **not** belong in this package: `flutter_secure_storage`, `connectivity_plus`, `package_info_plus`, push/location/camera plugins. Business apps add these to their own `pubspec.yaml`. This rule prevents the scaffold's release cadence from being held hostage by a single business app's native config.

### Test conventions

- Singletons (`AppConfig`, `PrefsStorage`) expose `@visibleForTesting static void reset()` for teardown; there is no automatic reset between tests. Network tests typically just `AppConfig.bind(...)` in `setUpAll`.
- Tests under `test/network/` and `test/ui/` characterize the load-bearing invariants of the interceptors and page lifecycle — they are the executable spec for README §九. Update both together when behavior intentionally changes.

## Linting notes

`analysis_options.yaml` extends `very_good_analysis` but disables several rules that conflict with this codebase's style: `public_member_api_docs`, `lines_longer_than_80_chars`, `always_use_package_imports` (relative imports inside `lib/src/` are intentional), `sort_pub_dependencies` (deps are grouped semantically), and a few others. Don't re-enable these without discussion.

Generated files (`**/*.g.dart`, `**/*.freezed.dart`, `lib/generated/**`) are excluded from analysis.

## Versioning

Dart SDK `^3.11.5`, Flutter `>=3.24.0`. The package does not depend on `get`/`getx` — page lifecycle is intentionally implemented with platform primitives.
