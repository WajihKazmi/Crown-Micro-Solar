import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../routes/app_routes.dart';
import '../../core/utils/app_buttons.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_text_fields.dart';
import '../../presentation/viewmodels/auth_viewmodel.dart';
import '../../view/home/home_screen.dart';
import 'package:logger/logger.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  static const String routeName = AppRoutes.login;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isInstallerMode = false;
  final _logger = Logger();

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _userIdController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final viewModel = context.read<AuthViewModel>();
    final credentials = await viewModel.getSavedCredentials();
    if (credentials['username'] != null && credentials['password'] != null) {
      setState(() {
        _userIdController.text = credentials['username']!;
        _passwordController.text = credentials['password']!;
      });
    }
  }

  @override
  void dispose() {
    _userIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    print("hit login");
    // Only validate if fields are empty
    if (_userIdController.text.isEmpty || _passwordController.text.isEmpty) {
      _formKey.currentState?.validate();
      return;
    }

    final viewModel = context.read<AuthViewModel>();
    viewModel.setInstallerMode(_isInstallerMode);

    try {
      final success = await viewModel.login(
        _userIdController.text,
        _passwordController.text,
      );

      if (mounted) {
        if (success) {
          if (viewModel.agentsList != null) {
            _showAgentSelectionDialog();
          } else {
            // Navigate to home screen
            Navigator.of(context).pushReplacement(
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    const HomeScreen(),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                  const begin = Offset(1.0, 0.0);
                  const end = Offset.zero;
                  const curve = Curves.easeInOut;
                  var tween = Tween(begin: begin, end: end)
                      .chain(CurveTween(curve: curve));
                  var offsetAnimation = animation.drive(tween);
                  return SlideTransition(
                      position: offsetAnimation, child: child);
                },
                transitionDuration: const Duration(milliseconds: 500),
              ),
            );
          }
    } else {
          // Show error message if login failed
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text(viewModel.error ?? 'Login failed. Please try again.'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An error occurred: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _showAgentSelectionDialog() {
    final viewModel = context.read<AuthViewModel>();
    final agentsList = viewModel.agentsList;

    if (agentsList == null) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
          title: const Text(
            'Tap to login',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              fontFamily: "Roboto",
              letterSpacing: 1,
              color: Colors.red,
            ),
          ),
          content: SizedBox(
            width: 200,
            height: 300,
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              itemCount: agentsList.length,
              itemBuilder: (BuildContext context, int index) {
                return ListTile(
                  trailing: const Icon(Icons.arrow_right),
                  title: Text(
                    'SN: ${agentsList[index]['SNNumber']}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      fontFamily: "Roboto",
                      letterSpacing: 1,
                      color: Colors.black,
                    ),
                  ),
                  subtitle: Text(
                    'Username: ${agentsList[index]['Username']}'.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      fontFamily: "Roboto",
                      letterSpacing: 1,
                      color: Colors.black,
                    ),
                  ),
                  onTap: () async {
                    Navigator.of(context).pop();
                    final success = await viewModel.loginAgent(
                      agentsList[index]['Username'],
                      agentsList[index]['Password'],
                    );

                    if (mounted) {
                      if (success) {
                        Navigator.of(context).pushReplacement(
                          PageRouteBuilder(
                            pageBuilder:
                                (context, animation, secondaryAnimation) =>
                                    const HomeScreen(),
                            transitionsBuilder: (context, animation,
                                secondaryAnimation, child) {
                              const begin = Offset(1.0, 0.0);
                              const end = Offset.zero;
                              const curve = Curves.easeInOut;
                              var tween = Tween(begin: begin, end: end)
                                  .chain(CurveTween(curve: curve));
                              var offsetAnimation = animation.drive(tween);
                              return SlideTransition(
                                  position: offsetAnimation, child: child);
                            },
                            transitionDuration:
                                const Duration(milliseconds: 500),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content:
                                Text(viewModel.error ?? 'Agent login failed'),
                            backgroundColor: Colors.red,
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      }
                    }
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _showWifiConfigDialog() {
    _logger.i('Opening Wi-Fi Configuration dialog');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Wi-Fi Configuration'),
        content: const Text('Wi-Fi configuration feature coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSupportDialog() {
    _logger.i('Opening Support dialog');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contact Support'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('For support, please contact:'),
            const SizedBox(height: 8),
            const Text('Email: support@crownmicrosolar.com'),
            const SizedBox(height: 4),
            const Text('Phone: +1 (555) 123-4567'),
            const SizedBox(height: 4),
            const Text('Hours: Mon-Fri, 9AM-5PM EST'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final viewModel = context.watch<AuthViewModel>();

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 20),
            child: Form(
              key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 60.0),
                    Text(
                      'Welcome Back',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 15.0),
                    Text(
                      'Enter the data below to get a verification code',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 20.0),
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
                    ),
                    const SizedBox(height: 15.0),
                    Text(
                      'Password',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5.0),
                    AppTextField(
                      controller: _passwordController,
                        hintText: 'Enter your password',
                      isPassword: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        return null;
                      },
                    ),
                      const SizedBox(height: 15.0),
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
                                activeColor: Colors.green,
                            ),
                            Text(
                              'Installer Mode',
                              style: theme.textTheme.bodyMedium!
                                  .copyWith(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: () {
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
                      const SizedBox(height: 20.0),
                    AppButtons.primaryButton(
                        horizontalPadding: 0,
                      context: context,
                        text: viewModel.isLoading ? 'Logging in...' : 'Login',
                        onTap: _login,
                        isLoading: viewModel.isLoading,
                    ),
                    const SizedBox(height: 10.0),
                    AppButtons.primaryButton(
                      context: context,
                        onTap: _showWifiConfigDialog,
                      text: 'Wi-Fi Configuration',
                      isFilled: false,
                      textColor: Colors.black,
                        horizontalPadding: 0,
                    ),
                    const SizedBox(height: 10.0),
                    AppButtons.primaryButton(
                      context: context,
                      onTap: () {
                          Navigator.of(context)
                              .pushNamed(AppRoutes.registration);
                      },
                      text: 'Register',
                      isFilled: false,
                      textColor: Colors.black,
                        horizontalPadding: 0,
                    ),
                    const SizedBox(height: 15.0),
                    TextButton.icon(
                        onPressed: _showSupportDialog,
                      icon: Image.asset(
                          'assets/icons/support.png',
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
                  ],
                ),
                Padding(
                  padding: const EdgeInsetsGeometry.symmetric(vertical: 0),
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