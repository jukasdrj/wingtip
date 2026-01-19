import 'dart:io';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

/// Fake implementation of PathProviderPlatform for testing
class FakePathProviderPlatform extends PathProviderPlatform {
  @override
  Future<String?> getTemporaryPath() async {
    return Directory.systemTemp.path;
  }

  @override
  Future<String?> getApplicationSupportPath() async {
    final dir = await Directory.systemTemp.createTemp('app_support_');
    return dir.path;
  }

  @override
  Future<String?> getApplicationDocumentsPath() async {
    final dir = await Directory.systemTemp.createTemp('app_documents_');
    return dir.path;
  }

  @override
  Future<String?> getApplicationCachePath() async {
    final dir = await Directory.systemTemp.createTemp('app_cache_');
    return dir.path;
  }

  @override
  Future<String?> getDownloadsPath() async {
    final dir = await Directory.systemTemp.createTemp('downloads_');
    return dir.path;
  }

  @override
  Future<List<String>?> getExternalCachePaths() async {
    return null;
  }

  @override
  Future<String?> getExternalStoragePath() async {
    return null;
  }

  @override
  Future<List<String>?> getExternalStoragePaths({
    StorageDirectory? type,
  }) async {
    return null;
  }

  @override
  Future<String?> getLibraryPath() async {
    final dir = await Directory.systemTemp.createTemp('library_');
    return dir.path;
  }
}
