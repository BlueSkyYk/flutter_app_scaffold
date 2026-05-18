import 'api_exception.dart';

/// 统一返回类型。业务层不写 try-catch，直接 when/match 处理。
sealed class ApiResult<T> {
  const ApiResult();

  const factory ApiResult.success(T data) = ApiSuccess<T>;
  const factory ApiResult.failure(ApiException error) = ApiFailure<T>;

  bool get isSuccess => this is ApiSuccess<T>;
  bool get isFailure => this is ApiFailure<T>;

  T? get dataOrNull => switch (this) {
        ApiSuccess<T>(:final data) => data,
        ApiFailure<T>() => null,
      };

  ApiException? get errorOrNull => switch (this) {
        ApiSuccess<T>() => null,
        ApiFailure<T>(:final error) => error,
      };

  R when<R>({
    required R Function(T data) success,
    required R Function(ApiException error) failure,
  }) {
    return switch (this) {
      ApiSuccess<T>(:final data) => success(data),
      ApiFailure<T>(:final error) => failure(error),
    };
  }

  ApiResult<R> map<R>(R Function(T data) mapper) {
    return switch (this) {
      ApiSuccess<T>(:final data) => ApiSuccess(mapper(data)),
      ApiFailure<T>(:final error) => ApiFailure(error),
    };
  }
}

class ApiSuccess<T> extends ApiResult<T> {
  const ApiSuccess(this.data);
  final T data;
}

class ApiFailure<T> extends ApiResult<T> {
  const ApiFailure(this.error);
  final ApiException error;
}
