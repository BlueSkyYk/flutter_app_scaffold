# Riverpod 使用指南

本指南是 `flutter_app_scaffold` 项目中 Riverpod 3 的实战手册，覆盖心智模型、Provider 选型、生命周期、错误处理、跨页面联动、性能优化、调试与常见陷阱。

> 适用版本：`flutter_riverpod ^3.3.x`（基于 `riverpod-3.2.1` 源码分析）

## 目录

1. [心智模型：三个角色](#1-心智模型三个角色)
2. [Provider 类型选型](#2-provider-类型选型)
3. [`ref` 三件套：watch / read / listen](#3-ref-三件套watch--read--listen)
4. [`AsyncValue` 三态机制](#4-asyncvalue-三态机制)
5. [`autoDispose` 生命周期](#5-autodispose-生命周期)
6. [`family` 参数化 Provider](#6-family-参数化-provider)
7. [Riverpod 3 自动重试（重要陷阱）](#7-riverpod-3-自动重试重要陷阱)
8. [`select` 选择性订阅](#8-select-选择性订阅)
9. [常见状态组织模式](#9-常见状态组织模式)
10. [跨 Controller 联动](#10-跨-controller-联动)
11. [错误处理的分层](#11-错误处理的分层)
12. [测试与依赖注入](#12-测试与依赖注入)
13. [调试技巧](#13-调试技巧)
14. [反模式速查](#14-反模式速查)
15. [API 速查表](#15-api-速查表)

---

## 1. 心智模型：三个角色

把 Riverpod 拆成三个角色就清楚了：

| 角色 | 你写的 | 谁在用 | 类比 |
| --- | --- | --- | --- |
| **Provider**（描述） | `final fooProvider = Provider(...)` | 全局唯一、不可变的"配方" | Class |
| **Notifier**（逻辑） | `class FooController extends AsyncNotifier<Foo>` | 真正持有 state 的"实例" | Object |
| **Element**（运行时容器） | 看不到，Riverpod 内部管 | 内存里实际跑的"槽位" | JVM Heap object |

关系：`Provider --(创建)--> Element --(持有)--> Notifier`。

```dart
// Provider 是描述符，全局变量
final feedControllerProvider =
    AsyncNotifierProvider.autoDispose<FeedController, FeedState>(
      FeedController.new,
    );

// Notifier 是用户写的逻辑类
class FeedController extends AsyncNotifier<FeedState> {
  @override
  Future<FeedState> build() async => FeedState();
}

// Element 是 Riverpod 内部维护的运行时容器
//   - 持有当前 state（AsyncValue<FeedState>）
//   - 维护订阅图
//   - 管理 autoDispose 计数器
//   - 调度 retry timer
```

**关键事实**：
- 一个 Provider 全局只有一份描述
- 一个 ProviderContainer 中，每个 Provider（family 各参数）对应一个 Element
- `ref.watch(provider)` 第一次触发时才创建 Element 和 Notifier 实例

---

## 2. Provider 类型选型

| 类型 | 用途 | 可变？ | 异步？ |
| --- | --- | --- | --- |
| `Provider<T>` | 纯依赖（service / repository / config） | ❌ | ❌ |
| `NotifierProvider<N, T>` | 同步可变状态（计数器 / 表单） | ✅ | ❌ |
| `FutureProvider<T>` | 一次性异步获取（不需要 mutate） | ❌ | ✅ |
| `AsyncNotifierProvider<N, T>` | 异步可变状态（列表 / 详情 / 业务流） | ✅ | ✅ |
| `StreamProvider<T>` | 实时流（WebSocket / Firestore） | ❌ | ✅ |
| `StreamNotifierProvider<N, T>` | 流 + 自定义方法 | ✅ | ✅ |

### 决策树

```
有交互动作（mutate）吗？
├─ 没有
│   ├─ 异步取一次 → FutureProvider
│   ├─ 持续流    → StreamProvider
│   └─ 纯依赖    → Provider
│
└─ 有
    ├─ 异步       → AsyncNotifierProvider
    ├─ 流式       → StreamNotifierProvider
    └─ 同步       → NotifierProvider
```

### 选型示例（本项目）

```dart
// 全局单例，不可变 → Provider
final dioProvider = Provider<DioClient>((ref) => DioClient()..enableAuth(...));

// 仓库实现 → Provider（接口暴露给上层）
final feedRepositoryProvider = Provider<FeedRepository>(
  (ref) => FeedRepositoryImpl(api: ref.read(feedApiProvider)),
);

// 全局登录态，异步可变 → AsyncNotifierProvider
final authControllerProvider = AsyncNotifierProvider<AuthController, AuthUser?>(
  AuthController.new,
);

// 页面级动态列表，异步可变 → AsyncNotifierProvider.autoDispose
final feedControllerProvider =
    AsyncNotifierProvider.autoDispose<FeedController, FeedState>(
      FeedController.new,
      retry: (_, _) => null,
    );
```

---

## 3. `ref` 三件套：watch / read / listen

| 方法 | 触发 widget rebuild？ | 建立订阅？ | 用途 |
| --- | --- | --- | --- |
| `ref.watch(p)` | ✅ | ✅ | 在 `build` 里订阅，值变了重建 |
| `ref.read(p)` | ❌ | ❌ | 一次性取值（事件回调里调动作） |
| `ref.listen(p, cb)` | ❌ | ✅ | 订阅但不重建，做副作用（弹 toast / 跳路由 / 写日志） |

### 三件套各司其职

```dart
class LoginPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ① watch：UI 显示需要订阅
    final auth = ref.watch(authControllerProvider);
    final isLoading = auth.isLoading;

    // ② listen：副作用，登录失败弹 SnackBar（不是 UI，不能放 build 主体）
    ref.listen<AsyncValue<AuthUser?>>(authControllerProvider, (prev, next) {
      if (next.hasError && !next.isLoading) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('登录失败: ${next.error}')),
        );
      }
    });

    return ElevatedButton(
      onPressed: isLoading
          ? null
          : () {
              // ③ read：事件回调里调动作，不订阅
              ref.read(authControllerProvider.notifier).login(...);
            },
      child: isLoading ? CircularProgressIndicator() : Text('登录'),
    );
  }
}
```

### `ref.listen` 的 `prev` / `next`

```dart
ref.listen(provider, (T? previous, T next) {
  // previous: 变化前的值（首次回调时为 null）
  // next:     变化后的值（当前最新）
});
```

**几乎总是用 `next` 判断**："状态变成什么样了，我要做什么副作用"。`previous` 只在需要"对比变化"时才用：

```dart
// 只在"刚从未登录变成已登录"那一瞬间跳转，避免每次都跳
ref.listen(authControllerProvider, (prev, next) {
  if (prev?.value == null && next.value != null) {
    context.go('/home');
  }
});
```

### `WidgetRef` vs `Ref`

- `WidgetRef`：在 `ConsumerWidget` / `ConsumerStatefulWidget` 里用
- `Ref`：在 Notifier / Provider 内部用

API 基本一致。

---

## 4. `AsyncValue` 三态机制

`AsyncNotifier<T>` / `FutureProvider<T>` 的 state 类型是 `AsyncValue<T>`（密封类）：

```dart
sealed class AsyncValue<T> {
  AsyncData<T>      // 已经有数据
  AsyncLoading<T>   // 加载中（可能保留上一次的 value）
  AsyncError<T>     // 出错（也可能保留上一次的 value）
}
```

### 三态视图

```dart
final state = ref.watch(feedControllerProvider);

return state.when(
  loading: () => const Center(child: CircularProgressIndicator()),
  error: (err, stack) => ErrorView(message: '$err'),
  data: (feed) => ListView.builder(...),
);
```

### `AsyncLoading` / `AsyncError` 都可以保留旧值

```dart
ValueT? get value => _value?.$1;   // riverpod-3.2.1/lib/src/core/async_value.dart:551
```

刷新中 / 报错中，`state.value` 仍然返回最近一次成功的数据：

```dart
final cur = state.value;          // 不管 state 是 loading/error/data，都拿最近的成功值
if (cur == null) return;          // 没有就早返回
state = AsyncData(cur.copyWith(...));   // 增量更新
```

这就是为什么"下拉刷新时不闪屏" / "出错时仍能显示旧列表"成为可能。

### 常用工具

```dart
state.isLoading           // 是否正在加载（refreshing 时也是 true）
state.hasValue            // 是否有 value（包括 loading / error 时保留的旧值）
state.hasError            // 是否处于错误态
state.value               // T?（最近一次的成功值）
state.requireValue        // T（没值就抛 AsyncValueIsLoadingException）
state.error               // Object?（错误对象）
state.stackTrace          // StackTrace?
state.retrying            // bool（Riverpod 在自动重试中）

state.when(loading:, error:, data:)
state.maybeWhen(data:, orElse:)
state.whenOrNull(data:)
state.whenData((data) => ...)     // 只对 data 分支变换
```

### `AsyncValue.guard`：把异常装进 state

```dart
Future<void> refresh() async {
  state = await AsyncValue.guard(() async {
    return await _repo.fetch();   // 抛异常 → state = AsyncError(err)
  });
}
```

`AsyncValue.guard` 内部：

```dart
static Future<AsyncValue<T>> guard<T>(Future<T> Function() future) async {
  try {
    return AsyncData(await future());
  } catch (err, stack) {
    return AsyncError(err, stack);
  }
}
```

---

## 5. `autoDispose` 生命周期

**没人监听就销毁，有人监听就保活**。

### 监听计数规则

| 操作 | 计数变化 |
| --- | --- |
| `ref.watch(p)` 出现在 widget build 中 | +1（widget 还活着就一直 +1） |
| widget 销毁 / `ref.watch` 不再出现 | -1 |
| `ref.listen(p, ...)` 注册 | +1 |
| `ref.read(p)` 一次性读取 | **不计数** |
| 另一个 provider 内部 `ref.watch(p)` | +1（那个 provider 活着就 +1） |

普通 `Provider`：计数到 0 不销毁，整个 ProviderContainer 生命周期都在。
`Provider.autoDispose`：计数到 0 的下一帧 → 调 `onDispose` → 销毁 → 下次 watch 重建。

### 何时用 / 不用

| 场景 | autoDispose？ |
| --- | --- |
| 页面专属数据（列表 / 详情 / 搜索结果 / 表单草稿） | ✅ |
| 大对象、占内存的数据（图片缓存、长列表） | ✅ |
| 带订阅的资源（WebSocket / Timer / Stream） | ✅，配合 `ref.onDispose` 关流 |
| 全局长生命周期状态（登录态、当前用户、主题） | ❌ |
| 单例服务（`DioClient` / `FlutterSecureStorage`） | ❌ |

经验法则：**"路由全部 pop 后这个状态还有意义吗？"** —— 没有就 autoDispose。

### 跨页面共享时的"接力"

```
列表页 watch(feedProvider)         → 计数 1，创建实例
进详情，详情也 watch(feedProvider)  → 计数 2
detail pop，列表又是唯一监听者      → 计数 1，实例保留
列表页 pop                         → 计数 0，销毁
```

监听者从未归零，实例就一直存活 —— 这是"列表 → 详情 → 列表"中详情改的 state 列表能看到的原因。

### `ref.keepAlive()`：临时延寿

```dart
@override
Future<Foo> build() async {
  final link = ref.keepAlive();          // 取消"无监听者就销毁"
  Timer(const Duration(minutes: 5), link.close); // 5 分钟后允许销毁
  return await api.fetch();
}
```

常见场景：
- 拉一次缓存 N 分钟
- 异步保存还没完时不许销毁
- 后台下载任务跑完才能放

### `ref.onDispose`：关闭外部资源

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

### autoDispose 的高频踩坑

#### 坑 1：async 操作中页面 pop → "Notifier was disposed"

```dart
Future<void> like(String id) async {
  state = AsyncData(...);
  await api.like(id);             // ← 期间用户 pop 了
  if (!ref.mounted) return;        // ← 必须检查，否则下行会抛
  state = AsyncData(...);
}
```

#### 坑 2：`ref.read` 不能保活

```dart
@override
void initState() {
  super.initState();
  ref.read(myAutoDisposeProvider); // 一次性读，不计数 → 下一帧无 watch 就销毁
}
```

保活靠 `ref.watch` / `ref.listen`，不是 `ref.read`。

#### 坑 3：autoDispose 抖动

页面快速进出 / 切 Tab / `select` 误用，会导致 provider 反复创建销毁、接口被多次调用。用 `keepAlive()` 短保活，或检查 widget 是否抖动重建。

#### 坑 4：autoDispose provider 之间互相 watch

容易写出"a 销毁 → b 销毁 → 无人 watch a → 重建"的循环。互相依赖时尽量用 `ref.read`。

---

## 6. `family` 参数化 Provider

按参数区分不同实例，每个参数一个独立的 Element：

```dart
final userDetailProvider =
    AsyncNotifierProvider.autoDispose.family<UserDetailController, User, String>(
      UserDetailController.new,
    );

class UserDetailController
    extends AutoDisposeFamilyAsyncNotifier<User, String /* userId */> {
  @override
  Future<User> build(String userId) {
    return ref.read(userRepoProvider).fetch(userId);
  }
}

// 使用
final user = ref.watch(userDetailProvider('user_123'));
```

`family('user_123')` 和 `family('user_456')` 是两个独立 Element，各自计数、各自销毁。

### family 参数的等值约定

family 参数会作为 Element 的 key，必须有正确的 `==` / `hashCode`。复杂参数推荐用 freezed 或类型化 record：

```dart
final searchProvider = FutureProvider.family<List<Item>, ({String keyword, int page})>(
  (ref, args) => api.search(args.keyword, page: args.page),
);

ref.watch(searchProvider((keyword: 'flutter', page: 1)));
```

### 何时用 family

- "看某个用户" / "看某条详情" / "查某个标签" 这类按 id 区分的页面
- 同一个页面打开多个标签 / 多个搜索条件
- 参数会变但希望各自独立缓存

---

## 7. Riverpod 3 自动重试（重要陷阱）

**Riverpod 3 默认对所有 async provider 启用了指数退避重试 10 次。**

### 默认行为

源码：`riverpod-3.2.1/lib/src/core/provider_container.dart:831`

```dart
static Duration? defaultRetry(
  int retryCount,
  Object error, {
  int maxRetries = 10,
  Duration maxDelay = const Duration(milliseconds: 6400),
  Duration minDelay = const Duration(milliseconds: 200),
}) {
  if (retryCount >= maxRetries) return null;
  if (error is ProviderException || error is Error) return null;
  final delay = minDelay * math.pow(2, retryCount).toInt();
  if (delay > maxDelay) return maxDelay;
  return delay;
}
```

退避序列：

| 次数 | 间隔 | 累计 |
| --- | --- | --- |
| 1 | 200ms | 0.2s |
| 2 | 400ms | 0.6s |
| 3 | 800ms | 1.4s |
| 4 | 1.6s | 3.0s |
| 5 | 3.2s | 6.2s |
| 6~10 | 6.4s（封顶） | ~38s |

### 触发条件

- `build()` 抛 **`Exception`**（包括所有自定义 `ApiException`）→ 触发
- 抛 **`Error`** / `ProviderException` → 不触发

### 关闭粒度

```dart
// ① 单 provider 关闭（推荐用于列表 / 分页 / 详情）
final feedControllerProvider =
    AsyncNotifierProvider.autoDispose<FeedController, FeedState>(
      FeedController.new,
      retry: (retryCount, error) => null,
    );

// ② 全局关闭（在 ProviderScope 上）
ProviderScope(
  retry: (_, _) => null,
  child: const MyApp(),
);

// ③ 自定义策略（只重 1 次、只对网络错）
retry: (retryCount, error) {
  if (retryCount >= 1) return null;
  if (error is! NetworkException) return null;
  return const Duration(milliseconds: 500);
}
```

### 何时保留 / 何时关闭

| 场景 | 建议 |
| --- | --- |
| 列表 / 分页 / 详情（有手动重试按钮） | **关闭** |
| Token restore / 配置拉取（能自然恢复） | **保留默认 10 次** |
| 没有重试 UI 且失败影响小 | 保留，但调小到 2~3 次 |

### 与 dio 的 `enableRetry` 的关系

两层独立 + **会叠加**：

```
dio HTTP 层：超时/连接错重试（默认 2 次）
  └─ 失败抛 ApiException
       └─ Riverpod provider 层：build() 抛 Exception 重试（默认 10 次）

最坏情况：(1 + 2) × (1 + 10) = 33 次实际 HTTP，跨度数分钟。
```

**两层都开默认值时一定要有意识地评估 UI 反馈延迟。**

---

## 8. `select` 选择性订阅

只订阅 state 的某一部分，避免无关变化引起 rebuild。

```dart
// 没用 select：state 任何字段变了都重建
final state = ref.watch(feedControllerProvider);
final loading = state.isLoading;

// 用 select：只在 isLoading 变化时重建
final loading = ref.watch(
  feedControllerProvider.select((s) => s.isLoading),
);
```

### 在列表 + 详情联动里发挥威力

详情页只订阅"当前这条"，别的条目变化不会让详情页重建：

```dart
class FeedDetailPage extends ConsumerWidget {
  final String itemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final item = ref.watch(
      feedControllerProvider.select(
        (async) => async.value?.items.firstWhereOrNull((i) => i.id == itemId),
      ),
    );
    ...
  }
}
```

### `select` 的等值判断

`select` 内部用 `==` 比较新旧返回值。如果返回的是新对象，每次都会触发：

```dart
// ❌ 每次都返回新对象，select 失效
ref.watch(provider.select((s) => SomeWrapper(s.foo)));

// ✅ 返回原始字段或 immutable 对象
ref.watch(provider.select((s) => s.foo));
```

业务实体推荐用 freezed，自动生成 `==` / `hashCode`，配合 `select` 才精确。

---

## 9. 常见状态组织模式

### 模式 1：多 Controller（各管一类实体）

每个实体独立的 Notifier，UI 各 watch 各的。适合**独立加载、不同更新频率、可单独使用**的实体。

```dart
final authControllerProvider =
    AsyncNotifierProvider<AuthController, AuthUser?>(...);
final preferencesControllerProvider =
    AsyncNotifierProvider<PreferencesController, UserPreferences>(...);
final permissionsControllerProvider =
    AsyncNotifierProvider<PermissionsController, List<Permission>>(...);
```

### 模式 2：单 Controller + 复合 State

实体之间必须一起存在，业务上不可分割。一个 Controller 暴露一个聚合 state。

```dart
class AuthState {
  const AuthState({
    required this.user,
    required this.preferences,
    required this.permissions,
  });
  final AuthUser user;
  final UserPreferences preferences;
  final List<Permission> permissions;
  AuthState copyWith({...}) => ...;
}

class AuthController extends AsyncNotifier<AuthState?> {
  @override
  Future<AuthState?> build() async {
    final results = await Future.wait([
      _userRepo.fetch(),
      _prefsRepo.fetch(),
      _permsRepo.fetch(),
    ]);
    return AuthState(
      user: results[0] as AuthUser,
      preferences: results[1] as UserPreferences,
      permissions: results[2] as List<Permission>,
    );
  }
}
```

UI 用 `select` 订阅自己关心的字段。

### 模式 3：派生 Provider（computed）

派生数据用纯 `Provider`，从多个源 provider 计算出来：

```dart
final adminViewProvider = Provider<AdminView?>((ref) {
  final user = ref.watch(authControllerProvider).value;
  final perms = ref.watch(permissionsControllerProvider).value;
  if (user == null || !perms.contains(Permission.admin)) return null;
  return AdminView(user: user, permissions: perms);
});
```

适合"看似实体、其实是几个实体的视图"。

### 决策规则（三个问题）

```
Q1: 这几个实体的数据源是同一个接口吗？
    是 → 模式 2
    否 → Q2

Q2: 能否独立加载？(其中一个失败、其它仍可用)
    能   → 模式 1
    不能 → 模式 2

Q3: 是真的"实体"，还是"另外几个实体派生出来的视图"？
    派生 → 模式 3
    真实体 → Q1 / Q2
```

---

## 10. 跨 Controller 联动

### 主动 invalidate

```dart
class AuthController extends AsyncNotifier<AuthUser?> {
  Future<void> logout() async {
    await _repo.logout();
    state = const AsyncData(null);
    // 主动让兄弟 controller 重建
    ref.invalidate(preferencesControllerProvider);
    ref.invalidate(permissionsControllerProvider);
  }
}
```

### 被动 watch（更优雅）

```dart
class PreferencesController extends AsyncNotifier<UserPreferences> {
  @override
  Future<UserPreferences> build() async {
    // 登录态变化时，本 controller 的 build() 自动重跑
    final user = ref.watch(authControllerProvider).value;
    if (user == null) return UserPreferences.guest();
    return await _repo.fetchFor(user.id);
  }
}
```

`ref.watch` 让被订阅 provider 的变化自动级联重建上游 —— 这是 Riverpod 最优雅的"联动"方式，比手动 invalidate 干净。

### 列表 + 详情联动

详情页 mutate 共享 controller，列表页通过 `ref.watch` 自动同步：

```dart
class FeedController extends AsyncNotifier<FeedState> {
  // 详情页调这个，列表页 ref.watch 自动看到
  Future<void> toggleLike(String id) async {
    final cur = state.value;
    if (cur == null) return;

    // 乐观更新
    final original = cur.items;
    final updated = original.map((it) {
      if (it.id != id) return it;
      return it.copyWith(
        liked: !it.liked,
        likeCount: it.liked ? it.likeCount - 1 : it.likeCount + 1,
      );
    }).toList();
    state = AsyncData(cur.copyWith(items: updated));

    // 同步后端，失败回滚
    try {
      await _repo.toggleLike(id);
    } catch (e, st) {
      if (!ref.mounted) return;
      state = AsyncData(cur.copyWith(items: original));
      Error.throwWithStackTrace(e, st);
    }
  }
}
```

---

## 11. 错误处理的分层

本项目的约定（与 `lib/src/network/` 配套）：

```
后端非 2xx / 断网 / 超时
        ↓
  Dio 抛 DioException
        ↓
  DioClient.request 的 catch → mapDioException → 抛 ApiException
        ↓
  你的 Api.method（直接抛，不 try/catch）
        ↓
  Repository.method（直接抛，不 try/catch；只有"失败也要继续"才捕获）
        ↓
  Controller 用 AsyncValue.guard 兜住
        ↓
  UI 通过 ref.listen 或 state.when(error:) 展示
```

### 分层职责表

| 层 | 写 try/catch 吗？ | 责任 |
| --- | --- | --- |
| API（HTTP 端点） | ❌ | 把方法名 + 参数翻译成 HTTP，抛出 ApiException |
| Repository | ❌（一般） | 协调多个 API 调用 + DTO→Entity；"失败也继续"才捕获 |
| Controller | ✅（用 `AsyncValue.guard`） | 异常装进 state.error |
| UI（page） | ✅（`ref.listen`） | 把 state.error 翻译成 SnackBar / 错误占位 |

### 三态 UI

```dart
return state.when(
  loading: () => const Center(child: CircularProgressIndicator()),
  error: (err, _) => ErrorView(
    message: err is ApiException ? err.message : '加载失败',
    onRetry: () => ref.invalidate(myProvider),
  ),
  data: (data) => ListView(...),
);
```

错误细分：

```dart
final msg = switch (err) {
  NetworkException() => '网络异常,请检查网络',
  BusinessException(:final message) => message,
  HttpStatusException(:final statusCode) => '服务异常 $statusCode',
  ParseException() => '数据解析失败',
  CancelException() => null,                // 用户主动取消，不提示
  _ => '操作失败',
};
```

---

## 12. 测试与依赖注入

### Override 用 Fake 替换真实仓库

```dart
class FakeFeedRepository implements FeedRepository {
  @override
  Future<PageModel<FeedItem>> fetch({required int page, int pageSize = 20}) async {
    return PageModel(list: [
      FeedItem(id: '1', author: 'test', content: 'hi', publishedAt: DateTime.now()),
    ]);
  }
}

testWidgets('feed page shows list', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        feedRepositoryProvider.overrideWith((ref) => FakeFeedRepository()),
      ],
      child: const MaterialApp(home: FeedPage()),
    ),
  );
  await tester.pumpAndSettle();
  expect(find.text('hi'), findsOneWidget);
});
```

### Override 整个 Notifier

```dart
class FakeFeedController extends FeedController {
  @override
  Future<FeedState> build() async => FeedState(items: [...]);
}

ProviderScope(
  overrides: [
    feedControllerProvider.overrideWith(FakeFeedController.new),
  ],
  child: ...,
);
```

### 测试 Notifier 自身

```dart
test('toggleLike toggles and rolls back on failure', () async {
  final container = ProviderContainer(overrides: [
    feedRepositoryProvider.overrideWith((_) => ThrowingFeedRepo()),
  ]);
  addTearDown(container.dispose);

  final ctrl = container.read(feedControllerProvider.notifier);
  await container.read(feedControllerProvider.future);

  expect(() => ctrl.toggleLike('id'), throwsA(isA<NetworkException>()));
  // 验证 state 回滚
  ...
});
```

---

## 13. 调试技巧

### `ProviderObserver` 看全局生命周期

```dart
class _DebugObserver extends ProviderObserver {
  @override
  void didAddProvider(...) => AppLog.d('add: $provider');
  @override
  void didDisposeProvider(...) => AppLog.d('dispose: $provider');
  @override
  void didUpdateProvider(...) => AppLog.d('update: $provider $newValue');
}

ProviderScope(
  observers: [_DebugObserver()],
  child: const MyApp(),
);
```

### 加构造 / build / dispose 日志

```dart
class FeedController extends AsyncNotifier<FeedState> {
  FeedController() {
    AppLog.w('[FeedController] new instance ${identityHashCode(this)}');
  }

  @override
  Future<FeedState> build() async {
    AppLog.w('[FeedController] build() ${identityHashCode(this)}');
    ref.onDispose(() => AppLog.w('[FeedController] disposed'));
    ...
  }
}
```

对比 `new instance` 和 `build()` 的次数：
- `new instance` 1 条 + `build()` N 条 → 同实例被 N 次重跑（依赖变了 / Riverpod retry）
- `new instance` N 条（hashcode 不同）→ 实例反复创建（autoDispose 抖动 / 路由 remount）

### Flutter DevTools

`Flutter DevTools` 的 Riverpod 面板可以实时看：
- 每个 Provider 的当前 state
- 监听者数量
- 是否 autoDispose
- 依赖图

---

## 14. 反模式速查

| 反模式 | 为什么不好 | 应该怎样 |
| --- | --- | --- |
| `Provider<Map<String, dynamic>>` 当大杂烩 | 类型丢失、`select` 失效、改一个字段全 App rebuild | 拆成多个 Provider 或定义聚合 state 类 |
| 在 `initState` 用 `ref.read` 保活 | `read` 不计数，autoDispose 立刻销毁 | 在 `build` 里用 `ref.watch` |
| `build` 主体里写副作用（弹 SnackBar / 跳路由） | `build` 可能被多次调用，副作用重复触发 | 用 `ref.listen` |
| `AsyncNotifier` 里手动 try/catch 把异常吞掉 | 错误信息丢失，UI 无法显示 | 抛出来让 `AsyncValue.guard` / Riverpod 装进 state.error |
| 把所有 provider 都加 `autoDispose` | 长生命周期数据频繁重拉，浪费 | 看作用域：路由全 pop 后还有意义就不加 |
| `loadMore` 失败也写 `state.error` | 整页变错误占位，已加载列表丢失 | 只复位 `loadingMore` + 抛出让全局 toast |
| 详情页不用 `select` 直接 watch 整个 state | 别的条目变化也触发详情页 rebuild | 用 `ref.watch(provider.select((s) => s.items[i]))` |
| 异步操作后无脑 `state =` | 页面 pop 后 notifier 已销毁，会抛 | 加 `if (!ref.mounted) return;` |
| 互相 `ref.watch` 的 autoDispose providers | 容易循环 / 抖动 | 单向依赖，反向用 `ref.read` |
| 把 service / repository 写成 autoDispose | 无状态服务也跟着销毁，多次重建浪费 | 普通 `Provider`（不 autoDispose） |

---

## 15. API 速查表

### Provider 创建

```dart
final p = Provider((ref) => ...);
final p = Provider.autoDispose((ref) => ...);
final p = Provider.family<T, Arg>((ref, arg) => ...);
final p = Provider.autoDispose.family<T, Arg>((ref, arg) => ...);

final fp = FutureProvider((ref) async => ...);
final sp = StreamProvider((ref) => stream);

final np = NotifierProvider<MyNotifier, T>(MyNotifier.new);
final ap = AsyncNotifierProvider<MyAsyncNotifier, T>(MyAsyncNotifier.new);

// 关闭 Riverpod 自动重试
final ap = AsyncNotifierProvider<C, T>(
  C.new,
  retry: (_, _) => null,
);
```

### Notifier 内部

```dart
class MyNotifier extends Notifier<T> {
  @override
  T build() => initial;

  void update() {
    state = newValue;          // 同步赋值，同步通知订阅者
  }
}

class MyAsyncNotifier extends AsyncNotifier<T> {
  @override
  Future<T> build() async => await api.fetch();

  Future<void> action() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => api.do());
  }
}
```

### Ref 三件套

```dart
ref.watch(p);              // 订阅 + rebuild on change
ref.read(p);               // 取一次，不订阅
ref.listen(p, (prev, next) => ...);  // 订阅但不 rebuild

ref.watch(p.select((s) => s.foo));   // 选择性订阅
```

### 生命周期

```dart
ref.invalidate(p);         // 销毁 Element + 重建（重跑 build）
ref.refresh(p);            // 同 invalidate，但返回新值（少用，invalidate 更直观）
ref.keepAlive();           // 取消 autoDispose，返回 KeepAliveLink
ref.onDispose(() {...});   // 实例销毁时回调
ref.mounted;               // 是否仍存活（async 操作后必查）
```

### AsyncValue 工具

```dart
AsyncValue.data(v)
AsyncValue.loading()
AsyncValue.error(e, st)
AsyncValue.guard(() async => ...)

state.when(loading:, error:, data:)
state.maybeWhen(data:, orElse:)
state.whenOrNull(data:)
state.whenData((d) => ...)

state.value           // T?
state.requireValue    // T (throws if not data)
state.error           // Object?
state.stackTrace      // StackTrace?
state.isLoading       // bool
state.hasValue        // bool
state.hasError        // bool
state.retrying        // bool
```

### Override（测试用）

```dart
ProviderScope(
  overrides: [
    repoProvider.overrideWith((ref) => FakeRepo()),
    notifierProvider.overrideWith(FakeNotifier.new),
  ],
  child: ...,
);
```

---

## 附：源码定位

| 概念 | 源码位置 |
| --- | --- |
| `AsyncNotifier` 抽象 | `riverpod/lib/src/providers/async_notifier/orphan.dart` |
| `runBuild` 调度 | `riverpod/lib/src/providers/async_notifier/orphan.dart:37` |
| `defaultRetry` | `riverpod/lib/src/core/provider_container.dart:831` |
| `triggerRetry` | `riverpod/lib/src/core/element.dart:699` |
| `AsyncValue` | `riverpod/lib/src/core/async_value.dart` |
| `value` getter | `riverpod/lib/src/core/async_value.dart:551` |

---

## 项目内相关代码索引

| 文件 | 看什么 |
| --- | --- |
| `example/lib/features/auth/presentation/auth_controller.dart` | 全局 `AsyncNotifier` 范例（不 autoDispose） |
| `example/lib/features/feed/presentation/feed_controller.dart` | 页面级 `AsyncNotifier.autoDispose` + 关闭 retry + loadMore 模式 |
| `example/lib/features/feed/presentation/feed_page.dart` | 三态 UI + RefreshIndicator + 滚动监听 |
| `example/lib/features/auth/presentation/login_page.dart` | `ref.watch` + `ref.listen` 的标准搭配 |
| `example/lib/core/network/dio_provider.dart` | 普通 `Provider` 装服务实例 |
| `example/lib/app/router.dart` | `ref.listen` 触发 router.refresh 的联动模式 |

