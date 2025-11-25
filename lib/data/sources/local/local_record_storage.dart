import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:logger/logger.dart';
import '../../../core/error/exceptions.dart';

class LocalRecordStorage {
  final Logger _logger = Logger();
  static const String _recordingsFolder = 'AudioMeetings/Recordings';

  Future<String> getRecordingsPath() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final recordingsDir = Directory('${directory.path}/$_recordingsFolder');
      
      if (!await recordingsDir.exists()) {
        await recordingsDir.create(recursive: true);
      }
      
      return recordingsDir.path;
    } catch (e) {
      _logger.e('Failed to get recordings path: $e');
      throw CacheException(message: 'Failed to access recordings directory');
    }
  }

  Future<File> saveRecording({
    required String meetingId,
    required String recordingPath,
  }) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${meetingId}_$timestamp.aac';
      final targetPath = await getRecordingsPath();
      final targetFile = File('$targetPath/$fileName');

      final sourceFile = File(recordingPath);
      if (!await sourceFile.exists()) {
        throw CacheException(message: 'Source recording file not found');
      }

      await sourceFile.copy(targetFile.path);
      _logger.i('Saved recording: $fileName');
      
      return targetFile;
    } catch (e) {
      _logger.e('Failed to save recording: $e');
      throw CacheException(message: 'Failed to save recording');
    }
  }

  Future<List<File>> getAllRecordings() async {
    try {
      final recordingsPath = await getRecordingsPath();
      final directory = Directory(recordingsPath);
      
      if (!await directory.exists()) {
        return [];
      }

      final files = directory
          .listSync()
          .whereType<File>()
          .where((file) => file.path.endsWith('.aac') || file.path.endsWith('.mp3'))
          .toList();

      // Sort by modification date (newest first)
      files.sort((a, b) => 
        b.statSync().modified.compareTo(a.statSync().modified)
      );

      return files;
    } catch (e) {
      _logger.e('Failed to get recordings: $e');
      return [];
    }
  }

  Future<File?> getRecording(String fileName) async {
    try {
      final recordingsPath = await getRecordingsPath();
      final file = File('$recordingsPath/$fileName');
      
      if (await file.exists()) {
        return file;
      }
      
      return null;
    } catch (e) {
      _logger.e('Failed to get recording: $e');
      return null;
    }
  }

  Future<bool> deleteRecording(String filePath) async {
    try {
      final file = File(filePath);
      
      if (!await file.exists()) {
        _logger.w('Recording file not found: $filePath');
        return false;
      }

      await file.delete();
      _logger.i('Deleted recording: $filePath');
      return true;
    } catch (e) {
      _logger.e('Failed to delete recording: $e');
      throw CacheException(message: 'Failed to delete recording');
    }
  }

  Future<int> deleteOldRecordings({int daysToKeep = 7}) async {
    try {
      final recordings = await getAllRecordings();
      final now = DateTime.now();
      final cutoffDate = now.subtract(Duration(days: daysToKeep));
      int deletedCount = 0;

      for (final file in recordings) {
        final stat = await file.stat();
        if (stat.modified.isBefore(cutoffDate)) {
          await file.delete();
          deletedCount++;
          _logger.i('Deleted old recording: ${file.path}');
        }
      }

      _logger.i('Deleted $deletedCount old recordings');
      return deletedCount;
    } catch (e) {
      _logger.e('Failed to delete old recordings: $e');
      throw CacheException(message: 'Failed to cleanup old recordings');
    }
  }

  Future<Map<String, dynamic>?> getRecordingMetadata(String filePath) async {
    try {
      final file = File(filePath);
      
      if (!await file.exists()) {
        return null;
      }

      final stat = await file.stat();
      final fileName = file.path.split('/').last;

      return {
        'path': filePath,
        'fileName': fileName,
        'size': stat.size,
        'sizeInMB': (stat.size / (1024 * 1024)).toStringAsFixed(2),
        'created': stat.modified,
        'modified': stat.modified,
      };
    } catch (e) {
      _logger.e('Failed to get recording metadata: $e');
      return null;
    }
  }

  Future<int> getTotalSize() async {
    try {
      final recordings = await getAllRecordings();
      int totalSize = 0;

      for (final file in recordings) {
        final stat = await file.stat();
        totalSize += stat.size;
      }

      return totalSize;
    } catch (e) {
      _logger.e('Failed to get total size: $e');
      return 0;
    }
  }

  Future<String> getTotalSizeFormatted() async {
    final bytes = await getTotalSize();
    
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(2)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
  }

  Future<int> getRecordingCount() async {
    try {
      final recordings = await getAllRecordings();
      return recordings.length;
    } catch (e) {
      _logger.e('Failed to get recording count: $e');
      return 0;
    }
  }

  Future<bool> recordingExists(String fileName) async {
    try {
      final recordingsPath = await getRecordingsPath();
      final file = File('$recordingsPath/$fileName');
      return await file.exists();
    } catch (e) {
      _logger.e('Failed to check recording existence: $e');
      return false;
    }
  }

  Future<void> clearAllRecordings() async {
    try {
      final recordings = await getAllRecordings();
      
      for (final file in recordings) {
        await file.delete();
      }
      
      _logger.i('Cleared all recordings (${recordings.length} files)');
    } catch (e) {
      _logger.e('Failed to clear all recordings: $e');
      throw CacheException(message: 'Failed to clear recordings');
    }
  }

  Future<File?> moveRecording({
    required String sourcePath,
    required String newFileName,
  }) async {
    try {
      final sourceFile = File(sourcePath);
      
      if (!await sourceFile.exists()) {
        throw CacheException(message: 'Source file not found');
      }

      final recordingsPath = await getRecordingsPath();
      final targetFile = File('$recordingsPath/$newFileName');

      await sourceFile.rename(targetFile.path);
      _logger.i('Moved recording to: ${targetFile.path}');
      
      return targetFile;
    } catch (e) {
      _logger.e('Failed to move recording: $e');
      throw CacheException(message: 'Failed to move recording');
    }
  }

  Future<File?> copyRecording({
    required String sourcePath,
    required String newFileName,
  }) async {
    try {
      final sourceFile = File(sourcePath);
      
      if (!await sourceFile.exists()) {
        throw CacheException(message: 'Source file not found');
      }

      final recordingsPath = await getRecordingsPath();
      final targetFile = File('$recordingsPath/$newFileName');

      await sourceFile.copy(targetFile.path);
      _logger.i('Copied recording to: ${targetFile.path}');
      
      return targetFile;
    } catch (e) {
      _logger.e('Failed to copy recording: $e');
      throw CacheException(message: 'Failed to copy recording');
    }
  }
}