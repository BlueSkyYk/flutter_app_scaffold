import 'package:example/core/network/http_result.dart';

import 'feed_item.dart';

/// 动态仓库的契约接口(domain 层)。
///
/// presentation(controller)只依赖这个抽象,不感知是网络 / 本地 / 缓存来的数据。
/// 切换数据源 = 替换 [FeedRepository] 的 Impl,controller 不动。
abstract class FeedRepository {
  /// 拉取第 [page] 页(每页 [pageSize] 条)。
  /// 失败时直接抛 `ApiException`(由 DioClient 映射好),controller 用
  /// AsyncValue.guard 兜住即可,不需要在这里写 try/catch。
  Future<PageModel<FeedItem>> fetch({
    required int page,
    int pageSize = 20,
  });
}