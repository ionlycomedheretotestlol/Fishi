import 'dart:ui';

import 'package:flutter/material.dart';

class AppColors {
  static const bg = Color(0xFF000000);
  static const panel = Color(0xFF0E0E10);
  static const line = Color(0xFF1F1F23);
  static const text = Color(0xFFF5F5F7);
  static const muted = Color(0xFF8E8E93);
  static const mine = Color(0xFF0A84FF);
  static const theirs = Color(0xFF26252A);
  static const danger = Color(0xFFFF453A);
}

class GlassBar extends StatelessWidget {
  const GlassBar({super.key, required this.child, this.top = true});

  final Widget child;
  final bool top;

  @override
  Widget build(BuildContext context) {
    final border = BorderSide(color: AppColors.line, width: 0.5);
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.panel.withValues(alpha: 0.8),
            border: top ? Border(bottom: border) : Border(top: border),
          ),
          child: SafeArea(top: top, bottom: !top, child: child),
        ),
      ),
    );
  }
}
