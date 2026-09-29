import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../brand/fish_logo.dart';

const chatPatterns = ['Bubbles', 'School', 'Waves'];

class ChatBackground extends StatelessWidget {
  const ChatBackground({super.key, required this.pattern, required this.color});

  final int pattern;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(painter: ChatPatternPainter(pattern: pattern, color: color), size: Size.infinite),
    );
  }
}

class ChatPatternPainter extends CustomPainter {
  ChatPatternPainter({required this.pattern, required this.color});

  final int pattern;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = color.withValues(alpha: 0.07)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    final fill = Paint()..color = color.withValues(alpha: 0.05);
    switch (pattern % chatPatterns.length) {
      case 0:
        final rnd = math.Random(4);
        const cell = 70.0;
        for (var y = 0.0; y < size.height + cell; y += cell) {
          for (var x = 0.0; x < size.width + cell; x += cell) {
            final cx = x + rnd.nextDouble() * cell;
            final cy = y + rnd.nextDouble() * cell;
            final r = 3 + rnd.nextDouble() * 11;
            canvas.drawCircle(Offset(cx, cy), r, stroke);
            if (r > 8) {
              canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: r * 0.6), math.pi * 1.1, math.pi * 0.35, false, stroke);
            }
          }
        }
      case 1:
        const cell = 92.0;
        var row = 0;
        for (var y = 10.0; y < size.height + cell; y += cell * 0.8) {
          final shift = row.isOdd ? cell / 2 : 0.0;
          for (var x = -cell + shift; x < size.width + cell; x += cell) {
            canvas.save();
            canvas.translate(x, y);
            if (row.isOdd) {
              canvas.translate(34, 0);
              canvas.scale(-1, 1);
            }
            final s = 34 / 1254;
            canvas.scale(s);
            canvas.drawPath(fishBodyPath(), fill);
            canvas.restore();
          }
          row++;
        }
      default:
        const gap = 34.0;
        for (var y = 0.0; y < size.height + gap; y += gap) {
          final path = Path()..moveTo(0, y);
          for (var x = 0.0; x <= size.width + 20; x += 20) {
            path.quadraticBezierTo(x + 5, y + ((x / 20).floor().isEven ? -6 : 6), x + 10, y);
            path.quadraticBezierTo(x + 15, y + ((x / 20).floor().isEven ? 6 : -6), x + 20, y);
          }
          canvas.drawPath(path, stroke);
        }
    }
  }

  @override
  bool shouldRepaint(ChatPatternPainter old) => old.pattern != pattern || old.color != color;
}
