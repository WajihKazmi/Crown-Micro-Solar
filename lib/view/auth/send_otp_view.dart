import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mrc/resource/app_navigator.dart';
import 'package:mrc/resource/app_padding.dart';
import 'package:mrc/resource/components/app_button.dart';
import 'package:mrc/resource/components/app_text_form_field.dart';
import 'package:mrc/resource/images.dart';
import 'package:mrc/utils/routes/routes_name.dart';
import 'package:mrc/view_model/auth/send_otp_view_model.dart';
import 'package:provider/provider.dart';

class SendOtpView extends StatelessWidget {
  const SendOtpView({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: ChangeNotifierProvider(
      create: (_) => SendOtpViewModel(),
      child: Builder(builder: (context) {
        final sendOtpProvider = Provider.of<SendOtpViewModel>(context);
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
                        Text('Send OTP',
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
                child: Form(
                  key: sendOtpProvider.formKey,
                  child: Padding(
                    padding: AppPadding.screenPadding.copyWith(top: 0.h),
                    child: Column(
                      children: [
                        AppTextFormField(
                            controller: sendOtpProvider.emailController,
                            validator: sendOtpProvider.emailValidator,
                            isPassword: false,
                            keyboardType: TextInputType.emailAddress,
                            fillColor:
                                Theme.of(context).colorScheme.primaryContainer,
                            hintText: 'Enter your Email'),
                        10.verticalSpace,
                        AppButton.getButton(
                            loading: sendOtpProvider.sendOtpLoading,
                            child: Text('Send OTP',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onPrimary)),
                            onPressed: () {
                              sendOtpProvider.sendOtpApi(context);
                            },
                            context: context),
                        20.verticalSpace,
                        Text('OTP has been sent on to you registered number',
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimaryContainer
                                        .withOpacity(0.5))),
                      ],
                    ),
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
