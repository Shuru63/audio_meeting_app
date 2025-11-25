import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:logger/logger.dart';
import 'package:permission_handler/permission_handler.dart';

class RecordingService {
  final AudioRecorder _audioRecorder = AudioRecorder();
  final Logger _logger = Logger();

  String? _currentRecordingPath;
  bool _isRecording = false;
  DateTime? _recordingStartTime;

  bool get isRecording => _isRecording;
  String? get currentRecordingPath => _currentRecordingPath;
  Duration? get recordingDuration {
    if (_recordingStartTime != null) {
      return DateTime.now().difference(_recordingStartTime!);
    }
    return null;
  }

  Future<bool> checkAndRequestPermission() async {
    final status = await Permission.microphone.status;
    
    if (status.isDenied) {
      final result = await Permission.microphone.request();
      return result.isGranted;
    }
    
    return status.isGranted;
  }

  Future<String> _getRecordingsDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    final recordingsDir = Directory('${directory.path}/AudioMeetings/Recordings');
    
    if (!await recordingsDir.exists()) {
      await recordingsDir.create(recursive: true);
    }
    
    return recordingsDir.path;
  }

  Future<bool> startRecording(String meetingId) async {
    try {
      // Check permission
      final hasPermission = await checkAndRequestPermission();
      if (!hasPermission) {
        _logger.e('Microphone permission not granted');
        return false;
      }

      // Check if already recording
      if (_isRecording) {
        _logger.w('Recording already in progress');
        return false;
      }

      // Get recordings directory
      final recordingsPath = await _getRecordingsDirectory();
      
      // Create file path with timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _currentRecordingPath = '$recordingsPath/${meetingId}_$timestamp.aac';

      // Start recording
      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: _currentRecordingPath!,
      );

      _isRecording = true;
      _recordingStartTime = DateTime.now();
      _logger.i('Recording started: $_currentRecordingPath');
      
      return true;
    } catch (e) {
      _logger.e('Error starting recording: $e');
      return false;
    }
  }

  Future<String?> stopRecording() async {
    try {
      if (!_isRecording) {
        _logger.w('No recording in progress');
        return null;
      }

      final path = await _audioRecorder.stop();
      
      _isRecording = false;
      _recordingStartTime = null;
      
      if (path != null) {
        _logger.i('Recording stopped: $path');
        final savedPath = _currentRecordingPath;
        _currentRecordingPath = null;
        return savedPath;
      }
      
      return null;
    } catch (e) {
      _logger.e('Error stopping recording: $e');
      return null;
    }
  }

  Future<void> pauseRecording() async {
    try {
      if (_isRecording) {
        await _audioRecorder.pause();
        _logger.i('Recording paused');
      }
    } catch (e) {
      _logger.e('Error pausing recording: $e');
    }
  }

  Future<void> resumeRecording() async {
    try {
      if (_isRecording) {
        await _audioRecorder.resume();
        _logger.i('Recording resumed');
      }
    } catch (e) {
      _logger.e('Error resuming recording: $e');
    }
  }

  Future<void> cancelRecording() async {
    try {
      if (_isRecording) {
        await _audioRecorder.stop();
        
        // Delete the recording file
        if (_currentRecordingPath != null) {
          final file = File(_currentRecordingPath!);
          if (await file.exists()) {
            await file.delete();
          }
        }
        
        _isRecording = false;
        _recordingStartTime = null;
        _currentRecordingPath = null;
        
        _logger.i('Recording cancelled and deleted');
      }
    } catch (e) {
      _logger.e('Error cancelling recording: $e');
    }
  }

  Future<List<File>> getAllRecordings() async {
    try {
      final recordingsPath = await _getRecordingsDirectory();
      final directory = Directory(recordingsPath);
      
      if (!await directory.exists()) {
        return [];
      }
      
      final files = directory.listSync()
          .whereType<File>()
          .where((file) => file.path.endsWith('.aac'))
          .toList();
      
      // Sort by modification date (newest first)
      files.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
      
      return files;
    } catch (e) {
      _logger.e('Error getting recordings: $e');
      return [];
    }
  }

  Future<void> deleteRecording(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        _logger.i('Recording deleted: $filePath');
      }
    } catch (e) {
      _logger.e('Error deleting recording: $e');
    }
  }

  Future<void> deleteOldRecordings({int daysToKeep = 7}) async {
    try {
      final recordingsPath = await _getRecordingsDirectory();
      final directory = Directory(recordingsPath);
      
      if (!await directory.exists()) {
        return;
      }
      
      final files = directory.listSync().whereType<File>();
      final now = DateTime.now();
      final cutoffDate = now.subtract(Duration(days: daysToKeep));
      
      int deletedCount = 0;
      for (var file in files) {
        final stat = await file.stat();
        if (stat.modified.isBefore(cutoffDate)) {
          await file.delete();
          deletedCount++;
        }
      }
      
      _logger.i('Deleted $deletedCount old recordings');
    } catch (e) {
      _logger.e('Error deleting old recordings: $e');
    }
  }

  Future<Map<String, dynamic>?> getRecordingInfo(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return null;
      }
      
      final stat = await file.stat();
      final fileName = file.path.split('/').last;
      
      return {
        'path': filePath,
        'name': fileName,
        'size': stat.size,
        'sizeInMB': (stat.size / (1024 * 1024)).toStringAsFixed(2),
        'created': stat.modified,
        'duration': null, // Could be calculated if needed
      };
    } catch (e) {
      _logger.e('Error getting recording info: $e');
      return null;
    }
  }

  Future<void> dispose() async {
    if (_isRecording) {
      await stopRecording();
    }
    await _audioRecorder.dispose();
  }
}