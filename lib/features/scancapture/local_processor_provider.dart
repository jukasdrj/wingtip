import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'local_processor_service.dart';

final localProcessorServiceProvider = Provider<LocalProcessorService>((ref) {
  final service = LocalProcessorService();
  ref.onDispose(() => service.dispose());
  return service;
});
