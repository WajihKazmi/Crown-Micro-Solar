import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mrc/resource/app_navigator.dart';
import 'package:mrc/resource/app_padding.dart';
import 'package:mrc/resource/components/app_button.dart';
import 'package:mrc/resource/components/app_text_form_field.dart';
import 'package:mrc/resource/images.dart';
import 'package:mrc/utils/routes/routes_name.dart';
import 'package:mrc/view_model/auth/login_view_model.dart';
import 'package:provider/provider.dart';

import '../../utils/utils.dart';

class LoginView extends StatefulWidget {
  const LoginView({Key? key}) : super(key: key);

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ChangeNotifierProvider(
        create: (_) => LoginViewModel(),
        child: Builder(
          builder: (context) {
            final loginProvider = Provider.of<LoginViewModel>(context);

            return Container(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: CustomScrollView(
                slivers: [
                  SliverAppBar(
                    automaticallyImplyLeading: false,
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    expandedHeight: 215.0.h,
                    flexibleSpace: FlexibleSpaceBar(
                      background: Align(
                        alignment: Alignment.center,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            IconButton(
                              onPressed: () => AppNavigator.pushNamed(
                                  context, RoutesName.loginAndSignupButtonView),
                              icon: Image.asset(
                                AppImages.backArrow,
                                height: 30.h,
                                width: 30.w,
                              ),
                            ),
                            Image.asset(
                              AppImages.logo,
                              height: 126.h,
                              width: 192.w,
                            ),
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
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(50.r),
                            topLeft: Radius.circular(50.r),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Form(
                    key: loginProvider.formKey,
                    child: SliverToBoxAdapter(
                      child: Padding(
                        padding: AppPadding.screenPadding.copyWith(top: 0.h),
                        child: Column(
                          children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Login to your Account',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimaryContainer,
                                    ),
                              ),
                            ),
                            20.verticalSpace,
                            AppTextFormField(
                              isPassword: false,
                              controller: loginProvider.emailController,
                              keyboardType: TextInputType.emailAddress,
                              autofillHints: [AutofillHints.email],
                              hintText: 'Email',
                              validator: loginProvider.emailValidator,
                            ),
                            8.verticalSpace,
                            AppTextFormField(
                              isPassword: true,
                              controller: loginProvider.passwordController,
                              keyboardType: TextInputType.visiblePassword,
                              autofillHints: [AutofillHints.password],
                              hintText: 'Password',
                              validator: loginProvider.passwordValidator,
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () => AppNavigator.pushNamed(
                                  context,
                                  RoutesName.sendOtp,
                                ),
                                child: Text(
                                  'Forget Password?',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onPrimaryContainer
                                            .withOpacity(0.8),
                                      ),
                                ),
                              ),
                            ),
                            20.verticalSpace,
                            AppButton.getButton(
                              loading: loginProvider.loginLoading,
                              child: Text(
                                'Login',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimary,
                                    ),
                              ),
                              onPressed: () {
                                loginProvider.loginApi(context);
                              },
                              context: context,
                            ),
                            20.verticalSpace,
                            Text(
                              '- Or Sign in with -',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelLarge
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimaryContainer
                                        .withOpacity(0.5),
                                  ),
                            ),
                            10.verticalSpace,
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                sociaMediaIconButton(
                                  onPressed: () {},
                                  name: AppImages.google,
                                ),
                                sociaMediaIconButton(
                                  onPressed: () {},
                                  name: AppImages.facebook,
                                ),
                                sociaMediaIconButton(
                                  onPressed: () {},
                                  name: AppImages.instagram,
                                ),
                                sociaMediaIconButton(
                                  onPressed: () {},
                                  name: AppImages.apple,
                                ),
                              ],
                            ),
                            150.verticalSpace,
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Don’t have an Account?',
                                  style:
                                      Theme.of(context).textTheme.labelMedium,
                                ),
                                TextButton(
                                  child: Text(
                                    'Sign Up',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                        ),
                                  ),
                                  onPressed: () => AppNavigator.pushNamed(
                                      context, RoutesName.signUp),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
