import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme.dart';

class Badge extends StatefulWidget {
  const Badge({super.key, required this.kind, this.size = 16});

  final String kind;
  final double size;

  @override
  State<Badge> createState() => _BadgeState();
}

class _BadgeState extends State<Badge> with SingleTickerProviderStateMixin {
  late final AnimationController _shine =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 3200))..repeat();

  @override
  void dispose() {
    _shine.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _shine,
        builder: (context, _) => CustomPaint(
          size: Size.square(widget.size),
          painter: _BadgePainter(kind: widget.kind, ink: p.ink, paper: p.paper, t: _shine.value),
        ),
      ),
    );
  }
}

class _BadgePainter extends CustomPainter {
  _BadgePainter({required this.kind, required this.ink, required this.paper, required this.t});

  final String kind;
  final Color ink;
  final Color paper;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    final fill = Paint()..color = ink;
    final mark = Paint()
      ..color = paper
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.12
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    Path shape;
    switch (kind) {
      case 'verified':
        shape = _scallop(c, r, r * 0.84, 10);
        canvas.drawPath(shape, fill);
        canvas.drawPath(
          Path()
            ..moveTo(c.dx - r * 0.38, c.dy + r * 0.02)
            ..lineTo(c.dx - r * 0.1, c.dy + r * 0.3)
            ..lineTo(c.dx + r * 0.42, c.dy - r * 0.28),
          mark,
        );
      case 'official':
        shape = Path()..addOval(Rect.fromCircle(center: c, radius: r));
        canvas.drawPath(shape, fill);
        final fish = Path()
          ..moveTo(c.dx - r * 0.55, c.dy - r * 0.28)
          ..quadraticBezierTo(c.dx - r * 0.3, c.dy, c.dx - r * 0.55, c.dy + r * 0.28)
          ..quadraticBezierTo(c.dx + r * 0.1, c.dy + r * 0.5, c.dx + r * 0.6, c.dy)
          ..quadraticBezierTo(c.dx + r * 0.1, c.dy - r * 0.5, c.dx - r * 0.55, c.dy - r * 0.28)
          ..close();
        canvas.drawPath(fish, Paint()..color = paper);
        canvas.drawCircle(Offset(c.dx + r * 0.28, c.dy - r * 0.05), r * 0.09, fill);
      case 'staff':
        shape = _star(c, r, r * 0.52, 5);
        canvas.drawPath(shape, fill);
      case 'ai':
        shape = Path()..addOval(Rect.fromCircle(center: c, radius: r));
        canvas.drawPath(shape, fill);
        canvas.drawPath(_star(c, r * 0.62, r * 0.16, 4), Paint()..color = paper);
      default:
        return;
    }

    final sweep = (t * 1.6 - 0.3) * size.width * 2 - size.width * 0.5;
    canvas.save();
    canvas.clipPath(shape);
    canvas.drawRect(
      Rect.fromLTWH(sweep, -size.height, size.width * 0.35, size.height * 3),
      Paint()
        ..shader = LinearGradient(colors: [
          paper.withValues(alpha: 0),
          paper.withValues(alpha: 0.45),
          paper.withValues(alpha: 0),
        ]).createShader(Rect.fromLTWH(sweep, 0, size.width * 0.35, size.height))
        ..blendMode = BlendMode.srcATop,
    );
    canvas.restore();
  }

  Path _scallop(Offset c, double outer, double inner, int bumps) {
    final path = Path();
    for (var i = 0; i <= bumps * 2; i++) {
      final a = -math.pi / 2 + i * math.pi / bumps;
      final rad = i.isEven ? outer : inner;
      final pt = c + Offset(math.cos(a), math.sin(a)) * rad;
      if (i == 0) {
        path.moveTo(pt.dx, pt.dy);
      } else {
        final mid = -math.pi / 2 + (i - 0.5) * math.pi / bumps;
        final ctrl = c + Offset(math.cos(mid), math.sin(mid)) * (i.isEven ? inner * 1.02 : outer * 1.02);
        path.quadraticBezierTo(ctrl.dx, ctrl.dy, pt.dx, pt.dy);
      }
    }
    return path..close();
  }

  Path _star(Offset c, double outer, double inner, int points) {
    final path = Path();
    for (var i = 0; i < points * 2; i++) {
      final a = -math.pi / 2 + i * math.pi / points;
      final rad = i.isEven ? outer : inner;
      final pt = c + Offset(math.cos(a), math.sin(a)) * rad;
      i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
    }
    return path..close();
  }

  @override
  bool shouldRepaint(_BadgePainter old) => old.t != t || old.ink != ink || old.kind != kind;
}

class BadgeRow extends StatelessWidget {
  const BadgeRow({super.key, required this.badges, this.size = 15});

  final List<String> badges;
  final double size;

  @override
  Widget build(BuildContext context) {
    const order = ['verified', 'official', 'staff', 'ai'];
    final list = order.where(badges.contains).toList();
    if (list.isEmpty) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final b in list)
          Padding(padding: EdgeInsets.only(left: size * 0.28), child: Badge(kind: b, size: size)),
      ],
    );
  }
}

class NameLine extends StatelessWidget {
  const NameLine({super.key, required this.name, required this.badges, this.style, this.badgeSize});

  final String name;
  final List<String> badges;
  final TextStyle? style;
  final double? badgeSize;

  @override
  Widget build(BuildContext context) {
    final s = style ?? DefaultTextStyle.of(context).style;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(child: Text(name, style: s, maxLines: 1, overflow: TextOverflow.ellipsis)),
        BadgeRow(badges: badges, size: badgeSize ?? (s.fontSize ?? 16) * 0.92),
      ],
    );
  }
}
