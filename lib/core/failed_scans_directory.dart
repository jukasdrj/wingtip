import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Utilities for managing the persistent failed scans directory
class FailedScansDirectory {
  static const String _dirName = 'failed_scans';

  /// Get the persistent failed scans directory
  /// Creates the directory if it doesn't exist
  static Future<Directory> getDirectory() async {
    final appDocsDir = await getApplicationDocumentsDirectory();
    final failedScansDir = Directory(p.join(appDocsDir.path, _dirName));

    if (!await failedScansDir.exists()) {
      await failedScansDir.create(recursive: true);
    }

    return failedScansDir;
  }

  /// Get the path for a failed scan image by job ID
  static Future<String> getImagePath(String jobId) async {
    final dir = await getDirectory();
    return p.join(dir.path, '$jobId.jpg');
  }

  /// Move an image from temp to persistent failed scans directory
  /// Returns the new persistent path
  static Future<String> moveImage(String sourcePath, String jobId) async {
    final sourceFile = File(sourcePath);
    if (!await sourceFile.exists()) {
      throw Exception('Source image does not exist: $sourcePath');
    }

    final destinationPath = await getImagePath(jobId);

    // Copy the file to the persistent location
    await sourceFile.copy(destinationPath);

    // Delete the source file from temp directory
    await sourceFile.delete();

    return destinationPath;
  }

  /// Delete a failed scan image by job ID
  static Future<void> deleteImage(String jobId) async {
    final imagePath = await getImagePath(jobId);
    final imageFile = File(imagePath);

    if (await imageFile.exists()) {
      await imageFile.delete();
    }
  }

  /// Check if an image exists for a job ID
  static Future<bool> imageExists(String jobId) async {
    final imagePath = await getImagePath(jobId);
    return await File(imagePath).exists();
  }
}
