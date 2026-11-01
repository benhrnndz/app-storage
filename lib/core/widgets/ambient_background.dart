// lib/core/widgets/ambient_background.dart
import 'package:flutter/material.dart';

/// Ambient mesh glow background that provides rich color refraction for frosted glass containers.
///
/// Employs a dual-layer hardware-accelerated cross-fade between day and night meshes
/// to achieve zero-lag, butter-smooth 60fps transitions.
class AmbientMeshBackground extends StatelessWidget {
  final Widget child;

  const AmbientMeshBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        // Constant Day Ambient Canvas (cached in display list)
        const Positioned.fill(
          child: RepaintBoundary(
            child: _DayAmbientMesh(),
          ),
        ),

        // Night Ambient Canvas cross-fading smoothly with GPU alpha interpolation
        Positioned.fill(
          child: RepaintBoundary(
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOutCubic,
              opacity: isDark ? 1.0 : 0.0,
              child: const _NightAmbientMesh(),
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

class _DayAmbientMesh extends StatelessWidget {
  const _DayAmbientMesh();

  @override
  Widget build(BuildContext context) {
    const baseColor = Color(0xFFF6F9F8);
    final topGlow = const Color(0xFF0D9488).withOpacity(0.14);
    final bottomGlow = const Color(0xFF10B981).withOpacity(0.12);
    final accentGlow = const Color(0xFF14B8A6).withOpacity(0.08);

    return Stack(
      children: [
        Positioned.fill(
          child: Container(color: baseColor),
        ),
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
      ],
    );
  }
}

class _NightAmbientMesh extends StatelessWidget {
  const _NightAmbientMesh();

  @override
  Widget build(BuildContext context) {
    const baseColor = Color(0xFF0A1211);
    final topGlow = const Color(0xFF0F766E).withOpacity(0.38);
    final bottomGlow = const Color(0xFF064E3B).withOpacity(0.32);
    final accentGlow = const Color(0xFF0E7490).withOpacity(0.28);

    return Stack(
      children: [
        Positioned.fill(
          child: Container(color: baseColor),
        ),
        Positioned(
          top: -120,
          right: -80,
          child: Container(
            width: 410,
            height: 410,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [topGlow, topGlow.withOpacity(0.0)],
                radius: 0.7,
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -100,
          left: -80,
          child: Container(
            width: 390,
            height: 390,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [bottomGlow, bottomGlow.withOpacity(0.0)],
                radius: 0.7,
              ),
            ),
          ),
        ),
        Positioned(
          top: 300,
          left: -60,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [accentGlow, accentGlow.withOpacity(0.0)],
                radius: 0.7,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
