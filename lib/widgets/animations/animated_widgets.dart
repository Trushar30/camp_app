/// Animated Widgets - Unique and smooth reusable animations
/// CampusEase Premium Animation Library
library;

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Animated Pressable - Smooth scale with haptic feedback
class AnimatedPressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scaleDown;
  final bool enableHaptic;

  const AnimatedPressable({
    super.key,
    required this.child,
    this.onTap,
    this.scaleDown = 0.96,
    this.enableHaptic = true,
  });

  @override
  State<AnimatedPressable> createState() => _AnimatedPressableState();
}

class _AnimatedPressableState extends State<AnimatedPressable>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.scaleDown,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
    if (widget.enableHaptic) {
      HapticFeedback.lightImpact();
    }
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }
}

/// Shimmer Loading Effect - Premium skeleton loader
class ShimmerLoading extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;
  final Color? baseColor;
  final Color? highlightColor;

  const ShimmerLoading({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
    this.baseColor,
    this.highlightColor,
  });

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.baseColor ?? Colors.grey.shade200;
    final highlightColor = widget.highlightColor ?? Colors.grey.shade50;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(_animation.value - 1, 0),
              end: Alignment(_animation.value + 1, 0),
              colors: [
                baseColor,
                highlightColor,
                baseColor,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }
}

/// Pulse Animation - Subtle attention-grabbing effect
class PulseAnimation extends StatefulWidget {
  final Widget child;
  final bool isActive;
  final double minScale;
  final double maxScale;
  final Duration duration;

  const PulseAnimation({
    super.key,
    required this.child,
    this.isActive = true,
    this.minScale = 0.95,
    this.maxScale = 1.05,
    this.duration = const Duration(milliseconds: 1200),
  });

  @override
  State<PulseAnimation> createState() => _PulseAnimationState();
}

class _PulseAnimationState extends State<PulseAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _animation = Tween<double>(
      begin: widget.minScale,
      end: widget.maxScale,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    if (widget.isActive) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(PulseAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.isActive && _controller.isAnimating) {
      _controller.stop();
      _controller.value = 0.5;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isActive) return widget.child;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: _animation.value,
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Staggered Fade Slide - Elegant list entrance animation
class StaggeredFadeSlide extends StatelessWidget {
  final int index;
  final Widget child;
  final Duration baseDelay;
  final Duration duration;
  final Offset slideOffset;

  const StaggeredFadeSlide({
    super.key,
    required this.index,
    required this.child,
    this.baseDelay = const Duration(milliseconds: 50),
    this.duration = const Duration(milliseconds: 400),
    this.slideOffset = const Offset(0, 20),
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(
              slideOffset.dx * (1 - value),
              slideOffset.dy * (1 - value),
            ),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

/// Floating Animation - Gentle floating effect for elements
class FloatingAnimation extends StatefulWidget {
  final Widget child;
  final double floatHeight;
  final Duration duration;

  const FloatingAnimation({
    super.key,
    required this.child,
    this.floatHeight = 8,
    this.duration = const Duration(milliseconds: 2000),
  });

  @override
  State<FloatingAnimation> createState() => _FloatingAnimationState();
}

class _FloatingAnimationState extends State<FloatingAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat(reverse: true);
    _animation = Tween<double>(
      begin: -widget.floatHeight / 2,
      end: widget.floatHeight / 2,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutSine,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _animation.value),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Glow Effect - Animated glow border for focus states
class GlowEffect extends StatefulWidget {
  final Widget child;
  final Color glowColor;
  final double blurRadius;
  final double spreadRadius;
  final bool isActive;

  const GlowEffect({
    super.key,
    required this.child,
    required this.glowColor,
    this.blurRadius = 20,
    this.spreadRadius = 2,
    this.isActive = true,
  });

  @override
  State<GlowEffect> createState() => _GlowEffectState();
}

class _GlowEffectState extends State<GlowEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _animation = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (widget.isActive) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(GlowEffect oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.isActive) {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isActive) return widget.child;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: widget.glowColor.withOpacity(_animation.value),
                blurRadius: widget.blurRadius,
                spreadRadius: widget.spreadRadius,
              ),
            ],
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Animated Gradient Background - Smooth morphing gradient
class AnimatedGradientBackground extends StatefulWidget {
  final List<List<Color>> colorSets;
  final Duration duration;
  final Widget? child;
  final AlignmentGeometry begin;
  final AlignmentGeometry end;

  const AnimatedGradientBackground({
    super.key,
    required this.colorSets,
    this.duration = const Duration(seconds: 4),
    this.child,
    this.begin = Alignment.topLeft,
    this.end = Alignment.bottomRight,
  });

  @override
  State<AnimatedGradientBackground> createState() =>
      _AnimatedGradientBackgroundState();
}

class _AnimatedGradientBackgroundState extends State<AnimatedGradientBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          setState(() {
            _currentIndex = (_currentIndex + 1) % widget.colorSets.length;
          });
          _controller.forward(from: 0);
        }
      })
      ..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentColors = widget.colorSets[_currentIndex];
    final nextColors =
        widget.colorSets[(_currentIndex + 1) % widget.colorSets.length];

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: widget.begin,
              end: widget.end,
              colors: [
                Color.lerp(currentColors[0], nextColors[0], _controller.value)!,
                Color.lerp(currentColors[1], nextColors[1], _controller.value)!,
              ],
            ),
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Bounce In Animation - Elastic entrance
class BounceIn extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;

  const BounceIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 600),
  });

  @override
  State<BounceIn> createState() => _BounceInState();
}

class _BounceInState extends State<BounceIn>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    Future.delayed(widget.delay, () {
      if (mounted) {
        _started = true;
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_started) {
      return Opacity(opacity: 0, child: widget.child);
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: _animation.value,
          child: Opacity(
            opacity: _animation.value.clamp(0, 1),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// Wave Loading Indicator - Unique loading animation
class WaveLoader extends StatefulWidget {
  final Color color;
  final double size;
  final int count;

  const WaveLoader({
    super.key,
    this.color = Colors.white,
    this.size = 40,
    this.count = 5,
  });

  @override
  State<WaveLoader> createState() => _WaveLoaderState();
}

class _WaveLoaderState extends State<WaveLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size * 2,
      height: widget.size,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(widget.count, (index) {
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final delay = index / widget.count;
              final value =
                  math.sin((_controller.value + delay) * 2 * math.pi);
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                width: widget.size / 6,
                height: widget.size * (0.4 + 0.6 * ((value + 1) / 2)),
                decoration: BoxDecoration(
                  color: widget.color.withOpacity(0.3 + 0.7 * ((value + 1) / 2)),
                  borderRadius: BorderRadius.circular(widget.size / 12),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}

/// Slide Counter - Animated number transitions
class SlideCounter extends StatelessWidget {
  final int value;
  final TextStyle? style;
  final Duration duration;

  const SlideCounter({
    super.key,
    required this.value,
    this.style,
    this.duration = const Duration(milliseconds: 300),
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: value),
      duration: duration,
      builder: (context, val, child) {
        return Text(
          val.toString(),
          style: style,
        );
      },
    );
  }
}
