/// Quick Stat Card Widget - Enhanced with animations and loading states
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/app_theme.dart';

class QuickStatCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;
  final bool isLoading;
  final VoidCallback? onTap;

  const QuickStatCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
    this.isLoading = false,
    this.onTap,
  });

  @override
  State<QuickStatCard> createState() => _QuickStatCardState();
}

class _QuickStatCardState extends State<QuickStatCard>
    with TickerProviderStateMixin {
  late AnimationController _pressController;
  late AnimationController _shimmerController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeOutCubic),
    );

    _shimmerAnimation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _pressController.forward();
    HapticFeedback.selectionClick();
  }

  void _onTapUp(TapUpDetails details) {
    _pressController.reverse();
  }

  void _onTapCancel() {
    _pressController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = widget.value == '...' || widget.isLoading;

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
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            boxShadow: AppTheme.cardShadow,
            border: Border.all(
              color: widget.color.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Icon container with subtle glow
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: widget.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withOpacity(0.2),
                      blurRadius: 8,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Icon(
                  widget.icon,
                  color: widget.color,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Value with loading shimmer or animated text
                    if (isLoading)
                      AnimatedBuilder(
                        animation: _shimmerAnimation,
                        builder: (context, child) {
                          return Container(
                            width: 50,
                            height: 24,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              gradient: LinearGradient(
                                begin: Alignment(_shimmerAnimation.value - 1, 0),
                                end: Alignment(_shimmerAnimation.value + 1, 0),
                                colors: [
                                  Colors.grey.shade200,
                                  Colors.grey.shade50,
                                  Colors.grey.shade200,
                                ],
                                stops: const [0.0, 0.5, 1.0],
                              ),
                            ),
                          );
                        },
                      )
                    else
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: 1),
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, child) {
                          return Opacity(
                            opacity: value,
                            child: Transform.translate(
                              offset: Offset(0, 8 * (1 - value)),
                              child: child,
                            ),
                          );
                        },
                        child: Text(
                          widget.value,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: widget.color,
                          ),
                        ),
                      ),
                    const SizedBox(height: 2),
                    Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

