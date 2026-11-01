// lib/core/widgets/ambient_background.dart
import 'package:flutter/material.dart';

/// Ambient mesh glow background that provides rich color refraction for frosted glass containers.
///
/// Features smooth continuous transitions between daylight alabaster-mint and nocturnal obsidian-teal.
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
        ? const Color(0xFF0F766E).withOpacity(0.38)
        : const Color(0xFF0D9488).withOpacity(0.14);
    final bottomGlow = isDark
        ? const Color(0xFF064E3B).withOpacity(0.32)
        : const Color(0xFF10B981).withOpacity(0.12);
    final accentGlow = isDark
        ? const Color(0xFF0E7490).withOpacity(0.28)
        : const Color(0xFF14B8A6).withOpacity(0.08);

    const animationDuration = Duration(milliseconds: 650);
    const animationCurve = Curves.easeInOutCubic;

    return Stack(
      children: [
        // Base solid color with smooth cross-fade
        Positioned.fill(
          child: AnimatedContainer(
            duration: animationDuration,
            curve: animationCurve,
            color: baseColor,
          ),
        ),

        // Top-right ambient blob - blooms slightly outward in night mode
        Positioned(
          top: isDark ? -110 : -130,
          right: isDark ? -70 : -90,
          child: AnimatedContainer(
            duration: animationDuration,
            curve: animationCurve,
            width: isDark ? 410 : 370,
            height: isDark ? 410 : 370,
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
          bottom: isDark ? -90 : -110,
          left: isDark ? -70 : -90,
          child: AnimatedContainer(
            duration: animationDuration,
            curve: animationCurve,
            width: isDark ? 390 : 350,
            height: isDark ? 390 : 350,
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
          top: isDark ? 290 : 310,
          left: isDark ? -50 : -70,
          child: AnimatedContainer(
            duration: animationDuration,
            curve: animationCurve,
            width: isDark ? 300 : 270,
            height: isDark ? 300 : 270,
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

