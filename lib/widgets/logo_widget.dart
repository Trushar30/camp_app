import 'package:flutter/material.dart';
import '../config/app_theme.dart';

class LogoWidget extends StatefulWidget {
  final double size;
  final bool withText;
  final Color? textColor;
  final bool enableShimmer;

  const LogoWidget({
    super.key,
    this.size = 100,
    this.withText = false,
    this.textColor,
    this.enableShimmer = false,
  });

  @override
  State<LogoWidget> createState() => _LogoWidgetState();
}

class _LogoWidgetState extends State<LogoWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _shimmerAnimation = Tween<double>(begin: -1, end: 2).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );

    if (widget.enableShimmer) {
      _shimmerController.repeat();
    }
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _shimmerController,
          builder: (context, child) {
            return Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(widget.size * 0.22),
                boxShadow: [
                  // Outer glow
                  BoxShadow(
                    color: AppTheme.primaryBlue.withOpacity(0.3),
                    blurRadius: widget.size * 0.2,
                    spreadRadius: 0,
                  ),
                  // Drop shadow
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: widget.size * 0.15,
                    offset: Offset(0, widget.size * 0.08),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(widget.size * 0.22),
                child: Stack(
                  children: [
                    // Base logo image
                    Image.asset(
                      'assets/images/logo.png',
                      width: widget.size,
                      height: widget.size,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        // Fallback gradient logo if image not found
                        return _buildFallbackLogo();
                      },
                    ),
                    // Shimmer overlay (only when animating)
                    if (widget.enableShimmer)
                      Positioned.fill(
                        child: ShaderMask(
                          shaderCallback: (bounds) {
                            return LinearGradient(
                              begin: Alignment(_shimmerAnimation.value - 1, 0),
                              end: Alignment(_shimmerAnimation.value, 0),
                              colors: [
                                Colors.transparent,
                                Colors.white.withOpacity(0.3),
                                Colors.transparent,
                              ],
                              stops: const [0.0, 0.5, 1.0],
                            ).createShader(bounds);
                          },
                          blendMode: BlendMode.srcATop,
                          child: Container(color: Colors.white),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
        if (widget.withText) ...[
          const SizedBox(height: 16),
          Text(
            'CampusEase',
            style: TextStyle(
              fontSize: widget.size * 0.25,
              fontWeight: FontWeight.bold,
              color: widget.textColor ?? AppTheme.textPrimaryLight,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFallbackLogo() {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
        ),
        borderRadius: BorderRadius.circular(widget.size * 0.22),
      ),
      child: Center(
        child: Icon(
          Icons.school_rounded,
          color: Colors.white,
          size: widget.size * 0.5,
        ),
      ),
    );
  }
}

