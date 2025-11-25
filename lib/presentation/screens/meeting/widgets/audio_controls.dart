import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/app_colors.dart';

class AudioControls extends StatelessWidget {
  final bool isMuted;
  final bool isRecording;
  final bool isHost;
  final VoidCallback onMuteToggle;
  final VoidCallback? onRecordingToggle;
  final VoidCallback onEndCall;

  const AudioControls({
    super.key,
    required this.isMuted,
    required this.isRecording,
    required this.isHost,
    required this.onMuteToggle,
    this.onRecordingToggle,
    required this.onEndCall,
  });

  @override
  Widget build(BuildContext context) {
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
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Mute/Unmute Button
            _buildControlButton(
              icon: isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
              label: isMuted ? 'Unmute' : 'Mute',
              color: isMuted ? AppColors.error : AppColors.success,
              onTap: onMuteToggle,
            ),

            // Recording Button (Host Only)
            if (isHost && onRecordingToggle != null)
              _buildControlButton(
                icon: isRecording
                    ? Icons.stop_circle_rounded
                    : Icons.fiber_manual_record_rounded,
                label: isRecording ? 'Stop Rec' : 'Record',
                color: isRecording ? AppColors.error : AppColors.warning,
                onTap: onRecordingToggle!,
              ),

            // End Call Button
            _buildControlButton(
              icon: Icons.call_end_rounded,
              label: isHost ? 'End' : 'Leave',
              color: AppColors.error,
              onTap: onEndCall,
            ),
          ],
        ),
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