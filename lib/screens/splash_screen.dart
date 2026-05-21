import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // --- Controllers ---
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _progressController;
  late AnimationController _particleController;

  // --- Logo animations ---
  late Animation<double> _logoScale;
  late Animation<double> _logoFade;
  late Animation<double> _logoRotate;
  late Animation<double> _ringScale;
  late Animation<double> _ringFade;

  // --- Text animations ---
  late Animation<double> _titleSlide;
  late Animation<double> _titleFade;
  late Animation<double> _subtitleSlide;
  late Animation<double> _subtitleFade;
  late Animation<double> _taglineFade;

  // --- Progress ---
  late Animation<double> _progressValue;
  late Animation<double> _progressFade;

  // --- Particles ---
  late Animation<double> _particleAnim;
  final List<_Particle> _particles = [];
  final math.Random _random = math.Random();

  // Brand colors matching the app icon
  static const Color kNavyDark = Color(0xFF0A1628);
  static const Color kNavyMid = Color(0xFF1E3A5F);
  static const Color kTeal = Color(0xFF00D4AA);
  static const Color kTealDark = Color(0xFF00A882);
  static const Color kAmber = Color(0xFFFFD166);

  @override
  void initState() {
    super.initState();

    // Force dark status bar icons
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    _generateParticles();
    _setupAnimations();
    _startSequence();
  }

  void _generateParticles() {
    for (int i = 0; i < 18; i++) {
      _particles.add(
        _Particle(
          x: _random.nextDouble(),
          y: _random.nextDouble(),
          size: _random.nextDouble() * 3 + 1,
          opacity: _random.nextDouble() * 0.35 + 0.05,
          speed: _random.nextDouble() * 0.4 + 0.1,
          color: i % 3 == 0
              ? kTeal
              : i % 3 == 1
              ? kAmber
              : Colors.white,
        ),
      );
    }
  }

  void _setupAnimations() {
    // Particle drift — continuous
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
    _particleAnim = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(_particleController);

    // Logo entrance
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );
    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );
    _logoRotate = Tween<double>(begin: -0.3, end: 0.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );
    _ringScale = Tween<double>(
      begin: 0.6,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _logoController, curve: Curves.easeOut));
    _ringFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeIn),
      ),
    );

    // Text stagger
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _titleSlide = Tween<double>(begin: 40.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
      ),
    );
    _titleFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );
    _subtitleSlide = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
      ),
    );
    _subtitleFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.2, 0.7, curve: Curves.easeIn),
      ),
    );
    _taglineFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
      ),
    );

    // Progress bar
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _progressValue = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );
    _progressFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _progressController,
        curve: const Interval(0.0, 0.2, curve: Curves.easeIn),
      ),
    );
  }

  void _startSequence() async {
    // Logo pops in first
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    _logoController.forward();

    // Text slides in after logo
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    _textController.forward();

    // Progress bar starts
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    _progressController.forward();

    // Navigate when done
    await Future.delayed(const Duration(milliseconds: 2200));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const HomeScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeIn),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _progressController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: kNavyDark,
      body: Stack(
        children: [
          // --- Background gradient ---
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [kNavyMid, kNavyDark, Color(0xFF050E1A)],
                stops: [0.0, 0.55, 1.0],
              ),
            ),
          ),

          // --- Ambient glow top-right (teal) ---
          Positioned(
            top: -80,
            right: -80,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kTeal.withValues(alpha: 0.07),
              ),
            ),
          ),

          // --- Ambient glow bottom-left (amber) ---
          Positioned(
            bottom: -60,
            left: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kAmber.withValues(alpha: 0.05),
              ),
            ),
          ),

          // --- Floating particles ---
          AnimatedBuilder(
            animation: _particleAnim,
            builder: (context, _) {
              return CustomPaint(
                size: size,
                painter: _ParticlePainter(
                  particles: _particles,
                  progress: _particleAnim.value,
                ),
              );
            },
          ),

          // --- Subtle grid lines ---
          CustomPaint(size: size, painter: _GridPainter()),

          // --- Main content ---
          SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 3),

                // Logo
                AnimatedBuilder(
                  animation: _logoController,
                  builder: (context, _) {
                    return FadeTransition(
                      opacity: _logoFade,
                      child: Transform.rotate(
                        angle: _logoRotate.value,
                        child: Transform.scale(
                          scale: _logoScale.value,
                          child: _buildLogo(),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 36),

                // Title
                AnimatedBuilder(
                  animation: _textController,
                  builder: (context, _) {
                    return FadeTransition(
                      opacity: _titleFade,
                      child: Transform.translate(
                        offset: Offset(0, _titleSlide.value),
                        child: const Text(
                          'PhoneFX+',
                          style: TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 3,
                            height: 1.0,
                          ),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 10),

                // Subtitle
                AnimatedBuilder(
                  animation: _textController,
                  builder: (context, _) {
                    return FadeTransition(
                      opacity: _subtitleFade,
                      child: Transform.translate(
                        offset: Offset(0, _subtitleSlide.value),
                        child: _buildSubtitleChips(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 12),

                // Tagline
                AnimatedBuilder(
                  animation: _textController,
                  builder: (context, _) {
                    return FadeTransition(
                      opacity: _taglineFade,
                      child: Text(
                        'Repair · Bill · Done',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.4),
                          letterSpacing: 4,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    );
                  },
                ),

                const Spacer(flex: 3),

                // Progress bar
                AnimatedBuilder(
                  animation: _progressController,
                  builder: (context, _) {
                    return FadeTransition(
                      opacity: _progressFade,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 48),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Loading...',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.white.withValues(alpha: 0.35),
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                Text(
                                  '${(_progressValue.value * 100).toInt()}%',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: kTeal.withValues(alpha: 0.8),
                                    letterSpacing: 1,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            _buildProgressBar(),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 24),

                // Created by
                AnimatedBuilder(
                  animation: _textController,
                  builder: (context, _) {
                    return FadeTransition(
                      opacity: _taglineFade,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 28,
                            height: 1,
                            color: Colors.white.withValues(alpha: 0.12),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Created by ',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white.withValues(alpha: 0.3),
                              letterSpacing: 0.5,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                          Text(
                            'PhoneFX+',
                            style: TextStyle(
                              fontSize: 11,
                              color: kTeal.withValues(alpha: 0.75),
                              letterSpacing: 0.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            width: 28,
                            height: 1,
                            color: Colors.white.withValues(alpha: 0.12),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return AnimatedBuilder(
      animation: _logoController,
      builder: (context, _) {
        return SizedBox(
          width: 140,
          height: 140,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer ring pulse
              FadeTransition(
                opacity: _ringFade,
                child: Transform.scale(
                  scale: _ringScale.value,
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: kTeal.withValues(alpha: 0.25),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
              // Mid ring
              FadeTransition(
                opacity: _ringFade,
                child: Container(
                  width: 116,
                  height: 116,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: kTeal.withValues(alpha: 0.15),
                      width: 1,
                    ),
                  ),
                ),
              ),
              // Icon background
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: kNavyMid,
                  border: Border.all(
                    color: kTeal.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: kTeal.withValues(alpha: 0.30),
                      blurRadius: 28,
                      spreadRadius: 4,
                    ),
                    BoxShadow(
                      color: kAmber.withValues(alpha: 0.15),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
              // Phone icon
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.phone_android_rounded, size: 38, color: kTeal),
                  const SizedBox(height: 2),
                  // Wrench accent
                  Icon(Icons.build_rounded, size: 18, color: kAmber),
                ],
              ),
              // Amber plus badge
              Positioned(
                top: 14,
                right: 14,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: kAmber,
                    boxShadow: [
                      BoxShadow(
                        color: kAmber.withValues(alpha: 0.5),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.add, size: 16, color: kNavyDark),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSubtitleChips() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _chip(Icons.receipt_long_rounded, 'Billing', kTeal),
        const SizedBox(width: 8),
        _chip(Icons.build_circle_rounded, 'Repair', kAmber),
        const SizedBox(width: 8),
        _chip(Icons.smartphone_rounded, 'Devices', Colors.white54),
      ],
    );
  }

  Widget _chip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return AnimatedBuilder(
      animation: _progressValue,
      builder: (context, _) {
        return Container(
          height: 4,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(2),
          ),
          child: FractionallySizedBox(
            widthFactor: 1.0,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  children: [
                    Container(
                      width: constraints.maxWidth * _progressValue.value,
                      height: 4,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        gradient: const LinearGradient(
                          colors: [kTeal, kTealDark],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: kTeal.withValues(alpha: 0.6),
                            blurRadius: 6,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}

// --- Particle model ---
class _Particle {
  final double x;
  final double y;
  final double size;
  final double opacity;
  final double speed;
  final Color color;

  const _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.opacity,
    required this.speed,
    required this.color,
  });
}

// --- Particle painter ---
class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;

  _ParticlePainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final dy = (progress * p.speed) % 1.0;
      final y = (p.y - dy + 1.0) % 1.0;
      final paint = Paint()
        ..color = p.color.withValues(alpha: p.opacity)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        Offset(p.x * size.width, y * size.height),
        p.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => true;
}

// --- Subtle grid painter ---
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.025)
      ..strokeWidth = 0.5;

    const step = 60.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) => false;
}
