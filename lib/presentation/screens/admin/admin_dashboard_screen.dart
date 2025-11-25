import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/router/route_names.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.adminPanel),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Stats Cards
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      context,
                      icon: Icons.people,
                      title: 'Total Users',
                      value: '0',
                      color: AppColors.primary,
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: _buildStatCard(
                      context,
                      icon: Icons.videocam,
                      title: 'Active Meetings',
                      value: '0',
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),

              SizedBox(height: 32.h),

              // Menu Items
              _buildMenuItem(
                context,
                icon: Icons.person_add,
                title: 'Create User',
                subtitle: 'Add new user account',
                onTap: () {
                  // TODO: Navigate to create user
                },
              ),

              SizedBox(height: 16.h),

              _buildMenuItem(
                context,
                icon: Icons.manage_accounts,
                title: AppStrings.userManagement,
                subtitle: 'View and manage users',
                onTap: () {
                  Get.toNamed(RouteNames.userManagement);
                },
              ),

              SizedBox(height: 16.h),

              _buildMenuItem(
                context,
                icon: Icons.meeting_room,
                title: AppStrings.activeMeetings,
                subtitle: 'Monitor ongoing meetings',
                onTap: () {
                  // TODO: Navigate to active meetings
                },
              ),

              SizedBox(height: 16.h),

              _buildMenuItem(
                context,
                icon: Icons.history,
                title: 'Meeting History',
                subtitle: 'View past meetings',
                onTap: () {
                  // TODO: Navigate to meeting history
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.textWhite, size: 32.sp),
          SizedBox(height: 12.h),
          Text(
            value,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: AppColors.textWhite,
                  fontWeight: FontWeight.bold,
                ),
          ),
          SizedBox(height: 4.h),
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textWhite.withOpacity(0.9),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Row(
            children: [
              Container(
                width: 50.w,
                height: 50.w,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  icon,
                  color: AppColors.primary,
                  size: 24.sp,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: AppColors.iconSecondary,
                size: 24.sp,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
