// lib/core/widgets/ambient_background.dart
import 'dart:ui';
import 'package:flutter/material.dart';

/// Ambient mesh glow background that provides rich color refraction for frosted glass containers.
class AmbientMeshBackground extends StatelessWidget {
  final Widget child;

  const AmbientMeshBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final baseColor = isDark ? const Color(0xFF0A0D14) : const Color(0xFFF5F7FB);
    final topGlow = isDark
        ? const Color(0xFF1E3A8A).withOpacity(0.35)
        : const Color(0xFF3B82F6).withOpacity(0.12);
    final bottomGlow = isDark
        ? const Color(0xFF4C1D95).withOpacity(0.28)
        : const Color(0xFF8B5CF6).withOpacity(0.09);
    final accentGlow = isDark
        ? const Color(0xFF064E3B).withOpacity(0.25)
        : const Color(0xFF06B6D4).withOpacity(0.08);

    return Stack(
      children: [
        // Base solid color
        Positioned.fill(
          child: Container(color: baseColor),
        ),

        // Top-right ambient blob
        Positioned(
          top: -120,
          right: -80,
          child: Container(
            width: 380,
            height: 380,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [topGlow, topGlow.withOpacity(0.0)],
                radius: 0.7,
              ),
            ),
          ),
        ),

        // Bottom-left ambient blob
        Positioned(
          bottom: -100,
          left: -80,
          child: Container(
            width: 360,
            height: 360,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [bottomGlow, bottomGlow.withOpacity(0.0)],
                radius: 0.7,
              ),
            ),
          ),
        ),

        // Mid-accent blob
        Positioned(
          top: 300,
          left: -60,
          child: Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [accentGlow, accentGlow.withOpacity(0.0)],
                radius: 0.7,
              ),
            ),
          ),
        ),

        // Foreground content
        Positioned.fill(
          child: child,
        ),
      ],
    );
  }
}
