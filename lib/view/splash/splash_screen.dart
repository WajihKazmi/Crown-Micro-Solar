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
    final start = DateTime.now();
    try {
      // Ensure first frame then proceed
      await Future.delayed(const Duration(milliseconds: 200));
      if (!mounted) return;

      final prefs = await SharedPreferences.getInstance();
      final onboardingComplete = prefs.getBool('onboarding_complete') ?? false;
      final savedUsername = prefs.getString('Username');
      final savedPassword = prefs.getString('pass');
      final isLoggedIn = prefs.getBool('loggedin') ?? false;
      final token = prefs.getString('token');

      // Mark initialized (no longer tracked with a field)

      if (!onboardingComplete) {
        // Ensure minimum splash time of 2s
        final elapsed = DateTime.now().difference(start);
        final remaining = const Duration(seconds: 2) - elapsed;
        if (remaining.inMilliseconds > 0) {
          await Future.delayed(remaining);
        }
        Navigator.of(context).pushReplacementNamed(AppRoutes.onboarding);
        return;
      }

      // If we have an active session (token + loggedin), go straight to home.
      // Do NOT block on re-login; this preserves session across minimize/offline restarts.
      if (isLoggedIn && token != null && token.isNotEmpty) {
        final elapsed = DateTime.now().difference(start);
        final remaining = const Duration(seconds: 2) - elapsed;
        if (remaining.inMilliseconds > 0) {
          await Future.delayed(remaining);
        }
        Navigator.of(context).pushReplacementNamed(AppRoutes.homeInternal);
        return;
      }

      // Otherwise, attempt auto-login if credentials are saved
      if (savedUsername != null && savedPassword != null) {
        final auth = Provider.of<AuthViewModel>(context, listen: false);
        final ok = await auth.login(savedUsername, savedPassword);
        final elapsed = DateTime.now().difference(start);
        final remaining = const Duration(seconds: 2) - elapsed;
        if (remaining.inMilliseconds > 0) {
          await Future.delayed(remaining);
        }
        Navigator.of(context).pushReplacementNamed(
            ok ? AppRoutes.homeInternal : AppRoutes.login);
        return;
      }

      // Fallback: route based on loggedin flag (even if token missing, allow app to handle gracefully)
      final elapsed = DateTime.now().difference(start);
      final remaining = const Duration(seconds: 2) - elapsed;
      if (remaining.inMilliseconds > 0) {
        await Future.delayed(remaining);
      }
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
