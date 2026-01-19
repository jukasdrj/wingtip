import 'package:dio/dio.dart';

/// Exception thrown when a rate limit is hit
class RateLimitException implements Exception {
  final int retryAfterMs;
  final String message;

  RateLimitException({
    required this.retryAfterMs,
    this.message = 'Rate limit exceeded',
  });

  @override
  String toString() => 'RateLimitException: $message (retry after ${retryAfterMs}ms)';
}

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
    // Check for 429 rate limit response
    if (err.response?.statusCode == 429) {
      final retryAfterMs = _parseRetryAfter(err.response);
      handler.reject(
        DioException(
          requestOptions: err.requestOptions,
          response: err.response,
          type: err.type,
          error: RateLimitException(retryAfterMs: retryAfterMs),
        ),
      );
      return;
    }

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

  /// Parse retry-after from response headers or body
  int _parseRetryAfter(Response? response) {
    if (response == null) return 60000; // Default 60 seconds

    // Try to get from Retry-After header (in seconds)
    final retryAfterHeader = response.headers.value('retry-after');
    if (retryAfterHeader != null) {
      final seconds = int.tryParse(retryAfterHeader);
      if (seconds != null) {
        return seconds * 1000; // Convert to milliseconds
      }
    }

    // Try to get from response body
    if (response.data is Map<String, dynamic>) {
      final data = response.data as Map<String, dynamic>;
      final retryAfterMs = data['retryAfterMs'] as int?;
      if (retryAfterMs != null) {
        return retryAfterMs;
      }
    }

    // Default to 60 seconds if not found
    return 60000;
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
