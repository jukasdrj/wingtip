import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wingtip/core/device_id_provider.dart';
import 'package:wingtip/core/network_client.dart';
import 'package:wingtip/core/talaria_client.dart';

/// Provider for the TalariaClient
///
/// Depends on deviceIdProvider to inject the device ID into the client.
/// Uses a NetworkClient configured with the Talaria base URL.
final talariaClientProvider = FutureProvider<TalariaClient>((ref) async {
  final deviceId = await ref.watch(deviceIdProvider.future);

  // TODO: Configure actual Talaria base URL from environment
  final networkClient = NetworkClient(baseUrl: 'https://api.talaria.example.com');

  return TalariaClient(
    dio: networkClient.dio,
    deviceId: deviceId,
  );
});
