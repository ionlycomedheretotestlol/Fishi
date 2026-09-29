import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/data.dart';
import '../core/theme.dart';

Path bubblePath(BubbleShape shape, Size s, {required bool tail}) {
  final w = s.width;
  final h = s.height;
  switch (shape) {
    case BubbleShape.classic:
    case BubbleShape.outline:
      final body = Path()..addRRect(RRect.fromLTRBR(0, 0, w - 6, h, const Radius.circular(18)));
      if (!tail) return body;
      final t = Path()
        ..moveTo(w - 14, h - 17)
        ..quadraticBezierTo(w - 6, h - 3, w, h)
        ..quadraticBezierTo(w - 11, h + 0.5, w - 20, h - 5)
        ..close();
      return Path.combine(PathOperation.union, body, t);
    case BubbleShape.soft:
      return Path()..addRRect(RRect.fromLTRBR(0, 0, w - 6, h, const Radius.circular(22)));
    case BubbleShape.pill:
      return Path()..addRRect(RRect.fromLTRBR(0, 0, w - 6, h, Radius.circular(math.min(h / 2, 24))));
    case BubbleShape.square:
      return Path()
        ..addRRect(RRect.fromLTRBAndCorners(0, 0, w - 6, h,
            topLeft: const Radius.circular(6),
            topRight: const Radius.circular(6),
            bottomLeft: const Radius.circular(6),
            bottomRight: Radius.circular(tail ? 1 : 6)));
    case BubbleShape.fish:
      final r = math.min(h / 2, 20.0);
      final body = Path()..addRRect(RRect.fromLTRBR(0, 0, w - 12, h, Radius.circular(r)));
      final cy = h / 2;
      final fin = Path()
        ..moveTo(w - 16, cy)
        ..quadraticBezierTo(w - 6, cy - 4, w, cy - 11)
        ..quadraticBezierTo(w - 3, cy, w, cy + 11)
        ..quadraticBezierTo(w - 6, cy + 4, w - 16, cy)
        ..close();
      final dorsal = Path()
        ..moveTo(w * 0.35, 1)
        ..quadraticBezierTo(w * 0.42, -6, w * 0.55, -5)
        ..quadraticBezierTo(w * 0.5, -1, w * 0.52, 1)
        ..close();
      return Path.combine(PathOperation.union, Path.combine(PathOperation.union, body, fin), dorsal);
    case BubbleShape.cloud:
      var path = Path()..addRRect(RRect.fromLTRBR(3, 5, w - 9, h - 5, const Radius.circular(14)));
      final n = math.max(2, ((w - 12) / 24).floor());
      for (var i = 0; i < n; i++) {
        final x = 12 + (w - 30) * (n == 1 ? 0.5 : i / (n - 1));
        path = Path.combine(PathOperation.union, path, Path()..addOval(Rect.fromCircle(center: Offset(x, 8), radius: 9)));
        path = Path.combine(PathOperation.union, path, Path()..addOval(Rect.fromCircle(center: Offset(x + 6, h - 8), radius: 9)));
      }
      if (tail) {
        path = Path.combine(PathOperation.union, path, Path()..addOval(Rect.fromCircle(center: Offset(w - 4, h - 2), radius: 3.5)));
      }
      return path;
    case BubbleShape.bolt:
      return Path()
        ..moveTo(7, 0)
        ..lineTo(w - 6, 0)
        ..lineTo(w - 13, h)
        ..lineTo(0, h)
        ..close();
  }
}

EdgeInsets bubblePadding(BubbleShape shape) => switch (shape) {
      BubbleShape.fish => const EdgeInsets.fromLTRB(14, 9, 24, 9),
      BubbleShape.cloud => const EdgeInsets.fromLTRB(15, 13, 21, 13),
      BubbleShape.bolt => const EdgeInsets.fromLTRB(16, 9, 22, 9),
      BubbleShape.pill => const EdgeInsets.fromLTRB(16, 9, 22, 9),
      _ => const EdgeInsets.fromLTRB(13, 8, 19, 8),
    };

Color bubbleFill(BubbleStyle style, Palette p, {required bool mine}) =>
    style.color ?? (mine ? p.ink : p.soft);

Color bubbleText(BubbleStyle style, Palette p, {required bool mine}) {
  if (style.shape == BubbleShape.outline) return style.color ?? p.ink;
  final fill = bubbleFill(style, p, mine: mine);
  return fill.computeLuminance() > 0.45 ? const Color(0xFF141414) : const Color(0xFFF2F0EC);
}

class BubblePainter extends CustomPainter {
  BubblePainter({required this.style, required this.color, required this.mine, required this.tail});

  final BubbleStyle style;
  final Color color;
  final bool mine;
  final bool tail;

  @override
  void paint(Canvas canvas, Size size) {
    var path = bubblePath(style.shape, size, tail: tail);
    if (!mine) {
      path = path.transform((Matrix4.identity()
            ..translateByDouble(size.width, 0, 0, 1)
            ..scaleByDouble(-1, 1, 1, 1))
          .storage);
    }
    final paint = Paint()
      ..color = color
      ..isAntiAlias = true;
    if (style.shape == BubbleShape.outline) {
      paint
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(BubblePainter old) =>
      old.style.shape != style.shape || old.color != color || old.mine != mine || old.tail != tail;
}

class BubbleBox extends StatelessWidget {
  const BubbleBox({super.key, required this.style, required this.mine, required this.tail, required this.child, this.padding});

  final BubbleStyle style;
  final bool mine;
  final bool tail;
  final Widget child;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    var pad = padding ?? bubblePadding(style.shape);
    if (!mine) pad = EdgeInsets.fromLTRB(pad.right, pad.top, pad.left, pad.bottom);
    return CustomPaint(
      painter: BubblePainter(style: style, color: bubbleFill(style, p, mine: mine), mine: mine, tail: tail),
      child: Padding(padding: pad, child: child),
    );
  }
}
