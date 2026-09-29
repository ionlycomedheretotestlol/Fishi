import 'package:flutter/material.dart';

const _canvas = 1254.0;

Path fishBodyPath() {
  return Path()
    ..moveTo(462, 563)
    ..cubicTo(505, 512, 545, 475, 588, 450)
    ..cubicTo(565, 405, 540, 372, 530, 352)
    ..cubicTo(522, 338, 530, 325, 548, 321)
    ..cubicTo(650, 300, 760, 335, 820, 428)
    ..cubicTo(920, 458, 1000, 530, 1024, 610)
    ..cubicTo(1030, 625, 1025, 632, 1020, 640)
    ..cubicTo(960, 745, 890, 795, 795, 812)
    ..cubicTo(740, 875, 660, 915, 550, 906)
    ..cubicTo(530, 903, 528, 890, 537, 880)
    ..cubicTo(560, 850, 585, 815, 598, 789)
    ..cubicTo(540, 760, 500, 730, 462, 678)
    ..cubicTo(420, 765, 340, 815, 258, 802)
    ..cubicTo(250, 720, 275, 660, 342, 618)
    ..cubicTo(280, 575, 250, 500, 262, 425)
    ..cubicTo(350, 412, 430, 460, 462, 563)
    ..close();
}

enum FishHalf { whole, back, front }

class FishPainter extends CustomPainter {
  FishPainter({
    required this.color,
    required this.eyeColor,
    this.half = FishHalf.whole,
    this.blink = 0,
    this.pupil = Offset.zero,
  });

  final Color color;
  final Color eyeColor;
  final FishHalf half;
  final double blink;
  final Offset pupil;

  static const splitX = 627.0;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide / _canvas;
    canvas.save();
    canvas.translate((size.width - _canvas * s) / 2, (size.height - _canvas * s) / 2);
    canvas.scale(s);

    if (half == FishHalf.back) canvas.clipRect(const Rect.fromLTWH(0, 0, splitX, _canvas));
    if (half == FishHalf.front) canvas.clipRect(const Rect.fromLTWH(splitX, 0, _canvas - splitX, _canvas));

    canvas.drawPath(fishBodyPath(), Paint()..color = color..isAntiAlias = true);

    if (half != FishHalf.back) {
      const eye = Offset(842, 610);
      final open = (1 - blink).clamp(0.08, 1.0);
      canvas.save();
      canvas.translate(eye.dx, eye.dy);
      canvas.scale(1, open);
      canvas.drawCircle(Offset.zero, 97, Paint()..color = eyeColor);
      canvas.drawCircle(const Offset(38, -12) + pupil * 30, 44, Paint()..color = color);
      canvas.restore();
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(FishPainter old) =>
      old.color != color || old.eyeColor != eyeColor || old.half != half || old.blink != blink || old.pupil != pupil;
}

class FishLogo extends StatelessWidget {
  const FishLogo({super.key, this.size = 96, this.color, this.eyeColor, this.half = FishHalf.whole, this.blink = 0});

  final double size;
  final Color? color;
  final Color? eyeColor;
  final FishHalf half;
  final double blink;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = color ?? (dark ? const Color(0xFFF4F2EE) : const Color(0xFF121212));
    final paper = eyeColor ?? (dark ? const Color(0xFF121212) : const Color(0xFFF4F2EE));
    return RepaintBoundary(
      child: CustomPaint(
        size: Size.square(size),
        painter: FishPainter(color: ink, eyeColor: paper, half: half, blink: blink),
      ),
    );
  }
}
