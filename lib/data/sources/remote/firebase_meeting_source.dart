import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import '../../../core/error/exceptions.dart';
import '../../models/meeting_model.dart';
import '../../models/participant_model.dart';

class FirebaseMeetingSource {
  final FirebaseFirestore _firestore;
  final Logger _logger = Logger();

  FirebaseMeetingSource({required FirebaseFirestore firestore})
      : _firestore = firestore;

  Future<String> createMeeting(Map<String, dynamic> meetingData) async {
    try {
      final docRef = await _firestore.collection('meetings').add(meetingData);
      return docRef.id;
    } catch (e) {
      _logger.e('Create meeting error: $e');
      throw ServerException(message: 'Failed to create meeting');
    }
  }

  Future<MeetingModel?> getMeetingById(String meetingId) async {
    try {
      final doc = await _firestore.collection('meetings').doc(meetingId).get();
      if (!doc.exists) return null;
      return MeetingModel.fromFirestore(doc);
    } catch (e) {
      _logger.e('Get meeting error: $e');
      throw ServerException(message: 'Failed to get meeting');
    }
  }

  Future<MeetingModel?> getMeetingByCode(String meetingCode) async {
    try {
      final querySnapshot = await _firestore
          .collection('meetings')
          .where('meetingCode', isEqualTo: meetingCode)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) return null;
      return MeetingModel.fromFirestore(querySnapshot.docs.first);
    } catch (e) {
      _logger.e('Get meeting by code error: $e');
      throw ServerException(message: 'Failed to find meeting');
    }
  }

  Future<List<MeetingModel>> getUserMeetings({
    required String userId,
    int? limit,
  }) async {
    try {
      Query query = _firestore
          .collection('meetings')
          .where('participantIds', arrayContains: userId)
          .orderBy('createdAt', descending: true);

      if (limit != null) {
        query = query.limit(limit);
      }

      final querySnapshot = await query.get();
      return querySnapshot.docs
          .map((doc) => MeetingModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      _logger.e('Get user meetings error: $e');
      throw ServerException(message: 'Failed to get meetings');
    }
  }

  Future<List<MeetingModel>> getActiveMeetings() async {
    try {
      final querySnapshot = await _firestore
          .collection('meetings')
          .where('status', isEqualTo: 'active')
          .orderBy('startedAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => MeetingModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      _logger.e('Get active meetings error: $e');
      throw ServerException(message: 'Failed to get active meetings');
    }
  }

  Future<void> updateMeeting({
    required String meetingId,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _firestore.collection('meetings').doc(meetingId).update(data);
    } catch (e) {
      _logger.e('Update meeting error: $e');
      throw ServerException(message: 'Failed to update meeting');
    }
  }

  Future<void> deleteMeeting(String meetingId) async {
    try {
      await _firestore.collection('meetings').doc(meetingId).delete();
    } catch (e) {
      _logger.e('Delete meeting error: $e');
      throw ServerException(message: 'Failed to delete meeting');
    }
  }

  Stream<MeetingModel> watchMeeting(String meetingId) {
    return _firestore
        .collection('meetings')
        .doc(meetingId)
        .snapshots()
        .map((snapshot) => MeetingModel.fromFirestore(snapshot));
  }

  // Participant operations
  Future<String> addParticipant(
    String meetingId,
    Map<String, dynamic> participantData,
  ) async {
    try {
      final docRef = await _firestore
          .collection('meetings')
          .doc(meetingId)
          .collection('participants')
          .add(participantData);
      return docRef.id;
    } catch (e) {
      _logger.e('Add participant error: $e');
      throw ServerException(message: 'Failed to add participant');
    }
  }

  Future<List<ParticipantModel>> getParticipants(String meetingId) async {
    try {
      final querySnapshot = await _firestore
          .collection('meetings')
          .doc(meetingId)
          .collection('participants')
          .where('status', isEqualTo: 'active')
          .get();

      return querySnapshot.docs
          .map((doc) => ParticipantModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      _logger.e('Get participants error: $e');
      throw ServerException(message: 'Failed to get participants');
    }
  }

  Future<void> updateParticipant({
    required String meetingId,
    required String participantId,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _firestore
          .collection('meetings')
          .doc(meetingId)
          .collection('participants')
          .doc(participantId)
          .update(data);
    } catch (e) {
      _logger.e('Update participant error: $e');
      throw ServerException(message: 'Failed to update participant');
    }
  }

  Future<void> removeParticipant({
    required String meetingId,
    required String participantId,
  }) async {
    try {
      await _firestore
          .collection('meetings')
          .doc(meetingId)
          .collection('participants')
          .doc(participantId)
          .update({
        'status': 'removed',
        'leftAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      _logger.e('Remove participant error: $e');
      throw ServerException(message: 'Failed to remove participant');
    }
  }

  Stream<List<ParticipantModel>> watchParticipants(String meetingId) {
    return _firestore
        .collection('meetings')
        .doc(meetingId)
        .collection('participants')
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ParticipantModel.fromFirestore(doc))
            .toList());
  }

  // WebRTC Signaling
  Future<void> sendSignal({
    required String meetingId,
    required String signalType,
    required Map<String, dynamic> signalData,
  }) async {
    try {
      await _firestore
          .collection('meetings')
          .doc(meetingId)
          .collection('signals')
          .add({
        ...signalData,
        'type': signalType,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      _logger.e('Send signal error: $e');
      throw ServerException(message: 'Failed to send signal');
    }
  }

  Stream<QuerySnapshot> watchSignals({
    required String meetingId,
    required String userId,
  }) {
    return _firestore
        .collection('meetings')
        .doc(meetingId)
        .collection('signals')
        .where('to', isEqualTo: userId)
        .orderBy('timestamp')
        .snapshots();
  }
}