import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AnimatedSplashScreen extends StatefulWidget {
  final VoidCallback onAnimationComplete;

  const AnimatedSplashScreen({super.key, required this.onAnimationComplete});

  @override
  State<AnimatedSplashScreen> createState() => _AnimatedSplashScreenState();
}

class _AnimatedSplashScreenState extends State<AnimatedSplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textRevealController;
  late AnimationController _rotationController;
  late AnimationController _pulseController;

  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoOpacityAnimation;
  late Animation<double> _textSlideAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _pulseAnimation;

  bool _isHovering = false;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );

    _textRevealController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 12000),
      vsync: this,
    )..repeat();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _logoScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );

    _logoOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
      ),
    );

    _textSlideAnimation = Tween<double>(begin: 40.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _textRevealController,
        curve: Curves.easeOutCubic,
      ),
    );

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(_rotationController);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _startAnimation();
  }

  void _startAnimation() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _logoController.forward();

    await Future.delayed(const Duration(milliseconds: 700));
    _textRevealController.forward();

    await Future.delayed(const Duration(milliseconds: 2500));
    if (mounted) {
      widget.onAnimationComplete();
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textRevealController.dispose();
    _rotationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: Stack(
        children: [
          // Animated Background
          _buildAnimatedBackground(),

          // Floating particles
          _buildFloatingParticles(),

          // Main Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildAnimatedLogo(),
                const SizedBox(height: 40),
                _buildAnimatedBrandName(),
                const SizedBox(height: 20),
                _buildAnimatedTagline(),
                const SizedBox(height: 50),
                _buildLoadingIndicator(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: Listenable.merge([_rotationController, _pulseController]),
      builder: (context, child) {
        return CustomPaint(
          painter: SimplifiedBackgroundPainter(
            rotationValue: _rotationAnimation.value,
            pulseValue: _pulseAnimation.value,
          ),
          size: Size.infinite,
        );
      },
    );
  }

  Widget _buildFloatingParticles() {
    return AnimatedBuilder(
      animation: _rotationController,
      builder: (context, child) {
        return CustomPaint(
          painter: SimpleParticlePainter(progress: _rotationController.value),
          size: Size.infinite,
        );
      },
    );
  }

  Widget _buildAnimatedLogo() {
    return AnimatedBuilder(
      animation: Listenable.merge([_logoController, _pulseController]),
      builder: (context, child) {
        return Transform.scale(
          scale: _logoScaleAnimation.value,
          child: Opacity(
            opacity: _logoOpacityAnimation.value,
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                _logoController.reverse().then((_) {
                  _logoController.forward();
                });
              },
              child: MouseRegion(
                onEnter: (_) => setState(() => _isHovering = true),
                onExit: (_) => setState(() => _isHovering = false),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  width: _isHovering ? 280 : 260,
                  height: _isHovering ? 280 : 260,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(
                          0xFFE65100,
                        ).withValues(alpha: _isHovering ? 0.4 : 0.2),
                        blurRadius: _isHovering ? 50 : 30,
                        spreadRadius: _isHovering ? 10 : 5,
                      ),
                      BoxShadow(
                        color: const Color(
                          0xFF93C572,
                        ).withValues(alpha: _isHovering ? 0.3 : 0.15),
                        blurRadius: _isHovering ? 60 : 40,
                        spreadRadius: _isHovering ? 15 : 8,
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Transform.rotate(
                        angle: _rotationAnimation.value,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: SweepGradient(
                              colors: [
                                const Color(0xFFE65100).withValues(alpha: 0.2),
                                const Color(0xFF93C572).withValues(alpha: 0.3),
                                const Color(0xFFE65100).withValues(alpha: 0.2),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(
                              0xFFE65100,
                            ).withValues(alpha: 0.5),
                            width: 2,
                          ),
                        ),
                      ),
                      Container(
                        width: 240,
                        height: 240,
                        decoration: const BoxDecoration(shape: BoxShape.circle),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/sipora_logo.png',
                            width: 240,
                            height: 240,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return _buildFallbackLogo();
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedBrandName() {
    return AnimatedBuilder(
      animation: _textRevealController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _textSlideAnimation.value),
          child: Opacity(
            opacity: _textRevealController.value,
            child: ShaderMask(
              shaderCallback: (bounds) {
                return LinearGradient(
                  colors: [
                    const Color(0xFFE65100),
                    const Color(0xFFFF8A65),
                    const Color(0xFF93C572),
                  ],
                ).createShader(bounds);
              },
              child: const Text(
                'SIPORA',
                style: TextStyle(
                  fontSize: 52,
                  fontWeight: FontWeight.w200,
                  letterSpacing: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedTagline() {
    return AnimatedBuilder(
      animation: _textRevealController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _textSlideAnimation.value * 0.6),
          child: Opacity(
            opacity: _textRevealController.value * 0.9,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                border: Border.all(
                  color: const Color(0xFF93C572).withValues(alpha: 0.4),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.eco_outlined,
                    size: 14,
                    color: const Color(0xFF93C572).withValues(alpha: 0.9),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Every Sip Rewards You.',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 3,
                      color: const Color(0xFFFFF8E7).withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    Icons.local_drink_outlined,
                    size: 14,
                    color: const Color(0xFFE65100).withValues(alpha: 0.9),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingIndicator() {
    return AnimatedBuilder(
      animation: _rotationController,
      builder: (context, child) {
        return Column(
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: CustomPaint(
                painter: SimpleLoadingPainter(
                  progress: _rotationController.value,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'BREWING PERFECTION...',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w300,
                letterSpacing: 4,
                color: const Color(0xFFFFF8E7).withValues(alpha: 0.5),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFallbackLogo() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [const Color(0xFF1A1A1A), const Color(0xFF2A2A2A)],
        ),
        border: Border.all(
          color: const Color(0xFFE65100).withValues(alpha: 0.6),
          width: 2,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                Icons.eco,
                size: 55,
                color: const Color(0xFF93C572).withValues(alpha: 0.7),
              ),
              Icon(
                Icons.local_cafe,
                size: 45,
                color: const Color(0xFFE65100).withValues(alpha: 0.9),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'SIPORA',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w300,
              letterSpacing: 8,
              color: const Color(0xFFFFF8E7).withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== BACKGROUND PAINTER ====================
class SimplifiedBackgroundPainter extends CustomPainter {
  final double rotationValue;
  final double pulseValue;

  SimplifiedBackgroundPainter({
    required this.rotationValue,
    required this.pulseValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Draw subtle rings
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (int i = 0; i < 3; i++) {
      final radius = size.width * (0.3 + i * 0.15);

      if (i % 2 == 0) {
        ringPaint.color = const Color(0xFFE65100).withValues(alpha: 0.03);
      } else {
        ringPaint.color = const Color(0xFF93C572).withValues(alpha: 0.03);
      }

      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(rotationValue * (i % 2 == 0 ? 0.3 : -0.2));

      // Draw dotted circle
      _drawDottedCircle(canvas, Offset.zero, radius, 60, ringPaint);

      canvas.restore();
    }

    // Draw tea leaves
    _drawTeaLeaves(canvas, size);
  }

  void _drawDottedCircle(
    Canvas canvas,
    Offset center,
    double radius,
    int dotCount,
    Paint paint,
  ) {
    final path = Path();
    final angleStep = (2 * math.pi) / dotCount;

    for (int i = 0; i < dotCount; i++) {
      if (i % 3 == 0) {
        final angle = i * angleStep;
        final x = center.dx + math.cos(angle) * radius;
        final y = center.dy + math.sin(angle) * radius;
        path.addOval(Rect.fromCircle(center: Offset(x, y), radius: 2));
      }
    }

    canvas.drawPath(path, paint);
  }

  void _drawTeaLeaves(Canvas canvas, Size size) {
    final leafPaint = Paint()..style = PaintingStyle.fill;
    final center = Offset(size.width / 2, size.height / 2);

    for (int i = 0; i < 6; i++) {
      final angle = i * (2 * math.pi / 6) + rotationValue * 0.2;
      final radius = size.width * 0.35 + math.sin(rotationValue * 2 + i) * 20;

      final x = center.dx + math.cos(angle) * radius;
      final y = center.dy + math.sin(angle) * radius * 0.6;

      if (i % 2 == 0) {
        leafPaint.color = const Color(0xFF93C572).withValues(alpha: 0.06);
      } else {
        leafPaint.color = const Color(0xFFE65100).withValues(alpha: 0.04);
      }

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(angle + math.pi / 3);

      final leafPath = Path();
      leafPath.moveTo(0, 0);
      leafPath.quadraticBezierTo(10, -5, 18, 0);
      leafPath.quadraticBezierTo(10, 5, 0, 0);

      canvas.drawPath(leafPath, leafPaint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(SimplifiedBackgroundPainter oldDelegate) {
    return oldDelegate.rotationValue != rotationValue ||
        oldDelegate.pulseValue != pulseValue;
  }
}

// ==================== PARTICLE PAINTER ====================
class SimpleParticlePainter extends CustomPainter {
  final double progress;

  SimpleParticlePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final center = Offset(size.width / 2, size.height / 2);

    // Floating particles around the circle
    for (int i = 0; i < 20; i++) {
      final particleProgress = (progress + i / 20) % 1.0;

      final angle = i * (2 * math.pi / 20) + progress * 2 * math.pi;
      final radius = size.width * 0.35 * particleProgress;

      final x = center.dx + math.cos(angle) * radius;
      final y = center.dy + math.sin(angle) * radius;

      final opacity = (1 - particleProgress) * 0.15;

      if (i % 2 == 0) {
        paint.color = const Color(0xFF93C572).withValues(alpha: opacity);
      } else {
        paint.color = const Color(0xFFFF8A65).withValues(alpha: opacity);
      }

      canvas.drawCircle(Offset(x, y), 2, paint);
    }

    // Steam particles rising from the logo
    for (int i = 0; i < 15; i++) {
      final steamProgress = (progress * 1.5 + i / 15) % 1.0;

      final x =
          center.dx +
          math.sin(steamProgress * 2 * math.pi * 2 + i) * size.width * 0.2;
      final y = center.dy - 50 - steamProgress * size.height * 0.25;

      final opacity = math.sin(steamProgress * math.pi) * 0.12;

      paint.color = const Color(0xFFFFF8E7).withValues(alpha: opacity);

      canvas.drawCircle(Offset(x, y), 3, paint);
    }
  }

  @override
  bool shouldRepaint(SimpleParticlePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

// ==================== LOADING PAINTER ====================
class SimpleLoadingPainter extends CustomPainter {
  final double progress;

  SimpleLoadingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.35;

    // Outer ring
    final outerPaint = Paint()
      ..color = const Color(0xFFE65100).withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(progress * 2 * math.pi);

    canvas.drawArc(
      Rect.fromCircle(center: Offset.zero, radius: radius),
      0,
      math.pi * 1.8,
      false,
      outerPaint,
    );

    // Inner ring
    final innerPaint = Paint()
      ..color = const Color(0xFF93C572).withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    canvas.rotate(-progress * 3 * math.pi);

    canvas.drawArc(
      Rect.fromCircle(center: Offset.zero, radius: radius * 0.6),
      0,
      math.pi * 1.7,
      false,
      innerPaint,
    );

    // Center dot
    final dotPaint = Paint()
      ..color = const Color(0xFFFFF8E7).withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset.zero, 3, dotPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(SimpleLoadingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
