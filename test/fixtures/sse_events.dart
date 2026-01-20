import 'package:wingtip/core/sse_client.dart';

/// Sample SSE events covering all event types for testing

/// Progress event - indicates job is in progress
final progressEvent10 = SseEvent(
  type: SseEventType.progress,
  data: {
    'progress': 0.1,
    'message': 'Analyzing image...',
  },
);

final progressEvent50 = SseEvent(
  type: SseEventType.progress,
  data: {
    'progress': 0.5,
    'message': 'Detecting book spines...',
  },
);

final progressEvent80 = SseEvent(
  type: SseEventType.progress,
  data: {
    'progress': 0.8,
    'message': 'Enriching book metadata...',
  },
);

/// Result event - book metadata found
final resultEventMartian = SseEvent(
  type: SseEventType.result,
  data: {
    'isbn': '978-0-553-41802-6',
    'title': 'The Martian',
    'author': 'Andy Weir',
    'coverUrl': 'https://covers.openlibrary.org/b/isbn/9780553418026-L.jpg',
    'format': 'Paperback',
    'spineConfidence': 0.95,
  },
);

final resultEventHarryPotter = SseEvent(
  type: SseEventType.result,
  data: {
    'isbn': '978-0-439-70818-8',
    'title': 'Harry Potter and the Philosopher\'s Stone',
    'author': 'J.K. Rowling',
    'coverUrl': 'https://covers.openlibrary.org/b/isbn/9780439708188-L.jpg',
    'format': 'Hardcover',
    'spineConfidence': 0.92,
  },
);

final resultEvent1984 = SseEvent(
  type: SseEventType.result,
  data: {
    'isbn': '978-0-7432-7356-5',
    'title': '1984',
    'author': 'George Orwell',
    'coverUrl': 'https://covers.openlibrary.org/b/isbn/9780743273565-L.jpg',
    'format': 'Paperback',
    'spineConfidence': 0.88,
  },
);

/// Result event with low confidence (needs review)
final resultEventLowConfidence = SseEvent(
  type: SseEventType.result,
  data: {
    'isbn': '978-0-00-000000-0',
    'title': 'Unknown Book',
    'author': 'Unknown Author',
    'coverUrl': null,
    'format': null,
    'spineConfidence': 0.45,
  },
);

/// Result event with missing optional fields
final resultEventMinimal = SseEvent(
  type: SseEventType.result,
  data: {
    'isbn': '978-1-111-11111-1',
    'title': 'Minimal Book Data',
    'author': 'Test Author',
    'spineConfidence': 0.75,
  },
);

/// Complete event - job finished successfully
final completeEvent = SseEvent(
  type: SseEventType.complete,
  data: {
    'message': 'Job completed successfully',
    'totalBooks': 3,
  },
);

final completeEventSingleBook = SseEvent(
  type: SseEventType.complete,
  data: {
    'message': 'Job completed successfully',
    'totalBooks': 1,
  },
);

/// Error events - various error scenarios
final errorEventNetworkError = SseEvent(
  type: SseEventType.error,
  data: {
    'message': 'Unable to connect to server',
    'code': 'NETWORK_ERROR',
  },
);

final errorEventQualityTooLow = SseEvent(
  type: SseEventType.error,
  data: {
    'message': 'Image quality too low. Please ensure good lighting and focus.',
    'code': 'QUALITY_TOO_LOW',
  },
);

final errorEventNoBooksFound = SseEvent(
  type: SseEventType.error,
  data: {
    'message': 'No book spines detected in the image.',
    'code': 'NO_BOOKS_FOUND',
  },
);

final errorEventServerError = SseEvent(
  type: SseEventType.error,
  data: {
    'message': 'Server encountered an error. Please try again later.',
    'code': 'SERVER_ERROR',
    'statusCode': 500,
  },
);

final errorEventRateLimited = SseEvent(
  type: SseEventType.error,
  data: {
    'message': 'Rate limit exceeded',
    'code': 'RATE_LIMITED',
    'retryAfterMs': 30000,
  },
);

final errorEventConnectionLost = SseEvent(
  type: SseEventType.error,
  data: {
    'message': 'Connection lost during processing',
  },
);

/// Complete SSE event sequences for testing full workflows

/// Successful scan with single book
final successfulSingleBookSequence = [
  progressEvent10,
  progressEvent50,
  progressEvent80,
  resultEventMartian,
  completeEventSingleBook,
];

/// Successful scan with multiple books
final successfulMultiBookSequence = [
  progressEvent10,
  progressEvent50,
  resultEventMartian,
  progressEvent80,
  resultEventHarryPotter,
  resultEvent1984,
  completeEvent,
];

/// Scan with low confidence result (needs review)
final lowConfidenceScanSequence = [
  progressEvent10,
  progressEvent50,
  progressEvent80,
  resultEventLowConfidence,
  completeEventSingleBook,
];

/// Failed scan due to quality
final qualityErrorSequence = [
  progressEvent10,
  progressEvent50,
  errorEventQualityTooLow,
];

/// Failed scan due to no books found
final noBooksFoundSequence = [
  progressEvent10,
  progressEvent50,
  progressEvent80,
  errorEventNoBooksFound,
];

/// Failed scan due to network error
final networkErrorSequence = [
  progressEvent10,
  errorEventNetworkError,
];

/// Failed scan due to rate limiting
final rateLimitSequence = [
  progressEvent10,
  progressEvent50,
  errorEventRateLimited,
];

/// Failed scan due to server error
final serverErrorSequence = [
  progressEvent10,
  progressEvent50,
  progressEvent80,
  errorEventServerError,
];

/// Connection lost mid-stream
final connectionLostSequence = [
  progressEvent10,
  progressEvent50,
  resultEventMartian,
  errorEventConnectionLost,
];

/// Helper function to create a progress event
SseEvent createProgressEvent(double progress, String message) {
  return SseEvent(
    type: SseEventType.progress,
    data: {
      'progress': progress,
      'message': message,
    },
  );
}

/// Helper function to create a result event
SseEvent createResultEvent({
  required String isbn,
  required String title,
  required String author,
  String? coverUrl,
  String? format,
  double? spineConfidence,
}) {
  final data = <String, dynamic>{
    'isbn': isbn,
    'title': title,
    'author': author,
  };

  if (coverUrl != null) data['coverUrl'] = coverUrl;
  if (format != null) data['format'] = format;
  if (spineConfidence != null) data['spineConfidence'] = spineConfidence;

  return SseEvent(
    type: SseEventType.result,
    data: data,
  );
}

/// Helper function to create a complete event
SseEvent createCompleteEvent({int? totalBooks, String? message}) {
  return SseEvent(
    type: SseEventType.complete,
    data: {
      'message': message ?? 'Job completed successfully',
      if (totalBooks != null) 'totalBooks': totalBooks,
    },
  );
}

/// Helper function to create an error event
SseEvent createErrorEvent({
  required String message,
  String? code,
  int? statusCode,
  int? retryAfterMs,
}) {
  final data = <String, dynamic>{
    'message': message,
  };

  if (code != null) data['code'] = code;
  if (statusCode != null) data['statusCode'] = statusCode;
  if (retryAfterMs != null) data['retryAfterMs'] = retryAfterMs;

  return SseEvent(
    type: SseEventType.error,
    data: data,
  );
}

/// SSE event JSON strings for testing parsing
const progressEventJson = '''
{
  "type": "progress",
  "data": {
    "progress": 0.5,
    "message": "Analyzing image..."
  }
}
''';

const resultEventJson = '''
{
  "type": "result",
  "data": {
    "isbn": "978-0-553-41802-6",
    "title": "The Martian",
    "author": "Andy Weir",
    "coverUrl": "https://covers.openlibrary.org/b/isbn/9780553418026-L.jpg",
    "format": "Paperback",
    "spineConfidence": 0.95
  }
}
''';

const completeEventJson = '''
{
  "type": "complete",
  "data": {
    "message": "Job completed successfully",
    "totalBooks": 1
  }
}
''';

const errorEventJson = '''
{
  "type": "error",
  "data": {
    "message": "Image quality too low",
    "code": "QUALITY_TOO_LOW"
  }
}
''';
