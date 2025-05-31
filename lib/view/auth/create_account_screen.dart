import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';
import '../../core/utils/app_buttons.dart';

class CreateAccountScreen extends StatelessWidget {
  const CreateAccountScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Stack(
        children: [
          // Background image at the bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Image.asset(
              'assets/images/solar_vector.png',
              fit: BoxFit.cover,
              // The height of the image will be determined by the available space and fit: BoxFit.cover
            ),
          ),
          // Main content layered on top
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo
                  Image.asset(
                    'assets/images/logo_main.png',
                    height:
                        100, // Keeping a height for the logo for now based on screenshot
                  ),
                  const SizedBox(height: 50),
                  // Title
                  Text(
                    'Create Account',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Subtitle
                  Text(
                    'If you don\'t have an account,\nplease register first',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Login Button
                  AppButtons.primaryButton(
                    context: context,
                    onTap: () {
                      Navigator.of(context)
                          .pushReplacementNamed(AppRoutes.login);
                    },
                    text: 'Login',
                    isFilled: true,
                    horizontalPadding: 0, // Padding handled by the parent Padding
                  ),
                  // Add flexible space to push content up and terms down
                  Expanded(child: Container()),
                  // Terms & Conditions / Privacy Policy
                  Column(
                    children: [
                      Text(
                        'By signing-in, you agree to our',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall!
                            .copyWith(color: Colors.white),
                      ),
                      const SizedBox(height: 4.0),
                      Text.rich(
                        TextSpan(
                          text: 'Terms & Conditions ',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                          children: [
                            TextSpan(
                              text: '| ',
                              style: theme.textTheme.bodySmall,
                            ),
                            TextSpan(
                              text: 'Privacy Policy',
                              style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.white,
                                  decoration: TextDecoration.underline,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
