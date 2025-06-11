import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';
import '../../core/utils/app_buttons.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_text_fields.dart';
import 'package:flutter/gestures.dart'; // Import for TapGestureRecognizer

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  static const String routeName = AppRoutes.login;

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isInstallerMode = false;
  bool _isPasswordVisible = false;

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _userIdController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _userIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() {
    // Use FormState validate to trigger validation on all fields in the form
    if (_formKey.currentState?.validate() ?? false) {
      // If the form is valid, proceed with login logic
      // TODO: Implement login logic
    } else {
      // If validation fails, clear the text fields
      _userIdController.clear();
      _passwordController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: GestureDetector(
        onTap: () {
          // Dismiss the keyboard when tapping outside text fields
          FocusScope.of(context).unfocus();
        },
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Title

                    const SizedBox(height: 40.0),
                    Text(
                      'Welcome Back,\nCrown Member!',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5.0),
                    // Subtitle
                    Text(
                      'Enter the data below to get a verification code',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 20.0),
                    // User ID Text Field
                    Text(
                      'User ID',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5.0),
                    AppTextField(
                      controller: _userIdController,
                      hintText: 'Azidaniro25',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your User ID';
                        }
                        return null;
                      },
                      onFieldSubmitted: (_) {
                        // Accept String parameter
                        // TODO: Handle field submission if needed
                        _login(); // Optionally trigger login on submitting this field
                      },
                    ),
                    const SizedBox(height: 10.0),
                    // Password Text Field
                    Text(
                      'Password',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5.0),
                    AppTextField(
                      controller: _passwordController,
                      hintText: '********',
                      isPassword: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                      onFieldSubmitted: (_) {
                        // Accept String parameter
                        // TODO: Handle field submission if needed
                        _login(); // Optionally trigger login on submitting this field
                      },
                    ),
                    const SizedBox(height: 10.0),
                    // Installer Mode and Forgot Password
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Switch(
                              value: _isInstallerMode,
                              onChanged: (value) {
                                setState(() {
                                  _isInstallerMode = value;
                                });
                              },
                              activeColor:
                                  Colors.green, // Use theme color for switch
                            ),
                            Text(
                              'Installer Mode',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: () {
                            // Navigate to the Forgot Password screen
                            Navigator.of(context)
                                .pushNamed(AppRoutes.forgotPassword);
                          },
                          child: Text(
                            'Forgot Password?',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15.0),
                    // Login Button (Filled)
                    AppButtons.primaryButton(
                      context: context,
                      onTap:
                          _login, // Call the _login method to trigger validation
                      text: 'Login',
                      isFilled: true,
                      horizontalPadding:
                          0, // Padding handled by parent SingleChildScrollView
                    ),
                    const SizedBox(height: 10.0),
                    // Wi-Fi Configuration Button (Outlined)
                    AppButtons.primaryButton(
                      context: context,
                      onTap: () {
                        // TODO: Implement Wi-Fi Configuration logic
                      },
                      text: 'Wi-Fi Configuration',
                      isFilled: false,
                      textColor: Colors.black,
                      horizontalPadding:
                          0, // Padding handled by parent SingleChildScrollView
                    ),
                    const SizedBox(height: 10.0),
                    // Register Button (Outlined)
                    AppButtons.primaryButton(
                      context: context,
                      onTap: () {
                        // TODO: Implement Register logic
                        // Navigate to Registration Screen
                        Navigator.of(context).pushNamed(AppRoutes.register);
                      },
                      text: 'Register',
                      isFilled: false,
                      textColor: Colors.black,
                      horizontalPadding:
                          0, // Padding handled by parent SingleChildScrollView
                    ),
                    // Contact Options
                    TextButton.icon(
                      onPressed: () {
                        // TODO: Implement Contact to Support logic
                      },
                      icon: Image.asset(
                        'assets/icons/support.png', // Support icon
                        width: 20,
                        height: 20,
                      ),
                      label: Text(
                        'Contact to Support',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        // TODO: Implement WhatsApp logic
                      },
                      icon: Image.asset(
                        'assets/icons/whatsapp.png', // WhatsApp icon
                        width: 20,
                        height: 20,
                      ),
                      label: Text(
                        'WhatsApp',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsetsGeometry.symmetric(vertical: 8),
                  child: Image.asset(
                    'assets/images/logo_main.png',
                    height: 80,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
