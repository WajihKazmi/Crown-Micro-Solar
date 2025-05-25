import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppButton {
  static ElevatedButton getButton({
    required BuildContext context,
    required Widget? child,
    required void Function()? onPressed,
    double? width,
    double? height,
    Color? color,
    double? radius,
    bool loading = false,
  }) =>
      ElevatedButton(
          style: ElevatedButton.styleFrom(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(radius?.r ?? 20.0.r),
              ),
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              backgroundColor: color ?? Theme.of(context).colorScheme.primary,
              minimumSize:
                  Size(width?.w ?? double.infinity.w, height?.h ?? 50.0.h)),
          onPressed: loading == true ? null : onPressed,
          child: loading
              ? CircularProgressIndicator.adaptive(
                  backgroundColor: Theme.of(context).colorScheme.onPrimary,
                )
              : child);

  static OutlinedButton outlineGetButton({
    required BuildContext context,
    required Widget? child,
    required void Function()? onPressed,
    double? width,
    double? height,
    Color? color,
    double? radius,
    bool loading = false,
  }) =>
      OutlinedButton(
          style: OutlinedButton.styleFrom(
              elevation: 0,
              side: BorderSide(
                  width: 2, color: Theme.of(context).colorScheme.outline),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(radius?.r ?? 20.0.r),
              ),
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              backgroundColor: color ?? Colors.transparent,
              // Theme.of(context).colorScheme.primaryContainer,
              minimumSize:
                  Size(width?.w ?? double.infinity.w, height?.h ?? 50.0.h)),
          onPressed: loading == true ? null : onPressed,
          child: loading
              ? CircularProgressIndicator.adaptive(
                  backgroundColor: Theme.of(context).colorScheme.onPrimary,
                )
              : child);
}
