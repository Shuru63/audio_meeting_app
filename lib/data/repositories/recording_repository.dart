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
    required String localPath,
    required int duration,
    required int fileSize,
  }) async {
    try {
      final recording = RecordingModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        meetingId: meetingId,
        meetingTitle: meetingTitle,
        localPath: localPath,
        duration: duration,
        fileSize: fileSize,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 7)),
        isUploaded: false,
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
        final info = await _recordingService.getRecordingInfo(file.path);
        if (info != null) {
          recordings.add(RecordingModel(
            id: file.path.split('/').last,
            meetingId: '',
            meetingTitle: info['name'],
            localPath: file.path,
            duration: 0,
            fileSize: info['size'],
            createdAt: info['created'],
            expiresAt: info['created'].add(const Duration(days: 7)),
          ));
        }
      }

      return Right(recordings);
    } catch (e) {
      return Left(Failure('Failed to get local recordings: ${e.toString()}'));
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
      await _recordingService.deleteRecording(filePath);
      return const Right(null);
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
  }) async {
    try {
      // TODO: Implement cloud storage upload
      // For now, just update the recording status
      await _firebaseService.updateDocument(
        collection: 'recordings',
        docId: recordingId,
        data: {
          'isUploaded': true,
          'uploadUrl': 'https://storage.example.com/$recordingId',
        },
      );

      final doc = await _firebaseService.getDocument('recordings', recordingId);
      return Right(RecordingModel.fromFirestore(doc));
    } catch (e) {
      return Left(Failure('Failed to upload recording: ${e.toString()}'));
    }
  }
}