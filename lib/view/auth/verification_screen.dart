import 'package:crown_micro_solar/core/utils/app_text_fields.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import '../../routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_animations.dart';
import '../../core/utils/app_buttons.dart'; // Import AppButtons
import 'forgot_password_screen.dart'; // Import RecoveryMode enum

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
      final mode = ModalRoute.of(context)?.settings.arguments as RecoveryMode?;
      if (mode != null) {
        setState(() {
          _recoveryMode = mode;
        });
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
    // Combine code from all controllers
    final enteredCode =
        _codeControllers.map((controller) => controller.text).join();

    // Validate the combined code
    if (enteredCode.length == 4 && RegExp(r'^\d{4}').hasMatch(enteredCode)) {
      setState(() {
        _codeError = false; // Clear combined error on success
        _codeErrorMessage = null;
        _isLoading = true;
      });
      // TODO: Implement actual code verification logic
      // For now, simulate a delay
      await Future.delayed(const Duration(seconds: 2));

      setState(() {
        _isLoading = false;
        // TODO: Navigate or show success/error based on verification result

        // Navigate based on recovery mode
        if (_recoveryMode == RecoveryMode.password) {
          Navigator.of(context).pushReplacementNamed(AppRoutes.resetPassword);
        } else {
          Navigator.of(context).pushReplacementNamed(AppRoutes.changeUserId);
        }
      });
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

  void _resendCode() {
    // TODO: Implement resend code logic
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: Text(
          'Verification Code!',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
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
            padding: const EdgeInsets.all(24.0),
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
