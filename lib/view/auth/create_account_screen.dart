import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';
import '../../../core/utils/app_text_fields.dart';
import '../../../core/utils/app_buttons.dart';
import '../common/bordered_icon_button.dart';
import 'package:provider/provider.dart';
import '../../presentation/viewmodels/auth_viewmodel.dart';
import 'forgot_password_screen.dart'; // Import RecoveryMode enum

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({Key? key}) : super(key: key);

  static const String routeName = AppRoutes.createAccount;

  @override
  _CreateAccountScreenState createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _continue() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      final email = _emailController.text.trim();
      
      // Send OTP to email using PushShortCode API
      bool success = await authViewModel.forgotPassword(email);

      setState(() {
        _isLoading = false;
      });

      if (success) {
        // Navigate to verification screen with registration mode
        Navigator.of(context).pushNamed(
          AppRoutes.verification,
          arguments: {
            'mode': RecoveryMode.registration,
            'email': email,
          },
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to send verification code. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: BorderedIconButton(
          icon: Icons.arrow_back_ios_new,
          onTap: () => Navigator.of(context).pop(),
          margin: const EdgeInsets.only(left: 16.0),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      resizeToAvoidBottomInset: false,
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 10.0),
                  Text(
                    'Create Account',
                    style: theme.textTheme.displaySmall!
                        .copyWith(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 16.0),
                  Text(
                    'Enter your email address to receive a verification code',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 40.0),
                  
                  // Email Field
                  Text('Email Address', 
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5.0),
                  AppTextField(
                    controller: _emailController,
                    hintText: 'Enter your email',
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!RegExp(r'^[\w.-]+@([\w-]+\.)+[\w-]{2,63}$')
                          .hasMatch(value.trim())) {
                        return 'Please enter a valid email address';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 40.0),

                  // Continue Button
                  _isLoading
                      ? Center(
                          child: CircularProgressIndicator(
                            color: theme.colorScheme.primary,
                          ),
                        )
                      : AppButtons.primaryButton(
                          context: context,
                          onTap: _continue,
                          text: 'Continue',
                          isFilled: true,
                        ),
                  
                  const Spacer(),
                  
                  // Logo at bottom
                  Center(
                    child: Image.asset(
                      'assets/images/logo_main.png',
                      height: 80,
                    ),
                  ),
                  const SizedBox(height: 20.0),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
