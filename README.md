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
| 存储 | `shared_preferences` |
| 日志 | `logger` |
| 屏幕适配 | [`flutter_screenutil`](https://pub.dev/packages/flutter_screenutil) |
| Lint | `very_good_analysis` |

> **GetX 不再使用**。页面生命周期通过 `RouteObserver` + `WidgetsBindingObserver` 实现，原生方案，包体更小。
>
> **不内置的依赖**：脚手架刻意不引入会触发原生工程配置（minSdk / 权限 / entitlement）的插件，例如 `flutter_secure_storage`、`connectivity_plus`、`package_info_plus`、推送 / 定位 / 相机等。需要时由业务自行在自家 `pubspec` 引入，避免脚手架升级和业务原生配置耦合。

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
      ref: main
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
        GoRoute(path: '/', builder: (_, _) => const HomePage()),
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
  designSize: Size(375, 812), // 屏幕适配设计稿尺寸,见第 13 节
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

业务侧建议依赖 `KvStorage` 接口而非具体实现，方便测试 mock。

> 敏感数据（access token / refresh token / 密钥）请业务自行引入
> [`flutter_secure_storage`](https://pub.dev/packages/flutter_secure_storage) 等插件。
> 脚手架不内置：这类插件会强制 Android `minSdkVersion` / iOS Keychain entitlement
> 等项目级原生配置，由业务在自家 `pubspec` 显式声明更合适。

### 5. 网络

最小用法：

```dart
final client = DioClient();
final res = await client.get<Map<String, dynamic>>('/users/me');
```

#### 启用鉴权（含 token 自动刷新）

`enableAuth` 一行启用：注入 token、检测 401、调用业务侧 refresh、重发原请求。

```dart
client.enableAuth(
  // 每次请求前异步取当前 token
  tokenProvider: () => secureStorage.read(key: 'access_token'),

  // 配置后即开启 401 → refresh → 重发原请求
  refreshToken: () async {
    final rt = await secureStorage.read(key: 'refresh_token');
    if (rt == null) return null;

    // 推荐用一个独立 Dio 调刷新接口，避免循环
    final resp = await Dio().post(
      'https://api.example.com/auth/refresh',
      data: {'refresh_token': rt},
    );
    final newAccess = resp.data['access_token'] as String;
    await secureStorage.write(key: 'access_token', value: newAccess);
    return newAccess; // 拦截器拿到新 token 后会重发原请求
  },

  // refresh 失败 / 未配 refresh / 重发仍失败时调用
  onUnauthorized: () async {
    await secureStorage.deleteAll();
    appRouter.go('/login');
  },
);
```

刷新机制覆盖的边界：

| 场景 | 行为 |
|---|---|
| N 个请求并发 401 | 单飞合并：只刷新 1 次，所有请求共用结果 |
| 刷新成功 | 自动用新 token 重发原请求，业务方拿到的是 200 |
| `refreshToken` 抛异常 / 返回 null | 调 `onUnauthorized`，原 401 抛回业务 |
| 重发后仍 401（新 token 也失效） | 不二次刷新（防死循环），调 `onUnauthorized` |
| 自定义鉴权语义（200 + 业务 code） | 传 `shouldRefresh: (err) => ...` 覆盖默认判断 |

> 业务负责持久化新 token：`refreshToken` 回调内必须先写入存储，再 `return newAccess`，
> 这样下次 `tokenProvider()` 才能读到最新值。

##### 单接口跳过鉴权 `Options().noAuth()`

登录、验证码、注册、公开内容等接口**不应该**带当前用户 token。在调用点显式标记即可：

```dart
// 登录:不带 token
await client.post(
  '/auth/login',
  data: {'phone': phone, 'code': code},
  options: Options().noAuth(),
);

// 公开内容:理论上带不带都行,带上反而暴露用户信息
await client.get('/public/banner', options: Options().noAuth());

// 链式组合:不带 token + 不弹 toast/loading
await client.post('/heartbeat', options: Options().noAuth().silent());
```

`noAuth()` 做两件事：

1. **`onRequest` 不注入 Authorization header**
2. **即使响应 401，也不触发 `refreshToken` / `onUnauthorized`**（避免 `/login` 返回 401「账号密码错」被错误识别成 session 过期）

如果业务侧不想用扩展，可以裸写 `extra: {kAuthSkipKey: true}`，效果相同。但推荐 `Options().noAuth()` —— 类型安全、易读、跟 `silent()` / `ui(...)` 风格一致。

#### 启用重试（针对网络层错误）

```dart
client.enableRetry(maxRetries: 2, initialDelay: Duration(milliseconds: 500));
```

仅对超时 / 连接错误做指数退避重试。建议 `enableAuth()` → `enableRetry()` 顺序添加。

#### 启用 UI 反馈（loading 遮罩 + 错误 toast）

把"显示 loading / 失败 toast"的样板从每个调用点抽走，业务在启动时一次性注入回调即可：

```dart
client.enableUiFeedback(UiFeedback(
  // loading 计数器：0→1 时调 start，N→0 时调 end
  onLoadingStart: () => globalLoading.show(),
  onLoadingEnd:   () => globalLoading.hide(),

  // 错误展示（仅 showErrorToast=true 时调）
  onError: (ApiException e) => Toast.show(e.message),

  // 业务码错误检测：把 200 + 非 0 code 翻译成 BusinessException
  detectBusinessError: (response) {
    final data = response.data as Map<String, dynamic>;
    final code = data['code'] as int? ?? 0;
    if (code != 0) {
      return BusinessException(
        data['msg'] as String? ?? '请求失败',
        code: code,
        data: data['data'],
      );
    }
    return null;
  },

  defaultShowLoading: false,    // 默认不显示遮罩
  defaultShowErrorToast: true,  // 默认弹错误 toast
));
```

调用时按需通过 `Options().ui(...)` / `silent()` 覆盖默认：

```dart
// 走默认（不显遮罩、错误弹 toast）
await client.get('/users');

// 关键动作显式开 loading
await client.post('/login',
  data: x,
  options: Options().ui(loading: true),
);

// 心跳 / 埋点静默
await client.get('/heartbeat', options: Options().silent());

// 只关 toast、loading 沿用默认
await client.get('/poll', options: Options().ui(errorToast: false));
```

行为保证：

| 场景 | 行为 |
|---|---|
| 多个并发请求都 `showLoading` | 只调 1 次 `onLoadingStart`、1 次 `onLoadingEnd` |
| 业务码失败（`detectBusinessError` 返回非 null） | 自动调 `onError` 弹 toast，原 `safeRequest` 拿到 `ApiResult.failure(BusinessException)` |
| 网络错误 / HTTP 错误 | 调 `onError`，业务侧仍可在 `safeRequest` 里继续处理 |

> **拦截器顺序建议**：`enableUiFeedback()` → `enableAuth()` → `enableRetry()`。
> UI 反馈在最外圈，能正确捕获最终结果（鉴权刷新成功视为成功，重试穷尽后视为失败）。

#### `safeRequest` 把成功/失败封装成 `ApiResult`，业务无需 try-catch

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

#### 异常体系（sealed class，`switch` 即可穷举）

- `NetworkException` 网络/超时/连接失败
- `HttpStatusException` 非 2xx
- `BusinessException` 业务 code 失败（由 `UiFeedback.detectBusinessError` 翻译，或业务自行抛出）
- `CancelException` 请求取消
- `ParseException` 解析异常

`mapDioException` 是 `DioException → ApiException` 的唯一转换点。若拦截器把
`ApiException` 包装在 `DioException.error` 字段里 reject，转换函数会直通透传，不会被
按 `DioExceptionType` 错误降级——业务码错误能正确流向 `safeRequest`。

### 6. 路由

```dart
final router = AppRouter.create(
  initialLocation: '/home',
  routes: [
    GoRoute(path: '/login', builder: (_, _) => const LoginPage()),
    GoRoute(path: '/home', builder: (_, _) => const HomePage()),
  ],
  redirect: (context, state) {
    // 鉴权重定向
    return null;
  },
);
```

`AppRouter.create` 会自动挂上 `appRouteObserver`，`BasePage` / `PageLifecycleMixin`
才能感知 push/pop。

### 7. 页面写法与生命周期

页面有两个独立的诉求维度：**是否需要 Riverpod `ref`** 和 **是否需要页面级生命周期**
（`onPageShow / onPageHide / onAppForeground / onAppBackground`）。按需要组合，避免一律继承同一个基类。

| 需要 ref | 需要生命周期 | 推荐写法 |
|---|---|---|
| ❌ | ❌ | `StatelessWidget` / `StatefulWidget` |
| ✅ | ❌ | `ConsumerWidget` / `ConsumerStatefulWidget` |
| ❌ | ✅ | `BasePage` + `BasePageState` |
| ✅ | ✅ | `ConsumerStatefulWidget` + `PageLifecycleMixin` |

四个生命周期钩子的语义：

- `onPageShow`：当前页变为顶层（首次进入 / 从下一页返回 / 从后台回前台）。
- `onPageHide`：当前页被遮挡（push 新页 / 进入后台）。
- `onAppForeground` / `onAppBackground`：应用前后台切换。

**前提**：路由必须挂 `appRouteObserver`。`AppRouter.create` 自动挂；手写 `GoRouter`
时自行 `observers: [appRouteObserver]`，否则回调静默不触发。

#### 只要生命周期：`BasePage` + `BasePageState`

```dart
class TrackingPage extends BasePage {
  const TrackingPage({super.key});
  @override
  State<TrackingPage> createState() => _TrackingPageState();
}

class _TrackingPageState extends BasePageState<TrackingPage> {
  @override
  void onPageShow() => Analytics.track('tracking_show');

  @override
  void onPageHide() => Analytics.track('tracking_hide');

  @override
  Widget build(BuildContext context) => const Scaffold(/* ... */);
}
```

#### 同时要 ref 和生命周期：`PageLifecycleMixin`

`PageLifecycleMixin<T>` 可以应用到任意 `State<T>` 子类（包括 `ConsumerState`），
提供与 `BasePageState` 等价的钩子，无需嵌套 `Consumer`：

```dart
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});
  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage>
    with PageLifecycleMixin<LoginPage> {
  @override
  void onPageShow() => AppLog.d('[LoginPage] show');

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider); // ref 直接可用
    return Scaffold(/* ... */);
  }
}
```

`BasePageState` 内部也是基于 `PageLifecycleMixin` 实现，二者行为等价 ——
选 `BasePageState` 还是 mixin 取决于"需不需要同时拿 ref"。

#### 注意

`dispose` 阶段不会再回调 `onPageHide`——此时 `mounted=false`，触碰 `setState` / `context`
会抛错。资源清理请在子类的 `dispose` 中处理。

### 8. 主题

```dart
MaterialApp(
  theme: AppTheme.light(
    colors: const AppColors(primary: Color(0xFF1677FF)),
  ),
  darkTheme: AppTheme.dark(),
);
```

### Riverpod 完整指南

📖 **完整的 Riverpod 实战手册见 [docs/riverpod-guide.md](docs/riverpod-guide.md)**，覆盖心智模型、Provider 选型、`autoDispose` 生命周期、`AsyncValue` 三态、自动重试陷阱、跨页面联动、错误处理分层、测试与调试。下面 §9-§11 是几个最常用的快查；深入用法请直接读完整指南。

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

### 10. AsyncNotifier 自动重试（Riverpod 3 默认行为）

> ⚠️ **必读陷阱**：Riverpod 3 给所有 `AsyncNotifier` / `FutureProvider` / `StreamProvider` **默认开启了指数退避自动重试**：

- 当 `build()` 抛出 `Exception`（不抛 `Error`）时触发
- 默认 **最多 10 次**，间隔 200ms → 400 → 800 → 1.6s → 3.2s → 6.4s（封顶），累计约 **38 秒**
- 重试期间 `state` 是 `AsyncError(retrying: true)`，UI 看到的就是"加载很久 → 才显示错误"

源码：`riverpod/lib/src/core/provider_container.dart` 的 `defaultRetry`。

#### 三种关闭粒度

```dart
// ① 单 provider 关闭（推荐用于列表/分页等"用户能手动重试"的页面）
final feedControllerProvider =
    AsyncNotifierProvider.autoDispose<FeedController, FeedState>(
  FeedController.new,
  retry: (retryCount, error) => null,
);

// ② 全局关闭（在 ProviderScope 上）
ProviderScope(
  retry: (retryCount, error) => null,
  child: const MyApp(),
)

// ③ 自定义策略（只重 1 次、只对网络错）
retry: (retryCount, error) {
  if (retryCount >= 1) return null;
  if (error is! NetworkException) return null;
  return const Duration(milliseconds: 500);
}
```

#### 何时保留 / 何时关闭

| 场景 | 建议 |
| --- | --- |
| 列表 / 分页 / 详情页（有手动"重试"按钮） | **关闭**，让用户立刻看到错误并主动重试 |
| Token restore、配置拉取等长生命周期且能"自然恢复" | **保留默认 10 次** |
| 加载没有重试 UI、且失败影响小 | 保留，但调小到 2~3 次 |

#### 与 `DioClient.enableRetry` 的关系

两层独立、**会叠加**：dio 层重试针对 HTTP 超时 / 连接错（默认 2 次），Riverpod 层重试针对 `build()` 抛出的任何 `Exception`（默认 10 次）。最坏情况下一次"逻辑失败"会触发 `(1 + dio重试) × (1 + riverpod重试) = 33` 次实际 HTTP，跨度可达数分钟。**两层都开默认值时一定要有意识地评估 UI 反馈延迟。**

### 11. `autoDispose` 生命周期

`autoDispose` 是 Riverpod 控制 Provider 生命周期的修饰符。一句话:**没人监听就销毁,有人监听就保活**。

#### 监听计数规则

| 操作 | 计数变化 |
| --- | --- |
| `ref.watch(p)` 出现在 widget build 中 | +1（widget 还活着就一直 +1） |
| widget 被销毁 / `ref.watch` 不再出现 | -1 |
| `ref.listen(p, ...)` 注册 | +1 |
| `ref.read(p)` 一次性读取 | **不计数** |
| 另一个 provider 内部 `ref.watch(p)` | +1（那个 provider 活着就 +1） |

普通 `Provider`：计数到 0 不销毁，整个 ProviderContainer 生命周期都在。
`Provider.autoDispose`：计数到 0 的下一帧 → 调 `onDispose` → 销毁实例 → 下次 watch 重建。

#### 何时用 / 不用

| 场景 | 用 autoDispose 吗 |
| --- | --- |
| 页面专属数据（列表 / 详情 / 搜索结果 / 表单草稿） | ✅ |
| 大对象、占内存的数据（图片缓存、长列表） | ✅ |
| 带订阅的资源（WebSocket / Timer / Stream） | ✅，配合 `ref.onDispose` 关流 |
| 全局长生命周期状态（登录态、当前用户、主题） | ❌ |
| 单例服务（`DioClient` / `FlutterSecureStorage`） | ❌ |

经验法则：**"路由全部 pop 后这个状态还有意义吗？"** —— 没有就 autoDispose。

#### 跨页面共享时的"接力"

```
列表页 watch(feedProvider)         → 计数 1，创建实例
进详情，详情也 watch(feedProvider)  → 计数 2
detail pop，列表又是唯一监听者      → 计数 1，实例保留
列表页 pop                         → 计数 0，销毁
```

监听者从未归零，实例就一直存活 —— 这就是"列表 → 详情 → 列表"中详情改的 state 列表能看到的原因。

#### `ref.keepAlive()`：临时延寿

需要"页面 pop 后保留 N 秒、N 秒内再进直接复用"的语义：

```dart
class FooController extends AsyncNotifier<Foo> {
  @override
  Future<Foo> build() async {
    final link = ref.keepAlive();          // 取消"无监听者就销毁"
    Timer(const Duration(minutes: 5), link.close); // 5 分钟后允许销毁
    return await api.fetch();
  }
}
```

常见场景：
- 拉一次缓存 N 分钟
- 异步保存还没完时不许销毁
- 后台下载任务跑完才能放

#### `ref.onDispose`：关闭外部资源

```dart
@override
Future<Foo> build() async {
  final timer = Timer.periodic(...);
  final sub = stream.listen(...);
  ref.onDispose(() {
    timer.cancel();
    sub.cancel();
  });
  return ...;
}
```

Stream / Timer / WebSocket / 文件句柄等外部资源都要在这里关。

#### 高频踩坑

**坑 1：async 操作中页面 pop → "Notifier was disposed"**

```dart
Future<void> like(String id) async {
  state = AsyncData(...);
  await api.like(id);             // ← 期间用户 pop 了
  if (!ref.mounted) return;        // ← 必须检查，否则下行会抛
  state = AsyncData(...);
}
```

**坑 2：`ref.read` 不能保活**

```dart
@override
void initState() {
  super.initState();
  ref.read(myAutoDisposeProvider); // 一次性读，不计数 → 下一帧无 watch 就销毁
}
```

保活靠 `ref.watch` / `ref.listen`，不是 `ref.read`。

**坑 3：autoDispose 抖动（频繁创建销毁）**

页面快速进出 / 切 Tab / `select` 误用，会导致 provider 反复创建销毁、接口被多次调用。用 `keepAlive()` 短保活 / 检查 widget 是否抖动重建。

**坑 4：autoDispose provider 之间互相 watch**

容易写出"a 销毁 → b 销毁 → 无人 watch a → 重建"的循环。互相依赖时尽量用 `ref.read`。

#### 调试技巧

```dart
class _DebugObserver extends ProviderObserver {
  @override
  void didAddProvider(...) => AppLog.d('add: $provider');
  @override
  void didDisposeProvider(...) => AppLog.d('dispose: $provider');
}
ProviderScope(observers: [_DebugObserver()], child: ...);
```

DevTools 的 Riverpod 面板可以实时看每个 provider 的状态、监听者数量、是否 autoDispose。

### 12. 错误兜底

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

### 13. 屏幕适配

脚手架已内置 [`flutter_screenutil`](https://pub.dev/packages/flutter_screenutil),`AppBootstrap.run` 会自动用 `ScreenUtilInit` 包住 `runApp`,业务侧**无需任何包裹代码**就能直接用 `.w` / `.h` / `.sp` / `.r` 后缀:

```dart
Container(
  width: 200.w,            // 设计稿 200px → 按设备宽度等比缩放
  height: 80.h,            // 设计稿 80px  → 按设备高度等比缩放
  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
  child: Text('hello', style: TextStyle(fontSize: 14.sp)),
);

SizedBox(width: 24.r, height: 24.r); // .r 取宽高较小者,适合圆角 / 图标
```

#### 配置设计稿尺寸

通过 `AppConfig` 一次性配置:

```dart
const AppConfig(
  env: AppEnv.dev,
  apiBaseUrl: 'https://api.example.com',
  // 设计稿尺寸,默认 375×812(iPhone X / 13 mini)。
  // 改成你团队设计稿的实际尺寸,所有 .w/.h 即基于此计算。
  designSize: Size(390, 844),
  // 字号在横屏 / 平板上是否仍取较小边缩放,默认 true(避免字过大)。
  minTextAdapt: true,
  // 是否分屏模式,默认 false。
  splitScreenMode: false,
);
```

#### 注意

1. **导入只走脚手架 barrel**:`flutter_screenutil` 已被 `flutter_app_scaffold.dart` re-export,业务侧不要直接 `import 'package:flutter_screenutil/...'`。
2. **不要手动包 `ScreenUtilInit`**:`AppBootstrap` 内部已经包过一层。再包会得到嵌套 LayoutBuilder,白嫖性能;且若 `designSize` 不一致还会出现尺寸跳变。
3. **常量场景慎用**:`.w/.h` 不是 `const`,所以 `EdgeInsets.symmetric(horizontal: 16.w)` 不能再加 `const`。如果旧代码到处是 `const EdgeInsets`,改造时要去掉 `const`。
4. **字号系统设置**:`flutter_screenutil` 不会替你裁剪系统级字号放大。若布局对超大字号敏感,业务侧自行在根 `MaterialApp.builder` 里 clamp `MediaQuery.textScaler`。
5. **平板 / 桌面端**:`flutter_screenutil` 适合手机端等比缩放;真正的多端响应式建议在外层叠加 `LayoutBuilder` + 断点判断,不要让 `.w` 在大屏上把按钮拉到几百像素宽。

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
    ├── storage/                      # KvStorage / PrefsStorage
    └── ui/
        ├── base/                     # BasePage / BasePageState / PageLifecycleMixin
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
5. 页面按需选型：纯展示用 `ConsumerWidget`；需要本地 state + ref 用 `ConsumerStatefulWidget`；
   需要页面生命周期再加 `PageLifecycleMixin`（或单纯继承 `BasePage`）。需要保活的子组件包 `KeepAliveWrapper`。

