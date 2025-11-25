import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../widgets/loading_indicator.dart';
import 'meeting_controller.dart';
import 'widgets/participant_tile.dart';

class MeetingScreen extends StatelessWidget {
  final String meetingId;
  final bool isHost;

  const MeetingScreen({
    super.key,
    required this.meetingId,
    required this.isHost,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(
      MeetingController(meetingId: meetingId, isHost: isHost),
    );

    return WillPopScope(
      onWillPop: () async {
        controller.onLeaveMeeting();
        return false;
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundDark,
        body: SafeArea(
          child: Obx(() {
            if (controller.isLoading.value) {
              return const Center(
                child: LoadingIndicator(color: AppColors.textWhite),
              );
            }

            return Column(
              children: [
                // Meeting Header
                _buildMeetingHeader(context, controller),

                // Participants List
                Expanded(
                  child: _buildParticipantsList(controller),
                ),

                // Audio Controls
                _buildAudioControls(context, controller),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildMeetingHeader(BuildContext context, MeetingController controller) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Obx(
                    () => Text(
                      controller.meeting.value?.title ?? 'Meeting',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppColors.textWhite,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Obx(
                    () => Text(
                      'Code: ${controller.meeting.value?.meetingCode ?? ''}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textWhite.withOpacity(0.7),
                          ),
                    ),
                  ),
                ],
              ),
              Obx(
                () => controller.isRecording.value
                    ? Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 6.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 8.w,
                              height: 8.w,
                              decoration: const BoxDecoration(
                                color: AppColors.textWhite,
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(width: 6.w),
                            Text(
                              'REC',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: AppColors.textWhite,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Obx(
                () => Text(
                  controller.durationText.value,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppColors.primaryLight,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              Obx(
                () => Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(color: AppColors.primary),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.people,
                        size: 16.sp,
                        color: AppColors.primaryLight,
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        '${controller.participants.length}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textWhite,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantsList(MeetingController controller) {
    return Obx(() {
      if (controller.participants.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.people_outline,
                size: 80.sp,
                color: AppColors.iconDisabled,
              ),
              SizedBox(height: 16.h),
              Text(
                'Waiting for participants...',
                style: TextStyle(
                  color: AppColors.textWhite.withOpacity(0.7),
                  fontSize: 16.sp,
                ),
              ),
            ],
          ),
        );
      }

      return ListView.separated(
        padding: EdgeInsets.all(20.w),
        itemCount: controller.participants.length,
        separatorBuilder: (context, index) => SizedBox(height: 12.h),
        itemBuilder: (context, index) {
          final participant = controller.participants[index];
          return ParticipantTile(
            participant: participant,
            isHost: isHost,
            onMute: () => controller.muteParticipant(participant.userId),
            onRemove: () => controller.removeParticipant(participant.userId),
          );
        },
      );
    });
  }

  Widget _buildAudioControls(BuildContext context, MeetingController controller) {
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Mute/Unmute Button
          Obx(
            () => _buildControlButton(
              icon: controller.isMuted.value
                  ? Icons.mic_off_rounded
                  : Icons.mic_rounded,
              label: controller.isMuted.value ? 'Unmute' : 'Mute',
              color: controller.isMuted.value
                  ? AppColors.error
                  : AppColors.success,
              onTap: controller.toggleMute,
            ),
          ),

          // Recording Button (Host Only)
          if (isHost)
            Obx(
              () => _buildControlButton(
                icon: controller.isRecording.value
                    ? Icons.stop_circle_rounded
                    : Icons.fiber_manual_record_rounded,
                label: controller.isRecording.value ? 'Stop Rec' : 'Record',
                color: controller.isRecording.value
                    ? AppColors.error
                    : AppColors.warning,
                onTap: controller.toggleRecording,
              ),
            ),

          // End/Leave Meeting Button
          _buildControlButton(
            icon: Icons.call_end_rounded,
            label: isHost ? 'End' : 'Leave',
            color: AppColors.error,
            onTap: () {
              if (isHost) {
                controller.onEndMeeting();
              } else {
                controller.onLeaveMeeting();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(35.r),
          child: Container(
            width: 70.w,
            height: 70.w,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: AppColors.textWhite,
              size: 32.sp,
            ),
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          label,
          style: TextStyle(
            color: AppColors.textWhite,
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}