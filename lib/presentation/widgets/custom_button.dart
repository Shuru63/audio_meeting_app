import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/constants/app_colors.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isOutlined;
  final IconData? icon;
  final Color? color;
  final Gradient? gradient;
  final double? width;
  final double? height;
  final bool isDisabled;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isOutlined = false,
    this.icon,
    this.color,
    this.gradient,
    this.width,
    this.height,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isOutlined) {
      return OutlinedButton(
        onPressed: isDisabled ? null : onPressed,
        style: OutlinedButton.styleFrom(
          minimumSize: Size(width ?? double.infinity, height ?? 56.h),
          side: BorderSide(
            color: isDisabled ? AppColors.border : (color ?? AppColors.primary),
            width: 1.5,
          ),
        ),
        child: _buildContent(context),
      );
    }

    if (gradient != null) {
      return Container(
        width: width ?? double.infinity,
        height: height ?? 56.h,
        decoration: BoxDecoration(
          gradient: isDisabled ? null : gradient,
          color: isDisabled ? AppColors.border : null,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: isDisabled
              ? null
              : [
                  BoxShadow(
                    color: (color ?? AppColors.primary).withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isDisabled ? null : onPressed,
            borderRadius: BorderRadius.circular(12.r),
            child: Center(child: _buildContent(context)),
          ),
        ),
      );
    }

    return ElevatedButton(
      onPressed: isDisabled ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color ?? AppColors.primary,
        minimumSize: Size(width ?? double.infinity, height ?? 56.h),
      ),
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (icon != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20.sp),
          SizedBox(width: 8.w),
          Text(text),
        ],
      );
    }
    return Text(text);
  }
}



