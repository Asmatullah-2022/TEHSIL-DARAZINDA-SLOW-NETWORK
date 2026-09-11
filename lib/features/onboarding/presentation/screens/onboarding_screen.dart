import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class _OnboardingPage {
  const _OnboardingPage(this.icon, this.title, this.body);
  final IconData icon;
  final String title;
  final String body;
}

const List<_OnboardingPage> _pages = [
  _OnboardingPage(
    Icons.speed,
    'Measure Your Network',
    'Test your real signal strength, download/upload speed and latency '
        'in seconds.',
  ),
  _OnboardingPage(
    Icons.map_outlined,
    'Map Connectivity',
    'See a live community map of signal quality across Darazinda Tehsil.',
  ),
  _OnboardingPage(
    Icons.report_problem_outlined,
    'Report Problems',
    'Submit evidence-based reports with GPS location, operator and '
        'measurement data.',
  ),
  _OnboardingPage(
    Icons.fact_check_outlined,
    'Build Evidence',
    'Help build the evidence needed for better connectivity in your area.',
  ),
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _index = 0;

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_seen', true);
    if (!mounted) return;
    context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final bool isLast = _index == _pages.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _finish,
                child: const Text('Skip'),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) {
                  final page = _pages[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlue.withOpacity(0.08),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(page.icon,
                              size: 56, color: AppColors.primaryBlue),
                        ),
                        const SizedBox(height: 32),
                        Text(page.title,
                            style: AppTextStyles.headline,
                            textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        Text(page.body,
                            style: AppTextStyles.bodySecondary,
                            textAlign: TextAlign.center),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: i == _index ? 22 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: i == _index
                        ? AppColors.primaryBlue
                        : AppColors.divider,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (isLast) {
                      _finish();
                    } else {
                      _controller.nextPage(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                      );
                    }
                  },
                  child: Text(isLast ? 'Get Started' : 'Next'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
