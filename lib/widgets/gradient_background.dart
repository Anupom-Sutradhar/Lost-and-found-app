import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../config/theme.dart';


class GradientBackground extends StatefulWidget {
  final Widget child;
  const GradientBackground({super.key, required this.child});

  @override
  State<GradientBackground> createState() => _GradientBackgroundState();
}

class _GradientBackgroundState extends State<GradientBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, child) {
          final t = _ctrl.value * 2 * math.pi;
          return Stack(
            children: [
              // Animated floating elements
              _floatingCircle(
                top: -20 + math.sin(t) * 8,
                left: -10 + math.cos(t) * 6,
                size: 140, opacity: 0.10,
              ),
              _floatingCircle(
                top: 90 + math.cos(t * 0.7) * 10,
                right: -30 + math.sin(t * 0.7) * 8,
                size: 100, opacity: 0.08,
              ),
              _floatingCircle(
                top: 220 + math.sin(t * 1.2) * 6,
                left: 40 + math.cos(t * 1.2) * 5,
                size: 22, opacity: 0.25, ring: true,
              ),
              _floatingCircle(
                bottom: 200 + math.cos(t * 0.9) * 8,
                right: 50 + math.sin(t * 0.9) * 7,
                size: 30, opacity: 0.18, ring: true,
              ),
              _floatingCircle(
                bottom: 100 + math.sin(t * 0.6) * 12,
                left: -20 + math.cos(t * 0.6) * 10,
                size: 110, opacity: 0.07,
              ),
              _floatingCircle(
                top: 350 + math.cos(t * 1.1) * 5,
                right: 80 + math.sin(t * 1.1) * 4,
                size: 16, opacity: 0.22, ring: true,
              ),
              _floatingCircle(
                bottom: 300 + math.sin(t * 0.8) * 7,
                left: 100 + math.cos(t * 0.8) * 6,
                size: 12, opacity: 0.20, ring: true,
              ),
              // A subtle glow effect in the center
              Positioned(
                top: MediaQuery.of(context).size.height * 0.3,
                left: MediaQuery.of(context).size.width * 0.1,
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.8,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.white.withOpacity(0.06),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              widget.child,
            ],
          );
        },
      ),
    );
  }

  Widget _floatingCircle({
    double? top,
    double? bottom,
    double? left,
    double? right,
    required double size,
    required double opacity,
    bool ring = false,
  }) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: ring ? null : Colors.white.withOpacity(opacity),
          border: ring
              ? Border.all(
                  color: Colors.white.withOpacity(opacity), width: 2)
              : null,
        ),
      ),
    );
  }
}

/// Wavy gradient decoration painted at the bottom of a white auth card.
class CardWave extends StatelessWidget {
  final double height;
  const CardWave({super.key, this.height = 90});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(painter: _WavePainter()),
    );
  }
}

class _WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = AppColors.waveGradient
          .createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path()
      ..moveTo(0, size.height * 0.45)
      ..quadraticBezierTo(
        size.width * 0.25, size.height * 0.15,
        size.width * 0.5, size.height * 0.45,
      )
      ..quadraticBezierTo(
        size.width * 0.75, size.height * 0.75,
        size.width, size.height * 0.40,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
