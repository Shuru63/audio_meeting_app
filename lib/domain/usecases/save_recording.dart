import 'package:dartz/dartz.dart';
import '../../core/error/failure.dart';
import '../../data/models/recording_model.dart';
import '../../data/repositories/recording_repository.dart';

class SaveRecordingUseCase {
  final RecordingRepository repository;

  SaveRecordingUseCase(this.repository);

  Future<Either<Failure, RecordingModel>> call({
    required String meetingId,
    required String meetingTitle,
    required String localPath,
    required int duration,
    required int fileSize,
  }) async {
    // Validate inputs
    if (meetingId.isEmpty) {
      return Left(ValidationFailure('Meeting ID cannot be empty'));
    }

    if (localPath.isEmpty) {
      return Left(ValidationFailure('Recording path cannot be empty'));
    }

    if (duration <= 0) {
      return Left(ValidationFailure('Duration must be greater than 0'));
    }

    if (fileSize <= 0) {
      return Left(ValidationFailure('File size must be greater than 0'));
    }

    // Call repository
    return await repository.createRecording(
      meetingId: meetingId,
      meetingTitle: meetingTitle,
      localPath: localPath,
      duration: duration,
      fileSize: fileSize,
    );
  }
}