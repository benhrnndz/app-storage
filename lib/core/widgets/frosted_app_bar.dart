// lib/core/widgets/frosted_app_bar.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A vibrant frosted gradient top app bar encapsulating the Emil Kowalski
/// Alabaster Frost design language.
///
/// Combines BackdropFilter blur, luminous gradient washes (e.g. Royal Azure
/// to Electric Indigo), and a crisp specular highlight bottom border.
class FrostedAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? title;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  final List<Color>? gradientColors;
  final Color? baseColor;
  final Color? borderColor;
  final double blur;
  final bool centerTitle;
  final double? titleSpacing;
  final double toolbarHeight;
  final bool showBottomBorder;

  const FrostedAppBar({
    super.key,
    this.title,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.actions,
    this.bottom,
    this.gradientColors,
    this.baseColor,
    this.borderColor,
    this.blur = 20.0,
    this.centerTitle = false,
    this.titleSpacing,
    this.toolbarHeight = kToolbarHeight,
    this.showBottomBorder = true,
  });

  @override
  Size get preferredSize => Size.fromHeight(
        toolbarHeight + (bottom?.preferredSize.height ?? 0.0),
      );

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final defaultColors = [
      AppTheme.primaryTeal.withOpacity(isDark ? 0.30 : 0.16),
      AppTheme.accentTeal.withOpacity(isDark ? 0.22 : 0.11),
      AppTheme.secondarySage.withOpacity(isDark ? 0.16 : 0.06),
    ];

    final colors = gradientColors ?? defaultColors;

    final effectiveBaseColor = baseColor ??
        (isDark
            ? const Color(0xFF0F172A).withOpacity(0.80)
            : Colors.white.withOpacity(0.84));

    final effectiveBorderColor = borderColor ??
        (isDark
            ? Colors.white.withOpacity(0.12)
            : AppTheme.accentTeal.withOpacity(0.18));

    return AppBar(
      title: title,
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
      actions: actions,
      bottom: bottom,
      centerTitle: centerTitle,
      titleSpacing: titleSpacing,
      toolbarHeight: toolbarHeight,
      elevation: 0,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            decoration: BoxDecoration(
              color: effectiveBaseColor,
              gradient: LinearGradient(
                colors: colors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: showBottomBorder
                  ? Border(
                      bottom: BorderSide(
                        color: effectiveBorderColor,
                        width: 1.2,
                      ),
                    )
                  : null,
              boxShadow: [
                BoxShadow(
                  color: (isDark ? Colors.black : const Color(0xFF042F2E))
                      .withOpacity(isDark ? 0.35 : 0.04),
                  blurRadius: 14,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

