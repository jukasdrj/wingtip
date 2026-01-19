import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wingtip/core/device_id_service.dart';

/// Provider for the DeviceIdService singleton.
final deviceIdServiceProvider = Provider<DeviceIdService>((ref) {
  return DeviceIdService();
});

/// Provider that reads and caches the device ID.
///
/// This provider automatically fetches the device ID from secure storage
/// on first access and caches it for the lifetime of the app.
final deviceIdProvider = FutureProvider<String>((ref) async {
  final service = ref.watch(deviceIdServiceProvider);
  return await service.getDeviceId();
});
