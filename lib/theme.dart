import 'dart:ui';

import 'package:flutter/material.dart';

class Palette {
  const Palette({required this.ink, required this.paper, required this.muted, required this.line, required this.soft});

  final Color ink;
  final Color paper;
  final Color muted;
  final Color line;
  final Color soft;

  static const light = Palette(
    ink: Color(0xFF121212),
    paper: Color(0xFFF4F2EE),
    muted: Color(0xFF8A8883),
    line: Color(0xFFE2DFD9),
    soft: Color(0xFFE9E6E0),
  );

  static const dark = Palette(
    ink: Color(0xFFF4F2EE),
    paper: Color(0xFF121212),
    muted: Color(0xFF85837E),
    line: Color(0xFF26252A),
    soft: Color(0xFF1E1E20),
  );

  static Palette of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}

class AppColors {
  static const bg = Color(0xFF121212);
  static const panel = Color(0xFF18181A);
  static const line = Color(0xFF26252A);
  static const text = Color(0xFFF4F2EE);
  static const muted = Color(0xFF85837E);
  static const mine = Color(0xFFF4F2EE);
  static const theirs = Color(0xFF26252A);
  static const danger = Color(0xFFE5484D);
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
