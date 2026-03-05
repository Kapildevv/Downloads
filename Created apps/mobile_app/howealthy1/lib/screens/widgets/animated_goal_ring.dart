import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import 'dart:math' as math;

class AnimatedGoalRing extends StatefulWidget {
  final double progress; // 0.0 to 1.0
  final Widget child;
  final double size;
  final double strokeWidth;
  final Color primaryColor;
  final Color secondaryColor;
  final Duration animationDuration;

  const AnimatedGoalRing({
    super.key,
    required this.progress,
    required this.child,
    this.size = 250.0,
    this.strokeWidth = 20.0,
    this.primaryColor = AppColors.primaryTealAccent,
    this.secondaryColor = AppColors.primaryGold,
    this.animationDuration = const Duration(milliseconds: 1500),
  });

  @override
  State<AnimatedGoalRing> createState() => _AnimatedGoalRingState();
}

class _AnimatedGoalRingState extends State<AnimatedGoalRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );

    _animation = Tween<double>(begin: 0.0, end: widget.progress).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.elasticOut, // Satisfying bounce physics
      ),
    );

    _controller.forward();
  }

  @override
  void didUpdateWidget(AnimatedGoalRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      _animation = Tween<double>(
        begin: _animation.value,
        end: widget.progress,
      ).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Curves.elasticOut,
        ),
      );
      _controller
        ..value = 0
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _GoalRingPainter(
            progress: _animation.value,
            strokeWidth: widget.strokeWidth,
            primaryColor: widget.primaryColor,
            secondaryColor: widget.secondaryColor,
          ),
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: Center(child: widget.child),
          ),
        );
      },
    );
  }
}

class _GoalRingPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color primaryColor;
  final Color secondaryColor;

  _GoalRingPainter({
    required this.progress,
    required this.strokeWidth,
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;

    // Draw Background Track
    final trackPaint = Paint()
      ..color = AppColors.darkDivider.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    // Draw Foreground Animated Arc
    final sweepGradient = SweepGradient(
      colors: [primaryColor, secondaryColor, primaryColor],
      stops: const [0.0, 0.5, 1.0],
      startAngle: -math.pi / 2,
      endAngle: 3 * math.pi / 2,
    ).createShader(Rect.fromCircle(center: center, radius: radius));

    final shadowPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..maskFilter =
          const MaskFilter.blur(BlurStyle.normal, 8); // Beautiful glow

    final arcPaint = Paint()
      ..shader = sweepGradient
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    const startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * progress;

    // Draw Glow
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      shadowPaint,
    );

    // Draw Main Arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _GoalRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.secondaryColor != secondaryColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
