import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:logger/logger.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_service.dart';

class WebRTCService {
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  final Map<String, RTCPeerConnection> _peerConnections = {};
  final Map<String, MediaStream> _remoteStreams = {};
  final Logger _logger = Logger();
  
  bool _isMuted = false;
  String? _currentMeetingId;

  final Map<String, dynamic> _configuration = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
      {'urls': 'stun:stun2.l.google.com:19302'},
    ],
  };

  final Map<String, dynamic> _constraints = {
    'mandatory': {},
    'optional': [
      {'DtlsSrtpKeyAgreement': true},
    ],
  };

  Future<void> initializeWebRTC(String meetingId, String userId) async {
    try {
      _currentMeetingId = meetingId;
      await _createLocalStream();
      await _setupSignaling(meetingId, userId);
    } catch (e) {
      _logger.e('Error initializing WebRTC: $e');
      rethrow;
    }
  }

  Future<void> _createLocalStream() async {
    try {
      final Map<String, dynamic> mediaConstraints = {
        'audio': {
          'echoCancellation': true,
          'noiseSuppression': true,
          'autoGainControl': true,
        },
        'video': false,
      };

      _localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
      _logger.i('Local stream created successfully');
    } catch (e) {
      _logger.e('Error creating local stream: $e');
      rethrow;
    }
  }

  Future<void> _setupSignaling(String meetingId, String userId) async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    // Listen for new participants
    firestore
        .collection('meetings')
        .doc(meetingId)
        .collection('participants')
        .where('userId', isNotEqualTo: userId)
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final participantId = change.doc.id;
          _createPeerConnection(meetingId, userId, participantId);
        } else if (change.type == DocumentChangeType.removed) {
          final participantId = change.doc.id;
          _removePeerConnection(participantId);
        }
      }
    });

    // Listen for offers
    firestore
        .collection('meetings')
        .doc(meetingId)
        .collection('offers')
        .where('to', isEqualTo: userId)
        .snapshots()
        .listen((snapshot) {
      for (var doc in snapshot.docs) {
        _handleOffer(meetingId, userId, doc.data());
      }
    });

    // Listen for answers
    firestore
        .collection('meetings')
        .doc(meetingId)
        .collection('answers')
        .where('to', isEqualTo: userId)
        .snapshots()
        .listen((snapshot) {
      for (var doc in snapshot.docs) {
        _handleAnswer(doc.data());
      }
    });

    // Listen for ICE candidates
    firestore
        .collection('meetings')
        .doc(meetingId)
        .collection('ice_candidates')
        .where('to', isEqualTo: userId)
        .snapshots()
        .listen((snapshot) {
      for (var doc in snapshot.docs) {
        _handleIceCandidate(doc.data());
      }
    });
  }

  Future<void> _createPeerConnection(
    String meetingId,
    String userId,
    String remoteUserId,
  ) async {
    try {
      final pc = await createPeerConnection(_configuration, _constraints);

      // Add local stream tracks
      if (_localStream != null) {
        _localStream!.getTracks().forEach((track) {
          pc.addTrack(track, _localStream!);
        });
      }

      // Handle ICE candidates
      pc.onIceCandidate = (RTCIceCandidate candidate) {
        _sendIceCandidate(meetingId, userId, remoteUserId, candidate);
      };

      // Handle remote stream
      pc.onTrack = (RTCTrackEvent event) {
        _logger.i('Remote track received from $remoteUserId');
        if (event.streams.isNotEmpty) {
          _remoteStreams[remoteUserId] = event.streams[0];
        }
      };

      pc.onIceConnectionState = (RTCIceConnectionState state) {
        _logger.i('ICE connection state with $remoteUserId: $state');
      };

      _peerConnections[remoteUserId] = pc;

      // Create and send offer
      final offer = await pc.createOffer();
      await pc.setLocalDescription(offer);
      await _sendOffer(meetingId, userId, remoteUserId, offer);
    } catch (e) {
      _logger.e('Error creating peer connection: $e');
    }
  }

  Future<void> _sendOffer(
    String meetingId,
    String from,
    String to,
    RTCSessionDescription offer,
  ) async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    await firestore
        .collection('meetings')
        .doc(meetingId)
        .collection('offers')
        .add({
      'from': from,
      'to': to,
      'sdp': offer.sdp,
      'type': offer.type,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _handleOffer(
    String meetingId,
    String userId,
    Map<String, dynamic> data,
  ) async {
    try {
      final remoteUserId = data['from'];
      final offer = RTCSessionDescription(data['sdp'], data['type']);

      final pc = _peerConnections[remoteUserId] ??
          await createPeerConnection(_configuration, _constraints);

      await pc.setRemoteDescription(offer);

      final answer = await pc.createAnswer();
      await pc.setLocalDescription(answer);

      await _sendAnswer(meetingId, userId, remoteUserId, answer);

      _peerConnections[remoteUserId] = pc;
    } catch (e) {
      _logger.e('Error handling offer: $e');
    }
  }

  Future<void> _sendAnswer(
    String meetingId,
    String from,
    String to,
    RTCSessionDescription answer,
  ) async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    await firestore
        .collection('meetings')
        .doc(meetingId)
        .collection('answers')
        .add({
      'from': from,
      'to': to,
      'sdp': answer.sdp,
      'type': answer.type,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _handleAnswer(Map<String, dynamic> data) async {
    try {
      final remoteUserId = data['from'];
      final answer = RTCSessionDescription(data['sdp'], data['type']);

      final pc = _peerConnections[remoteUserId];
      if (pc != null) {
        await pc.setRemoteDescription(answer);
      }
    } catch (e) {
      _logger.e('Error handling answer: $e');
    }
  }

  Future<void> _sendIceCandidate(
    String meetingId,
    String from,
    String to,
    RTCIceCandidate candidate,
  ) async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    await firestore
        .collection('meetings')
        .doc(meetingId)
        .collection('ice_candidates')
        .add({
      'from': from,
      'to': to,
      'candidate': candidate.candidate,
      'sdpMid': candidate.sdpMid,
      'sdpMLineIndex': candidate.sdpMLineIndex,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _handleIceCandidate(Map<String, dynamic> data) async {
    try {
      final remoteUserId = data['from'];
      final candidate = RTCIceCandidate(
        data['candidate'],
        data['sdpMid'],
        data['sdpMLineIndex'],
      );

      final pc = _peerConnections[remoteUserId];
      if (pc != null) {
        await pc.addCandidate(candidate);
      }
    } catch (e) {
      _logger.e('Error handling ICE candidate: $e');
    }
  }

  void _removePeerConnection(String userId) {
    final pc = _peerConnections[userId];
    if (pc != null) {
      pc.close();
      _peerConnections.remove(userId);
      _remoteStreams.remove(userId);
    }
  }

  void muteAudio(bool mute) {
    _isMuted = mute;
    _localStream?.getAudioTracks().forEach((track) {
      track.enabled = !mute;
    });
  }

  bool get isMuted => _isMuted;

  MediaStream? get localStream => _localStream;
  Map<String, MediaStream> get remoteStreams => _remoteStreams;

  Future<void> dispose() async {
    _localStream?.getTracks().forEach((track) {
      track.stop();
    });
    await _localStream?.dispose();

    for (var pc in _peerConnections.values) {
      await pc.close();
    }
    _peerConnections.clear();

    for (var stream in _remoteStreams.values) {
      await stream.dispose();
    }
    _remoteStreams.clear();
  }
}