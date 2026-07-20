import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';

/// Splash screen with fade-in + scale animation.
/// Shown for [AppConstants.splashDuration] then auto-navigates to /home.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.65, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOutBack),
      ),
    );

    _controller.forward();

    Future.delayed(AppConstants.splashDuration, () {
      if (mounted) {
        context.go('/home');
      }
    });
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
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeAnimation.value,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: child,
              ),
            );
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                AppConstants.splashLogo,
                width: 120,
                height: 120,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.offline_bolt,
                  size: 96,
                  color: Color(0xFF1D4ED8),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'CSC Smart Toolkit',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Offline · Secure · Fast',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748B),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
