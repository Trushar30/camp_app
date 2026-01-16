/// Splash Screen - Premium animated experience
library;

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/logo_widget.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _gradientController;
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _loaderController;

  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _textOpacity;
  late Animation<Offset> _textSlide;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAnimations();
    });
  }

  void _initAnimations() {
    // Gradient animation
    _gradientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    // Logo animation
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _logoScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );
    _logoOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0, 0.5, curve: Curves.easeOut),
      ),
    );

    // Text animation
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _textOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOut),
    );
    _textSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _textController, curve: Curves.easeOut));

    // Loader animation
    _loaderController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  void _startAnimations() async {
    _logoController.forward();
    await Future.delayed(const Duration(milliseconds: 400));
    _textController.forward();
    await Future.delayed(const Duration(milliseconds: 1800));
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    if (!mounted) return;

    final authProvider = context.read<AuthProvider>();
    await authProvider.initialize();

    if (!mounted) return;

    if (authProvider.isLoggedIn) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  void dispose() {
    _gradientController.dispose();
    _logoController.dispose();
    _textController.dispose();
    _loaderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _gradientController,
        builder: (context, child) {
          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.lerp(
                    const Color(0xFF1E3A8A),
                    const Color(0xFF1E40AF),
                    (math.sin(_gradientController.value * math.pi * 2) + 1) / 2,
                  )!,
                  Color.lerp(
                    const Color(0xFF1E40AF),
                    const Color(0xFF3B82F6),
                    (math.cos(_gradientController.value * math.pi * 2) + 1) / 2,
                  )!,
                ],
              ),
            ),
            child: child,
          );
        },
        child: Stack(
          children: [
            // Floating particles effect
            ...List.generate(6, (index) => _FloatingParticle(
              delay: index * 0.2,
              controller: _gradientController,
              index: index,
            )),
            
            // Main content
            SafeArea(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo with glow
                    AnimatedBuilder(
                      animation: _logoController,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _logoOpacity.value,
                          child: Transform.scale(
                            scale: _logoScale.value,
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.white.withOpacity(0.3 * _logoOpacity.value),
                                    blurRadius: 40,
                                    spreadRadius: 10,
                                  ),
                                ],
                              ),
                              child: const LogoWidget(size: 140, withText: false),
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 32),

                    // App Name
                    AnimatedBuilder(
                      animation: _textController,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _textOpacity.value,
                          child: SlideTransition(
                            position: _textSlide,
                            child: const Text(
                              'CampusEase',
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 12),

                    // Tagline
                    AnimatedBuilder(
                      animation: _textController,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _textOpacity.value,
                          child: Text(
                            'Your Complete Campus Companion',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white.withOpacity(0.9),
                              letterSpacing: 0.5,
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 60),

                    // Wave loader
                    _WavyLoader(controller: _loaderController),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FloatingParticle extends StatelessWidget {
  final double delay;
  final AnimationController controller;
  final int index;

  const _FloatingParticle({
    required this.delay,
    required this.controller,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final random = math.Random(index);
    final startX = random.nextDouble() * size.width;
    final startY = random.nextDouble() * size.height;
    final particleSize = 4.0 + random.nextDouble() * 8;

    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final progress = (controller.value + delay) % 1.0;
        final y = startY + math.sin(progress * math.pi * 2) * 30;
        final x = startX + math.cos(progress * math.pi * 2 + index) * 20;
        final opacity = 0.1 + (math.sin(progress * math.pi) * 0.2);

        return Positioned(
          left: x,
          top: y,
          child: Container(
            width: particleSize,
            height: particleSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(opacity),
            ),
          ),
        );
      },
    );
  }
}

class _WavyLoader extends StatelessWidget {
  final AnimationController controller;

  const _WavyLoader({required this.controller});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      height: 24,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(5, (index) {
          return AnimatedBuilder(
            animation: controller,
            builder: (context, child) {
              final delay = index / 5;
              final value = math.sin((controller.value + delay) * 2 * math.pi);
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: 6,
                height: 12 + 12 * ((value + 1) / 2),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.5 + 0.5 * ((value + 1) / 2)),
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}

