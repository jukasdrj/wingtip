import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'failed_scan_retention_service.dart';

/// Service for managing network reconnection auto-retry settings
class NetworkReconnectService {
  static const String _autoRetryKey = 'auto_retry_on_reconnect';

  final SharedPreferences _prefs;

  NetworkReconnectService(this._prefs);

  /// Get the auto-retry preference (default: false)
  bool getAutoRetry() {
    return _prefs.getBool(_autoRetryKey) ?? false;
  }

  /// Set the auto-retry preference
  Future<void> setAutoRetry(bool enabled) async {
    await _prefs.setBool(_autoRetryKey, enabled);
  }
}

/// Provider for NetworkReconnectService
final networkReconnectServiceProvider = Provider<NetworkReconnectService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider).value;
  if (prefs == null) {
    throw Exception('SharedPreferences not initialized');
  }
  return NetworkReconnectService(prefs);
});

/// State notifier for auto-retry setting
class AutoRetryNotifier extends Notifier<bool> {
  @override
  bool build() {
    final service = ref.watch(networkReconnectServiceProvider);
    return service.getAutoRetry();
  }

  Future<void> setAutoRetry(bool enabled) async {
    final service = ref.read(networkReconnectServiceProvider);
    await service.setAutoRetry(enabled);
    state = enabled;
  }

  Future<void> toggle() async {
    await setAutoRetry(!state);
  }
}

final autoRetryProvider = NotifierProvider<AutoRetryNotifier, bool>(
  AutoRetryNotifier.new,
);
