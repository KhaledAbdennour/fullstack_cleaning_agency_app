import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login.dart';
import 'create_account_page.dart';
import 'feature_page.dart';
import 'experience_page.dart';
import 'launch_page.dart';
import '../core/debug/debug_logger.dart';
import '../l10n/app_localizations.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  final List<Widget> _pages = const [
    FeaturePage(),
    ExperiencePage(),
    LaunchPage(),
  ];

  void _nextPage() async {
    if (_currentPage < _pages.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    } else {
      // #region agent log
      DebugLogger.log('OnboardingScreen', '_nextPage_COMPLETED', data: {
        'hypothesisId': 'H5',
        'currentPage': _currentPage,
        'totalPages': _pages.length,
        'sessionId': 'debug-session',
        'runId': 'run1',
      });
      // #endregion
      
      // Mark onboarding as seen when user completes it
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('has_seen_onboarding', true);
        
        // #region agent log
        final verified = prefs.getBool('has_seen_onboarding') ?? false;
        DebugLogger.log('OnboardingScreen', '_nextPage_MARKED_SEEN', data: {
          'hypothesisId': 'H5',
          'hasSeenOnboarding': verified,
          'verified': verified,
          'sessionId': 'debug-session',
          'runId': 'run1',
        });
        // #endregion
      } catch (e) {
        // #region agent log
        DebugLogger.error('OnboardingScreen', '_nextPage_SET_FLAG_ERROR', e, StackTrace.current, data: {
          'hypothesisId': 'H5',
          'sessionId': 'debug-session',
          'runId': 'run1',
        });
        // #endregion
      }
      
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const CreateAccountPage()),
        );
      }
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _controller.previousPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goToPage(int index) {
    if (index >= 0 && index < _pages.length && index != _currentPage) {
      _controller.animateToPage(
        index,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  void _skipToLogin() async {
    // #region agent log
    DebugLogger.log('OnboardingScreen', '_skipToLogin_CALLED', data: {
      'hypothesisId': 'H5',
      'sessionId': 'debug-session',
      'runId': 'run1',
    });
    // #endregion
    
    // Mark onboarding as seen
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_seen_onboarding', true);
      
      // #region agent log
      final verified = prefs.getBool('has_seen_onboarding') ?? false;
      DebugLogger.log('OnboardingScreen', '_skipToLogin_MARKED_SEEN', data: {
        'hypothesisId': 'H5',
        'hasSeenOnboarding': verified,
        'verified': verified,
        'sessionId': 'debug-session',
        'runId': 'run1',
      });
      // #endregion
    } catch (e) {
      // #region agent log
      DebugLogger.error('OnboardingScreen', '_skipToLogin_SET_FLAG_ERROR', e, StackTrace.current, data: {
        'hypothesisId': 'H5',
        'sessionId': 'debug-session',
        'runId': 'run1',
      });
      // #endregion
    }
    
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Login()),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                children: _pages,
              ),
            ),
            _buildIndicator(),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                children: [
                  _buildNavigationButtons(),
                  const SizedBox(height: 12),
                  _buildSecondaryButton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        _pages.length,
        (index) => GestureDetector(
          onTap: () => _goToPage(index),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.all(4),
            child: Container(
              width: _currentPage == index ? 10 : 8,
              height: _currentPage == index ? 10 : 8,
              decoration: BoxDecoration(
                color: _currentPage == index
                    ? const Color(0xFF3B82F6)
                    : const Color(0xFFD1D5DB),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationButtons() {
    final localizations = AppLocalizations.of(context)!;
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _nextPage,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF3B82F6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(
          _currentPage == 2 ? localizations.createAccount : localizations.next,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryButton() {
    final localizations = AppLocalizations.of(context)!;
    final text = _currentPage == 2 ? localizations.iAlreadyHaveAccount : localizations.skipToLogin;
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        onPressed: _skipToLogin,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFF3B82F6)),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Color(0xFF3B82F6),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}


