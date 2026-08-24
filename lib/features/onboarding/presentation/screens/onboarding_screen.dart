import 'package:flutter/material.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _step = 0;

  static const _steps = [
    _OnboardingStepData(
      title: 'Welcome to PNYP',
      description: 'Your platform for youth empowerment, events, and community engagement.',
      icon: Icons.volunteer_activism_rounded,
      color: Color(0xFF1A3A5C),
    ),
    _OnboardingStepData(
      title: 'Stay Updated',
      description: 'Get the latest news, event announcements, and important updates.',
      icon: Icons.notifications_active_rounded,
      color: Color(0xFF2E7D32),
    ),
    _OnboardingStepData(
      title: 'Get Involved',
      description: 'Register for events, apply for volunteer opportunities, and grow with us.',
      icon: Icons.people_rounded,
      color: Color(0xFF1565C0),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final data = _steps[_step];

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        color: data.color.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(data.icon, size: 80, color: data.color),
                    ),
                    const SizedBox(height: 48),
                    Text(
                      data.title,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: data.color,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      data.description,
                      style: Theme.of(context).textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              Row(
                children: List.generate(_steps.length, (index) {
                  final isActive = index == _step;
                  return Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: isActive ? data.color : Colors.grey[300],
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => _handleNext(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: data.color,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(_step == _steps.length - 1 ? 'Get Started' : 'Continue'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleNext(BuildContext context) {
    if (_step < _steps.length - 1) {
      setState(() => _step++);
    } else {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }
}

class _OnboardingStepData {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  const _OnboardingStepData({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}
