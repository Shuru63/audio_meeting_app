import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/empty_state.dart';

import 'admin_controller.dart';

class UserManagementScreen extends StatelessWidget {
  const UserManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AdminController());

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.userManagement),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearchDialog(context, controller),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: controller.loadUsers,
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoadingUsers.value) {
          return const Center(child: LoadingIndicator());
        }

        if (controller.users.isEmpty) {
          return EmptyStateWidget(
            title: 'No Users Found',
            message: 'Create your first user to get started',
            icon: Icons.people_outline,
            action: ElevatedButton.icon(
              onPressed: () => _showCreateUserDialog(context, controller),
              icon: const Icon(Icons.person_add),
              label: const Text('Create User'),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.loadUsers,
          child: ListView.separated(
            padding: EdgeInsets.all(16.w),
            itemCount: controller.users.length,
            separatorBuilder: (context, index) => SizedBox(height: 12.h),
            itemBuilder: (context, index) {
              final user = controller.users[index];
              return _buildUserCard(context, user, controller);
            },
          ),
        );
      }),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateUserDialog(context, controller),
        icon: const Icon(Icons.person_add),
        label: const Text('Create User'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  Widget _buildUserCard(BuildContext context, dynamic user, AdminController controller) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
        side: BorderSide(
          color: user.isActive ? AppColors.success.withOpacity(0.3) : AppColors.error.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () => _showUserDetailsDialog(context, user, controller),
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Avatar
                  Container(
                    width: 50.w,
                    height: 50.w,
                    decoration: BoxDecoration(
                      gradient: _getGradientForName(user.name),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        _getInitials(user.name),
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
                                user.name,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(width: 8.w),
                            _buildRoleBadge(user.role),
                          ],
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          user.email,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  // Status Indicator
                  Container(
                    width: 12.w,
                    height: 12.w,
                    decoration: BoxDecoration(
                      color: user.isActive ? AppColors.success : AppColors.error,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),

              SizedBox(height: 12.h),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => user.isActive
                        ? controller.deactivateUser(user.id)
                        : controller.activateUser(user.id),
                    icon: Icon(
                      user.isActive ? Icons.block : Icons.check_circle,
                      size: 16.sp,
                    ),
                    label: Text(user.isActive ? 'Deactivate' : 'Activate'),
                    style: TextButton.styleFrom(
                      foregroundColor: user.isActive ? AppColors.error : AppColors.success,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  TextButton.icon(
                    onPressed: () => controller.resetUserPassword(user.id),
                    icon: Icon(Icons.lock_reset, size: 16.sp),
                    label: const Text('Reset'),
                  ),
                  SizedBox(width: 8.w),
                  IconButton(
                    onPressed: () => _showUserOptionsMenu(context, user, controller),
                    icon: const Icon(Icons.more_vert),
                    iconSize: 20.sp,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleBadge(String role) {
    Color color;
    switch (role.toLowerCase()) {
      case 'admin':
        color = AppColors.error;
        break;
      case 'host':
        color = AppColors.warning;
        break;
      default:
        color = AppColors.primary;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        role.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10.sp,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showSearchDialog(BuildContext context, AdminController controller) {
    final searchController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: const Text('Search Users'),
        content: TextField(
          controller: searchController,
          decoration: const InputDecoration(
            hintText: 'Enter name or email',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (value) => controller.searchUsers(value),
        ),
        actions: [
          TextButton(
            onPressed: () {
              searchController.clear();
              controller.loadUsers();
              Get.back();
            },
            child: const Text('Clear'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showCreateUserDialog(BuildContext context, AdminController controller) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final phoneController = TextEditingController();
    final roleValue = 'user'.obs;

    Get.dialog(
      AlertDialog(
        title: const Text('Create New User'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              SizedBox(height: 16.h),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              SizedBox(height: 16.h),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
              ),
              SizedBox(height: 16.h),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone (Optional)',
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),
              SizedBox(height: 16.h),
              Obx(() => DropdownButtonFormField<String>(
                    value: roleValue.value,
                    decoration: const InputDecoration(
                      labelText: 'Role',
                      prefixIcon: Icon(Icons.badge),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'user', child: Text('User')),
                      DropdownMenuItem(value: 'host', child: Text('Host')),
                      DropdownMenuItem(value: 'admin', child: Text('Admin')),
                    ],
                    onChanged: (value) {
                      if (value != null) roleValue.value = value;
                    },
                  )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty &&
                  emailController.text.isNotEmpty &&
                  passwordController.text.isNotEmpty) {
                controller.createUser(
                  name: nameController.text,
                  email: emailController.text,
                  password: passwordController.text,
                  phone: phoneController.text.isNotEmpty ? phoneController.text : null,
                  role: roleValue.value,
                );
                Get.back();
              } else {
                Get.snackbar('Error', 'Please fill all required fields');
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showUserDetailsDialog(BuildContext context, dynamic user, AdminController controller) {
    Get.dialog(
      AlertDialog(
        title: Text(user.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Email', user.email),
            if (user.phone != null) _buildDetailRow('Phone', user.phone),
            _buildDetailRow('Role', user.role.toUpperCase()),
            _buildDetailRow('Status', user.isActive ? 'Active' : 'Inactive'),
            _buildDetailRow('Created', _formatDate(user.createdAt)),
            if (user.lastLogin != null)
              _buildDetailRow('Last Login', _formatDate(user.lastLogin)),
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
  }

  void _showUserOptionsMenu(BuildContext context, dynamic user, AdminController controller) {
    Get.bottomSheet(
      Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.logout, color: AppColors.warning),
                title: const Text('Force Logout'),
                onTap: () {
                  Get.back();
                  controller.forceLogout(user.id);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: AppColors.error),
                title: const Text('Delete User'),
                onTap: () {
                  Get.back();
                  controller.deleteUser(user.id);
                },
              ),
              SizedBox(height: 8.h),
              OutlinedButton(
                onPressed: () => Get.back(),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100.w,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14.sp,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 14.sp),
            ),
          ),
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}