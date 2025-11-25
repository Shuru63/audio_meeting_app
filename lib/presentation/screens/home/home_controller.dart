import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import 'dart:math';
import '../../../core/constants/app_strings.dart';
import '../../../core/router/route_names.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/meeting_model.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/meeting_repository.dart';
import '../../../core/services/local_storage_service.dart';

class HomeController extends GetxController {
  final AuthRepository _authRepository = Get.find<AuthRepository>();
  final MeetingRepository _meetingRepository = Get.find<MeetingRepository>();
  final LocalStorageService _storageService = Get.find<LocalStorageService>();

  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);
  final RxList<MeetingModel> meetings = <MeetingModel>[].obs;
  final RxBool isLoadingMeetings = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadCurrentUser();
    _loadMeetings();
  }

  Future<void> _loadCurrentUser() async {
    final user = await _storageService.getUser();
    currentUser.value = user;
  }

  Future<void> _loadMeetings() async {
    isLoadingMeetings.value = true;
    try {
      final result = await _meetingRepository.getUserMeetings(
        currentUser.value?.id ?? '',
      );
      
      result.fold(
        (failure) {
          Get.snackbar(
            'Error',
            failure.message,
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red.withOpacity(0.8),
            colorText: Colors.white,
          );
        },
        (meetingList) {
          meetings.value = meetingList;
        },
      );
    } catch (e) {
      debugPrint('Error loading meetings: $e');
    } finally {
      isLoadingMeetings.value = false;
    }
  }

  Future<void> refreshMeetings() async {
    await _loadMeetings();
  }

  Future<void> onCreateMeeting() async {
    if (currentUser.value == null) return;

    try {
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      // Generate meeting code
      final meetingCode = _generateMeetingCode();
      final meetingId = const Uuid().v4();

      final meeting = MeetingModel(
        id: meetingId,
        meetingCode: meetingCode,
        hostId: currentUser.value!.id,
        hostName: currentUser.value!.name,
        title: 'Meeting ${DateTime.now().toString().substring(0, 16)}',
        status: MeetingStatus.waiting,
        createdAt: DateTime.now(),
        participantCount: 0,
        isRecording: false,
        participantIds: [],
      );

      final result = await _meetingRepository.createMeeting(meeting);

      Get.back(); // Close loading dialog

      result.fold(
        (failure) {
          Get.snackbar(
            'Error',
            failure.message,
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red.withOpacity(0.8),
            colorText: Colors.white,
          );
        },
        (createdMeeting) {
          Get.toNamed(
            RouteNames.meeting,
            arguments: {
              'meetingId': createdMeeting.id,
              'isHost': true,
            },
          );
        },
      );
    } catch (e) {
      Get.back();
      Get.snackbar(
        'Error',
        AppStrings.somethingWentWrong,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    }
  }

  Future<void> onJoinMeeting(String meetingCode) async {
    if (currentUser.value == null) return;

    try {
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      final result = await _meetingRepository.joinMeeting(
        meetingCode: meetingCode,
        userId: currentUser.value!.id,
        userName: currentUser.value!.name,
      );

      Get.back(); // Close loading dialog

      result.fold(
        (failure) {
          Get.snackbar(
            'Error',
            failure.message,
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red.withOpacity(0.8),
            colorText: Colors.white,
          );
        },
        (meeting) {
          Get.toNamed(
            RouteNames.meeting,
            arguments: {
              'meetingId': meeting.id,
              'isHost': false,
            },
          );
        },
      );
    } catch (e) {
      Get.back();
      Get.snackbar(
        'Error',
        AppStrings.somethingWentWrong,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    }
  }

  void onMeetingTap(MeetingModel meeting) {
    if (meeting.isEnded) {
      // Show meeting details
      Get.dialog(
        AlertDialog(
          title: Text(meeting.title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Meeting Code: ${meeting.meetingCode}'),
              Text('Host: ${meeting.hostName}'),
              Text('Participants: ${meeting.participantCount}'),
              Text('Status: ${meeting.status.toString().split('.').last}'),
              if (meeting.duration != null)
                Text('Duration: ${_formatDuration(meeting.duration!)}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } else if (meeting.isActive) {
      // Rejoin meeting
      Get.toNamed(
        RouteNames.meeting,
        arguments: {
          'meetingId': meeting.id,
          'isHost': meeting.hostId == currentUser.value?.id,
        },
      );
    }
  }

  void navigateToAdmin() {
    Get.toNamed(RouteNames.adminDashboard);
  }

  Future<void> onLogout() async {
    Get.dialog(
      AlertDialog(
        title: const Text('Logout'),
        content: const Text(AppStrings.logoutConfirmation),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text(AppStrings.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              Get.dialog(
                const Center(child: CircularProgressIndicator()),
                barrierDismissible: false,
              );

              await _authRepository.logout();
              await _storageService.clearUser();

              Get.back();
              Get.offAllNamed(RouteNames.login);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text(AppStrings.logout),
          ),
        ],
      ),
    );
  }

  String _generateMeetingCode() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    
    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }
}