import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'barcode_service.dart';

final barcodeServiceProvider = Provider<BarcodeService>((ref) {
  final service = BarcodeService();
  ref.onDispose(() => service.dispose());
  return service;
});
