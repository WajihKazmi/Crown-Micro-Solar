import 'package:flutter/material.dart';
import 'package:crown_micro_solar/routes/app_routes.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:crown_micro_solar/presentation/viewmodels/auth_viewmodel.dart';
import 'package:crown_micro_solar/view/splash/splash.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String? _error;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      // Quick micro delay to allow first frame
      await Future.delayed(const Duration(milliseconds: 200));
      if (!mounted) return;

      final prefs = await SharedPreferences.getInstance();
      final onboardingComplete = prefs.getBool('onboarding_complete') ?? false;
      final savedUsername = prefs.getString('Username');
      final savedPassword = prefs.getString('pass');

      // Mark initialized (no longer tracked with a field)

      if (!onboardingComplete) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.onboarding);
        return;
      }

      // Onboarding done; enforce robust session: ALWAYS try auto re-login with saved credentials
      if (savedUsername != null && savedPassword != null) {
        final auth = Provider.of<AuthViewModel>(context, listen: false);
        final ok = await auth.login(savedUsername, savedPassword);
        if (ok && mounted) {
          Navigator.of(context).pushReplacementNamed(AppRoutes.homeInternal);
          return;
        }
        // If auto login fails, fall back to login screen
        if (mounted) {
          Navigator.of(context).pushReplacementNamed(AppRoutes.login);
          return;
        }
      }

      // No saved credentials; rely on stored login flag
      final isLoggedIn = prefs.getBool('loggedin') ?? false;
      Navigator.of(context).pushReplacementNamed(
          isLoggedIn ? AppRoutes.homeInternal : AppRoutes.login);
    } catch (e) {
      print('Error during initialization: $e');
      if (!mounted) return;
      setState(() {
        _error = 'Failed to initialize app. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
              ),
            )
          : const Splash(),
    );
  }
}
