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

    final baseColor = isDark ? const Color(0xFF0A1211) : const Color(0xFFF6F9F8);
    final topGlow = isDark
        ? const Color(0xFF0F766E).withOpacity(0.35)
        : const Color(0xFF0D9488).withOpacity(0.14);
    final bottomGlow = isDark
        ? const Color(0xFF064E3B).withOpacity(0.30)
        : const Color(0xFF10B981).withOpacity(0.12);
    final accentGlow = isDark
        ? const Color(0xFF0E7490).withOpacity(0.25)
        : const Color(0xFF14B8A6).withOpacity(0.08);

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

