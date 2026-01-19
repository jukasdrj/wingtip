import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wingtip/core/sse_client.dart';

/// Provider for SSE client
final sseClientProvider = Provider<SseClient>((ref) {
  return SseClient(
    timeout: const Duration(minutes: 5),
    maxRetries: 3,
    initialRetryDelay: const Duration(milliseconds: 500),
  );
});
