import 'package:flutter/material.dart';
import '../widgets/onboarding_page.dart';
import '../services/onboarding_service.dart';
import '../main.dart' show AuthGate;

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPageIndex = 0;
  final OnboardingService _onboardingService = OnboardingService();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNext() {
    if (_currentPageIndex < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  void _onSkip() {
    _finishOnboarding();
  }

  Future<void> _finishOnboarding() async {
    await _onboardingService.completeOnboarding();
    if (!mounted) return;
    
    // Smooth fade transition to AuthGate
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const AuthGate(),
        transitionDuration: const Duration(milliseconds: 500),
        transitionsBuilder: (context, anim, secondaryAnim, child) {
          return FadeTransition(
            opacity: anim,
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLastPage = _currentPageIndex == 2;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar Area (Skip Button)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _onSkip,
                    child: Text(
                      'Skip',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // PageView
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const BouncingScrollPhysics(),
                onPageChanged: (index) {
                  setState(() {
                    _currentPageIndex = index;
                  });
                },
                children: [
                  OnboardingPage(
                    title: 'Track Every Rupee',
                    description: 'Monitor your income, expenses, and savings with a clean and powerful finance tracker designed for daily use.',
                    illustration: Icon(
                      Icons.account_balance_wallet_rounded,
                      size: 100,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  OnboardingPage(
                    title: 'Manage Friend Transactions',
                    description: 'Keep track of money given to friends and money received from them with complete transparency.',
                    illustration: Icon(
                      Icons.people_alt_rounded,
                      size: 100,
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                  OnboardingPage(
                    title: 'Smart Insights & Reports',
                    description: 'Understand your spending habits through analytics, reports, and financial summaries.',
                    illustration: Icon(
                      Icons.bar_chart_rounded,
                      size: 100,
                      color: theme.colorScheme.tertiary,
                    ),
                  ),
                ],
              ),
            ),

            // Bottom Navigation Area
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Page Indicators
                  Row(
                    children: List.generate(
                      3,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(right: 8.0),
                        height: 8.0,
                        width: _currentPageIndex == index ? 24.0 : 8.0,
                        decoration: BoxDecoration(
                          color: _currentPageIndex == index
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                      ),
                    ),
                  ),
                  
                  // Next / Get Started Button
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    child: FilledButton(
                      onPressed: _onNext,
                      style: FilledButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          horizontal: isLastPage ? 32.0 : 24.0,
                          vertical: 16.0,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24.0),
                        ),
                      ),
                      child: Text(
                        isLastPage ? 'Get Started' : 'Next',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
