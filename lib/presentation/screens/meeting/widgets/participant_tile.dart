import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/participant_model.dart';

class ParticipantTile extends StatelessWidget {
  final ParticipantModel participant;
  final bool isHost;
  final VoidCallback? onMute;
  final VoidCallback? onRemove;

  const ParticipantTile({
    super.key,
    required this.participant,
    required this.isHost,
    this.onMute,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: participant.isHost
              ? AppColors.hostBadge.withOpacity(0.3)
              : AppColors.borderDark,
        ),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 50.w,
            height: 50.w,
            decoration: BoxDecoration(
              gradient: _getGradientForName(participant.userName),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                _getInitials(participant.userName),
                style: TextStyle(
                  color: AppColors.textWhite,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          SizedBox(width: 12.w),

          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        participant.userName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppColors.textWhite,
                              fontWeight: FontWeight.w600,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (participant.isHost) ...[
                      SizedBox(width: 8.w),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.hostBadge,
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Text(
                          'HOST',
                          style: TextStyle(
                            color: AppColors.textWhite,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: 4.h),
                Row(
                  children: [
                    Icon(
                      participant.isMuted
                          ? Icons.mic_off_rounded
                          : Icons.mic_rounded,
                      size: 14.sp,
                      color: participant.isMuted
                          ? AppColors.micMuted
                          : AppColors.micActive,
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      participant.isMuted ? 'Muted' : 'Speaking',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: participant.isMuted
                                ? AppColors.micMuted
                                : AppColors.micActive,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Host Controls
          if (isHost && !participant.isHost) ...[
            IconButton(
              icon: Icon(
                participant.isMuted ? Icons.mic_off : Icons.mic,
                color: participant.isMuted
                    ? AppColors.micMuted
                    : AppColors.textWhite,
              ),
              onPressed: onMute,
            ),
            IconButton(
              icon: const Icon(
                Icons.remove_circle_outline,
                color: AppColors.error,
              ),
              onPressed: onRemove,
            ),
          ],
        ],
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty) {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return 'U';
  }

  LinearGradient _getGradientForName(String name) {
    final hash = name.hashCode;
    final colors = [
      [const Color(0xFF667eea), const Color(0xFF764ba2)],
      [const Color(0xFFf093fb), const Color(0xFFf5576c)],
      [const Color(0xFF4facfe), const Color(0xFF00f2fe)],
      [const Color(0xFF43e97b), const Color(0xFF38f9d7)],
      [const Color(0xFFfa709a), const Color(0xFFfee140)],
      [const Color(0xFF30cfd0), const Color(0xFF330867)],
    ];

    final colorPair = colors[hash.abs() % colors.length];

    return LinearGradient(
      colors: colorPair,
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }
}