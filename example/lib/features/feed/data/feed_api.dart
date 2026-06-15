import 'package:example/core/network/http_parser.dart';
import 'package:example/core/network/http_result.dart';
import 'package:flutter_app_scaffold/flutter_app_scaffold.dart';

import '../../../core/network/dio_provider.dart';
import 'dto/feed_item_dto.dart';

/// feed 域的 HTTP 端点集合(data 层内部)。
class FeedApi {
  FeedApi(this._dio);

  final DioClient _dio;

  /// 拉取一页动态。
  ///
  /// 真实接口示例:
  /// ```dart
  /// final res = await _dio.get<Map<String, dynamic>>(
  ///   '/feed/list',
  ///   queryParameters: {'page': page, 'pageSize': pageSize},
  /// );
  /// final list = (HttpResult<dynamic>.fromJson(res.data!).data as List)
  ///     .cast<Map<dynamic, dynamic>>()
  ///     .map(FeedItemDto.fromJson)
  ///     .toList();
  /// return list;
  /// ```
  Future<PageModel<FeedItemDto>> fetch({
    required int page,
    int pageSize = 20,
  }) async {
    AppLog.i('[feed-api] GET /posts/list?page=$page&pageSize=$pageSize (mock)');

    // 模拟网络延迟。
    await Future<void>.delayed(const Duration(milliseconds: 600));
    final res = await _dio.get<Map<String, dynamic>>(
      '/posts/list',
      queryParameters: {'page': page, 'pageSize': pageSize},
    );
    // 偶尔模拟一次失败,演示错误链路是否走通。
    // 想观察重试 + 全局 toast 时把下面注释打开:
    // if (page == 2 && Random().nextBool()) {
    //   throw const NetworkException('mock: 网络抖动');
    // }
    return parsePageModel(response: res, itemParser: FeedItemDto.fromJson);
  }
}

final feedApiProvider = Provider<FeedApi>((ref) {
  return FeedApi(ref.read(dioProvider));
});
