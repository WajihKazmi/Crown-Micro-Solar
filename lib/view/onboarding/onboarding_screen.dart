import 'package:flutter/material.dart';
import 'onboarding_page.dart';
import '../../routes/app_routes.dart'; // Assuming you have defined routes here
import '../../core/utils/app_buttons.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController(initialPage: 0);
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
    });
  }

  void _skipOnboarding() {
    // Navigate to the next screen, e.g., login screen or home screen
    Navigator.of(context)
        .pushReplacementNamed(AppRoutes.login); // Navigate to the login route
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            children: const [
              OnboardingPage(
                imagePath: 'assets/images/onboarding_vector.png',
                title: 'Live Status, Every\nSecond Counts',
                description:
                    'Get real-time updates on solar input,\nbattery levels, and power usage.',
              ),
              OnboardingPage(
                imagePath: 'assets/images/onboarding_vector.png',
                title: 'Stay Ahead\nOf Problems',
                description:
                    'Get notified instantly if something goes\nwrong—before it becomes critical.',
              ),
              OnboardingPage(
                imagePath: 'assets/images/onboarding_vector.png',
                title: 'Track Savings,\nMaximize Efficiency',
                description:
                    'Monitor how much energy you\'re\nproducing and saving every day.',
              ),
            ],
          ),
          Positioned(
            bottom: 110.0,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children:
                  List.generate(3, (index) => _buildDotIndicator(index, theme)),
            ),
          ),
          Positioned(
            bottom: 30.0,
            left: 0,
            right: 0,
            child: _currentPage == 2
                ? AppButtons.primaryButton(
                    context: context,
                    onTap: _skipOnboarding,
                    text: 'Get Started',
                    isFilled: true,
                  )
                : AppButtons.primaryButton(
                    context: context,
                    onTap: () {
                      _pageController.animateToPage(
                        2,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    text: 'Skip',
                    isFilled: false,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDotIndicator(int index, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
      width: _currentPage == index ? 24.0 : 8.0,
      height: 8.0,
      decoration: BoxDecoration(
        color: _currentPage == index
            ? theme.colorScheme.primary
            : theme.colorScheme.secondary,
        borderRadius: BorderRadius.circular(4.0),
      ),
    );
  }
}
