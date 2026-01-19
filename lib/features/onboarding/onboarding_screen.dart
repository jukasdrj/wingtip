import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wingtip/core/theme.dart';
import 'package:wingtip/features/camera/permission_primer_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    // Light haptic feedback on completion
    HapticFeedback.lightImpact();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);

    if (!mounted) return;

    // Navigate to permission primer (integrates with US-128)
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const PermissionPrimerScreen(),
      ),
    );
  }

  void _nextPage() {
    HapticFeedback.lightImpact();
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _skipOnboarding() {
    HapticFeedback.lightImpact();
    _completeOnboarding();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.oledBlack,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextButton(
                  onPressed: _skipOnboarding,
                  child: Text(
                    'Skip',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              ),
            ),

            // Carousel
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _currentPage = index;
                  });
                },
                children: const [
                  _OnboardingSlide1(),
                  _OnboardingSlide2(),
                  _OnboardingSlide3(),
                ],
              ),
            ),

            // Page indicators
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4.0),
                    width: _currentPage == index ? 24.0 : 8.0,
                    height: 8.0,
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? AppTheme.internationalOrange
                          : AppTheme.borderGray,
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                  );
                }),
              ),
            ),

            // Next/Get Started button
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: SizedBox(
                height: 56,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _nextPage,
                  child: Text(_currentPage == 2 ? 'Get Started' : 'Next'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Slide 1: The Shutter That Remembers
class _OnboardingSlide1 extends StatelessWidget {
  const _OnboardingSlide1();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Bookshelf visual (using simple icon representation)
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              border: Border.all(
                color: AppTheme.borderGray,
                width: 1.0,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.camera_alt_outlined,
                  size: 80,
                  color: AppTheme.internationalOrange,
                ),
                SizedBox(height: 16),
                Icon(
                  Icons.auto_stories_outlined,
                  size: 60,
                  color: AppTheme.textPrimary,
                ),
              ],
            ),
          ),

          const SizedBox(height: 48),

          // Title
          Text(
            'The Shutter That Remembers',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 24),

          // Description
          Text(
            'Point your camera at any bookshelf. Wingtip sees every spine, identifies each book, and builds your library instantly.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// Slide 2: Local-First Library
class _OnboardingSlide2 extends StatelessWidget {
  const _OnboardingSlide2();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Local-first visual
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              border: Border.all(
                color: AppTheme.borderGray,
                width: 1.0,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.phone_iphone,
                  size: 80,
                  color: AppTheme.internationalOrange,
                ),
                SizedBox(height: 16),
                Icon(
                  Icons.lock_outline,
                  size: 60,
                  color: AppTheme.textPrimary,
                ),
              ],
            ),
          ),

          const SizedBox(height: 48),

          // Title
          Text(
            'Local-First Library',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 24),

          // Description
          Text(
            'Your data lives on your device. Browse, search, and organize offline. No cloud accounts, no subscriptions, no surveillance.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// Slide 3: Grant Camera Access (integrates with US-128)
class _OnboardingSlide3 extends StatelessWidget {
  const _OnboardingSlide3();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Camera permission visual
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              border: Border.all(
                color: AppTheme.borderGray,
                width: 1.0,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.camera_alt,
                  size: 100,
                  color: AppTheme.internationalOrange,
                ),
                SizedBox(height: 16),
                Icon(
                  Icons.check_circle_outline,
                  size: 40,
                  color: AppTheme.textPrimary,
                ),
              ],
            ),
          ),

          const SizedBox(height: 48),

          // Title
          Text(
            'Grant Camera Access',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 24),

          // Description
          Text(
            'Wingtip needs your camera to see books. Images are processed and deleted instantly. No photos are saved or uploaded.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
