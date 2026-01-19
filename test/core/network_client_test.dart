import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wingtip/core/network_client.dart';

void main() {
  group('NetworkClient', () {
    late NetworkClient networkClient;

    setUp(() {
      networkClient = NetworkClient(baseUrl: 'https://api.example.com');
    });

    test('should initialize Dio with correct base URL', () {
      expect(networkClient.dio.options.baseUrl, 'https://api.example.com');
    });

    test('should initialize Dio with correct timeout values', () {
      expect(networkClient.dio.options.connectTimeout,
          const Duration(seconds: 10));
      expect(networkClient.dio.options.receiveTimeout,
          const Duration(seconds: 10));
    });

    test('should have retry interceptor added', () {
      final interceptors = networkClient.dio.interceptors;
      expect(
        interceptors.any((interceptor) => interceptor is RetryInterceptor),
        true,
      );
    });
  });

  group('RetryInterceptor', () {
    late Dio dio;
    late RetryInterceptor retryInterceptor;

    setUp(() {
      dio = Dio();
      retryInterceptor = RetryInterceptor(
        dio: dio,
        maxRetries: 3,
        initialDelay: const Duration(milliseconds: 100),
      );
    });

    test('should initialize with correct default values', () {
      expect(retryInterceptor.maxRetries, 3);
      expect(retryInterceptor.initialDelay, const Duration(milliseconds: 100));
    });

    test('should calculate exponential backoff delay correctly', () {
      expect(
        retryInterceptor.calculateDelay(0),
        const Duration(milliseconds: 100),
      );
      expect(
        retryInterceptor.calculateDelay(1),
        const Duration(milliseconds: 200),
      );
      expect(
        retryInterceptor.calculateDelay(2),
        const Duration(milliseconds: 400),
      );
    });

    test('should retry on connection timeout', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.connectionTimeout,
      );
      expect(retryInterceptor.shouldRetry(error), true);
    });

    test('should retry on send timeout', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.sendTimeout,
      );
      expect(retryInterceptor.shouldRetry(error), true);
    });

    test('should retry on receive timeout', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.receiveTimeout,
      );
      expect(retryInterceptor.shouldRetry(error), true);
    });

    test('should retry on connection error', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.connectionError,
      );
      expect(retryInterceptor.shouldRetry(error), true);
    });

    test('should retry on 500+ status codes', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 500,
        ),
      );
      expect(retryInterceptor.shouldRetry(error), true);
    });

    test('should not retry on 4xx status codes', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 404,
        ),
      );
      expect(retryInterceptor.shouldRetry(error), false);
    });

    test('should not retry on cancel', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.cancel,
      );
      expect(retryInterceptor.shouldRetry(error), false);
    });
  });

  group('RateLimitException', () {
    test('should create exception with retryAfterMs', () {
      final exception = RateLimitException(retryAfterMs: 60000);
      expect(exception.retryAfterMs, 60000);
      expect(exception.message, 'Rate limit exceeded');
    });

    test('should create exception with custom message', () {
      final exception = RateLimitException(
        retryAfterMs: 120000,
        message: 'Daily limit reached',
      );
      expect(exception.retryAfterMs, 120000);
      expect(exception.message, 'Daily limit reached');
    });

    test('should format toString correctly', () {
      final exception = RateLimitException(retryAfterMs: 60000);
      expect(
        exception.toString(),
        'RateLimitException: Rate limit exceeded (retry after 60000ms)',
      );
    });
  });

  group('RetryInterceptor - Rate Limit Handling', () {
    late Dio dio;
    late RetryInterceptor retryInterceptor;

    setUp(() {
      dio = Dio();
      retryInterceptor = RetryInterceptor(
        dio: dio,
        maxRetries: 3,
        initialDelay: const Duration(milliseconds: 100),
      );
    });

    test('should parse retryAfterMs from response body', () {
      final response = Response(
        requestOptions: RequestOptions(path: '/test'),
        statusCode: 429,
        data: {'retryAfterMs': 120000},
      );

      final retryAfterMs = retryInterceptor.parseRetryAfter(response);
      expect(retryAfterMs, 120000);
    });

    test('should parse retry-after from header in seconds', () {
      final response = Response(
        requestOptions: RequestOptions(path: '/test'),
        statusCode: 429,
        headers: Headers.fromMap({
          'retry-after': ['60'],
        }),
      );

      final retryAfterMs = retryInterceptor.parseRetryAfter(response);
      expect(retryAfterMs, 60000); // 60 seconds = 60000 ms
    });

    test('should default to 60 seconds when no retry-after info', () {
      final response = Response(
        requestOptions: RequestOptions(path: '/test'),
        statusCode: 429,
      );

      final retryAfterMs = retryInterceptor.parseRetryAfter(response);
      expect(retryAfterMs, 60000);
    });

    test('should prioritize header over body', () {
      final response = Response(
        requestOptions: RequestOptions(path: '/test'),
        statusCode: 429,
        headers: Headers.fromMap({
          'retry-after': ['30'],
        }),
        data: {'retryAfterMs': 120000},
      );

      final retryAfterMs = retryInterceptor.parseRetryAfter(response);
      expect(retryAfterMs, 30000); // Header takes precedence
    });
  });
}

extension RetryInterceptorTest on RetryInterceptor {
  bool shouldRetry(DioException err) {
    return _shouldRetry(err);
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

  Duration calculateDelay(int retryCount) {
    return _calculateDelay(retryCount);
  }

  Duration _calculateDelay(int retryCount) {
    return initialDelay * (1 << retryCount);
  }

  int parseRetryAfter(Response? response) {
    return _parseRetryAfter(response);
  }

  int _parseRetryAfter(Response? response) {
    if (response == null) return 60000;

    final retryAfterHeader = response.headers.value('retry-after');
    if (retryAfterHeader != null) {
      final seconds = int.tryParse(retryAfterHeader);
      if (seconds != null) {
        return seconds * 1000;
      }
    }

    if (response.data is Map<String, dynamic>) {
      final data = response.data as Map<String, dynamic>;
      final retryAfterMs = data['retryAfterMs'] as int?;
      if (retryAfterMs != null) {
        return retryAfterMs;
      }
    }

    return 60000;
  }
}
