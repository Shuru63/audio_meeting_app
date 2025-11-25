import 'package:dartz/dartz.dart';
import '../../core/error/failure.dart';
import '../../data/models/meeting_model.dart';
import '../../data/repositories/meeting_repository.dart';

class JoinMeetingUseCase {
  final MeetingRepository repository;

  JoinMeetingUseCase(this.repository);

  Future<Either<Failure, MeetingModel>> call({
    required String meetingCode,
    required String userId,
    required String userName,
  }) async {
    // Validate inputs
    if (meetingCode.isEmpty) {
      return Left(ValidationFailure('Meeting code cannot be empty'));
    }

    if (meetingCode.length < 6 || meetingCode.length > 8) {
      return Left(ValidationFailure('Meeting code must be 6-8 digits'));
    }

    if (userId.isEmpty) {
      return Left(ValidationFailure('User ID cannot be empty'));
    }

    if (userName.isEmpty) {
      return Left(ValidationFailure('User name cannot be empty'));
    }

    // Call repository
    return await repository.joinMeeting(
      meetingCode: meetingCode,
      userId: userId,
      userName: userName,
    );
  }
}