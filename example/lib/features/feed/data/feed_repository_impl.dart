import 'package:example/core/network/http_result.dart';
import 'package:flutter_app_scaffold/flutter_app_scaffold.dart';

import '../domain/feed_item.dart';
import '../domain/feed_repository.dart';
import 'dto/feed_item_dto.dart';
import 'feed_api.dart';

/// DTO → Entity 转换下沉在 data 层,避免 domain 反向依赖 data/dto。
FeedItem _toFeedItem(FeedItemDto dto) => FeedItem(
      id: dto.id,
      userId: dto.userId,
      userNickname: dto.userNickname,
      userAvatar: dto.userAvatar,
      content: dto.content,
      contentType: dto.contentType,
      imageUrls: dto.imageUrls,
      videoUrl: dto.videoUrl,
      tags: dto.tags,
      visible: dto.visible,
      likeCount: dto.likeCount,
      commentCount: dto.commentCount,
      liked: dto.liked,
      createdAt: dto.createdAt,
    );

/// [FeedRepository] 的实际实现(data 层)。
///
/// 职责:协调 API 调用 + DTO→Entity 转换。
/// 这里没有持久化(动态列表通常不缓存),如果后续要加 N 分钟内复用,
/// 也是在这一层加一个内存 / Hive 缓存,Controller 完全不用动。
class FeedRepositoryImpl implements FeedRepository {
  FeedRepositoryImpl({required this.api});

  final FeedApi api;

  @override
  Future<PageModel<FeedItem>> fetch({
    required int page,
    int pageSize = 20,
  }) async {
    final dtos = await api.fetch(page: page, pageSize: pageSize);
    return dtos.cover(list: dtos.list, itemCover: _toFeedItem);
  }
}

/// 仓库 Provider:类型暴露成 domain 接口,调用方拿不到 Impl。
/// 测试时 `overrideWith((_) => FakeFeedRepository())` 即可注入假实现。
final feedRepositoryProvider = Provider<FeedRepository>((ref) {
  return FeedRepositoryImpl(api: ref.read(feedApiProvider));
});
