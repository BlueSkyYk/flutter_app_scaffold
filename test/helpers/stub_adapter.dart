import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// 测试用的 dio 适配器：按 [script] 顺序回放每次 fetch。
///
/// script 元素：[ResponseBody] 表示成功；[DioException] 表示失败
/// （按其 type 重放，便于覆盖 connectionTimeout / connectionError / badResponse 等分支）。
class StubAdapter implements HttpClientAdapter {
  StubAdapter(this.script);

  final List<Object> script;
  int callCount = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final item = script[callCount];
    callCount++;
    if (item is DioException) {
      throw DioException(
        requestOptions: options,
        type: item.type,
        response: item.response,
        message: item.message,
      );
    }
    return item as ResponseBody;
  }

  @override
  void close({bool force = false}) {}
}

/// 快速构造一个 JSON 成功响应体。
ResponseBody okBody([int code = 200, String body = '{}']) {
  final stream = Stream<Uint8List>.value(Uint8List.fromList(body.codeUnits));
  return ResponseBody(stream, code);
}
