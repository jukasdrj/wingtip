import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wingtip/core/device_id_provider.dart';
import 'package:wingtip/core/network_client.dart';
import 'package:wingtip/core/talaria_client.dart';

/// Provider for the TalariaClient
///
/// Depends on deviceIdProvider to inject the device ID into the client.
/// Uses a NetworkClient configured with the Talaria base URL.
///
/// The base URL is configured via the TALARIA_BASE_URL environment variable.
/// Example: flutter run --dart-define=TALARIA_BASE_URL="https://api.talaria.production.com"
final talariaClientProvider = FutureProvider<TalariaClient>((ref) async {
  final deviceId = await ref.watch(deviceIdProvider.future);

  // Read base URL from environment variable, default to example URL for development
  const baseUrl = String.fromEnvironment(
    'TALARIA_BASE_URL',
    defaultValue: 'https://api.talaria.example.com',
  );

  final networkClient = NetworkClient(baseUrl: baseUrl);

  return TalariaClient(
    dio: networkClient.dio,
    deviceId: deviceId,
  );
});
