import 'package:dio/dio.dart';
import 'package:wingtip/data/database.dart';

/// Categorizes errors into FailureReason enum values
class FailureCategorizer {
  /// Categorize an error into a FailureReason
  static FailureReason categorize(dynamic error, String? errorMessage) {
    // Check error type first
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.connectionError:
          return FailureReason.networkError;
        case DioExceptionType.badResponse:
          final statusCode = error.response?.statusCode;
          if (statusCode == 429) {
            return FailureReason.rateLimited;
          }
          if (statusCode == 400) {
            // 400 errors are typically image quality issues
            return FailureReason.qualityTooLow;
          }
          if (statusCode != null && statusCode >= 500) {
            return FailureReason.serverError;
          }
          return FailureReason.unknown;
        default:
          return FailureReason.networkError;
      }
    }

    // Check error message content
    final message = errorMessage?.toLowerCase() ?? error.toString().toLowerCase();

    if (message.contains('no books') || message.contains('no book')) {
      return FailureReason.noBooksFound;
    }

    if (message.contains('network') ||
        message.contains('connection') ||
        message.contains('timeout') ||
        message.contains('socket')) {
      return FailureReason.networkError;
    }

    if (message.contains('rate limit') || message.contains('429')) {
      return FailureReason.rateLimited;
    }

    if (message.contains('quality') ||
        message.contains('blurry') ||
        message.contains('blur') ||
        message.contains('too dark') ||
        message.contains('bad image')) {
      return FailureReason.qualityTooLow;
    }

    if (message.contains('server') ||
        message.contains('500') ||
        message.contains('503') ||
        message.contains('502')) {
      return FailureReason.serverError;
    }

    return FailureReason.unknown;
  }
}
