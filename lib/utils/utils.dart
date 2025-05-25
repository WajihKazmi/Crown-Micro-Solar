import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mrc/resource/app_padding.dart';
import 'package:mrc/resource/components/app_text_form_field.dart';

class Utils {
  snackbar(text, context) {
    var snackBar = SnackBar(
      backgroundColor: Colors.green.shade300,
      content: Text(
        text,
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  errorSnackbar(text, context) {
    var snackBar = SnackBar(
      backgroundColor: Colors.red.shade300,
      content: Text(
        text,
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}

void printWarning(text) {
  print('\x1B[33m$text\x1B[0m');
}

void printError(text) {
  print('\x1B[31m$text\x1B[0m');
}

void printInfo(text) {
  print('\x1B[34m$text\x1B[0m');
}

void printSuccess(text) {
  print('\x1B[32m$text\x1B[0m');
}

themeData(BuildContext context) => Theme.of(context);

IconButton sociaMediaIconButton(
        {required void Function()? onPressed, required String name}) =>
    IconButton(
        onPressed: onPressed,
        icon: Image.asset(
          name,
          height: 30.h,
          width: 30.w,
        ));
// SliverAppBar sliverAppBar(BuildContext context, String text) => SliverAppBar(
//       automaticallyImplyLeading: false,
//       backgroundColor: Theme.of(context).colorScheme.primary,
//       expandedHeight: 215.0.h,
//       centerTitle: true,
//       floating: true,
//       pinned: false,
//       title: Text(text,
//           style: Theme.of(context)
//               .textTheme
//               .headlineSmall
//               ?.copyWith(color: Theme.of(context).colorScheme.onPrimary)),
//       bottom: PreferredSize(
//           preferredSize: Size(double.infinity, 60.h),
//           child: Padding(
//             padding: AppPadding.screenPadding.copyWith(top: 0.h, bottom: 0.h),
//             child: AppTextFormField.textFormField(context,
//                 fillColor: Theme.of(context).colorScheme.primaryContainer,
//                 hintText: 'Search',
//                 suffixIcon: const Icon(CupertinoIcons.search)),
//           )),
//       // bottom: PreferredSize(
//       //     preferredSize: Size(double.infinity, 150.h),
//       //     child: Column(
//       //       children: [
//       //         Padding(
//       //           padding:
//       //               AppPadding.screenPadding.copyWith(top: 20.h, bottom: 30.h),
//       //           child: AppTextFormField.textFormField(context,
//       //               fillColor: Theme.of(context).colorScheme.onPrimary,
//       //               hintText: 'Search',
//       //               suffixIcon: const Icon(CupertinoIcons.search)),
//       //         ),
//       //         Container(
//       //           height: 50.h,
//       //           width: double.infinity,
//       //           decoration: BoxDecoration(
//       //               color: Theme.of(context).colorScheme.surface,
//       //               borderRadius: BorderRadius.only(
//       //                 topRight: Radius.circular(50.r),
//       //                 topLeft: Radius.circular(50.r),
//       //               )),
//       //         ),
//       //       ],
//       //     )),
//     );
SliverAppBar sliverAppBar(BuildContext context, String text,
        {expandedHeight, bottom, leading}) =>
    SliverAppBar(
      backgroundColor: Theme.of(context).colorScheme.primary,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      expandedHeight: expandedHeight ?? 150.0.h,
      centerTitle: true,
      floating: true,
      pinned: false,
      leading: leading,
      title: Text(text,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onPrimary)),
      bottom: bottom ??
          // PreferredSize(
          //     preferredSize: Size(double.infinity, 60.h),
          //     child: Padding(
          //       padding:
          //           AppPadding.screenPadding.copyWith(top: 0.h, bottom: 20.h),
          //       child: AppTextFormField.textFormField(context,
          //           fillColor: Theme.of(context).colorScheme.onPrimary,
          //           hintText: 'Search',
          //           suffixIcon: const Icon(CupertinoIcons.search)),
          //     )),
          PreferredSize(
              preferredSize: Size(double.infinity, 150.h),
              child: Column(
                children: [
                  Padding(
                    padding: AppPadding.screenPadding
                        .copyWith(top: 20.h, bottom: 30.h),
                    child: AppTextFormField(
                        fillColor: Theme.of(context).colorScheme.onPrimary,
                        hintText: 'Search',
                        suffixIcon: const Icon(CupertinoIcons.search)),
                  ),
                  Container(
                    height: 50.h,
                    width: double.infinity,
                    decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(50.r),
                          topLeft: Radius.circular(50.r),
                        )),
                  ),
                ],
              )),
    );
