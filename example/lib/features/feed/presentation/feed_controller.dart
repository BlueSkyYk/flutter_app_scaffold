import 'package:flutter_app_scaffold/flutter_app_scaffold.dart';

import '../data/feed_repository_impl.dart';
import '../domain/feed_item.dart';
import '../domain/feed_repository.dart';

/// 动态列表的页面状态(presentation 层私有结构)。
///
/// 不放进 domain —— "page / hasMore / loadingMore" 是 UI 的关心,
/// 不属于业务实体。
class FeedState {
  const FeedState({
    this.items = const [],
    this.page = 1,
    this.hasMore = true,
    this.loadingMore = false,
  });

  final List<FeedItem> items;
  final int page;
  final bool hasMore;
  final bool loadingMore;

  FeedState copyWith({
    List<FeedItem>? items,
    int? page,
    bool? hasMore,
    bool? loadingMore,
  }) => FeedState(
    items: items ?? this.items,
    page: page ?? this.page,
    hasMore: hasMore ?? this.hasMore,
    loadingMore: loadingMore ?? this.loadingMore,
  );
}

/// 动态列表 Controller。
///
/// 关键选择:
/// - `AutoDisposeAsyncNotifier`:页面没有监听者时自动销毁,内存友好。
///   离开页面 → 列表清空 → 下次进入重新拉第一页(符合"刷流"的产品直觉)。
/// - `AsyncValue.guard`:首屏 / 刷新失败时把异常装进 `state.error`,
///   UI 用 `state.when` 三态匹配即可,不需要写 try/catch。
/// - 加载更多失败**不**替换 state.error(那会让整个列表变成错误页),
///   只把 loadingMore 复位 + 让全局 UiFeedback 弹 toast。
class FeedController extends AsyncNotifier<FeedState> {
  static const _pageSize = 20;

  late final FeedRepository _repo = ref.read(feedRepositoryProvider);

  FeedController() {
    AppLog.w('[FeedController] new instance  ${identityHashCode(this)}');
  }

  /// AsyncNotifier 的 build = 首次构建时跑一次,等价于"首屏加载"。
  /// 抛出的异常会自动装进 state.error,UI 显示错误占位。
  @override
  Future<FeedState> build() async {
    AppLog.w('[FeedController] build()       ${identityHashCode(this)}');
    final result = await _repo.fetch(page: 1, pageSize: _pageSize);
    return FeedState(
      items: result.list,
      page: 1,
      hasMore: result.list.length >= _pageSize,
    );
  }

  /// 下拉刷新:回到第一页,清空旧数据。
  /// 刷新期间 state 切到 AsyncLoading,UI 由 RefreshIndicator 自己显示菊花,
  /// 这里**不**用全屏 loading(全屏 loading 只在 build() 那次首屏)。
  Future<void> refresh() async {
    // 注意不要 `state = AsyncLoading()`,否则列表会闪一下变成全屏 loading,
    // 体验差。AsyncValue.guard 拿到 future 后异步替换即可。
    state = await AsyncValue.guard(() async {
      final result = await _repo.fetch(page: 1, pageSize: _pageSize);
      return FeedState(
        items: result.list,
        page: 1,
        hasMore: result.list.length >= _pageSize,
      );
    });
  }

  /// 上拉加载更多:在现有列表后面拼新数据。
  /// 失败时**只复位 loadingMore + 抛出**,不污染 state.error,
  /// 全局 UiFeedback 会弹 toast(若已开启)。
  Future<void> loadMore() async {
    final cur = state.value;
    if (cur == null || !cur.hasMore || cur.loadingMore) return;

    state = AsyncData(cur.copyWith(loadingMore: true));
    try {
      final next = cur.page + 1;
      final more = await _repo.fetch(page: next, pageSize: _pageSize);
      state = AsyncData(
        cur.copyWith(
          items: [...cur.items, ...more.list],
          page: next,
          hasMore: more.list.length >= _pageSize,
          loadingMore: false,
        ),
      );
    } catch (e, st) {
      // 复位 loadingMore,保留已加载的列表。
      state = AsyncData(cur.copyWith(loadingMore: false));
      AppLog.w('[feed] loadMore failed: $e');
      // rethrow 让上层 / 全局错误反馈感知;不 rethrow 则静默。
      Error.throwWithStackTrace(e, st);
    }
  }
}

/// autoDispose:页面 pop 后自动销毁(无监听者即释放)。
///
/// `retry: (_, _) => null`:**关闭 Riverpod 3 默认的自动重试**。
/// Riverpod 3 默认会对 build() 抛 Exception 的 provider 指数退避重试 10 次
/// (200ms → 6.4s,总计 30+ 秒),这对"列表/分页 + 用户能手动重试"的页面是负优化:
/// 用户看到的是"加载很久 → 终于显示错误",而不是"立刻报错可重试"。
/// 这里禁用,把决策权交给 _ErrorView 的"重试"按钮(ref.invalidate)。
final feedControllerProvider =
    AsyncNotifierProvider.autoDispose<FeedController, FeedState>(
      FeedController.new,
      retry: (retryCount, error) {
        AppLog.d("业务重试");
        return null;
      },
    );
