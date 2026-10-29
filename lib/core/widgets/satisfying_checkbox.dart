// lib/core/widgets/satisfying_checkbox.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A spring-animated checkbox following Emil Kowalski's micro-interaction design:
/// satisfying elastic pop on toggle, gentle scale burst, and vibrant check animation.
class SatisfyingCheckbox extends StatefulWidget {
  final bool value;
  final ValueChanged<bool?> onChanged;
  final Color activeColor;

  const SatisfyingCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.activeColor = const Color(0xFF10B981), // Emerald glow
  });

  @override
  State<SatisfyingCheckbox> createState() => _SatisfyingCheckboxState();
}

class _SatisfyingCheckboxState extends State<SatisfyingCheckbox> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.82).chain(CurveTween(curve: Curves.easeOut)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.82, end: 1.16).chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.16, end: 1.0).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 25,
      ),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    HapticFeedback.lightImpact();
    _controller.forward(from: 0.0);
    widget.onChanged(!widget.value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _controller.isAnimating ? _scaleAnimation.value : 1.0,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: widget.value ? widget.activeColor : Colors.transparent,
                borderRadius: BorderRadius.circular(7),
                border: Border.all(
                  color: widget.value
                      ? widget.activeColor
                      : Colors.grey.shade400.withOpacity(0.8),
                  width: 1.6,
                ),
                boxShadow: widget.value
                    ? [
                        BoxShadow(
                          color: widget.activeColor.withOpacity(0.38),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: widget.value
                  ? const Icon(
                      Icons.check,
                      size: 15,
                      color: Colors.white,
                    )
                  : null,
            ),
          );
        },
      ),
    );
  }
}
