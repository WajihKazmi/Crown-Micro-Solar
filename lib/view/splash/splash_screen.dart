import 'package:flutter/material.dart';
import 'package:crown_micro_solar/routes/app_routes.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
      // Add a small delay for splash screen visibility
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;

      final prefs = await SharedPreferences.getInstance();
      final onboardingComplete = prefs.getBool('onboarding_complete') ?? false;
      final isLoggedIn = prefs.getBool('loggedin') ?? false;

      // Mark initialized (no longer tracked with a field)

      if (!onboardingComplete) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.onboarding);
        return;
      }

      // Onboarding done; decide between home or login.
      if (isLoggedIn) {
        // Go directly to home (root stack replace)
        Navigator.of(context).pushReplacementNamed(AppRoutes.homeInternal);
      } else {
        Navigator.of(context).pushReplacementNamed(AppRoutes.login);
      }
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
      body: Center(
        child: _error != null
            ? Column(
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
              )
            : const CircularProgressIndicator(),
      ),
    );
  }
}
