import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';
import '../../widgets/loading_indicator.dart';
import 'login_controller.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(LoginController());

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 60.h),
              
              // Logo or Icon
              Container(
                height: 100.h,
                width: 100.w,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.headset_mic_rounded,
                  size: 50.sp,
                  color: AppColors.textWhite,
                ),
              ),

              SizedBox(height: 40.h),

              // Welcome Text
              Text(
                AppStrings.welcomeBack,
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 8.h),

              Text(
                AppStrings.loginToContinue,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 48.h),

              // Email Field
              CustomTextField(
                controller: controller.emailController,
                label: AppStrings.email,
                hint: AppStrings.enterEmail,
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icons.email_outlined,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return AppStrings.emailRequired;
                  }
                  if (!GetUtils.isEmail(value)) {
                    return AppStrings.invalidEmail;
                  }
                  return null;
                },
              ),

              SizedBox(height: 20.h),

              // Password Field
              Obx(
                () => CustomTextField(
                  controller: controller.passwordController,
                  label: AppStrings.password,
                  hint: AppStrings.enterPassword,
                  obscureText: controller.obscurePassword.value,
                  prefixIcon: Icons.lock_outline,
                  suffixIcon: IconButton(
                    icon: Icon(
                      controller.obscurePassword.value
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: controller.togglePasswordVisibility,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return AppStrings.passwordRequired;
                    }
                    if (value.length < 6) {
                      return AppStrings.passwordTooShort;
                    }
                    return null;
                  },
                ),
              ),

              SizedBox(height: 12.h),

              // Forgot Password
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: controller.onForgotPassword,
                  child: Text(AppStrings.forgotPassword),
                ),
              ),

              SizedBox(height: 32.h),

              // Login Button
              Obx(
                () => controller.isLoading.value
                    ? const Center(child: LoadingIndicator())
                    : CustomButton(
                        text: AppStrings.login,
                        onPressed: controller.onLogin,
                        gradient: AppColors.primaryGradient,
                      ),
              ),

              SizedBox(height: 40.h),

              // Error Message
              Obx(
                () => controller.errorMessage.value.isNotEmpty
                    ? Container(
                        padding: EdgeInsets.all(16.w),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                            color: AppColors.error.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: AppColors.error,
                              size: 20.sp,
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Text(
                                controller.errorMessage.value,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(color: AppColors.error),
                              ),
                            ),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(),
              ),

              SizedBox(height: 20.h),
            ],
          ),
        ),
      ),
    );
  }
}