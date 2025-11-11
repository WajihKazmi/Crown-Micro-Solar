import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:crown_micro_solar/core/utils/app_buttons.dart';
import 'package:crown_micro_solar/core/utils/app_text_fields.dart';
import 'package:crown_micro_solar/presentation/viewmodels/auth_viewmodel.dart';
import 'package:crown_micro_solar/routes/app_routes.dart';
import 'package:crown_micro_solar/view/home/home_screen.dart';
import 'package:crown_micro_solar/core/utils/navigation_service.dart';
import 'package:logger/logger.dart';
import 'package:app_settings/app_settings.dart';
import 'package:crown_micro_solar/view/home/wifi_module_webview.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  static const String routeName = AppRoutes.login;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isInstallerMode = false;
  bool _rememberMe = false;
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
        _rememberMe = true; // If credentials are saved, remember me was checked
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
        rememberMe: _rememberMe,
      );

      if (mounted) {
        if (success) {
          if (viewModel.agentsList != null && _isInstallerMode) {
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
          // Show error message if login failed (AlertDialog, not SnackBar)
          await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Login Error'),
              content:
                  Text(viewModel.error ?? 'Login failed. Please try again.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Login Error'),
            content: Text('An error occurred: ${e.toString()}'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
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
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () async {
                // Reset installer state and close
                await viewModel.clearInstallerState();
                setState(() {
                  _isInstallerMode = false;
                });
                Navigator.of(dialogContext).pop();
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
              color: Colors.black,
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
                    // Close dialog first
                    Navigator.of(dialogContext).pop();

                    // Perform login
                    final success = await viewModel.loginAgent(
                      agentsList[index]['Username'],
                      agentsList[index]['Password'],
                    );

                    // Handle result using NavigationService
                    if (success) {
                      // Navigate to home screen using NavigationService
                      NavigationService.pushAndRemoveUntil(
                        PageRouteBuilder(
                          pageBuilder:
                              (context, animation, secondaryAnimation) =>
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
                        (route) => false, // Remove all previous routes
                      );
                    } else {
                      // Show error message safely using a delayed callback
                      Future.delayed(const Duration(milliseconds: 100), () {
                        if (NavigationService.navigatorKey.currentContext !=
                            null) {
                          ScaffoldMessenger.of(NavigationService
                                  .navigatorKey.currentContext!)
                              .showSnackBar(
                            SnackBar(
                              content: Text(
                                viewModel.error ?? 'Agent login failed',
                                style: const TextStyle(color: Colors.black),
                              ),
                              backgroundColor: Colors.white,
                              duration: const Duration(seconds: 3),
                            ),
                          );
                        }
                      });
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
    _logger.i('Opening Wi‑Fi Configuration dialog');
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Expanded(
                    child: Text('Wi‑Fi Configuration',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700))),
                IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close))
              ]),
              const SizedBox(height: 8),
              const Text(
                '1) Connect your phone to the Wi‑Fi whose SSID matches the module PN.\n'
                '2) Open the module network page to set STA Wi‑Fi credentials and restart.',
                style: TextStyle(color: Colors.black54, fontSize: 13),
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                    child: OutlinedButton(
                        onPressed: () async {
                          print('Open Wi-Fi Settings button tapped');
                          Navigator.of(ctx).pop();
                          await AppSettings.openAppSettingsPanel(
                              AppSettingsPanelType.wifi);
                        },
                        child: const Text('Open Wi‑Fi Settings'))),
                const SizedBox(width: 10),
                Expanded(
                    child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            foregroundColor:
                                Theme.of(context).colorScheme.onPrimary),
                        onPressed: () {
                          print('Open Network Page button tapped');
                          Navigator.of(ctx).pop();
                          Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => const WifiModuleWebView()));
                        },
                        child: const Text('Open Network Page')))
              ])
            ],
          ),
        ),
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
                        children: [
                          Checkbox(
                            value: _rememberMe,
                            onChanged: (value) {
                              setState(() {
                                _rememberMe = value ?? false;
                              });
                            },
                            activeColor: theme.colorScheme.primary,
                          ),
                          Text(
                            'Remember Me',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
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
                        onPressed: () {
                          // Redirect to WhatsApp support screen
                          Navigator.of(context).pushNamed(AppRoutes.whatsapp);
                        },
                        icon: Image.asset(
                          'assets/icons/whatsapp.png',
                          width: 24,
                          height: 24,
                        ),
                        label: Text(
                          'Contact via WhatsApp',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.green[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 0),
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
