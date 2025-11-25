import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/meeting_model.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../data/repositories/meeting_repository.dart';

class AdminController extends GetxController {
  final UserRepository _userRepository = Get.find<UserRepository>();
  final MeetingRepository _meetingRepository = Get.find<MeetingRepository>();

  final RxList<UserModel> users = <UserModel>[].obs;
  final RxList<MeetingModel> activeMeetings = <MeetingModel>[].obs;
  final RxBool isLoadingUsers = false.obs;
  final RxBool isLoadingMeetings = false.obs;
  final RxInt totalUsers = 0.obs;
  final RxInt activeMeetingsCount = 0.obs;

  @override
  void onInit() {
    super.onInit();
    loadUsers();
    loadActiveMeetings();
  }

  Future<void> loadUsers() async {
    isLoadingUsers.value = true;
    try {
      final result = await _userRepository.getAllUsers();
      result.fold(
        (failure) {
          Get.snackbar('Error', failure.message);
        },
        (userList) {
          users.value = userList;
          totalUsers.value = userList.length;
        },
      );
    } catch (e) {
      debugPrint('Error loading users: $e');
    } finally {
      isLoadingUsers.value = false;
    }
  }

  Future<void> loadActiveMeetings() async {
    isLoadingMeetings.value = true;
    try {
      // TODO: Implement get active meetings
      activeMeetingsCount.value = 0;
    } catch (e) {
      debugPrint('Error loading meetings: $e');
    } finally {
      isLoadingMeetings.value = false;
    }
  }

  Future<void> createUser({
    required String name,
    required String email,
    required String password,
    String? phone,
    required String role,
  }) async {
    try {
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      final result = await _userRepository.createUser(
        name: name,
        email: email,
        password: password,
        phone: phone,
        role: role,
      );

      Get.back(); // Close loading

      result.fold(
        (failure) {
          Get.snackbar('Error', failure.message);
        },
        (user) {
          users.add(user);
          totalUsers.value++;
          Get.snackbar(
            'Success',
            'User created successfully',
            backgroundColor: Colors.green.withOpacity(0.8),
            colorText: Colors.white,
          );
        },
      );
    } catch (e) {
      Get.back();
      Get.snackbar('Error', 'Failed to create user');
    }
  }

  Future<void> activateUser(String userId) async {
    try {
      final result = await _userRepository.activateUser(userId);
      result.fold(
        (failure) {
          Get.snackbar('Error', failure.message);
        },
        (_) {
          final index = users.indexWhere((u) => u.id == userId);
          if (index != -1) {
            users[index] = users[index].copyWith(isActive: true);
          }
          Get.snackbar(
            'Success',
            'User activated',
            backgroundColor: Colors.green.withOpacity(0.8),
            colorText: Colors.white,
          );
        },
      );
    } catch (e) {
      Get.snackbar('Error', 'Failed to activate user');
    }
  }

  Future<void> deactivateUser(String userId) async {
    try {
      final result = await _userRepository.deactivateUser(userId);
      result.fold(
        (failure) {
          Get.snackbar('Error', failure.message);
        },
        (_) {
          final index = users.indexWhere((u) => u.id == userId);
          if (index != -1) {
            users[index] = users[index].copyWith(isActive: false);
          }
          Get.snackbar(
            'Success',
            'User deactivated',
            backgroundColor: Colors.orange.withOpacity(0.8),
            colorText: Colors.white,
          );
        },
      );
    } catch (e) {
      Get.snackbar('Error', 'Failed to deactivate user');
    }
  }

  Future<void> resetUserPassword(String userId) async {
    try {
      final result = await _userRepository.resetPassword(
        userId: userId,
        newPassword: '',
      );
      result.fold(
        (failure) {
          Get.snackbar('Error', failure.message);
        },
        (_) {
          Get.snackbar(
            'Success',
            'Password reset email sent',
            backgroundColor: Colors.blue.withOpacity(0.8),
            colorText: Colors.white,
          );
        },
      );
    } catch (e) {
      Get.snackbar('Error', 'Failed to reset password');
    }
  }

  Future<void> forceLogout(String userId) async {
    try {
      final result = await _userRepository.forceLogout(userId);
      result.fold(
        (failure) {
          Get.snackbar('Error', failure.message);
        },
        (_) {
          Get.snackbar(
            'Success',
            'User logged out',
            backgroundColor: Colors.red.withOpacity(0.8),
            colorText: Colors.white,
          );
        },
      );
    } catch (e) {
      Get.snackbar('Error', 'Failed to logout user');
    }
  }

  Future<void> deleteUser(String userId) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Delete User'),
        content: const Text('Are you sure you want to delete this user?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final result = await _userRepository.deleteUser(userId);
        result.fold(
          (failure) {
            Get.snackbar('Error', failure.message);
          },
          (_) {
            users.removeWhere((u) => u.id == userId);
            totalUsers.value--;
            Get.snackbar(
              'Success',
              'User deleted',
              backgroundColor: Colors.green.withOpacity(0.8),
              colorText: Colors.white,
            );
          },
        );
      } catch (e) {
        Get.snackbar('Error', 'Failed to delete user');
      }
    }
  }

  void searchUsers(String query) {
    if (query.isEmpty) {
      loadUsers();
      return;
    }

    final filtered = users.where((user) {
      return user.name.toLowerCase().contains(query.toLowerCase()) ||
          user.email.toLowerCase().contains(query.toLowerCase());
    }).toList();

    users.value = filtered;
  }
}