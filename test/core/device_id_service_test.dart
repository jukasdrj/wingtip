import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:wingtip/core/device_id_service.dart';

// Mock implementation of FlutterSecureStorage for testing
class MockSecureStorage implements FlutterSecureStorage {
  final Map<String, String> _storage = {};

  @override
  Future<void> write({
    required String key,
    required String? value,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value != null) {
      _storage[key] = value;
    }
  }

  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return _storage[key];
  }

  @override
  Future<void> delete({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _storage.remove(key);
  }

  @override
  Future<Map<String, String>> readAll({
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return Map.from(_storage);
  }

  @override
  Future<void> deleteAll({
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _storage.clear();
  }

  @override
  Future<bool> containsKey({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return _storage.containsKey(key);
  }

  @override
  AndroidOptions get aOptions => throw UnimplementedError();

  @override
  IOSOptions get iOptions => throw UnimplementedError();

  @override
  LinuxOptions get lOptions => throw UnimplementedError();

  @override
  MacOsOptions get mOptions => throw UnimplementedError();

  @override
  WebOptions get webOptions => throw UnimplementedError();

  @override
  WindowsOptions get wOptions => throw UnimplementedError();

  @override
  Future<bool> isCupertinoProtectedDataAvailable() async {
    return false;
  }

  @override
  void registerListener({
    required String key,
    required void Function(String value) listener,
  }) {
    // Not needed for tests
  }

  @override
  void unregisterAllListeners() {
    // Not needed for tests
  }

  @override
  void unregisterAllListenersForKey({required String key}) {
    // Not needed for tests
  }

  @override
  void unregisterListener({
    required String key,
    required void Function(String value) listener,
  }) {
    // Not needed for tests
  }

  @override
  Stream<bool>? get onCupertinoProtectedDataAvailabilityChanged {
    return null;
  }
}

void main() {
  group('DeviceIdService', () {
    late MockSecureStorage mockStorage;
    late DeviceIdService service;

    setUp(() {
      mockStorage = MockSecureStorage();
      service = DeviceIdService(secureStorage: mockStorage);
    });

    test('generates a UUID v4 on first call', () async {
      final deviceId = await service.getDeviceId();

      // UUID v4 format: xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx
      final uuidV4Regex = RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
      );

      expect(deviceId, isNotEmpty);
      expect(uuidV4Regex.hasMatch(deviceId), isTrue);
    });

    test('returns the same device ID on subsequent calls', () async {
      final firstCall = await service.getDeviceId();
      final secondCall = await service.getDeviceId();

      expect(firstCall, equals(secondCall));
    });

    test('stores device ID in secure storage', () async {
      final deviceId = await service.getDeviceId();
      final storedId = await mockStorage.read(key: 'device_id');

      expect(storedId, equals(deviceId));
    });

    test('retrieves existing device ID from secure storage', () async {
      const existingId = '12345678-1234-4234-8234-123456789abc';
      await mockStorage.write(key: 'device_id', value: existingId);

      final deviceId = await service.getDeviceId();

      expect(deviceId, equals(existingId));
    });

    test('regenerateDeviceId creates a new device ID', () async {
      final originalId = await service.getDeviceId();
      final newId = await service.regenerateDeviceId();

      expect(newId, isNot(equals(originalId)));
      expect(newId, isNotEmpty);

      final storedId = await mockStorage.read(key: 'device_id');
      expect(storedId, equals(newId));
    });

    test('getDeviceId returns new ID after regeneration', () async {
      final originalId = await service.getDeviceId();
      final regeneratedId = await service.regenerateDeviceId();
      final retrievedId = await service.getDeviceId();

      expect(retrievedId, equals(regeneratedId));
      expect(retrievedId, isNot(equals(originalId)));
    });

    test('clearDeviceId removes device ID from storage', () async {
      await service.getDeviceId();
      await service.clearDeviceId();

      final storedId = await mockStorage.read(key: 'device_id');
      expect(storedId, isNull);
    });

    test('generates new ID after clearing', () async {
      final originalId = await service.getDeviceId();
      await service.clearDeviceId();
      final newId = await service.getDeviceId();

      expect(newId, isNot(equals(originalId)));
      expect(newId, isNotEmpty);
    });
  });
}
