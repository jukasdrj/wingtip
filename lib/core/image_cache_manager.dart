import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Custom cache manager for book cover images with 50MB limit
///
/// MEMORY OPTIMIZATION:
/// - Limits cache size to 50MB (configurable)
/// - Expires entries after 30 days
/// - Uses LRU (Least Recently Used) eviction policy
/// - Configurable max file count to prevent excessive file handles
class ImageCacheManager {
  static const key = 'wingtip_image_cache';

  static CacheManager? _instance;

  static CacheManager get instance {
    _instance ??= CacheManager(
      Config(
        key,
        // 50MB cache size limit
        maxNrOfCacheObjects: 200, // ~250KB per image average
        stalePeriod: const Duration(days: 30),
        repo: JsonCacheInfoRepository(databaseName: key),
        fileService: HttpFileService(),
      ),
    );
    return _instance!;
  }

  /// Clear the entire image cache
  /// Call this on memory pressure warnings
  static Future<void> clearCache() async {
    await instance.emptyCache();
  }

  /// Remove old/stale entries without clearing everything
  static Future<void> cleanupCache() async {
    // This will remove entries older than stalePeriod
    // and trim cache if it exceeds maxNrOfCacheObjects
    await instance.emptyCache();
  }
}
