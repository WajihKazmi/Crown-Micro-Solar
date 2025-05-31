import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';
import '../../core/utils/app_buttons.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_text_fields.dart';

class ChangeUserIdScreen extends StatefulWidget {
  const ChangeUserIdScreen({Key? key}) : super(key: key);

  @override
  _ChangeUserIdScreenState createState() => _ChangeUserIdScreenState();
}

class _ChangeUserIdScreenState extends State<ChangeUserIdScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _newUserIdController = TextEditingController();

  @override
  void dispose() {
    _newUserIdController.dispose();
    super.dispose();
  }

  void _changeUserId() {
    if (_formKey.currentState?.validate() ?? false) {
      // TODO: Implement User ID change logic
      Navigator.of(context).pushReplacementNamed(AppRoutes.login);
    } else {
      // If validation fails, clear the text field
      _newUserIdController.clear();
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
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      resizeToAvoidBottomInset: false,
      body: GestureDetector(
        onTap: () {
          // Dismiss the keyboard when tapping outside text fields
          FocusScope.of(context).unfocus();
        },
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Title
                      Text(
                        'Change User ID!',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      // Subtitle
                      Text(
                        'Enter your new User ID',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 24.0),
                      // New User ID Text Field
                      Text(
                        'New User ID',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      AppTextField(
                        controller: _newUserIdController,
                        hintText: 'Azidaniro25',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your new User ID';
                          }
                          // Add more specific User ID validation if needed
                          return null;
                        },
                        onFieldSubmitted: (_) {
                          _changeUserId();
                        },
                      ),
                      const SizedBox(height: 24.0),
                      // Continue Button
                      AppButtons.primaryButton(
                        context: context,
                        onTap: _changeUserId,
                        text: 'Continue',
                        isFilled: true,
                        horizontalPadding: 0,
                      ),
                    ],
                  ),
                  // Logo at the bottom
                  Center(
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
      ),
    );
  }
} 