import 'package:dio/dio.dart';

/// 网络层统一异常。拦截器把 DioException 转成 ApiException 抛出。
sealed class ApiException implements Exception {
  const ApiException(this.message, {this.cause, this.stackTrace});

  final String message;
  final Object? cause;
  final StackTrace? stackTrace;

  @override
  String toString() => '$runtimeType($message)';
}

/// 网络不可达 / 超时 / 连接失败。
class NetworkException extends ApiException {
  const NetworkException(super.message, {super.cause, super.stackTrace});
}

/// 服务端返回非 2xx 状态码。
class HttpStatusException extends ApiException {
  const HttpStatusException(
    super.message, {
    required this.statusCode,
    this.responseBody,
    super.cause,
    super.stackTrace,
  });

  final int statusCode;
  final Object? responseBody;
}

/// 业务返回的非成功 code（接口 200 但 code != 0）。
class BusinessException extends ApiException {
  const BusinessException(
    super.message, {
    required this.code,
    this.data,
    super.cause,
    super.stackTrace,
  });

  final int code;
  final Object? data;
}

/// 请求被取消。
class CancelException extends ApiException {
  const CancelException([super.message = '请求已取消']);
}

/// 解析失败。
class ParseException extends ApiException {
  const ParseException(super.message, {super.cause, super.stackTrace});
}

/// 把 DioException 映射成 ApiException。
ApiException mapDioException(DioException e) {
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return NetworkException('网络超时', cause: e, stackTrace: e.stackTrace);
    case DioExceptionType.connectionError:
      return NetworkException('网络连接失败', cause: e, stackTrace: e.stackTrace);
    case DioExceptionType.cancel:
      return const CancelException();
    case DioExceptionType.badCertificate:
      return NetworkException('证书校验失败', cause: e, stackTrace: e.stackTrace);
    case DioExceptionType.badResponse:
      final code = e.response?.statusCode ?? -1;
      return HttpStatusException(
        'HTTP $code',
        statusCode: code,
        responseBody: e.response?.data,
        cause: e,
        stackTrace: e.stackTrace,
      );
    case DioExceptionType.unknown:
      return NetworkException(
        e.message ?? '未知网络错误',
        cause: e,
        stackTrace: e.stackTrace,
      );
  }
}
