import 'package:flutter/material.dart';
import 'package:focusable_control_builder/focusable_control_builder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/consent_modal.dart';
import '../../../features/home/home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingData> _pages = [
    OnboardingData(
      title: 'Welcome to Lumio',
      description: 'The most advanced IPTV player for your entertainment needs.',
      icon: Icons.play_circle_filled,
    ),
    OnboardingData(
      title: 'Your Content, Your Way',
      description: 'We don\'t provide content. Add your own M3U playlists or Xtream Codes to start watching.',
      icon: Icons.add_to_queue,
    ),
    OnboardingData(
      title: 'Premium Experience',
      description: 'Enjoy a sleek, dark interface designed for the best viewing experience on any device.',
      icon: Icons.star,
    ),
  ];

  Future<void> _completeOnboarding() async {
    final accepted = await ConsentModal.show(context);
    if (accepted == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_completed', true);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: _pages.length,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemBuilder: (context, index) {
              return OnboardingPage(data: _pages[index]);
            },
          ),
          Positioned(
            bottom: 60,
            left: 24,
            right: 24,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _pages.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      height: 8,
                      width: _currentPage == index ? 24 : 8,
                      decoration: BoxDecoration(
                        color: _currentPage == index
                            ? const Color(0xFFE50914)
                            : Colors.white24,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 48),
                SizedBox(
                  width: double.infinity,
                  child: FocusableControlBuilder(
                    onPressed: () {
                      if (_currentPage < _pages.length - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        _completeOnboarding();
                      }
                    },
                    builder: (context, state) {
                      final isFocused = state.isFocused;
                      return AnimatedScale(
                        scale: isFocused ? 1.02 : 1.0,
                        duration: const Duration(milliseconds: 200),
                        child: ElevatedButton(
                          onPressed: () {
                            if (_currentPage < _pages.length - 1) {
                              _pageController.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            } else {
                              _completeOnboarding();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isFocused
                                ? const Color(0xFFE50914).withOpacity(0.8)
                                : const Color(0xFFE50914),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: isFocused
                                  ? const BorderSide(color: Colors.white, width: 2)
                                  : BorderSide.none,
                            ),
                            elevation: isFocused ? 8 : 0,
                          ),
                          child: Text(
                            _currentPage == _pages.length - 1
                                ? 'GET STARTED'
                                : 'NEXT',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (_currentPage < _pages.length - 1)
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: FocusableControlBuilder(
                      onPressed: _completeOnboarding,
                      builder: (context, state) {
                        final isFocused = state.isFocused;
                        return AnimatedScale(
                          scale: isFocused ? 1.1 : 1.0,
                          duration: const Duration(milliseconds: 200),
                          child: TextButton(
                            onPressed: _completeOnboarding,
                            style: TextButton.styleFrom(
                              foregroundColor: isFocused ? Colors.white : Colors.white54,
                              backgroundColor: isFocused ? Colors.white.withOpacity(0.1) : null,
                            ),
                            child: Text(
                              'SKIP',
                              style: TextStyle(
                                color: isFocused ? Colors.white : Colors.white54,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingData {
  final String title;
  final String description;
  final IconData icon;

  OnboardingData({
    required this.title,
    required this.description,
    required this.icon,
  });
}

class OnboardingPage extends StatelessWidget {
  final OnboardingData data;

  const OnboardingPage({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFE50914).withOpacity(0.2),
                  blurRadius: 30,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: Icon(
              data.icon,
              size: 100,
              color: const Color(0xFFE50914),
            ),
          ),
          const SizedBox(height: 60),
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            data.description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
