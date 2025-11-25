import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/router/route_names.dart';
import '../../../data/models/meeting_model.dart';
import '../../../data/models/participant_model.dart';
import '../../../data/repositories/meeting_repository.dart';
import '../../../core/services/webrtc_service.dart';
import '../../../core/services/recording_service.dart';
import '../../../core/services/local_storage_service.dart';

class MeetingController extends GetxController {
  final String meetingId;
  final bool isHost;

  final MeetingRepository _meetingRepository = Get.find<MeetingRepository>();
  final WebRTCService _webrtcService = Get.find<WebRTCService>();
  final RecordingService _recordingService = Get.find<RecordingService>();
  final LocalStorageService _storageService = Get.find<LocalStorageService>();

  final RxBool isLoading = true.obs;
  final Rx<MeetingModel?> meeting = Rx<MeetingModel?>(null);
  final RxList<ParticipantModel> participants = <ParticipantModel>[].obs;
  final RxBool isMuted = false.obs;
  final RxBool isRecording = false.obs;
  final RxString durationText = '00:00'.obs;

  Timer? _durationTimer;
  StreamSubscription? _meetingSubscription;
  StreamSubscription? _participantsSubscription;
  String? _currentUserId;

  MeetingController({
    required this.meetingId,
    required this.isHost,
  });

  @override
  void onInit() {
    super.onInit();
    _initializeMeeting();
  }

  @override
  void onClose() {
    _cleanup();
    super.onClose();
  }

  Future<void> _initializeMeeting() async {
    try {
      // Get current user
      final user = await _storageService.getUser();
      _currentUserId = user?.id;

      if (_currentUserId == null) {
        Get.snackbar('Error', 'User not found');
        Get.back();
        return;
      }

      // Initialize WebRTC
      await _webrtcService.initializeWebRTC(meetingId, _currentUserId!);

      // Listen to meeting updates
      _listenToMeeting();

      // Listen to participants
      _listenToParticipants();

      // Start duration timer
      _startDurationTimer();

      // Auto-start recording if host
      if (isHost) {
        await Future.delayed(const Duration(seconds: 2));
        await _startRecording();
      }

      isLoading.value = false;
    } catch (e) {
      debugPrint('Error initializing meeting: $e');
      Get.snackbar('Error', 'Failed to initialize meeting');
      Get.back();
    }
  }

  void _listenToMeeting() {
    _meetingSubscription = _meetingRepository
        .meetingStream(meetingId)
        .listen((meetingData) {
      meeting.value = meetingData;

      // Check if meeting ended
      if (meetingData.isEnded) {
        _handleMeetingEnded();
      }

      // Update recording status
      isRecording.value = meetingData.isRecording;
    });
  }

  void _listenToParticipants() {
    _participantsSubscription = _meetingRepository
        .participantsStream(meetingId)
        .listen((participantList) {
      participants.value = participantList;
      
      // Check if current user was removed
      final currentParticipant = participantList.firstWhereOrNull(
        (p) => p.userId == _currentUserId,
      );
      
      if (currentParticipant == null && !isHost) {
        _handleRemovedFromMeeting();
      } else if (currentParticipant != null) {
        // Update mute status based on server
        if (currentParticipant.isMuted && !isMuted.value) {
          isMuted.value = true;
          _webrtcService.muteAudio(true);
          Get.snackbar(
            'Muted',
            'You have been muted by the host',
            snackPosition: SnackPosition.BOTTOM,
          );
        }
      }
    });
  }

  void _startDurationTimer() {
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (meeting.value != null) {
        final duration = meeting.value!.duration ?? Duration.zero;
        durationText.value = _formatDuration(duration);
      }
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    
    if (hours > 0) {
      return '${twoDigits(hours)}:${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
    return '${twoDigits(minutes)}:${twoDigits(seconds)}';
  }

  void toggleMute() {
    isMuted.value = !isMuted.value;
    _webrtcService.muteAudio(isMuted.value);
    
    if (!isHost) {
      // Update participant status
      _meetingRepository.muteParticipant(
        meetingId: meetingId,
        userId: _currentUserId!,
        mute: isMuted.value,
      );
    }
  }

  Future<void> toggleRecording() async {
    if (!isHost) return;

    try {
      if (isRecording.value) {
        await _stopRecording();
      } else {
        await _startRecording();
      }
    } catch (e) {
      debugPrint('Error toggling recording: $e');
      Get.snackbar('Error', 'Failed to toggle recording');
    }
  }

  Future<void> _startRecording() async {
    final started = await _recordingService.startRecording(meetingId);
    
    if (started) {
      await _meetingRepository.startRecording(meetingId);
      isRecording.value = true;
      Get.snackbar(
        'Recording Started',
        'Meeting recording has started',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withOpacity(0.8),
        colorText: Colors.white,
      );
    } else {
      Get.snackbar(
        'Error',
        'Failed to start recording',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _stopRecording() async {
    final recordingPath = await _recordingService.stopRecording();
    
    if (recordingPath != null) {
      await _meetingRepository.stopRecording(
        meetingId: meetingId,
        recordingUrl: recordingPath,
      );
      isRecording.value = false;
      Get.snackbar(
        'Recording Stopped',
        'Meeting recording has been saved',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.blue.withOpacity(0.8),
        colorText: Colors.white,
      );
    }
  }

  Future<void> muteParticipant(String userId) async {
    if (!isHost) return;

    try {
      final participant = participants.firstWhereOrNull((p) => p.userId == userId);
      if (participant == null) return;

      final result = await _meetingRepository.muteParticipant(
        meetingId: meetingId,
        userId: userId,
        mute: !participant.isMuted,
      );

      result.fold(
        (failure) {
          Get.snackbar('Error', failure.message);
        },
        (_) {
          Get.snackbar(
            'Success',
            '${participant.userName} has been ${participant.isMuted ? 'unmuted' : 'muted'}',
            snackPosition: SnackPosition.BOTTOM,
          );
        },
      );
    } catch (e) {
      debugPrint('Error muting participant: $e');
    }
  }

  Future<void> removeParticipant(String userId) async {
    if (!isHost) return;

    final participant = participants.firstWhereOrNull((p) => p.userId == userId);
    if (participant == null) return;

    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Remove Participant'),
        content: Text('Are you sure you want to remove ${participant.userName}?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final result = await _meetingRepository.removeParticipant(
        meetingId: meetingId,
        userId: userId,
      );

      result.fold(
        (failure) {
          Get.snackbar('Error', failure.message);
        },
        (_) {
          Get.snackbar(
            'Success',
            '${participant.userName} has been removed',
            snackPosition: SnackPosition.BOTTOM,
          );
        },
      );
    }
  }

  Future<void> onEndMeeting() async {
    if (!isHost) return;

    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('End Meeting'),
        content: const Text(AppStrings.endMeetingConfirmation),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text(AppStrings.cancel),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('End Meeting'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Stop recording if active
      if (isRecording.value) {
        await _stopRecording();
      }

      // End meeting
      await _meetingRepository.endMeeting(meetingId);
      
      await _cleanup();
      Get.offAllNamed(RouteNames.home);
    }
  }

  Future<void> onLeaveMeeting() async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Leave Meeting'),
        content: const Text(AppStrings.leaveMeetingConfirmation),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text(AppStrings.cancel),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Leave'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _meetingRepository.leaveMeeting(
        meetingId: meetingId,
        userId: _currentUserId!,
      );
      
      await _cleanup();
      Get.back();
    }
  }

  void _handleMeetingEnded() {
    Get.dialog(
      AlertDialog(
        title: const Text('Meeting Ended'),
        content: const Text('This meeting has been ended by the host'),
        actions: [
          ElevatedButton(
            onPressed: () {
              Get.back();
              _cleanup();
              Get.offAllNamed(RouteNames.home);
            },
            child: const Text('OK'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  void _handleRemovedFromMeeting() {
    Get.dialog(
      AlertDialog(
        title: const Text('Removed from Meeting'),
        content: const Text('You have been removed from this meeting'),
        actions: [
          ElevatedButton(
            onPressed: () {
              Get.back();
              _cleanup();
              Get.offAllNamed(RouteNames.home);
            },
            child: const Text('OK'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  Future<void> _cleanup() async {
    _durationTimer?.cancel();
    await _meetingSubscription?.cancel();
    await _participantsSubscription?.cancel();
    
    if (isRecording.value) {
      await _stopRecording();
    }
    
    await _webrtcService.dispose();
  }
}