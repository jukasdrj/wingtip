import 'package:dio/dio.dart';

class NetworkClient {
  late final Dio _dio;

  NetworkClient({String? baseUrl}) {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl ?? '',
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );

    _dio.interceptors.add(RetryInterceptor(dio: _dio));
  }

  Dio get dio => _dio;
}

class RetryInterceptor extends Interceptor {
  final Dio dio;
  final int maxRetries;
  final Duration initialDelay;

  RetryInterceptor({
    required this.dio,
    this.maxRetries = 3,
    this.initialDelay = const Duration(milliseconds: 500),
  });

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (_shouldRetry(err)) {
      final retryCount = err.requestOptions.extra['retryCount'] as int? ?? 0;

      if (retryCount < maxRetries) {
        final delay = _calculateDelay(retryCount);
        await Future.delayed(delay);

        err.requestOptions.extra['retryCount'] = retryCount + 1;

        try {
          final response = await dio.fetch(err.requestOptions);
          return handler.resolve(response);
        } on DioException catch (e) {
          return super.onError(e, handler);
        }
      }
    }

    return super.onError(err, handler);
  }

  bool _shouldRetry(DioException err) {
    return err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError ||
        (err.type == DioExceptionType.badResponse &&
            err.response?.statusCode != null &&
            err.response!.statusCode! >= 500);
  }

  Duration _calculateDelay(int retryCount) {
    return initialDelay * (1 << retryCount);
  }
}
