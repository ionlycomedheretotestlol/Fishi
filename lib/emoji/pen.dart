import 'dart:math' as math;

import 'package:flutter/material.dart';

double rad(double deg) => deg * math.pi / 180;

class Pen {
  Pen(this.c, this.ink, this.paper);

  final Canvas c;
  final Color ink;
  final Color paper;

  static const w = 5.0;

  Paint get fill => Paint()
    ..color = ink
    ..isAntiAlias = true;

  Paint get blank => Paint()
    ..color = paper
    ..isAntiAlias = true;

  Paint tint([double a = 0.28]) => Paint()
    ..color = Color.alphaBlend(ink.withValues(alpha: a), paper)
    ..isAntiAlias = true;

  Paint stroke([double width = w, Color? color]) => Paint()
    ..color = color ?? ink
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..isAntiAlias = true;

  void shape(Path p, {bool dark = false, double width = w, Paint? body}) {
    c.drawPath(p, body ?? (dark ? fill : blank));
    c.drawPath(p, stroke(width));
  }

  void solid(Path p) => c.drawPath(p, fill);

  void line(double x1, double y1, double x2, double y2, [double width = w, Color? color]) =>
      c.drawLine(Offset(x1, y1), Offset(x2, y2), stroke(width, color));

  void poly(List<double> pts, {double width = w, bool close = false, Paint? paint}) {
    final p = Path()..moveTo(pts[0], pts[1]);
    for (var i = 2; i < pts.length; i += 2) {
      p.lineTo(pts[i], pts[i + 1]);
    }
    if (close) p.close();
    c.drawPath(p, paint ?? stroke(width));
  }

  void curve(double x1, double y1, double cx, double cy, double x2, double y2, [double width = w]) =>
      c.drawPath(Path()
        ..moveTo(x1, y1)
        ..quadraticBezierTo(cx, cy, x2, y2), stroke(width));

  void dot(double x, double y, double r, [Paint? paint]) => c.drawCircle(Offset(x, y), r, paint ?? fill);

  void oval(double x, double y, double rx, double ry, Paint paint) =>
      c.drawOval(Rect.fromCenter(center: Offset(x, y), width: rx * 2, height: ry * 2), paint);

  void ring(double x, double y, double r, {double width = w, bool dark = false, Paint? body}) {
    c.drawCircle(Offset(x, y), r, body ?? (dark ? fill : blank));
    c.drawCircle(Offset(x, y), r, stroke(width));
  }

  void arc(double x, double y, double rx, double ry, double startDeg, double sweepDeg, [double width = w]) => c.drawArc(
      Rect.fromCenter(center: Offset(x, y), width: rx * 2, height: ry * 2), rad(startDeg), rad(sweepDeg), false, stroke(width));

  Path rrect(double l, double t, double r, double b, double radius) =>
      Path()..addRRect(RRect.fromLTRBR(l, t, r, b, Radius.circular(radius)));

  Path ellipse(double x, double y, double rx, double ry) =>
      Path()..addOval(Rect.fromCenter(center: Offset(x, y), width: rx * 2, height: ry * 2));

  Path heartPath(double x, double y, double s) {
    return Path()
      ..moveTo(x, y + s * 0.95)
      ..cubicTo(x - s * 1.25, y + s * 0.1, x - s * 0.95, y - s * 0.95, x, y - s * 0.35)
      ..cubicTo(x + s * 0.95, y - s * 0.95, x + s * 1.25, y + s * 0.1, x, y + s * 0.95)
      ..close();
  }

  void heart(double x, double y, double s, {bool dark = true, double width = 4}) {
    final p = heartPath(x, y, s);
    if (dark) {
      c.drawPath(p, fill);
      c.drawPath(p, stroke(width));
    } else {
      shape(p, width: width);
    }
  }

  Path starPath(double x, double y, double r, {int points = 5, double inner = 0.45, double rot = -90}) {
    final p = Path();
    for (var i = 0; i < points * 2; i++) {
      final a = rad(rot + i * 180 / points);
      final rr = i.isEven ? r : r * inner;
      final pt = Offset(x + math.cos(a) * rr, y + math.sin(a) * rr);
      i == 0 ? p.moveTo(pt.dx, pt.dy) : p.lineTo(pt.dx, pt.dy);
    }
    return p..close();
  }

  void star(double x, double y, double r, {bool dark = true, int points = 5, double inner = 0.45, double width = 4}) {
    final p = starPath(x, y, r, points: points, inner: inner);
    if (dark) {
      c.drawPath(p, fill);
      c.drawPath(p, stroke(width));
    } else {
      shape(p, width: width);
    }
  }

  void sparkle(double x, double y, double r) {
    final p = Path()
      ..moveTo(x, y - r)
      ..quadraticBezierTo(x, y, x + r, y)
      ..quadraticBezierTo(x, y, x, y + r)
      ..quadraticBezierTo(x, y, x - r, y)
      ..quadraticBezierTo(x, y, x, y - r)
      ..close();
    c.drawPath(p, fill);
  }

  Path drop(double x, double y, double s) => Path()
    ..moveTo(x, y - s)
    ..cubicTo(x + s * 0.3, y - s * 0.4, x + s * 0.75, y + s * 0.05, x + s * 0.75, y + s * 0.45)
    ..arcToPoint(Offset(x - s * 0.75, y + s * 0.45), radius: Radius.circular(s * 0.75))
    ..cubicTo(x - s * 0.75, y + s * 0.05, x - s * 0.3, y - s * 0.4, x, y - s)
    ..close();

  void cloud(double x, double y, double s, {bool dark = false, double width = w, Paint? body}) {
    var p = Path()..addRRect(RRect.fromLTRBR(x - s, y - s * 0.1, x + s, y + s * 0.5, Radius.circular(s * 0.3)));
    p = Path.combine(PathOperation.union, p, ellipse(x - s * 0.45, y - s * 0.05, s * 0.4, s * 0.4));
    p = Path.combine(PathOperation.union, p, ellipse(x + s * 0.2, y - s * 0.25, s * 0.55, s * 0.55));
    p = Path.combine(PathOperation.union, p, ellipse(x + s * 0.7, y + s * 0.1, s * 0.35, s * 0.35));
    shape(p, dark: dark, width: width, body: body);
  }

  void z(double x, double y, double s, [double width = 3.5]) =>
      poly([x - s, y - s, x + s, y - s, x - s, y + s, x + s, y + s], width: width);

  void withRotation(double deg, void Function() draw, {double cx = 50, double cy = 50}) {
    c.save();
    c.translate(cx, cy);
    c.rotate(rad(deg));
    c.translate(-cx, -cy);
    draw();
    c.restore();
  }

  void withClip(Path clip, void Function() draw) {
    c.save();
    c.clipPath(clip);
    draw();
    c.restore();
  }

  void mitt(double x, double y, double s, {double angle = 0}) {
    c.save();
    c.translate(x, y);
    c.rotate(rad(angle));
    final p = Path()
      ..addRRect(RRect.fromLTRBR(-s * 0.55, -s * 0.5, s * 0.55, s * 0.6, Radius.circular(s * 0.4)));
    final thumb = Path()..addRRect(RRect.fromLTRBR(-s * 0.85, -s * 0.2, -s * 0.3, s * 0.2, Radius.circular(s * 0.2)));
    shape(Path.combine(PathOperation.union, p, thumb), width: 4);
    line(-s * 0.15, -s * 0.5, -s * 0.15, -s * 0.2, 3);
    line(s * 0.2, -s * 0.5, s * 0.2, -s * 0.2, 3);
    c.restore();
  }
}
