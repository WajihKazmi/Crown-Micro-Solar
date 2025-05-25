import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mrc/resource/app_navigator.dart';
import 'package:mrc/resource/app_padding.dart';
import 'package:mrc/resource/components/app_button.dart';
import 'package:mrc/resource/components/app_text_form_field.dart';
import 'package:mrc/resource/images.dart';
import 'package:mrc/view_model/auth/verify_otp_view_model.dart';
import 'package:provider/provider.dart';

class ForgotPasswordView extends StatelessWidget {
  const ForgotPasswordView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: ChangeNotifierProvider(
      create: (_) => VerifyOtpViewModel(),
      child: Builder(builder: (context) {
        return Container(
          color: Theme.of(context).colorScheme.surface,
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                automaticallyImplyLeading: false,
                backgroundColor: Theme.of(context).colorScheme.primary,
                expandedHeight: 215.0.h,
                flexibleSpace: FlexibleSpaceBar(
                  background: Padding(
                    padding: AppPadding.screenPadding,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            onPressed: () => AppNavigator.pop(context),
                            icon: Image.asset(
                              AppImages.backArrow,
                              color: Theme.of(context).colorScheme.onPrimary,
                              width: 30.w,
                            ),
                          ),
                        ),
                        Text('Change Password',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimary)),
                        const SizedBox(),
                        const SizedBox()
                      ],
                    ),
                  ),
                ),
                bottom: PreferredSize(
                    preferredSize: Size(double.infinity, 0.h),
                    child: Container(
                      height: 50.h,
                      width: double.infinity,
                      decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
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
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      AppTextFormField(
                        isPassword: true,
                        autofillHints: [AutofillHints.newPassword],
                        keyboardType: TextInputType.visiblePassword,
                        fillColor:
                            Theme.of(context).colorScheme.primaryContainer,
                        hintText: 'New Password',
                      ),
                      10.verticalSpace,
                      AppTextFormField(
                        isPassword: true,
                        autofillHints: [AutofillHints.newPassword],
                        keyboardType: TextInputType.visiblePassword,
                        fillColor:
                            Theme.of(context).colorScheme.primaryContainer,
                        hintText: 'Confirm Password',
                      ),
                      20.verticalSpace,
                      AppButton.getButton(
                        child: Text(
                          'Submit',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onPrimary,
                              ),
                        ),
                        onPressed: () {},
                        context: context,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    ));
  }
}
