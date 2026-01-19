import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';

/// Utility class for mapping exceptions to user-friendly error messages
class ErrorMessages {
  /// Map an exception to a user-friendly error message
  ///
  /// Handles common HTTP status codes and network exceptions with actionable guidance
  static String fromException(dynamic error) {
    if (error is DioException) {
      return _fromDioException(error);
    } else if (error is SocketException) {
      return 'Upload timed out. Check your connection and retry.';
    } else if (error is TimeoutException) {
      return 'Upload timed out. Check your connection and retry.';
    } else if (error.toString().contains('RateLimitException')) {
      // Rate limit is handled separately with countdown UI
      return error.toString();
    } else {
      return error.toString();
    }
  }

  /// Map DioException to user-friendly error message
  static String _fromDioException(DioException error) {
    // Handle response status codes
    if (error.response != null) {
      final statusCode = error.response!.statusCode;
      switch (statusCode) {
        case 400:
          return 'Image quality too low. Try again with better lighting.';
        case 404:
          return 'No books detected. Try closer zoom or clearer angle.';
        case 429:
          return 'Daily scan limit reached. Retry after countdown.';
        case 500:
        case 502:
        case 503:
        case 504:
          return 'Server issue. Your image is saved for manual retry.';
        default:
          return 'Server error: $statusCode';
      }
    }

    // Handle exception types without response
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Upload timed out. Check your connection and retry.';
      case DioExceptionType.connectionError:
        return 'Upload timed out. Check your connection and retry.';
      case DioExceptionType.cancel:
        return 'Upload cancelled';
      default:
        return 'Upload timed out. Check your connection and retry.';
    }
  }
}
