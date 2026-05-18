# flutter_app_scaffold

Flutter 应用脚手架。一个包搞定新项目最常见的脏活：**启动初始化、网络、存储、路由、主题、错误兜底、页面生命周期**。

## 一、为什么是它

一个新 Flutter 项目通常要重复做这些事：

- 异步初始化要按顺序跑（日志、配置、存储、网络…）
- dio 要装拦截器（鉴权、日志、重试），异常要统一
- 路由要支持 deeplink、有 RouteObserver 给页面派发生命周期
- 状态管理 / 主题 / loading-empty-error 三态展示
- 全局未捕获异常要兜底 + 上报

`flutter_app_scaffold` 把这些工程化模板抽成单包，业务侧 `pubspec` 加一行即可。

## 二、技术选型

| 模块 | 选型 |
|---|---|
| 状态管理 | [`flutter_riverpod`](https://pub.dev/packages/flutter_riverpod) |
| 路由 | [`go_router`](https://pub.dev/packages/go_router) |
| 网络 | [`dio`](https://pub.dev/packages/dio) |
| 存储 | `shared_preferences` + `flutter_secure_storage` |
| 日志 | `logger` |
| 设备/网络 | `connectivity_plus` + `package_info_plus` |
| Lint | `very_good_analysis` |

> **GetX 不再使用**。页面生命周期通过 `RouteObserver` + `WidgetsBindingObserver` 实现，原生方案，包体更小。

## 三、安装

monorepo 同目录：

```yaml
dependencies:
  flutter_app_scaffold:
    path: ../flutter_app_scaffold
```

或 git：

```yaml
dependencies:
  flutter_app_scaffold:
    git:
      url: https://github.com/your/flutter_app_scaffold.git
      ref: v0.1.0
```

业务侧只需一处导入：

```dart
import 'package:flutter_app_scaffold/flutter_app_scaffold.dart';
```

`flutter_riverpod`、`go_router`、`dio` 已被 re-export，无需重复 import。

## 四、快速开始

```dart
import 'package:flutter_app_scaffold/flutter_app_scaffold.dart';
import 'package:flutter/material.dart';

void main() {
  AppBootstrap.run(
    config: const AppConfig(
      env: AppEnv.dev,
      apiBaseUrl: 'https://api.example.com',
    ),
    initializers: [
      FunctionalInitializer(
        name: 'di',
        init: () async {
          // 注册全局依赖：DioClient、Repository 等
        },
      ),
    ],
    app: () => const ProviderScope(child: MyApp()),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final router = AppRouter.create(
      routes: [
        GoRoute(path: '/', builder: (_, __) => const HomePage()),
      ],
    );
    return MaterialApp.router(
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      routerConfig: router,
    );
  }
}
```

## 五、各模块用法

### 1. 启动初始化 `AppBootstrap`

`AppBootstrap.run` 自动完成：

1. `WidgetsFlutterBinding.ensureInitialized()`
2. 绑定 `AppConfig`
3. 安装全局错误兜底（FlutterError + PlatformDispatcher + runZonedGuarded）
4. 初始化 `PrefsStorage`
5. 顺序执行你提供的 `AppInitializer`
6. `runApp(...)`

自定义初始化器：

```dart
class FirebaseInitializer implements AppInitializer {
  @override
  String get name => 'firebase';

  @override
  bool get critical => false; // 失败不阻断启动

  @override
  Future<void> init() async {
    // await Firebase.initializeApp(...);
  }
}
```

### 2. 配置 `AppConfig` / `AppEnv`

```dart
const config = AppConfig(
  env: AppEnv.prod,
  apiBaseUrl: 'https://api.example.com',
  connectTimeout: Duration(seconds: 8),
  enableNetworkLog: false,
  extra: {'cdnBase': 'https://cdn.example.com'},
);

// 任意位置访问
final base = AppConfig.I.apiBaseUrl;
if (AppConfig.I.env.isProd) { /* ... */ }
```

### 3. 日志 `AppLog`

```dart
AppLog.d('debug 信息');
AppLog.i('普通信息');
AppLog.w('警告');
AppLog.e('错误', error: e, stackTrace: st);
```

release 模式默认只输出 `warning` 以上。自定义 printer / output：

```dart
AppLog.configure(Logger(/* ... */));
```

### 4. 存储

KV：

```dart
await PrefsStorage.I.setString('uid', '123');
final uid = await PrefsStorage.I.getString('uid');
```

敏感数据（token / 密钥）：

```dart
await SecureStorage.I.write('access_token', token);
final token = await SecureStorage.I.read('access_token');
```

业务侧建议依赖 `KvStorage` 接口而非具体实现，方便测试 mock。

### 5. 网络

最小用法：

```dart
final client = DioClient();
final res = await client.get<Map<String, dynamic>>('/users/me');
```

加拦截器：

```dart
client.addInterceptor(
  AuthInterceptor(
    tokenProvider: () => SecureStorage.I.read('access_token'),
    onUnauthorized: () async {
      // 跳登录、清 token
    },
  ),
);
client.addInterceptor(RetryInterceptor(dio: client.raw));
```

`safeRequest` 把成功/失败封装成 `ApiResult`，业务无需 try-catch：

```dart
final result = await client.safeRequest((c) async {
  final r = await c.get<Map<String, dynamic>>('/users/me');
  return User.fromJson(r.data!);
});

result.when(
  success: (user) => debugPrint(user.name),
  failure: (e) => debugPrint('failed: ${e.message}'),
);
```

异常体系（sealed class，`switch` 即可穷举）：

- `NetworkException` 网络/超时/连接失败
- `HttpStatusException` 非 2xx
- `BusinessException` 业务 code 失败（业务侧自行抛出）
- `CancelException` 请求取消
- `ParseException` 解析异常

### 6. 路由

```dart
final router = AppRouter.create(
  initialLocation: '/home',
  routes: [
    GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
    GoRoute(path: '/home', builder: (_, __) => const HomePage()),
  ],
  redirect: (context, state) {
    // 鉴权重定向
    return null;
  },
);
```

`AppRouter.create` 会自动挂上 `appRouteObserver`，`BasePage` 才能感知 push/pop。

### 7. 页面基类 `BasePage`

继承 `BasePageState`，重写四个钩子：

```dart
class HomePage extends BasePage {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends BasePageState<HomePage> {
  @override
  void onPageShow() {
    // 首次进入 / 从下一页返回 / 从后台回前台 都会触发
    AppLog.i('home shown');
  }

  @override
  void onPageHide() {}

  @override
  void onAppForeground() {}

  @override
  void onAppBackground() {}

  @override
  Widget build(BuildContext context) => const Scaffold(/* ... */);
}
```

> 这就是替代 GetX 页面生命周期能力的方案，零三方依赖。

### 8. 主题

```dart
MaterialApp(
  theme: AppTheme.light(
    colors: const AppColors(primary: Color(0xFF1677FF)),
  ),
  darkTheme: AppTheme.dark(),
);
```

### 9. AsyncValue 三态视图

配合 Riverpod 的 `AsyncValue` 直接渲染 loading / data / error / empty：

```dart
class UserListPage extends ConsumerWidget {
  const UserListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final users = ref.watch(userListProvider);
    return Scaffold(
      body: AsyncValueView<List<User>>(
        value: users,
        isEmpty: (list) => list.isEmpty,
        onRetry: () => ref.invalidate(userListProvider),
        dataBuilder: (list) => ListView(/* ... */),
      ),
    );
  }
}
```

### 10. 错误兜底

`AppBootstrap.run` 已自动安装。接入上报：

```dart
class SentryReporter implements ErrorReporter {
  @override
  Future<void> report(Object error, StackTrace stack,
      {Map<String, Object?>? context, bool fatal = false}) async {
    // await Sentry.captureException(error, stackTrace: stack);
  }
}

AppBootstrap.run(
  config: ...,
  errorReporter: SentryReporter(),
  app: ...,
);
```

## 六、目录结构

```
lib/
├── flutter_app_scaffold.dart                 # 统一导出
└── src/
    ├── bootstrap/                    # AppBootstrap / AppInitializer
    ├── config/                       # AppConfig / AppEnv
    ├── error/                        # ErrorReporter / GlobalErrorHandler
    ├── log/                          # AppLog
    ├── network/                      # DioClient / ApiResult / 拦截器
    │   └── interceptors/
    ├── router/                       # AppRouter / appRouteObserver
    ├── state/                        # AsyncValue 扩展
    ├── storage/                      # KvStorage / Prefs / Secure
    └── ui/
        ├── base/                     # BasePage / BasePageState
        ├── theme/                    # AppTheme / Colors / TextStyles
        └── widgets/                  # Loading/Empty/Error/AsyncValueView/KeepAlive
```

## 七、版本与兼容

- Dart SDK：`>=3.11.5`
- Flutter：`>=3.24.0`
- 不依赖 `get` / `getx`。

## 八、推荐工程实践

1. 业务包按 feature 切目录，每个 feature 包含 `data / domain / presentation`
2. Repository 返回 `ApiResult<T>` 而非抛异常
3. 数据模型用 `freezed`（业务侧自行加，脚手架不强绑定）
4. 路由集中放 `lib/router/`，每个 feature 暴露自己的 `RouteBase` 列表
5. 页面继承 `BasePage`，需要保活的子组件包 `KeepAliveWrapper`

## CHANGELOG

- 0.1.0：首个版本。完成 bootstrap / config / log / storage / network / router / theme / ui / base / error。
