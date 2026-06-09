import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_screen.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _revealController;
  late AnimationController _pulseController;
  late AnimationController _loaderController;

  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _textOpacity;

  @override
  void initState() {
    super.initState();

    // 1. Logo Reveal Animation (0.0 to 1.5 seconds)
    _revealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _logoScale = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(
        parent: _revealController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _revealController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _textOpacity = Tween<double>(begin: 0.0, end: 0.9).animate(
      CurvedAnimation(
        parent: _revealController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeIn),
      ),
    );

    // 2. Continuous Ambient Pulse Animation
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    // 3. Apple-style Loading Bar (0.5 to 2.8 seconds)
    _loaderController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    // Start intro animations
    _revealController.forward();
    
    // Delayed start for progress loader
    Timer(const Duration(milliseconds: 400), () {
      if (mounted) {
        _loaderController.forward().then((_) => _navigateBasedOnSession());
      }
    });
  }

  @override
  void dispose() {
    _revealController.dispose();
    _pulseController.dispose();
    _loaderController.dispose();
    super.dispose();
  }

  void _navigateBasedOnSession() {
    if (mounted) {
      final session = Supabase.instance.client.auth.currentSession;
      final targetScreen = session != null ? const HomeScreen() : const LoginScreen();

      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => targetScreen,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 1000),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background Glow Centered
          Center(
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                double scaleGlow = 1.0 + (_pulseController.value * 0.1);
                double opacityGlow = 0.02 + (_pulseController.value * 0.02);
                return Transform.scale(
                  scale: scaleGlow,
                  child: Container(
                    width: 260,
                    height: 260,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFBF5AF2).withOpacity(opacityGlow),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0A84FF).withOpacity(opacityGlow * 1.2),
                          blurRadius: 120,
                          spreadRadius: 20,
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Central Elements Centered
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Logo Symbol Reveal
                AnimatedBuilder(
                  animation: _revealController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _logoOpacity.value,
                      child: Transform.scale(
                        scale: _logoScale.value,
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF0A0A0A),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.05),
                              width: 1,
                            ),
                          ),
                          child: const Icon(
                            LucideIcons.brainCircuit,
                            color: Colors.white,
                            size: 36,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 28),

                // Title Typography Reveal (Using Plus Jakarta Sans instead of Syne)
                AnimatedBuilder(
                  animation: _revealController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _textOpacity.value,
                      child: Column(
                        children: [
                          Text(
                            "SocialSync",
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "YOUR COMMUNICATION COACH",
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white30,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 48),

                // Apple-style Minimal Progress Loader
                AnimatedBuilder(
                  animation: _loaderController,
                  builder: (context, child) {
                    return Container(
                      width: 120,
                      height: 2,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(1),
                      ),
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: _loaderController.value,
                        child: Container(
                          height: 2,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // Bottom calming tagline
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: AnimatedBuilder(
                animation: _revealController,
                builder: (context, child) {
                  return Opacity(
                    opacity: _textOpacity.value * 0.4,
                    child: Text(
                      "Designed for comfort & connection // © 2026",
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white38,
                        fontSize: 9,
                        letterSpacing: 0.5,
                      ),
                    ),
                  );
                },
              ),
            ),
          )
        ],
      ),
    );
  }
}
