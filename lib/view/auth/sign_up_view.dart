import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mrc/resource/app_navigator.dart';
import 'package:mrc/resource/app_padding.dart';
import 'package:mrc/resource/components/app_button.dart';
import 'package:mrc/resource/components/app_text_form_field.dart';
import 'package:mrc/resource/images.dart';
import 'package:mrc/utils/routes/routes_name.dart';
import 'package:mrc/utils/utils.dart';
import 'package:mrc/view_model/auth/sign_up_view_model.dart';
import 'package:provider/provider.dart';

class SignUpView extends StatefulWidget {
  const SignUpView({Key? key}) : super(key: key);

  @override
  State<SignUpView> createState() => _SignUpViewState();
}

class _SignUpViewState extends State<SignUpView> {
  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvoked: (didPop) {
        if (didPop) {
          Provider.of<SignUpViewModel>(context, listen: false).disposeFields();
        }
      },
      child: Scaffold(
        body: ChangeNotifierProvider(
          create: (_) => SignUpViewModel(),
          child: Builder(builder: (context) {
            final signupProvider = Provider.of<SignUpViewModel>(context);

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
                              onPressed: () => AppNavigator.pop(context),
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
                    key: signupProvider.formKey,
                    child: SliverToBoxAdapter(
                      child: Padding(
                        padding: AppPadding.screenPadding.copyWith(top: 0.h),
                        child: Column(
                          children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text('Create your Account',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onPrimaryContainer)),
                            ),
                            20.verticalSpace,
                            AppTextFormField(
                              isPassword: false,
                              controller: signupProvider.nameFirstController,
                              keyboardType: TextInputType.name,
                              autofillHints: [AutofillHints.username],
                              hintText: 'First Name',
                              validator: signupProvider.nameValidator,
                            ),
                            10.verticalSpace,
                            AppTextFormField(
                              isPassword: false,
                              controller: signupProvider.nameLastController,
                              keyboardType: TextInputType.name,
                              autofillHints: [AutofillHints.name],
                              hintText: 'Last Name',
                              validator: signupProvider.nameValidator,
                            ),
                            10.verticalSpace,
                            Container(
                              height: 55,
                              decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20)),
                              child: DropdownButtonFormField<String>(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                                borderRadius: BorderRadius.circular(20),
                                value:
                                    signupProvider.genderController.text.isEmpty
                                        ? null
                                        : signupProvider.genderController.text,
                                items: ['Male', 'Female'].map((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(
                                      value,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium,
                                    ),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  signupProvider.genderController.text =
                                      newValue!;
                                },
                                style: Theme.of(context).textTheme.bodyMedium,
                                decoration: InputDecoration(
                                    hintStyle: Theme.of(context)
                                        .textTheme
                                        .labelLarge
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withOpacity(0.4),
                                        ),
                                    hintText: 'Gender',
                                    border: OutlineInputBorder(
                                        borderSide: BorderSide.none,
                                        borderRadius:
                                            BorderRadius.circular(20))),
                                validator: signupProvider.genderValidator,
                              ),
                            ),
                            10.verticalSpace,
                            GestureDetector(
                              onTap: () async {
                                DateTime? pickedDate = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now(),
                                  firstDate: DateTime(1900),
                                  lastDate: DateTime(2100),
                                );
                                if (pickedDate != null) {
                                  signupProvider.dobController.text =
                                      "${pickedDate.toLocal()}".split(' ')[0];
                                }
                              },
                              child: AbsorbPointer(
                                child: AppTextFormField(
                                  isPassword: false,
                                  controller: signupProvider.dobController,
                                  keyboardType: TextInputType.datetime,
                                  autofillHints: [AutofillHints.birthday],
                                  hintText: 'DOB',
                                  validator: signupProvider.dateValidator,
                                ),
                              ),
                            ),
                            10.verticalSpace,
                            AppTextFormField(
                              isPassword: false,
                              controller: signupProvider.numberController,
                              autofillHints: [AutofillHints.telephoneNumber],
                              keyboardType: TextInputType.number,
                              hintText: 'Phone Number',
                              validator: signupProvider.numberValidator,
                            ),
                            10.verticalSpace,
                            AppTextFormField(
                              isPassword: false,
                              controller: signupProvider.emailController,
                              autofillHints: [AutofillHints.email],
                              keyboardType: TextInputType.emailAddress,
                              hintText: 'Email',
                              validator: signupProvider.emailValidator,
                            ),
                            10.verticalSpace,
                            AppTextFormField(
                              isPassword: true,
                              controller: signupProvider.passwordController,
                              autofillHints: [AutofillHints.newPassword],
                              keyboardType: TextInputType.visiblePassword,
                              hintText: 'Password',
                              validator: signupProvider.passwordValidator,
                            ),
                            10.verticalSpace,
                            AppTextFormField(
                              isPassword: true,
                              controller:
                                  signupProvider.passwordConfirmController,
                              autofillHints: [AutofillHints.newPassword],
                              keyboardType: TextInputType.visiblePassword,
                              hintText: 'Confirm Password',
                              validator:
                                  signupProvider.confirmPasswordValidator,
                            ),
                            10.verticalSpace,
                            AppTextFormField(
                              isPassword: false,
                              controller: signupProvider.interestsController,
                              keyboardType: TextInputType.text,
                              hintText: 'Interests',
                              validator: signupProvider.interestsValidator,
                            ),
                            10.verticalSpace,
                            AppButton.getButton(
                              loading: signupProvider.signUpLoading,
                              child: Text('Sign Up',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onPrimary)),
                              onPressed: () {
                                signupProvider.signUpApi(context);
                              },
                              context: context,
                            ),
                            50.verticalSpace,
                            Text('- Or Sign Up with -',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelLarge
                                    ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onPrimaryContainer
                                            .withOpacity(0.5))),
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
                                  'Already have a Account?',
                                  style:
                                      Theme.of(context).textTheme.labelMedium,
                                ),
                                TextButton(
                                  child: Text(
                                    'Sign In',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary),
                                  ),
                                  onPressed: () => AppNavigator.pushNamed(
                                      context, RoutesName.login),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}
