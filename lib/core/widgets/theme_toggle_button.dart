// lib/core/widgets/theme_toggle_button.dart
import 'package:flutter/material.dart';
import '../theme/theme_service.dart';
import 'bouncy_tap.dart';

/// A delightful, tactile theme toggle button featuring:
/// - Smooth celestial rotation and elastic spring scaling between Sun and Moon
/// - Micro-haptic tactile bounce on tap
/// - Glowing aura refraction adapting between daylight amber-teal and obsidian mint
class ThemeToggleButton extends StatelessWidget {
  final double size;
  final bool showBackground;
  final VoidCallback? onToggled;

  const ThemeToggleButton({
    super.key,
    this.size = 21.0,
    this.showBackground = false,
    this.onToggled,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final tooltip = isDark ? 'Switch to Day Mode' : 'Switch to Night Version';

    final iconWidget = AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      transitionBuilder: (Widget child, Animation<double> animation) {
        final isDarkChild = child.key == const ValueKey('light_mode_icon');
        return RotationTransition(
          turns: Tween<double>(
            begin: isDarkChild ? 0.35 : -0.35,
            end: 0.0,
          ).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
          ),
          child: ScaleTransition(
            scale: Tween<double>(
              begin: 0.45,
              end: 1.0,
            ).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
            ),
            child: FadeTransition(
              opacity: animation,
              child: child,
            ),
          ),
        );
      },
      child: isDark
          ? Icon(
              Icons.light_mode_rounded,
              key: const ValueKey('light_mode_icon'),
              size: size,
              color: const Color(0xFF2DD4BF),
            )
          : Icon(
              Icons.dark_mode_rounded,
              key: const ValueKey('dark_mode_icon'),
              size: size,
              color: const Color(0xFF0F766E),
            ),
    );

    if (!showBackground) {
      return IconButton(
        icon: iconWidget,
        tooltip: tooltip,
        onPressed: () {
          ThemeService.toggleTheme();
          onToggled?.call();
        },
      );
    }

    return Tooltip(
      message: tooltip,
      child: BouncyTap(
        scaleDown: 0.90,
        onTap: () {
          ThemeService.toggleTheme();
          onToggled?.call();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOutCubic,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF162524).withOpacity(0.85)
                : Colors.white.withOpacity(0.88),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? const Color(0xFF2DD4BF).withOpacity(0.35)
                  : const Color(0xFF0F766E).withOpacity(0.18),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? const Color(0xFF2DD4BF).withOpacity(0.18)
                    : const Color(0xFF0F766E).withOpacity(0.08),
                blurRadius: 14,
                spreadRadius: 1,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: iconWidget,
        ),
      ),
    );
  }
}
