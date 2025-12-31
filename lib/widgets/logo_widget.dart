import 'package:flutter/material.dart';
import '../config/app_theme.dart';

class LogoWidget extends StatelessWidget {
  final double size;
  final bool withText;
  final Color? textColor;

  const LogoWidget({
    super.key,
    this.size = 100,
    this.withText = false,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(size * 0.25),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(size * 0.25),
            child: Image.asset(
              'assets/images/logo.png',
              width: size,
              height: size,
              fit: BoxFit.cover,
            ),
          ),
        ),
        if (withText) ...[
          const SizedBox(height: 16),
          Text(
            'CampusEase',
            style: TextStyle(
              fontSize: size * 0.25,
              fontWeight: FontWeight.bold,
              color: textColor ?? AppTheme.textPrimaryLight,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ],
    );
  }
}
