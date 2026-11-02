// lib/features/landing/widgets/cinematic_logo.dart
import 'dart:io' show Platform;
import 'dart:math' as math;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

bool get _isInTest {
  if (kIsWeb) return false;
  return Platform.environment.containsKey('FLUTTER_TEST');
}

/// A premium cinematic brand emblem for Syllo.
///
/// Features multi-phase cinematic entrance:
/// 1. Ethereal radial aurora bloom behind the emblem.
/// 2. Smooth spring scale-in with 3D perspective tilt.
/// 3. Specular prism sweep (light shimmer traversing the 3D glass prism).
/// 4. Serene ambient floating/breathing idle loop with desktop hover depth.
class CinematicBrandEmblem extends StatefulWidget {
  final double size;
  final bool isDark;
  final bool enableIdleFloat;
  final bool interactiveHover;
  final VoidCallback? onTap;

  const CinematicBrandEmblem({
    super.key,
    required this.size,
    required this.isDark,
    this.enableIdleFloat = true,
    this.interactiveHover = true,
    this.onTap,
  });

  @override
  State<CinematicBrandEmblem> createState() => _CinematicBrandEmblemState();
}

class _CinematicBrandEmblemState extends State<CinematicBrandEmblem>
    with TickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _opacityAnimation;
  late final Animation<double> _tiltAnimation;
  late final Animation<double> _bloomAnimation;
  late final Animation<double> _sheenAnimation;

  AnimationController? _idleController;
  Animation<double>? _floatAnimation;
  Animation<double>? _pulseAnimation;

  bool _isHovered = false;

  @override
  void initState() {
    super.initState();

    // 1. Entrance animation (1600ms total timeline)
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _scaleAnimation = Tween<double>(begin: 0.70, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOutBack),
      ),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
      ),
    );

    _tiltAnimation = Tween<double>(begin: -0.15, end: 0.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.75, curve: Curves.easeOutCubic),
      ),
    );

    _bloomAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.15, 0.85, curve: Curves.easeOutQuad),
      ),
    );

    _sheenAnimation = Tween<double>(begin: -1.2, end: 2.2).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.40, 0.95, curve: Curves.easeInOutCubic),
      ),
    );

    // 2. Idle float & breathing loop
    if (widget.enableIdleFloat) {
      _idleController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 3600),
      );

      _floatAnimation = Tween<double>(begin: -3.5, end: 3.5).animate(
        CurvedAnimation(
          parent: _idleController!,
          curve: Curves.easeInOutSine,
        ),
      );

      _pulseAnimation = Tween<double>(begin: 0.94, end: 1.06).animate(
        CurvedAnimation(
          parent: _idleController!,
          curve: Curves.easeInOutSine,
        ),
      );

      _entranceController.forward().then((_) {
        if (mounted && _idleController != null && !_isInTest) {
          _idleController!.repeat(reverse: true);
        }
      });
    } else {
      _entranceController.forward();
    }
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _idleController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    final borderRadius = BorderRadius.circular(size * 0.28);
    final isDark = widget.isDark;

    final primaryAccent = isDark ? const Color(0xFF2DD4BF) : const Color(0xFF0F766E);
    const tileColor = Color(0xFF0A1211); // Obsidian backing

    return RepaintBoundary(
      child: MouseRegion(
        onEnter: (_) {
          if (widget.interactiveHover) setState(() => _isHovered = true);
        },
        onExit: (_) {
          if (widget.interactiveHover) setState(() => _isHovered = false);
        },
        cursor: widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedBuilder(
            animation: Listenable.merge([
              _entranceController,
              if (_idleController != null) _idleController!,
            ]),
            builder: (context, _) {
              final floatY = _floatAnimation?.value ?? 0.0;
              final pulse = _pulseAnimation?.value ?? 1.0;
              final bloom = _bloomAnimation.value;
              final sheenProgress = _sheenAnimation.value;

              final hoverScale = _isHovered ? 1.05 : 1.0;
              final totalScale = _scaleAnimation.value * hoverScale;

              return SizedBox(
                width: size * 1.8,
                height: size * 1.8,
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    // Outer Aurora Bloom Glow
                    Transform.scale(
                      scale: pulse,
                      child: Container(
                        width: size * 1.6,
                        height: size * 1.6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              primaryAccent.withOpacity(
                                (isDark ? 0.35 : 0.20) * bloom * (_isHovered ? 1.25 : 1.0),
                              ),
                              const Color(0xFF10B981).withOpacity(
                                (isDark ? 0.18 : 0.10) * bloom,
                              ),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.45, 1.0],
                          ),
                        ),
                      ),
                    ),

                    // Floating & Tilting Core Emblem
                    Transform.translate(
                      offset: Offset(0, floatY),
                      child: Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, 0.001)
                          ..rotateX(_tiltAnimation.value)
                          ..scale(totalScale),
                        child: Opacity(
                          opacity: _opacityAnimation.value,
                          child: Hero(
                            tag: 'syllo_brand_emblem',
                            flightShuttleBuilder: (_, animation, __, ___, toHero) {
                              return AnimatedBuilder(
                                animation: animation,
                                builder: (context, _) {
                                  return toHero.widget;
                                },
                              );
                            },
                            child: Container(
                              width: size,
                              height: size,
                              decoration: BoxDecoration(
                                color: tileColor,
                                borderRadius: borderRadius,
                                boxShadow: [
                                  // Colored focal glow
                                  BoxShadow(
                                    color: primaryAccent.withOpacity(isDark ? 0.36 : 0.20),
                                    blurRadius: size * 0.38,
                                    offset: Offset(0, size * 0.10),
                                  ),
                                  // Deep obsidian ambient drop shadow
                                  BoxShadow(
                                    color: Colors.black.withOpacity(isDark ? 0.45 : 0.14),
                                    blurRadius: size * 0.20,
                                    offset: Offset(0, size * 0.08),
                                  ),
                                ],
                              ),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  // 3D Glass Syllabus Prism Image
                                  ClipRRect(
                                    borderRadius: borderRadius,
                                    child: Image.asset(
                                      'assets/images/syllo_logo.jpg',
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        color: tileColor,
                                        child: Icon(
                                          Icons.school_rounded,
                                          size: size * 0.55,
                                          color: primaryAccent,
                                        ),
                                      ),
                                    ),
                                  ),

                                  // Cinematic Specular Prism Light Sweep
                                  if (_entranceController.isAnimating || _isHovered)
                                    ClipRRect(
                                      borderRadius: borderRadius,
                                      child: CustomPaint(
                                        painter: _PrismSheenPainter(
                                          progress: sheenProgress,
                                          sheenColor: Colors.white.withOpacity(
                                            isDark ? 0.35 : 0.45,
                                          ),
                                        ),
                                      ),
                                    ),

                                  // Specular Border Highlight
                                  Positioned.fill(
                                    child: IgnorePointer(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius: borderRadius,
                                          border: Border.all(
                                            color: primaryAccent.withOpacity(
                                              isDark ? 0.35 : 0.24,
                                            ),
                                            width: 1.0,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Custom painter for the cinematic specular sweep across the glass prism.
class _PrismSheenPainter extends CustomPainter {
  final double progress;
  final Color sheenColor;

  const _PrismSheenPainter({
    required this.progress,
    required this.sheenColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress < -1.0 || progress > 2.0) return;

    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment(-1.5 + 2.5 * progress, -1.0),
        end: Alignment(-0.5 + 2.5 * progress, 1.0),
        colors: [
          Colors.transparent,
          sheenColor,
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant _PrismSheenPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.sheenColor != sheenColor;
  }
}
