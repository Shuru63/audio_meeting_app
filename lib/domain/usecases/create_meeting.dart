import 'package:dartz/dartz.dart';
import '../../core/error/failure.dart';
import '../../data/models/meeting_model.dart';
import '../../data/repositories/meeting_repository.dart';

class CreateMeetingUseCase {
  final MeetingRepository repository;

  CreateMeetingUseCase(this.repository);

  Future<Either<Failure, MeetingModel>> call(MeetingModel meeting) async {
    // Validate meeting data
    if (meeting.meetingCode.isEmpty) {
      return Left(ValidationFailure('Meeting code cannot be empty'));
    }

    if (meeting.meetingCode.length < 6 || meeting.meetingCode.length > 8) {
      return Left(ValidationFailure('Meeting code must be 6-8 digits'));
    }

    if (meeting.hostId.isEmpty) {
      return Left(ValidationFailure('Host ID cannot be empty'));
    }

    if (meeting.title.isEmpty) {
      return Left(ValidationFailure('Meeting title cannot be empty'));
    }

    // Call repository
    return await repository.createMeeting(meeting);
  }
}