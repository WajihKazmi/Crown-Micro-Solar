import 'package:flutter/material.dart';

class ShakeAnimation extends StatefulWidget {
  final Widget child;
  final bool shouldShake;

  const ShakeAnimation({
    Key? key,
    required this.child,
    required this.shouldShake,
  }) : super(key: key);

  @override
  _ShakeAnimationState createState() => _ShakeAnimationState();
}

class _ShakeAnimationState extends State<ShakeAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.elasticOut,
      ),
    );
  }

  @override
  void didUpdateWidget(ShakeAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.shouldShake && !oldWidget.shouldShake) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Only apply translation if shaking is needed
        if (widget.shouldShake) {
          final double offset = _animation.value * (widget.shouldShake ? 1 : -1);
          return Transform.translate(
            offset: Offset(offset, 0),
            child: widget.child,
          );
        } else {
          // Return the child directly when not shaking
          return widget.child;
        }
      },
      child: widget.child, // Pass the child once to AnimatedBuilder
    );
  }
} 