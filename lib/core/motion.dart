import 'package:flutter/material.dart';

const kSpring = Cubic(0.2, 0.9, 0.25, 1.15);
const kSmooth = Cubic(0.22, 1, 0.36, 1);

class Reveal extends StatefulWidget {
  const Reveal({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 620),
    this.offset = const Offset(0, 18),
    this.scale = 0.96,
    this.blur = true,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;
  final Offset offset;
  final double scale;
  final bool blur;

  @override
  State<Reveal> createState() => _RevealState();
}

class _RevealState extends State<Reveal> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: widget.duration);

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (context, child) {
        final t = kSmooth.transform(_c.value);
        return Opacity(
          opacity: Curves.easeOut.transform(_c.value.clamp(0, 1)),
          child: Transform.translate(
            offset: widget.offset * (1 - t),
            child: Transform.scale(scale: widget.scale + (1 - widget.scale) * t, child: child),
          ),
        );
      },
    );
  }
}

class Stagger extends StatelessWidget {
  const Stagger({super.key, required this.children, this.step = const Duration(milliseconds: 70), this.start = Duration.zero});

  final List<Widget> children;
  final Duration step;
  final Duration start;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < children.length; i++) Reveal(delay: start + step * i, child: children[i]),
      ],
    );
  }
}

Route<T> fadeRoute<T>(Widget page) => PageRouteBuilder<T>(
      transitionDuration: const Duration(milliseconds: 520),
      reverseTransitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (_, _, _) => page,
      transitionsBuilder: (_, a, _, child) {
        final t = kSmooth.transform(a.value);
        return Opacity(opacity: t, child: Transform.scale(scale: 0.97 + 0.03 * t, child: child));
      },
    );

Route<T> sheetRoute<T>(Widget page) => PageRouteBuilder<T>(
      opaque: false,
      barrierColor: Colors.black38,
      barrierDismissible: true,
      transitionDuration: const Duration(milliseconds: 460),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, _, _) => page,
      transitionsBuilder: (_, a, _, child) {
        final t = kSmooth.transform(a.value);
        return FractionalTranslation(translation: Offset(0, 1 - t), child: child);
      },
    );
