import 'package:dartz/dartz.dart';
import '../../core/error/failure.dart';
import '../../data/repositories/meeting_repository.dart';

class ManageParticipantsUseCase {
  final MeetingRepository repository;

  ManageParticipantsUseCase(this.repository);

  Future<Either<Failure, void>> muteParticipant({
    required String meetingId,
    required String userId,
    required bool mute,
  }) async {
    if (meetingId.isEmpty) {
      return Left(ValidationFailure('Meeting ID cannot be empty') as Failure);
    }

    if (userId.isEmpty) {
      return Left(ValidationFailure('User ID cannot be empty') as Failure);
    }

    return await repository.muteParticipant(
      meetingId: meetingId,
      userId: userId,
      mute: mute,
    );
  }

  Future<Either<Failure, void>> removeParticipant({
    required String meetingId,
    required String userId,
  }) async {
    if (meetingId.isEmpty) {
      return Left(ValidationFailure('Meeting ID cannot be empty') as Failure);
    }

    if (userId.isEmpty) {
      return Left(ValidationFailure('User ID cannot be empty') as Failure);
    }

    return await repository.removeParticipant(
      meetingId: meetingId,
      userId: userId,
    );
  }

  Future<Either<Failure, void>> endMeeting(String meetingId) async {
    if (meetingId.isEmpty) {
      return Left(ValidationFailure('Meeting ID cannot be empty') as Failure);
    }

    return await repository.endMeeting(meetingId);
  }

  Future<Either<Failure, void>> leaveMeeting({
    required String meetingId,
    required String userId,
  }) async {
    if (meetingId.isEmpty) {
      return Left(ValidationFailure('Meeting ID cannot be empty') as Failure);
    }

    if (userId.isEmpty) {
      return Left(ValidationFailure('User ID cannot be empty') as Failure);
    }

    return await repository.leaveMeeting(
      meetingId: meetingId,
      userId: userId,
    );
  }
}