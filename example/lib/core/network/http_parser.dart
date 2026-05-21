import 'package:flutter_app_scaffold/flutter_app_scaffold.dart';

import 'http_result.dart';

T parseModel<T>({
  required Response<dynamic> response,
  required T Function(Map<dynamic, dynamic>) parser,
}) {
  final result = HttpResult<dynamic>.fromJson(response.data!);
  return parser(result.data);
}

PageModel<T> parsePageModel<T>({
  required Response<dynamic> response,
  required T Function(Map<dynamic, dynamic>) itemParser,
}) {
  final result = HttpResult<dynamic>.fromJson(response.data!);
  return PageModel.fromJson(result.data, (data) => itemParser(data));
}
