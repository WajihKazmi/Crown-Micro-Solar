import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';
import '../../core/utils/app_buttons.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_text_fields.dart';

enum RecoveryMode {
  password,
  userId,
  registration, // Added for new user registration flow
}

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  RecoveryMode _mode = RecoveryMode.password; // Default to Forgot Password
  final _formKey = GlobalKey<FormState>(); // Add a GlobalKey for the Form
  final TextEditingController _emailController =
      TextEditingController(); // Add controller for email field

  void _switchMode(RecoveryMode mode) {
    setState(() {
      _mode = mode;
    });
  }

  @override
  void dispose() {
    _emailController.dispose(); // Dispose the controller
    super.dispose();
  }

  void _continue() {
    if (_formKey.currentState!.validate()) {
      // If the form is valid, proceed with the action based on _mode
      Navigator.of(context).pushNamed(
        AppRoutes.verification,
        arguments: _mode, // Pass the selected mode as an argument
      );
    } else {
      // If validation fails, clear the text field
      _emailController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      resizeToAvoidBottomInset:
          false, // Prevent screen resize when keyboard appears
      body: GestureDetector(
        onTap: () {
          // Dismiss the keyboard when tapping outside text fields
          FocusScope.of(context).unfocus();
        },
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 24.0, vertical: 10.0), // Adjusted padding
            child: Form(
              key: _formKey, // Assign the form key
              child: Column(
                mainAxisAlignment: MainAxisAlignment
                    .spaceBetween, // Use spaceBetween to push logo down
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Main content column
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Title (moved from AppBar)
                      Text(
                        _mode == RecoveryMode.password
                            ? 'Forgot Password'
                            : 'Forgot User ID',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8.0), // Space below title
                      // Subtitle
                      Text(
                        'Enter your email address',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 40.0),
                      // Email Address Text Field
                      Text(
                        'Email Address',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      AppTextField(
                        controller: _emailController, // Assign controller
                        hintText: 'Enter your email address',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email address';
                          }
                          // Basic email format validation using a regular expression
                          if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                            return 'Please enter a valid email address';
                          }
                          return null;
                        },
                        onFieldSubmitted: (_) {
                          // Accept String parameter
                          // TODO: Handle field submission if needed
                          _continue(); // Optionally trigger continue on submitting this field
                        },
                      ),
                      const SizedBox(height: 15.0),
                      // Continue Button
                      AppButtons.primaryButton(
                        context: context,
                        onTap:
                            _continue, // Call the validation and navigation function
                        text: 'Continue',
                        isFilled: true,
                        horizontalPadding:
                            0, // Padding handled by parent Padding
                      ),
                      // Forgot User ID / Forgot Password links
                      Padding(
                        padding: const EdgeInsets.only(
                            top: 15.0), // Add some space above links
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Forgot User ID link
                            TextButton(
                              onPressed: _mode == RecoveryMode.userId
                                  ? null
                                  : () => _switchMode(RecoveryMode.userId),
                              child: Text(
                                'Forgot User ID?',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: _mode == RecoveryMode.userId
                                      ? Colors.lightGreen.shade500
                                      : Colors.grey,
                                  // decoration: _mode == RecoveryMode.userId
                                  //     ? TextDecoration.none
                                  //     : TextDecoration.underline,
                                ),
                              ),
                            ),
                            // Forgot Password link
                            TextButton(
                              onPressed: _mode == RecoveryMode.password
                                  ? null
                                  : () => _switchMode(RecoveryMode.password),
                              child: Text(
                                'Forgot Password?',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: _mode == RecoveryMode.password
                                      ? Colors.lightGreen.shade500
                                      : Colors.grey,
                                  // decoration: _mode == RecoveryMode.password
                                  //     ? TextDecoration.none
                                  //     : TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  // Logo at the bottom
                  Center(
                    child: Image.asset(
                      'assets/images/logo_main.png',
                      height: 80, // Changed height from 50 to 80
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
