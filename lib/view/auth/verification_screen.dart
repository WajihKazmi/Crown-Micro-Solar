import 'package:crown_micro_solar/core/utils/app_text_fields.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import '../../routes/app_routes.dart';
import '../../core/utils/app_animations.dart';
import '../../core/utils/app_buttons.dart'; // Import AppButtons
import 'forgot_password_screen.dart'; // Import RecoveryMode enum
import '../common/bordered_icon_button.dart';
import 'package:provider/provider.dart';
import '../../presentation/viewmodels/auth_viewmodel.dart';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({Key? key}) : super(key: key);

  static const String routeName = '/verification';

  @override
  _VerificationScreenState createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  late Timer _timer;
  int _start = 60; // Countdown starts from 60 seconds
  bool _isLoading = false;
  final List<TextEditingController> _codeControllers =
      List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());
  RecoveryMode _recoveryMode = RecoveryMode.password; // Default value
  String? _email;

  // Combined error state and message for the entire code input area
  bool _codeError = false;
  String? _codeErrorMessage;
  Timer? _codeErrorTimer; // Timer for combined error message duration

  @override
  void initState() {
    super.initState();
    startTimer();
    // No need for listeners on individual controllers anymore for combined validation
    // for (var controller in _codeControllers) {
    //   controller.addListener(_onCodeChanged);
    // }
    // Set initial focus to first field
    _focusNodes[0].requestFocus();

    // Get the recovery mode from arguments
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map) {
        _recoveryMode = args['mode'] as RecoveryMode? ?? RecoveryMode.password;
        _email = args['email'] as String?;
      } else if (args is RecoveryMode) {
        _recoveryMode = args;
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _codeErrorTimer?.cancel(); // Cancel the code error timer
    for (var controller in _codeControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void startTimer() {
    _start = 60; // Reset timer if needed
    _isLoading = false; // Reset loading state
    const oneSec = Duration(seconds: 1);
    _timer = Timer.periodic(
      oneSec,
      (Timer timer) {
        if (_start == 0) {
          setState(() {
            timer.cancel();
          });
        } else {
          setState(() {
            _start--;
          });
        }
      },
    );
  }

  void _verifyCode() async {
    final enteredCode =
        _codeControllers.map((controller) => controller.text).join();
    if (enteredCode.length == 4 && RegExp(r'^\d{4}').hasMatch(enteredCode)) {
      setState(() {
        _codeError = false;
        _codeErrorMessage = null;
        _isLoading = true;
      });
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      bool success = false;
      if (_email != null) {
        success = await authViewModel.verifyOtp(_email!, enteredCode);
      } else {
        // fallback: simulate success
        await Future.delayed(const Duration(seconds: 2));
        success = true;
      }
      setState(() {
        _isLoading = false;
      });
      if (success) {
        if (_recoveryMode == RecoveryMode.password) {
          Navigator.of(context).pushReplacementNamed(
            AppRoutes.resetPassword,
            arguments: {
              'email': _email,
            },
          );
        } else if (_recoveryMode == RecoveryMode.userId) {
          Navigator.of(context).pushReplacementNamed(AppRoutes.changeUserId);
        } else if (_recoveryMode == RecoveryMode.registration) {
          // Navigate directly to home screen after successful registration verification
          Navigator.of(context).pushReplacementNamed(AppRoutes.homeInternal);
        } else {
          Navigator.of(context).pushReplacementNamed(AppRoutes.login);
        }
      } else {
        setState(() {
          _codeError = true;
          _codeErrorMessage = 'Invalid code. Please try again.';
        });
      }
    } else {
      // Validation failed, show error, shake, and clear fields
      setState(() {
        _codeError = true;
        _codeErrorMessage = 'Enter a valid 4-digit code';
        // Clear all text fields on validation failure
        for (var controller in _codeControllers) {
          controller.clear();
        }
        // Reset focus to the first field
        _focusNodes[0].requestFocus();
      });

      // Start timer for combined error message duration
      _codeErrorTimer?.cancel(); // Cancel previous timer if any
      _codeErrorTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _codeError = false;
            _codeErrorMessage = null;
          });
        }
      });

      // Trigger shake animation - ShakeAnimation widget listens to _codeError
    }
  }

  void _resendCode() async {
    // Only resend if we have an email
    if (_email != null) {
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);

      // Show loading state
      setState(() {
        _isLoading = true;
      });

      // Resend OTP using forgot password functionality
      bool success = await authViewModel.forgotPassword(_email!);

      setState(() {
        _isLoading = false;
      });

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification code sent successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Failed to send verification code. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    startTimer(); // Restart the timer
    // Clear any existing combined error message when resending
    setState(() {
      _codeError = false;
      _codeErrorMessage = null;
    });
    _codeErrorTimer?.cancel(); // Cancel the timer
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
            padding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16.0), // Space below title
                // Subtitle
                Text(
                  'We have sent you an email containing 4 digits verification code. Please enter the code to verify your identity',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 40.0),
                // Code Input Fields
                ShakeAnimation(
                  shouldShake: _codeError, // Use combined error state
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children:
                        List.generate(4, (index) => _buildCodeInput(index)),
                  ),
                ),
                // Display error message below the code inputs
                if (_codeError && _codeErrorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      _codeErrorMessage!,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ),
                const SizedBox(height: 40.0),
                // Conditional area below code inputs
                _isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                          color: theme.colorScheme.primary,
                        ),
                      )
                    : _start == 0
                        ? Center(
                            child: AppButtons.primaryButton(
                              context: context,
                              onTap: _resendCode,
                              text: 'Resend Code',
                              isFilled: true,
                              horizontalPadding: 0,
                            ),
                          )
                        : Center(
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  width: 100, // Adjust size as needed
                                  height: 100,
                                  child: CircularProgressIndicator(
                                    value: _start / 60, // Value from 0.0 to 1.0
                                    strokeWidth: 6.0, // Adjust thickness
                                    backgroundColor: Colors.grey[300],
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                                Text(
                                  '00:${_start.toString().padLeft(2, '0')}',
                                  style: theme.textTheme.headlineSmall,
                                ),
                              ],
                            ),
                          ),
                const Spacer(),
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
    );
  }

  Widget _buildCodeInput(int index) {
    return ShakeAnimation(
      shouldShake: _codeError,
      child: SizedBox(
        width: 60,
        height: 60,
        child: AppTextField(
          controller: _codeControllers[index],
          focusNode: _focusNodes[index],
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 1,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return '';
            }
            if (!RegExp(r'^\d$').hasMatch(value)) {
              setState(() {
                _codeError = true;
                _codeErrorMessage = 'Please enter only numbers';
              });
              return '';
            }
            return null;
          },
          onChanged: (value) {
            if (value.isEmpty) return;

            // If input is not a number, clear it and show error
            if (!RegExp(r'^\d$').hasMatch(value)) {
              _codeControllers[index].clear();
              setState(() {
                _codeError = true;
                _codeErrorMessage = 'Please enter only numbers';
              });
              return;
            }

            // Clear any existing error when valid input is entered
            if (_codeError) {
              setState(() {
                _codeError = false;
                _codeErrorMessage = null;
              });
            }

            // Move to next field if not the last one
            if (index < 3) {
              _focusNodes[index + 1].requestFocus();
            } else {
              // If it's the last field and we have a valid number, verify the code
              _verifyCode();
            }
          },
          decoration: InputDecoration(
            counterText: "",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.grey[200],
          ),
        ),
      ),
    );
  }
}
