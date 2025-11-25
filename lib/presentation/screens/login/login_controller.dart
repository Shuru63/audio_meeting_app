import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';
import '../../../core/constants/app_strings.dart';
import '../../../core/router/route_names.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../core/services/local_storage_service.dart';

class LoginController extends GetxController {
  final AuthRepository _authRepository = Get.find<AuthRepository>();
  final LocalStorageService _storageService = Get.find<LocalStorageService>();

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final RxBool isLoading = false.obs;
  final RxBool obscurePassword = true.obs;
  final RxString errorMessage = ''.obs;

  String? _deviceId;

  @override
  void onInit() {
    super.onInit();
    _getDeviceId();
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  Future<void> _getDeviceId() async {
    try {
      final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        _deviceId = androidInfo.id;
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        _deviceId = iosInfo.identifierForVendor;
      }
    } catch (e) {
      debugPrint('Error getting device ID: $e');
    }
  }

  void togglePasswordVisibility() {
    obscurePassword.value = !obscurePassword.value;
  }

  Future<void> onLogin() async {
    // Clear previous error
    errorMessage.value = '';

    // Validate inputs
    if (!_validateInputs()) return;

    isLoading.value = true;

    try {
      // Attempt login
      final result = await _authRepository.login(
        email: emailController.text.trim(),
        password: passwordController.text,
        deviceId: _deviceId,
      );

      result.fold(
        (failure) {
          // Handle failure
          errorMessage.value = failure.message;
        },
        (user) async {
          // Handle success
          await _storageService.saveUser(user);
          
          // Navigate to home screen
          Get.offAllNamed(RouteNames.home);
          
          // Show success message
          Get.snackbar(
            'Success',
            AppStrings.loginSuccessful,
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green.withOpacity(0.8),
            colorText: Colors.white,
            duration: const Duration(seconds: 2),
          );
        },
      );
    } catch (e) {
      errorMessage.value = AppStrings.somethingWentWrong;
      debugPrint('Login error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  bool _validateInputs() {
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty) {
      errorMessage.value = AppStrings.emailRequired;
      return false;
    }

    if (!GetUtils.isEmail(email)) {
      errorMessage.value = AppStrings.invalidEmail;
      return false;
    }

    if (password.isEmpty) {
      errorMessage.value = AppStrings.passwordRequired;
      return false;
    }

    if (password.length < 6) {
      errorMessage.value = AppStrings.passwordTooShort;
      return false;
    }

    return true;
  }

  void onForgotPassword() {
    Get.dialog(
      AlertDialog(
        title: const Text('Forgot Password'),
        content: const Text(
          'Please contact your administrator to reset your password.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}