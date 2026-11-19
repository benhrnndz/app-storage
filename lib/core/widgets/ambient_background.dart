// lib/core/widgets/ambient_background.dart
import 'package:flutter/material.dart';

/// Ambient mesh glow background that provides rich color refraction for frosted glass containers.
///
/// Employs a dual-layer hardware-accelerated cross-fade between day and night meshes
/// and smoothly glides the ambient glow orbs when [sceneIndex] changes (e.g. across tabs).
class AmbientMeshBackground extends StatelessWidget {
  final Widget child;

  /// Active navigation tab / scene index that determines the target positions
  /// of the ambient background bubbles. Changing this value smoothly animates
  /// the bubbles to their new coordinates rather than teleporting.
  final int sceneIndex;

  const AmbientMeshBackground({
    super.key,
    required this.child,
    this.sceneIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        // Constant Day Ambient Canvas
        Positioned.fill(
          child: ClipRect(
            child: _AmbientMeshLayer(
              sceneIndex: sceneIndex,
              baseColor: const Color(0xFFF6F9F8),
              topGlow: const Color(0xFF0D9488).withOpacity(0.14),
              bottomGlow: const Color(0xFF10B981).withOpacity(0.12),
              accentGlow: const Color(0xFF14B8A6).withOpacity(0.08),
              topSize: 380,
              bottomSize: 360,
              accentSize: 280,
            ),
          ),
        ),

        // Night Ambient Canvas cross-fading smoothly with GPU alpha interpolation
        Positioned.fill(
          child: ClipRect(
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOutCubic,
              opacity: isDark ? 1.0 : 0.0,
              child: _AmbientMeshLayer(
                sceneIndex: sceneIndex,
                baseColor: const Color(0xFF0A1211),
                topGlow: const Color(0xFF0F766E).withOpacity(0.38),
                bottomGlow: const Color(0xFF064E3B).withOpacity(0.32),
                accentGlow: const Color(0xFF0E7490).withOpacity(0.28),
                topSize: 410,
                bottomSize: 390,
                accentSize: 300,
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

/// Normalized (0.0–1.0) screen-relative center coordinates for the three ambient orbs.
class _AmbientScene {
  final Offset topCenter;
  final Offset bottomCenter;
  final Offset accentCenter;

  const _AmbientScene({
    required this.topCenter,
    required this.bottomCenter,
    required this.accentCenter,
  });
}

class _AmbientMeshLayer extends StatelessWidget {
  final int sceneIndex;
  final Color baseColor;
  final Color topGlow;
  final Color bottomGlow;
  final Color accentGlow;
  final double topSize;
  final double bottomSize;
  final double accentSize;

  static const Duration _glideDuration = Duration(milliseconds: 650);
  static const Curve _glideCurve = Curves.easeInOutCubic;

  /// Distinct, balanced orb compositions per tab so switching tabs
  /// smoothly glides the ambient light across the canvas.
  static const List<_AmbientScene> _scenes = [
    // Tab 0 (Courses): Top-right, bottom-left, mid-left
    _AmbientScene(
      topCenter: Offset(0.92, 0.06),
      bottomCenter: Offset(0.08, 0.94),
      accentCenter: Offset(0.08, 0.45),
    ),
    // Tab 1 (Schedule): Top-left, bottom-right, mid-right
    _AmbientScene(
      topCenter: Offset(0.12, 0.10),
      bottomCenter: Offset(0.90, 0.90),
      accentCenter: Offset(0.88, 0.42),
    ),
    // Tab 2 (AI Coach): Top-center, bottom-left-center, lower-right
    _AmbientScene(
      topCenter: Offset(0.52, 0.06),
      bottomCenter: Offset(0.24, 0.92),
      accentCenter: Offset(0.86, 0.64),
    ),
  ];

  const _AmbientMeshLayer({
    required this.sceneIndex,
    required this.baseColor,
    required this.topGlow,
    required this.bottomGlow,
    required this.accentGlow,
    required this.topSize,
    required this.bottomSize,
    required this.accentSize,
  });

  @override
  Widget build(BuildContext context) {
    final scene = _scenes[sceneIndex.abs() % _scenes.length];

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;

        return Stack(
          children: [
            Positioned.fill(
              child: Container(color: baseColor),
            ),
            _buildGlidingOrb(
              left: scene.topCenter.dx * w - topSize / 2,
              top: scene.topCenter.dy * h - topSize / 2,
              size: topSize,
              color: topGlow,
            ),
            _buildGlidingOrb(
              left: scene.bottomCenter.dx * w - bottomSize / 2,
              top: scene.bottomCenter.dy * h - bottomSize / 2,
              size: bottomSize,
              color: bottomGlow,
            ),
            _buildGlidingOrb(
              left: scene.accentCenter.dx * w - accentSize / 2,
              top: scene.accentCenter.dy * h - accentSize / 2,
              size: accentSize,
              color: accentGlow,
            ),
          ],
        );
      },
    );
  }

  Widget _buildGlidingOrb({
    required double left,
    required double top,
    required double size,
    required Color color,
  }) {
    return AnimatedPositioned(
      duration: _glideDuration,
      curve: _glideCurve,
      left: left,
      top: top,
      width: size,
      height: size,
      child: RepaintBoundary(
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [color, color.withOpacity(0.0)],
              radius: 0.7,
            ),
          ),
        ),
      ),
    );
  }
}
