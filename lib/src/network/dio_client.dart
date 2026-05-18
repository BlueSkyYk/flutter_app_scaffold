import 'package:dio/dio.dart';

import '../config/app_config.dart';
import 'api_exception.dart';
import 'api_result.dart';
import 'interceptors/log_interceptor.dart';

/// dio 封装。提供 [request]/[get]/[post] 等方法，自动把异常映射成 [ApiException]，
/// 并提供基于 [ApiResult] 的 safe-API。
class DioClient {
  DioClient({Dio? dio, AppConfig? config}) {
    final cfg = config ?? AppConfig.I;
    _dio = dio ??
        Dio(
          BaseOptions(
            baseUrl: cfg.apiBaseUrl,
            connectTimeout: cfg.connectTimeout,
            receiveTimeout: cfg.receiveTimeout,
            sendTimeout: cfg.sendTimeout,
            contentType: 'application/json; charset=utf-8',
            responseType: ResponseType.json,
          ),
        );
    if (cfg.enableNetworkLog) {
      _dio.interceptors.add(AppLogInterceptor());
    }
  }

  late final Dio _dio;

  Dio get raw => _dio;

  void addInterceptor(Interceptor interceptor) {
    _dio.interceptors.add(interceptor);
  }

  /// 抛异常版本。失败抛 [ApiException]，由调用方决定是否捕获。
  Future<Response<T>> request<T>(
    String path, {
    String method = 'GET',
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      return await _dio.request<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: (options ?? Options()).copyWith(method: method),
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
    } on DioException catch (e) {
      throw mapDioException(e);
    } on Object catch (e, st) {
      throw ParseException('请求异常: $e', cause: e, stackTrace: st);
    }
  }

  Future<Response<T>> get<T>(String path,
          {Map<String, dynamic>? queryParameters, Options? options}) =>
      request<T>(path,
          method: 'GET', queryParameters: queryParameters, options: options);

  Future<Response<T>> post<T>(String path,
          {Object? data, Map<String, dynamic>? queryParameters, Options? options}) =>
      request<T>(path,
          method: 'POST',
          data: data,
          queryParameters: queryParameters,
          options: options);

  Future<Response<T>> put<T>(String path,
          {Object? data, Map<String, dynamic>? queryParameters, Options? options}) =>
      request<T>(path,
          method: 'PUT',
          data: data,
          queryParameters: queryParameters,
          options: options);

  Future<Response<T>> delete<T>(String path,
          {Object? data, Map<String, dynamic>? queryParameters, Options? options}) =>
      request<T>(path,
          method: 'DELETE',
          data: data,
          queryParameters: queryParameters,
          options: options);

  /// 安全版本：把成功 / 失败封装到 [ApiResult]。
  Future<ApiResult<T>> safeRequest<T>(
    Future<T> Function(DioClient client) block,
  ) async {
    try {
      final data = await block(this);
      return ApiResult.success(data);
    } on ApiException catch (e) {
      return ApiResult.failure(e);
    } on DioException catch (e) {
      return ApiResult.failure(mapDioException(e));
    } on Object catch (e, st) {
      return ApiResult.failure(
        ParseException('未知错误: $e', cause: e, stackTrace: st),
      );
    }
  }
}
