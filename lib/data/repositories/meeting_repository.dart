import 'package:dartz/dartz.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/error/failure.dart';
import '../../core/services/firebase_service.dart';
import '../models/meeting_model.dart';
import '../models/participant_model.dart';

class MeetingRepository {
  final FirebaseService _firebaseService;

  MeetingRepository(this._firebaseService);

  Future<Either<Failure, MeetingModel>> createMeeting(
    MeetingModel meeting,
  ) async {
    try {
      // Create meeting document
      await _firebaseService.setDocument(
        collection: 'meetings',
        docId: meeting.id,
        data: meeting.toFirestore(),
      );

      // Add host as first participant
      final participant = ParticipantModel(
        id: '${meeting.id}_${meeting.hostId}',
        meetingId: meeting.id,
        userId: meeting.hostId,
        userName: meeting.hostName,
        joinedAt: DateTime.now(),
        isMuted: false,
        isHost: true,
        status: ParticipantStatus.active,
      );

      await _firebaseService.setDocument(
        collection: 'participants',
        docId: participant.id,
        data: participant.toFirestore(),
      );

      return Right(meeting);
    } catch (e) {
      return Left(Failure('Failed to create meeting: ${e.toString()}'));
    }
  }

  Future<Either<Failure, MeetingModel>> joinMeeting({
    required String meetingCode,
    required String userId,
    required String userName,
  }) async {
    try {
      // Find meeting by code
      final querySnapshot = await _firebaseService.firestore
          .collection('meetings')
          .where('meetingCode', isEqualTo: meetingCode)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return Left(Failure('Meeting not found'));
      }

      final meetingDoc = querySnapshot.docs.first;
      final meeting = MeetingModel.fromFirestore(meetingDoc);

      if (meeting.isEnded) {
        return Left(Failure('This meeting has ended'));
      }

      // Check if user already in meeting
      final existingParticipant = await _firebaseService.firestore
          .collection('participants')
          .where('meetingId', isEqualTo: meeting.id)
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'active')
          .get();

      if (existingParticipant.docs.isEmpty) {
        // Add user as participant
        final participant = ParticipantModel(
          id: '${meeting.id}_$userId',
          meetingId: meeting.id,
          userId: userId,
          userName: userName,
          joinedAt: DateTime.now(),
          isMuted: false,
          isHost: false,
          status: ParticipantStatus.active,
        );

        await _firebaseService.setDocument(
          collection: 'participants',
          docId: participant.id,
          data: participant.toFirestore(),
        );

        // Update participant count
        await _firebaseService.updateDocument(
          collection: 'meetings',
          docId: meeting.id,
          data: {
            'participantCount': FieldValue.increment(1),
            'participantIds': FieldValue.arrayUnion([userId]),
          },
        );
      }

      return Right(meeting);
    } catch (e) {
      return Left(Failure('Failed to join meeting: ${e.toString()}'));
    }
  }

  Future<Either<Failure, void>> leaveMeeting({
    required String meetingId,
    required String userId,
  }) async {
    try {
      final participantId = '${meetingId}_$userId';

      // Update participant status
      await _firebaseService.updateDocument(
        collection: 'participants',
        docId: participantId,
        data: {
          'status': 'left',
          'leftAt': FieldValue.serverTimestamp(),
        },
      );

      // Update meeting participant count
      await _firebaseService.updateDocument(
        collection: 'meetings',
        docId: meetingId,
        data: {
          'participantCount': FieldValue.increment(-1),
          'participantIds': FieldValue.arrayRemove([userId]),
        },
      );

      return const Right(null);
    } catch (e) {
      return Left(Failure('Failed to leave meeting: ${e.toString()}'));
    }
  }

  Future<Either<Failure, void>> endMeeting(String meetingId) async {
    try {
      // Update meeting status
      await _firebaseService.updateDocument(
        collection: 'meetings',
        docId: meetingId,
        data: {
          'status': 'ended',
          'endedAt': FieldValue.serverTimestamp(),
        },
      );

      // Update all active participants
      final participants = await _firebaseService.firestore
          .collection('participants')
          .where('meetingId', isEqualTo: meetingId)
          .where('status', isEqualTo: 'active')
          .get();

      for (var doc in participants.docs) {
        await _firebaseService.updateDocument(
          collection: 'participants',
          docId: doc.id,
          data: {
            'status': 'left',
            'leftAt': FieldValue.serverTimestamp(),
          },
        );
      }

      return const Right(null);
    } catch (e) {
      return Left(Failure('Failed to end meeting: ${e.toString()}'));
    }
  }

  Future<Either<Failure, void>> muteParticipant({
    required String meetingId,
    required String userId,
    required bool mute,
  }) async {
    try {
      final participantId = '${meetingId}_$userId';

      await _firebaseService.updateDocument(
        collection: 'participants',
        docId: participantId,
        data: {'isMuted': mute},
      );

      return const Right(null);
    } catch (e) {
      return Left(Failure('Failed to mute participant: ${e.toString()}'));
    }
  }

  Future<Either<Failure, void>> removeParticipant({
    required String meetingId,
    required String userId,
  }) async {
    try {
      final participantId = '${meetingId}_$userId';

      await _firebaseService.updateDocument(
        collection: 'participants',
        docId: participantId,
        data: {
          'status': 'removed',
          'leftAt': FieldValue.serverTimestamp(),
        },
      );

      await _firebaseService.updateDocument(
        collection: 'meetings',
        docId: meetingId,
        data: {
          'participantCount': FieldValue.increment(-1),
          'participantIds': FieldValue.arrayRemove([userId]),
        },
      );

      return const Right(null);
    } catch (e) {
      return Left(Failure('Failed to remove participant: ${e.toString()}'));
    }
  }

  Future<Either<Failure, MeetingModel>> getMeeting(String meetingId) async {
    try {
      final doc = await _firebaseService.getDocument('meetings', meetingId);

      if (!doc.exists) {
        return Left(Failure('Meeting not found'));
      }

      return Right(MeetingModel.fromFirestore(doc));
    } catch (e) {
      return Left(Failure('Failed to get meeting: ${e.toString()}'));
    }
  }

  Future<Either<Failure, List<MeetingModel>>> getUserMeetings(
    String userId,
  ) async {
    try {
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));

      final querySnapshot = await _firebaseService.firestore
          .collection('meetings')
          .where('participantIds', arrayContains: userId)
          .where('createdAt', isGreaterThan: Timestamp.fromDate(sevenDaysAgo))
          .orderBy('createdAt', descending: true)
          .get();

      final meetings = querySnapshot.docs
          .map((doc) => MeetingModel.fromFirestore(doc))
          .toList();

      return Right(meetings);
    } catch (e) {
      return Left(Failure('Failed to get meetings: ${e.toString()}'));
    }
  }

  Stream<MeetingModel> meetingStream(String meetingId) {
    return _firebaseService
        .documentStream('meetings', meetingId)
        .map((snapshot) => MeetingModel.fromFirestore(snapshot));
  }

  Stream<List<ParticipantModel>> participantsStream(String meetingId) {
    return _firebaseService.firestore
        .collection('participants')
        .where('meetingId', isEqualTo: meetingId)
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ParticipantModel.fromFirestore(doc))
            .toList());
  }

  Future<Either<Failure, void>> startRecording(String meetingId) async {
    try {
      await _firebaseService.updateDocument(
        collection: 'meetings',
        docId: meetingId,
        data: {'isRecording': true},
      );

      return const Right(null);
    } catch (e) {
      return Left(Failure('Failed to start recording: ${e.toString()}'));
    }
  }

  Future<Either<Failure, void>> stopRecording({
    required String meetingId,
    String? recordingUrl,
  }) async {
    try {
      await _firebaseService.updateDocument(
        collection: 'meetings',
        docId: meetingId,
        data: {
          'isRecording': false,
          if (recordingUrl != null) 'recordingUrl': recordingUrl,
        },
      );

      return const Right(null);
    } catch (e) {
      return Left(Failure('Failed to stop recording: ${e.toString()}'));
    }
  }
}