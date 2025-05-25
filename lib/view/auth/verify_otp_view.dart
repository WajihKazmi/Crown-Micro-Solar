import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mrc/resource/app_navigator.dart';
import 'package:mrc/resource/app_padding.dart';
import 'package:mrc/resource/components/app_button.dart';
import 'package:mrc/resource/components/app_text_form_field.dart';
import 'package:mrc/resource/images.dart';
import 'package:mrc/utils/routes/routes_name.dart';
import 'package:mrc/view/auth/forgot_password_view.dart';
import 'package:mrc/view_model/auth/verify_otp_view_model.dart';
import 'package:provider/provider.dart';

class VerifyOtpView extends StatelessWidget {
  const VerifyOtpView({super.key, required this.email});
  final String email;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: ChangeNotifierProvider(
      create: (_) => VerifyOtpViewModel(),
      child: Builder(builder: (context) {
        final verifyOtpProvider =
            Provider.of<VerifyOtpViewModel>(context, listen: false);
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
                        Text('Verify OTP',
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
                  key: verifyOtpProvider.formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        "Enter the verification code to continue",
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                      const SizedBox(
                        height: 50,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(
                          4,
                          (index) => SizedBox(
                            width: 60,
                            height: 50,
                            child: TextFormField(
                              controller:
                                  verifyOtpProvider.otpControllers[index],
                              textAlign: TextAlign.center,
                              keyboardType: TextInputType.number,
                              maxLength: 1,
                              validator: verifyOtpProvider.otpValidator,
                              decoration: InputDecoration(
                                hintText: ' ',
                                counterText: '',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary),
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              onChanged: (value) {
                                if (value.length == 1 && index < 3) {
                                  FocusScope.of(context).nextFocus();
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 30, vertical: 20),
                        child: Container(
                          width: double.maxFinite,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: AppButton.getButton(
                              loading: verifyOtpProvider.verifyOtpLoading,
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
                                verifyOtpProvider.verifyOtpApi(context, email);
                              },
                              context: context),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Didn't Receive Code?",
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                          TextButton(
                            onPressed: () {},
                            child: Text(
                              'Resend',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          )
                        ],
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
