import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';
import '../../core/utils/app_buttons.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_text_fields.dart';
import '../common/bordered_icon_button.dart';
import 'package:provider/provider.dart';
import '../../presentation/viewmodels/auth_viewmodel.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({Key? key}) : super(key: key);

  @override
  _ResetPasswordScreenState createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  String? _email;
  bool _submitting = false;

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map && args['email'] is String) {
        _email = args['email'] as String;
      }
    });
  }

  Future<void> _resetPassword() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      return;
    }
    if (_email == null || _email!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Missing email for reset')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      final auth = Provider.of<AuthViewModel>(context, listen: false);
      final userId = await auth.getUserIdForEmail(_email!);
      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No user found for this email')),
        );
        return;
      }
      final ok = await auth.updatePasswordWithUserId(userId, _newPasswordController.text);
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Your password is updated successfully.'), backgroundColor: Colors.green),
        );
        Navigator.of(context).pushReplacementNamed(AppRoutes.login);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update password.')), 
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
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
                      const SizedBox(height: 20.0),
                      // Subtitle
                      Text(
                        'Enter your new password',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 24.0),
                      // New Password Text Field
                      Text(
                        'New Password',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      AppTextField(
                        controller: _newPasswordController,
                        hintText: '********',
                        isPassword: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your new password';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                        onFieldSubmitted: (_) {
                          FocusScope.of(context).nextFocus();
                        },
                      ),
                      const SizedBox(height: 16.0),
                      // Confirm New Password Text Field
                      Text(
                        'Confirm New Password',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      AppTextField(
                        controller: _confirmPasswordController,
                        hintText: '********',
                        isPassword: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please confirm your new password';
                          }
                          if (value != _newPasswordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                        onFieldSubmitted: (_) {
                          _resetPassword();
                        },
                      ),
                      const SizedBox(height: 24.0),
                      // Reset Now Button
                      AppButtons.primaryButton(
                        context: context,
                        onTap: _submitting ? null : _resetPassword,
                        text: 'Reset Now',
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