import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../core/error/failure.dart';
import '../../core/services/firebase_service.dart';
import '../../core/services/recording_service.dart';
import '../models/recording_model.dart';

class RecordingRepository {
  final FirebaseService _firebaseService;
  final RecordingService _recordingService;

  RecordingRepository(this._firebaseService, this._recordingService);

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

  Future<Either<Failure, List<RecordingModel>>> getLocalRecordings() async {
    try {
      final files = await _recordingService.getAllRecordings();
      final recordings = <RecordingModel>[];

      for (var file in files) {
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
      }

      // Sort by creation date (newest first)
      recordings.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return Right(recordings);
    } catch (e) {
      return Left(Failure('Failed to get local recordings: ${e.toString()}'));
    }
  }

  String _getRecordingNameFromPath(String path) {
    final fileName = path.split('/').last;
    final withoutExtension = fileName.replaceAll(RegExp(r'\.(m4a|aac|mp3)$'), '');
    final parts = withoutExtension.split('_');
    
    if (parts.length > 1) {
      final meetingId = parts[0];
      final timestamp = parts.length > 1 ? parts[1] : '';
      return 'Meeting $meetingId - ${_formatTimestamp(timestamp)}';
    }
    
    return withoutExtension;
  }

  String _formatTimestamp(String timestamp) {
    try {
      final date = DateTime.fromMillisecondsSinceEpoch(int.parse(timestamp));
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return timestamp;
    }
  }

  Future<Either<Failure, void>> deleteRecording(String recordingId) async {
    try {
      await _firebaseService.deleteDocument('recordings', recordingId);
      return const Right(null);
    } catch (e) {
      return Left(Failure('Failed to delete recording: ${e.toString()}'));
    }
  }

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

  Future<Either<Failure, void>> cleanupOldRecordings() async {
    try {
      await _recordingService.deleteOldRecordings(daysToKeep: 7);
      return const Right(null);
    } catch (e) {
      return Left(Failure('Failed to cleanup recordings: ${e.toString()}'));
    }
  }

  Future<Either<Failure, RecordingModel>> uploadRecording({
    required String recordingId,
    required String localPath,
    required String userId,
  }) async {
    try {
      // TODO: Implement actual cloud storage upload
      // For now, simulate upload and update status
      await Future.delayed(const Duration(seconds: 2)); // Simulate upload time
      
      await _firebaseService.updateDocument(
        collection: 'recordings',
        docId: recordingId,
        data: {
          'isUploaded': true,
          'uploadUrl': 'https://storage.example.com/recordings/$recordingId',
          'uploadedAt': DateTime.now(),
        },
      );

      final doc = await _firebaseService.getDocument('recordings', recordingId);
      return Right(RecordingModel.fromFirestore(doc));
    } catch (e) {
      return Left(Failure('Failed to upload recording: ${e.toString()}'));
    }
  }

  Future<Either<Failure, void>> playRecording(String filePath) async {
    try {
      await _recordingService.playRecording(filePath);
      return const Right(null);
    } catch (e) {
      return Left(Failure('Failed to play recording: ${e.toString()}'));
    }
  }

  Future<Either<Failure, void>> stopPlayback() async {
    try {
      await _recordingService.stopPlayback();
      return const Right(null);
    } catch (e) {
      return Left(Failure('Failed to stop playback: ${e.toString()}'));
    }
  }

  Stream<Duration> get playbackPositionStream => 
      _recordingService.playbackPositionStream;

  Stream<PlayerState> get playbackStateStream => 
      _recordingService.playbackStateStream;
}