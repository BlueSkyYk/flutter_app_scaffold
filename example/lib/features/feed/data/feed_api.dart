import 'dart:math';

import 'package:example/core/network/http_parser.dart';
import 'package:example/core/network/http_result.dart';
import 'package:flutter_app_scaffold/flutter_app_scaffold.dart';

import '../../../core/network/dio_provider.dart';
import 'dto/feed_item_dto.dart';

/// feed 域的 HTTP 端点集合(data 层内部)。
///
/// 当前是 **mock 实现**(用 Future.delayed 模拟网络延迟 + 本地造数据),
/// 真实接后端时,把 mock 块替换成 `_dio.get(...)` + `parseModel(...)`,
/// 方法签名和返回类型不动,Repository / Controller / UI 都不用改。
class FeedApi {
  FeedApi(this._dio);

  // ignore: unused_field
  final DioClient _dio;

  /// 第 9000 条之后视为"到底",用来演示 hasMore = false。
  static const _totalMock = 87;

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

  String _lorem(Random rng) {
    const corpus = [
      '今天的天气很好,适合写代码。',
      'Riverpod 的 autoDispose 真好用。',
      'Flutter 比想象中流畅。',
      '又是被脚手架治愈的一天。',
      '终于把 401 刷新跑通了。',
      '抽屉里的零食吃完了,谁去补货?',
    ];
    return corpus[rng.nextInt(corpus.length)];
  }
}

final feedApiProvider = Provider<FeedApi>((ref) {
  return FeedApi(ref.read(dioProvider));
});
