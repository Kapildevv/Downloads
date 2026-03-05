import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// A premium animated background that shifts its aura color based on
/// the user's real-time financial health (e.g., savings rate).
class DynamicAuraBackground extends StatefulWidget {
  final Widget child;
  final double savingsRate;

  const DynamicAuraBackground({
    super.key,
    required this.child,
    required this.savingsRate,
  });

  @override
  State<DynamicAuraBackground> createState() => _DynamicAuraBackgroundState();
}

class _DynamicAuraBackgroundState extends State<DynamicAuraBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Color _targetAuraColor;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _targetAuraColor = _determineAuraColor(widget.savingsRate);
    _colorAnimation = AlwaysStoppedAnimation(_targetAuraColor);
  }

  @override
  void didUpdateWidget(DynamicAuraBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.savingsRate != widget.savingsRate) {
      final newColor = _determineAuraColor(widget.savingsRate);
      if (newColor != _targetAuraColor) {
        _colorAnimation = ColorTween(
          begin: _targetAuraColor,
          end: newColor,
        ).animate(CurvedAnimation(
          parent: _controller,
          curve: Curves.easeInOut,
        ));
        _targetAuraColor = newColor;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _determineAuraColor(double savingsRate) {
    if (savingsRate >= 0.3) {
      return const Color(0xFF004D40); // Deep Aurora Green (Healthy)
    } else if (savingsRate >= 0.1) {
      return const Color(0xFF003366); // Calm Blue (Neutral)
    } else if (savingsRate < 0) {
      return const Color(
          0xFF4A0000); // Moody Dark Red (High Debt / Over Budget)
    } else {
      return const Color(0xFF2C2C2C); // Standard Grey Aura
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Subtle pulsing effect on the gradient radius
        final double pulseRadius = 1.0 + (_controller.value * 0.2);
        final Color? activeColor = _colorAnimation.value;

        return Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            gradient: RadialGradient(
              center: const Alignment(0, -0.6),
              radius: pulseRadius,
              colors: [
                activeColor ?? AppColors.surface,
                AppColors.background,
              ],
              stops: const [0.0, 1.0],
            ),
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
