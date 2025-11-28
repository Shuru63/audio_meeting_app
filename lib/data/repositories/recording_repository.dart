import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:just_audio/just_audio.dart';
import '../../core/error/failure.dart';
import '../../core/services/firebase_service.dart';
import '../../core/services/recording_service.dart';
import '../models/recording_model.dart';

class RecordingRepository {
  final FirebaseService _firebaseService;
  final RecordingService _recordingService;

  RecordingRepository(this._firebaseService, this._recordingService);

  /// Create a new recording entry in Firebase
  Future<Either<Failure, RecordingModel>> createRecording({
    required String meetingId,
    required String meetingTitle,
    required String userId,
    required String localPath,
    required Duration duration,
    required int fileSize,
  }) async {
    try {
      final recording = RecordingModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        meetingId: meetingId,
        meetingTitle: meetingTitle,
        userId: userId,
        localPath: localPath,
        duration: duration.inSeconds,
        fileSize: fileSize,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 7)),
        isUploaded: false,
        status: 'completed',
      );

      await _firebaseService.setDocument(
        collection: 'recordings',
        docId: recording.id,
        data: recording.toFirestore(),
      );

      return Right(recording);
    } catch (e) {
      return Left(Failure('Failed to create recording: ${e.toString()}'));
    }
  }

  /// Get all recordings for a specific user from Firebase
  Future<Either<Failure, List<RecordingModel>>> getUserRecordings(
      String userId,
      ) async {
    try {
      final querySnapshot = await _firebaseService.firestore
          .collection('recordings')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      final recordings = querySnapshot.docs
          .map((doc) => RecordingModel.fromFirestore(doc))
          .toList();

      return Right(recordings);
    } catch (e) {
      return Left(Failure('Failed to get recordings: ${e.toString()}'));
    }
  }

  /// Get all local recordings from device storage
  Future<Either<Failure, List<RecordingModel>>> getLocalRecordings() async {
    try {
      final files = await _recordingService.getAllRecordings();
      final recordings = <RecordingModel>[];

      for (var file in files) {
        try {
          final fileStat = await File(file.path).stat();
          final duration = await _recordingService.getRecordingDuration(file.path);

          recordings.add(RecordingModel(
            id: file.path.split('/').last,
            meetingId: 'local',
            meetingTitle: _getRecordingNameFromPath(file.path),
            userId: 'local',
            localPath: file.path,
            duration: duration?.inSeconds ?? 0,
            fileSize: fileStat.size,
            createdAt: fileStat.modified,
            expiresAt: fileStat.modified.add(const Duration(days: 7)),
            isUploaded: false,
            status: 'local',
          ));
        } catch (e) {
          // Skip files that cause errors
          print('Error processing file ${file.path}: $e');
          continue;
        }
      }

      // Sort by creation date (newest first)
      recordings.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return Right(recordings);
    } catch (e) {
      return Left(Failure('Failed to get local recordings: ${e.toString()}'));
    }
  }

  /// Extract a readable name from the recording file path
  String _getRecordingNameFromPath(String path) {
    final fileName = path.split('/').last;
    final withoutExtension = fileName.replaceAll(RegExp(r'\.(m4a|aac|mp3|wav)$'), '');
    final parts = withoutExtension.split('_');

    if (parts.length > 1) {
      final meetingId = parts[0];
      final timestamp = parts.length > 1 ? parts[1] : '';
      return 'Meeting $meetingId - ${_formatTimestamp(timestamp)}';
    }

    return withoutExtension;
  }

  /// Format timestamp to readable date string
  String _formatTimestamp(String timestamp) {
    try {
      final date = DateTime.fromMillisecondsSinceEpoch(int.parse(timestamp));
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return timestamp;
    }
  }

  /// Delete a recording from Firebase
  Future<Either<Failure, void>> deleteRecording(String recordingId) async {
    try {
      await _firebaseService.deleteDocument('recordings', recordingId);
      return const Right(null);
    } catch (e) {
      return Left(Failure('Failed to delete recording: ${e.toString()}'));
    }
  }

  /// Delete a local recording file
  Future<Either<Failure, void>> deleteLocalRecording(String filePath) async {
    try {
      final success = await _recordingService.deleteRecording(filePath);
      if (success) {
        return const Right(null);
      } else {
        return Left(Failure('Failed to delete local recording'));
      }
    } catch (e) {
      return Left(Failure('Failed to delete local recording: ${e.toString()}'));
    }
  }

  /// Clean up old recordings from device storage
  Future<Either<Failure, void>> cleanupOldRecordings({int daysToKeep = 7}) async {
    try {
      await _recordingService.deleteOldRecordings(daysToKeep: daysToKeep);
      return const Right(null);
    } catch (e) {
      return Left(Failure('Failed to cleanup recordings: ${e.toString()}'));
    }
  }

  /// Upload recording to cloud storage
  Future<Either<Failure, RecordingModel>> uploadRecording({
    required String recordingId,
    required String localPath,
    required String userId,
  }) async {
    try {
      final file = File(localPath);
      if (!await file.exists()) {
        return Left(Failure('Recording file not found'));
      }

      await Future.delayed(const Duration(seconds: 2)); // Simulate upload time

      await _firebaseService.updateDocument(
        collection: 'recordings',
        docId: recordingId,
        data: {
          'isUploaded': true,
          'uploadUrl': 'https://storage.example.com/recordings/$recordingId',
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );

      final doc = await _firebaseService.getDocument('recordings', recordingId);
      return Right(RecordingModel.fromFirestore(doc));
    } catch (e) {
      return Left(Failure('Failed to upload recording: ${e.toString()}'));
    }
  }

  /// Play a recording file
  Future<Either<Failure, void>> playRecording(String filePath) async {
    try {
      await _recordingService.playRecording(filePath);
      return const Right(null);
    } catch (e) {
      return Left(Failure('Failed to play recording: ${e.toString()}'));
    }
  }

  /// Pause playback
  Future<Either<Failure, void>> pausePlayback() async {
    try {
      await _recordingService.pausePlayback();
      return const Right(null);
    } catch (e) {
      return Left(Failure('Failed to pause playback: ${e.toString()}'));
    }
  }

  /// Resume playback
  Future<Either<Failure, void>> resumePlayback() async {
    try {
      await _recordingService.resumePlayback();
      return const Right(null);
    } catch (e) {
      return Left(Failure('Failed to resume playback: ${e.toString()}'));
    }
  }

  /// Stop playback
  Future<Either<Failure, void>> stopPlayback() async {
    try {
      await _recordingService.stopPlayback();
      return const Right(null);
    } catch (e) {
      return Left(Failure('Failed to stop playback: ${e.toString()}'));
    }
  }

  /// Seek to a specific position in playback
  Future<Either<Failure, void>> seekPlayback(Duration position) async {
    try {
      await _recordingService.seekPlayback(position);
      return const Right(null);
    } catch (e) {
      return Left(Failure('Failed to seek playback: ${e.toString()}'));
    }
  }

  /// Get the duration of a recording file
  Future<Either<Failure, Duration?>> getRecordingDuration(String filePath) async {
    try {
      final duration = await _recordingService.getRecordingDuration(filePath);
      return Right(duration);
    } catch (e) {
      return Left(Failure('Failed to get recording duration: ${e.toString()}'));
    }
  }

  /// Get file size of a recording
  Future<Either<Failure, int>> getFileSize(String filePath) async {
    try {
      final size = await _recordingService.getFileSize(filePath);
      return Right(size);
    } catch (e) {
      return Left(Failure('Failed to get file size: ${e.toString()}'));
    }
  }

  /// Stream for playback position updates
  Stream<Duration> get playbackPositionStream =>
      _recordingService.playbackPositionStream;

  /// Stream for playback state updates
  Stream<PlayerState> get playbackStateStream =>
      _recordingService.playbackStateStream;

  /// Check if currently playing
  bool get isPlaying => _recordingService.isPlaying;

  /// Check if currently recording
  bool get isRecording => _recordingService.isRecording;
}