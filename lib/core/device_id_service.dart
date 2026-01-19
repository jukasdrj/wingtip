import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

/// Service responsible for generating and managing the device ID.
///
/// The device ID is a UUID v4 that is generated on first launch and
/// stored securely using FlutterSecureStorage.
class DeviceIdService {
  DeviceIdService({
    FlutterSecureStorage? secureStorage,
  }) : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _secureStorage;
  static const String _deviceIdKey = 'device_id';
  static const Uuid _uuid = Uuid();

  /// Gets the device ID, generating one if it doesn't exist.
  Future<String> getDeviceId() async {
    String? deviceId = await _secureStorage.read(key: _deviceIdKey);

    if (deviceId == null || deviceId.isEmpty) {
      deviceId = _generateDeviceId();
      await _secureStorage.write(key: _deviceIdKey, value: deviceId);
    }

    return deviceId;
  }

  /// Generates a new device ID (UUID v4).
  String _generateDeviceId() {
    return _uuid.v4();
  }

  /// Regenerates the device ID, replacing any existing one.
  /// This should only be used for debugging purposes.
  Future<String> regenerateDeviceId() async {
    final newDeviceId = _generateDeviceId();
    await _secureStorage.write(key: _deviceIdKey, value: newDeviceId);
    return newDeviceId;
  }

  /// Clears the stored device ID.
  /// This is primarily for testing purposes.
  Future<void> clearDeviceId() async {
    await _secureStorage.delete(key: _deviceIdKey);
  }
}
