// lib/core/widgets/glass_card.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'bouncy_tap.dart';

/// An iOS-inspired frosted glass container utilizing BackdropFilter,
/// soft translucency, delicate highlight borders, and rounded corners.
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double blur;
  final Color? color;
  final Color? borderColor;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;

  const GlassContainer({
    super.key,
    required this.child,
    this.borderRadius = 20,
    this.blur = 16,
    this.color,
    this.borderColor,
    this.padding,
    this.margin,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Translucent glass fill with specular clarity
    final glassColor = color ??
        (isDark
            ? const Color(0xFF131826).withOpacity(0.62)
            : Colors.white.withOpacity(0.78));

    // Delicate glass refraction border
    final glassBorder = borderColor ??
        (isDark
            ? Colors.white.withOpacity(0.15)
            : Colors.white.withOpacity(0.85));

    Widget content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: glassColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: glassBorder,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.35 : 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: (isDark ? Colors.blueAccent : Colors.indigoAccent).withOpacity(isDark ? 0.05 : 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );

    if (onTap != null) {
      content = BouncyTap(
        onTap: onTap,
        child: content,
      );
    }

    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: content,
        ),
      ),
    );
  }
}

