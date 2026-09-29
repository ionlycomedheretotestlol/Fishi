import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class Palette {
  const Palette({
    required this.ink,
    required this.paper,
    required this.muted,
    required this.line,
    required this.soft,
    required this.card,
    required this.danger,
  });

  final Color ink;
  final Color paper;
  final Color muted;
  final Color line;
  final Color soft;
  final Color card;
  final Color danger;

  static const light = Palette(
    ink: Color(0xFF141414),
    paper: Color(0xFFF5F3EF),
    muted: Color(0xFF8C8A85),
    line: Color(0xFFE3E0DA),
    soft: Color(0xFFE8E5DF),
    card: Color(0xFFFFFFFF),
    danger: Color(0xFFD9443F),
  );

  static const dark = Palette(
    ink: Color(0xFFF2F0EC),
    paper: Color(0xFF111111),
    muted: Color(0xFF86847F),
    line: Color(0xFF262628),
    soft: Color(0xFF232325),
    card: Color(0xFF19191B),
    danger: Color(0xFFEA5A55),
  );

  static Palette of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}

ThemeData buildTheme(Brightness brightness) {
  final p = brightness == Brightness.dark ? Palette.dark : Palette.light;
  final base = ThemeData(brightness: brightness, useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: p.paper,
    canvasColor: p.paper,
    colorScheme: ColorScheme.fromSeed(
      seedColor: p.ink,
      brightness: brightness,
      primary: p.ink,
      onPrimary: p.paper,
      surface: p.paper,
      onSurface: p.ink,
      error: p.danger,
    ),
    textTheme: base.textTheme.apply(bodyColor: p.ink, displayColor: p.ink),
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    dividerColor: p.line,
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: p.ink,
      selectionColor: p.ink.withValues(alpha: 0.2),
      selectionHandleColor: p.ink,
    ),
    cupertinoOverrideTheme: CupertinoThemeData(primaryColor: p.ink, brightness: brightness),
    pageTransitionsTheme: const PageTransitionsTheme(builders: {
      TargetPlatform.android: CupertinoPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
    }),
  );
}

class Glass extends StatelessWidget {
  const Glass({super.key, required this.child, this.top = true, this.border = true});

  final Widget child;
  final bool top;
  final bool border;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final side = BorderSide(color: border ? p.line : Colors.transparent, width: 0.5);
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: p.paper.withValues(alpha: 0.78),
            border: top ? Border(bottom: side) : Border(top: side),
          ),
          child: SafeArea(top: top, bottom: !top, child: child),
        ),
      ),
    );
  }
}

class Tappable extends StatefulWidget {
  const Tappable({super.key, required this.child, this.onTap, this.onLongPress, this.scale = 0.96});

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double scale;

  @override
  State<Tappable> createState() => _TappableState();
}

class _TappableState extends State<Tappable> {
  bool _down = false;

  void _set(bool v) {
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: AnimatedScale(
        scale: _down ? widget.scale : 1,
        duration: Duration(milliseconds: _down ? 90 : 320),
        curve: _down ? Curves.easeOut : Curves.easeOutBack,
        child: AnimatedOpacity(
          opacity: _down ? 0.75 : 1,
          duration: const Duration(milliseconds: 120),
          child: widget.child,
        ),
      ),
    );
  }
}
