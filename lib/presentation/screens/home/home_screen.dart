import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/loading_indicator.dart';
import 'home_controller.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(HomeController());

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.appName),
        actions: [
          Obx(
            () => controller.currentUser.value != null &&
                    controller.currentUser.value!.isAdmin
                ? IconButton(
                    icon: const Icon(Icons.admin_panel_settings),
                    onPressed: controller.navigateToAdmin,
                  )
                : const SizedBox.shrink(),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: controller.onLogout,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // User Info Card
              Obx(
                () => _buildUserInfoCard(
                  context,
                  controller.currentUser.value?.name ?? '',
                  controller.currentUser.value?.email ?? '',
                ),
              ),

              SizedBox(height: 32.h),

              // Create Meeting Button
              CustomButton(
                text: AppStrings.createMeeting,
                icon: Icons.add_circle_outline,
                gradient: AppColors.primaryGradient,
                onPressed: controller.onCreateMeeting,
              ),

              SizedBox(height: 16.h),

              // Join Meeting Button
              CustomButton(
                text: AppStrings.joinMeeting,
                icon: Icons.login,
                isOutlined: true,
                onPressed: () => _showJoinMeetingDialog(context, controller),
              ),

              SizedBox(height: 32.h),

              // Meeting History Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppStrings.meetingHistory,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  TextButton(
                    onPressed: controller.refreshMeetings,
                    child: const Row(
                      children: [
                        Icon(Icons.refresh, size: 18),
                        SizedBox(width: 4),
                        Text('Refresh'),
                      ],
                    ),
                  ),
                ],
              ),

              SizedBox(height: 16.h),

              // Meeting History List
              Expanded(
                child: Obx(
                  () {
                    if (controller.isLoadingMeetings.value) {
                      return const Center(child: LoadingIndicator());
                    }

                    if (controller.meetings.isEmpty) {
                      return _buildEmptyState(context);
                    }

                    return ListView.separated(
                      itemCount: controller.meetings.length,
                      separatorBuilder: (context, index) => SizedBox(height: 12.h),
                      itemBuilder: (context, index) {
                        final meeting = controller.meetings[index];
                        return _buildMeetingCard(context, meeting, controller);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserInfoCard(BuildContext context, String name, String email) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60.w,
            height: 60.w,
            decoration: BoxDecoration(
              color: AppColors.textWhite.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person,
              color: AppColors.textWhite,
              size: 30.sp,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.textWhite,
                        fontWeight: FontWeight.bold,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4.h),
                Text(
                  email,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textWhite.withOpacity(0.9),
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeetingCard(BuildContext context, dynamic meeting, HomeController controller) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: InkWell(
        onTap: () => controller.onMeetingTap(meeting),
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      meeting.title,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: _getStatusColor(meeting.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Text(
                      meeting.status.toString().split('.').last.toUpperCase(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: _getStatusColor(meeting.status),
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              Row(
                children: [
                  Icon(Icons.access_time, size: 16.sp, color: AppColors.iconSecondary),
                  SizedBox(width: 6.w),
                  Text(
                    _formatDateTime(meeting.createdAt),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  SizedBox(width: 16.w),
                  Icon(Icons.people, size: 16.sp, color: AppColors.iconSecondary),
                  SizedBox(width: 6.w),
                  Text(
                    '${meeting.participantCount} participants',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 80.sp,
            color: AppColors.iconDisabled,
          ),
          SizedBox(height: 16.h),
          Text(
            AppStrings.noMeetingsFound,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Create or join a meeting to get started',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textTertiary,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showJoinMeetingDialog(BuildContext context, HomeController controller) {
    final TextEditingController codeController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: const Text(AppStrings.joinMeeting),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: codeController,
              decoration: const InputDecoration(
                labelText: AppStrings.meetingCode,
                hintText: AppStrings.enterMeetingCode,
              ),
              keyboardType: TextInputType.number,
              maxLength: 8,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text(AppStrings.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              if (codeController.text.isNotEmpty) {
                controller.onJoinMeeting(codeController.text);
                Get.back();
              }
            },
            child: const Text(AppStrings.join),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(dynamic status) {
    final statusStr = status.toString().split('.').last.toLowerCase();
    switch (statusStr) {
      case 'active':
        return AppColors.success;
      case 'ended':
        return AppColors.textTertiary;
      default:
        return AppColors.warning;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return 'Today ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}