import 'package:flutter_app_scaffold/flutter_app_scaffold.dart';
import 'package:flutter/material.dart';

import '../domain/feed_item.dart';
import 'feed_controller.dart';

/// 动态列表页。
///
/// 同时需要 ref + 滚动监听(上拉加载更多),所以选 ConsumerStatefulWidget。
/// 三件套:
/// - watch  → 订阅 state 触发 rebuild(列表显示)
/// - read   → 在事件回调里调动作(refresh / loadMore)
/// - listen → 加载更多失败时弹 SnackBar 副作用(本页保留,即便全局 toast 也开了也没坏处)
class FeedPage extends ConsumerStatefulWidget {
  const FeedPage({super.key});

  @override
  ConsumerState<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends ConsumerState<FeedPage> {
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    AppLog.w('[FeedPage] State initState   ${identityHashCode(this)}');
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    AppLog.w('[FeedPage] State dispose     ${identityHashCode(this)}');
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    super.dispose();
  }

  /// 距离底部 200px 时触发加载更多 —— 比"滚到底"更跟手。
  void _onScroll() {
    final pos = _scrollCtrl.position;
    if (pos.pixels >= pos.maxScrollExtent - 200) {
      ref.read(feedControllerProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(feedControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('动态')),
      body: asyncState.when(
        // 首屏 loading
        loading: () => const Center(child: CircularProgressIndicator()),
        // 首屏失败:整页错误占位 + 重试
        error: (err, _) => _ErrorView(
          message: err is ApiException ? err.message : '加载失败',
          onRetry: () => ref.invalidate(feedControllerProvider),
        ),
        // 首屏成功:列表 + 下拉刷新 + 上拉加载更多
        data: (state) => RefreshIndicator(
          onRefresh: () =>
              ref.read(feedControllerProvider.notifier).refresh(),
          child: state.items.isEmpty
              ? const _EmptyView()
              : ListView.separated(
                  controller: _scrollCtrl,
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: state.items.length + 1,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (ctx, i) {
                    if (i == state.items.length) {
                      return _FooterIndicator(
                        loadingMore: state.loadingMore,
                        hasMore: state.hasMore,
                      );
                    }
                    return _FeedTile(item: state.items[i]);
                  },
                ),
        ),
      ),
    );
  }
}

class _FeedTile extends StatelessWidget {
  const _FeedTile({required this.item});

  final FeedItem item;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(child: Icon(Icons.two_mp)),
      title: Text(item.content??""),
      subtitle: Text(
        item.content??"",
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const Icon(Icons.favorite_border, size: 16),
          const SizedBox(height: 4),
          Text('${item.likeCount}'),
        ],
      ),
    );
  }
}

class _FooterIndicator extends StatelessWidget {
  const _FooterIndicator({required this.loadingMore, required this.hasMore});

  final bool loadingMore;
  final bool hasMore;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: loadingMore
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(
                hasMore ? '上拉加载更多' : '— 到底了 —',
                style: Theme.of(context).textTheme.bodySmall,
              ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    // ListView 必须能滚动,否则 RefreshIndicator 不响应下拉。
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: const [
        SizedBox(height: 200),
        Center(child: Text('还没有动态,下拉刷新试试')),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
          const SizedBox(height: 12),
          Text(message),
          const SizedBox(height: 12),
          FilledButton.tonal(onPressed: onRetry, child: const Text('重试')),
        ],
      ),
    );
  }
}