import 'dart:math' as math;

import 'package:flutter/material.dart';

class SendBubblePainter extends CustomPainter {
  SendBubblePainter({required this.color, this.fill, this.shine = 1});

  final Color color;
  final Color? fill;
  final double shine;

  @override
  void paint(Canvas canvas, Size size) {
    final d = size.shortestSide;
    final stroke = d * 0.13;
    final r = d / 2 - stroke / 2;
    final c = size.center(Offset.zero);

    if (fill != null) canvas.drawCircle(c, r, Paint()..color = fill!);

    final ring = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..isAntiAlias = true;
    canvas.drawCircle(c, r, ring);

    final arc = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = stroke * 0.85;

    double rad(double deg) => deg * math.pi / 180;
    final outer = r * 0.62;
    final inner = r * 0.36;
    canvas.drawArc(Rect.fromCircle(center: c, radius: outer), rad(278), rad(59) * shine, false, arc);
    if (inner > stroke) {
      canvas.drawArc(Rect.fromCircle(center: c, radius: inner), rad(300), rad(42) * shine, false, arc);
    }
  }

  @override
  bool shouldRepaint(SendBubblePainter old) => old.color != color || old.fill != fill || old.shine != shine;
}

class SendBubbleButton extends StatefulWidget {
  const SendBubbleButton({super.key, required this.enabled, required this.onTap, this.size = 44});

  final bool enabled;
  final VoidCallback onTap;
  final double size;

  @override
  State<SendBubbleButton> createState() => _SendBubbleButtonState();
}

class _SendBubbleButtonState extends State<SendBubbleButton> with SingleTickerProviderStateMixin {
  late final AnimationController _press =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 120), reverseDuration: const Duration(milliseconds: 420));

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = dark ? const Color(0xFFF4F2EE) : const Color(0xFF121212);
    return GestureDetector(
      onTapDown: widget.enabled ? (_) => _press.forward() : null,
      onTapCancel: () => _press.reverse(),
      onTapUp: widget.enabled
          ? (_) {
              _press.reverse();
              widget.onTap();
            }
          : null,
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: widget.enabled ? 1 : 0),
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOutBack,
        builder: (context, on, _) => AnimatedBuilder(
          animation: _press,
          builder: (context, _) {
            final pressCurve = Curves.easeOut.transform(_press.value);
            final scale = (0.82 + 0.18 * on) * (1 - 0.14 * pressCurve);
            return Transform.scale(
              scale: scale,
              child: Opacity(
                opacity: (0.35 + 0.65 * on).clamp(0, 1),
                child: CustomPaint(
                  size: Size.square(widget.size),
                  painter: SendBubblePainter(color: ink, shine: on.clamp(0, 1)),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
