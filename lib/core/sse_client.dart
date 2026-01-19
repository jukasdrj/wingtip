import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Events that can be received from the SSE stream
enum SseEventType {
  progress,
  result,
  complete,
  error,
}

/// Represents a single SSE event
class SseEvent {
  final SseEventType type;
  final Map<String, dynamic> data;

  const SseEvent({
    required this.type,
    required this.data,
  });

  factory SseEvent.fromJson(Map<String, dynamic> json) {
    final typeString = json['type'] as String?;
    final type = switch (typeString) {
      'progress' => SseEventType.progress,
      'result' => SseEventType.result,
      'complete' => SseEventType.complete,
      'error' => SseEventType.error,
      _ => throw FormatException('Unknown event type: $typeString'),
    };

    return SseEvent(
      type: type,
      data: json['data'] as Map<String, dynamic>? ?? {},
    );
  }

  @override
  String toString() => 'SseEvent(type: $type, data: $data)';
}

/// Client for listening to Server-Sent Events
class SseClient {
  final Duration timeout;
  final int maxRetries;
  final Duration initialRetryDelay;

  SseClient({
    this.timeout = const Duration(minutes: 5),
    this.maxRetries = 3,
    this.initialRetryDelay = const Duration(milliseconds: 500),
  });

  /// Listen to SSE stream for a specific job ID
  ///
  /// Opens connection to [streamUrl] and yields [SseEvent] objects.
  /// Connection is maintained until:
  /// - A 'complete' event is received
  /// - A 'error' event is received
  /// - The [timeout] duration is reached
  /// - The stream is cancelled
  ///
  /// Implements exponential backoff retry up to [maxRetries] times
  /// on connection errors.
  ///
  /// If the stream ends without receiving a 'complete' or 'error' event,
  /// yields a synthetic error event indicating connection was lost.
  Stream<SseEvent> listen(String streamUrl) async* {
    int retryCount = 0;
    http.Client? client;

    while (retryCount <= maxRetries) {
      bool receivedTerminalEvent = false;

      try {
        client = http.Client();
        debugPrint('[SseClient] Connecting to: $streamUrl (attempt ${retryCount + 1})');

        final request = http.Request('GET', Uri.parse(streamUrl));
        request.headers['Accept'] = 'text/event-stream';
        request.headers['Cache-Control'] = 'no-cache';

        final streamedResponse = await client.send(request).timeout(timeout);

        if (streamedResponse.statusCode != 200) {
          throw Exception(
            'SSE connection failed with status ${streamedResponse.statusCode}',
          );
        }

        debugPrint('[SseClient] Connected successfully');

        // Parse SSE stream
        await for (final event in _parseEventStream(streamedResponse.stream)) {
          debugPrint('[SseClient] Received event: $event');
          yield event;

          // Close connection on complete or error events
          if (event.type == SseEventType.complete ||
              event.type == SseEventType.error) {
            debugPrint('[SseClient] Stream ended with ${event.type}');
            receivedTerminalEvent = true;
            return;
          }
        }

        // Stream ended without receiving 'complete' or 'error' event
        // This indicates a connection drop mid-stream
        if (!receivedTerminalEvent) {
          debugPrint('[SseClient] Stream ended unexpectedly without terminal event');
          yield SseEvent(
            type: SseEventType.error,
            data: {'message': 'Connection lost during processing'},
          );
        }
        return;
      } catch (e) {
        debugPrint('[SseClient] Error: $e');

        if (retryCount >= maxRetries) {
          debugPrint('[SseClient] Max retries reached, giving up');
          throw Exception('SSE connection failed after $maxRetries retries: $e');
        }

        retryCount++;
        final delay = _calculateBackoffDelay(retryCount);
        debugPrint('[SseClient] Retrying in ${delay.inMilliseconds}ms...');
        await Future.delayed(delay);
      } finally {
        client?.close();
      }
    }
  }

  /// Parse SSE event stream into SseEvent objects
  Stream<SseEvent> _parseEventStream(Stream<List<int>> byteStream) async* {
    final lines = byteStream
        .transform(utf8.decoder)
        .transform(const LineSplitter());

    await for (final line in lines) {
      // SSE format: "data: {json}"
      if (line.startsWith('data:')) {
        final jsonString = line.substring(5).trim();
        if (jsonString.isNotEmpty) {
          try {
            final json = jsonDecode(jsonString) as Map<String, dynamic>;
            yield SseEvent.fromJson(json);
          } catch (e) {
            debugPrint('[SseClient] Failed to parse event: $e');
            // Continue processing other events
          }
        }
      }
      // Ignore comment lines and other SSE fields (event:, id:, retry:)
    }
  }

  /// Calculate exponential backoff delay
  Duration _calculateBackoffDelay(int retryCount) {
    return initialRetryDelay * (1 << (retryCount - 1));
  }
}
