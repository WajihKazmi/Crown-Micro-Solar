import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mrc/resource/app_navigator.dart';
import 'package:mrc/resource/app_padding.dart';
import 'package:mrc/resource/components/app_button.dart';
import 'package:mrc/resource/images.dart';
import 'package:mrc/utils/routes/routes_name.dart';

class LoginAndSignupButtonView extends StatelessWidget {
  const LoginAndSignupButtonView({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvoked: (bool b) {
        Navigator.of(context).pop(true); // Updated line
        return;
      },
      child: Scaffold(
          body: Container(
        color: Theme.of(context).colorScheme.primaryContainer,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              automaticallyImplyLeading: false,
              backgroundColor: Theme.of(context).colorScheme.surface,
              expandedHeight: 313.0.h,
              flexibleSpace: FlexibleSpaceBar(
                background: Align(
                  alignment: Alignment.center,
                  child: Image.asset(
                    AppImages.logo,
                    height: 126.h,
                    width: 192.w,
                  ),
                ),
              ),
              bottom: PreferredSize(
                  preferredSize: Size(double.infinity, 0.h),
                  child: Container(
                    height: 50.h,
                    width: double.infinity,
                    decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(50.r),
                          topLeft: Radius.circular(50.r),
                        )),
                  )),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: AppPadding.screenPadding.copyWith(top: 0.h),
                child: Column(
                  children: [
                    AppButton.getButton(
                        child: Text('Login',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimary)),
                        onPressed: () =>
                            AppNavigator.pushNamed(context, RoutesName.login),
                        context: context),
                    10.verticalSpace,
                    AppButton.outlineGetButton(
                        child: Text('Sign Up',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimaryContainer)),
                        onPressed: () =>
                            AppNavigator.pushNamed(context, RoutesName.signUp),
                        context: context),
                  ],
                ),
              ),
            ),
          ],
        ),
      )),
    );
  }
}
