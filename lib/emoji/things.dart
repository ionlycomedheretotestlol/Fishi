import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../brand/fish_logo.dart';
import 'faces.dart';
import 'pen.dart';

void heartPlain(Pen k, {bool dark = true, bool shine = true}) {
  final p = k.heartPath(50, 52, 40);
  k.shape(p, dark: dark);
  if (dark && shine) k.oval(34, 36, 7, 4.5, Paint()..color = k.paper.withValues(alpha: 0.85));
}

void heartBroken(Pen k) {
  final p = k.heartPath(50, 52, 40);
  final crack = Path()
    ..moveTo(50, 26)
    ..lineTo(44, 44)
    ..lineTo(54, 56)
    ..lineTo(46, 72)
    ..lineTo(50, 92);
  final left = Path()
    ..moveTo(0, 0)
    ..lineTo(50, 0)
    ..lineTo(50, 26)
    ..lineTo(44, 44)
    ..lineTo(54, 56)
    ..lineTo(46, 72)
    ..lineTo(50, 100)
    ..lineTo(0, 100)
    ..close();
  k.withRotation(-8, () => k.withClip(left, () => k.shape(p, dark: true)), cx: 44, cy: 90);
  k.withRotation(8, () {
    k.withClip(Path.combine(PathOperation.difference, Path()..addRect(const Rect.fromLTRB(0, 0, 100, 100)), left), () => k.shape(p, dark: true));
  }, cx: 56, cy: 90);
  k.c.drawPath(crack, k.stroke(1.5, k.paper));
}

void heartsTwo(Pen k) {
  k.heart(36, 58, 24);
  k.heart(72, 32, 16, dark: false);
}

void heartsRevolving(Pen k) {
  k.heart(34, 40, 18);
  k.heart(66, 66, 18, dark: false);
  k.arc(50, 52, 40, 36, 200, 60, 3);
  k.arc(50, 52, 40, 36, 20, 60, 3);
}

void heartBeat(Pen k) {
  k.heart(50, 52, 30);
  for (final s in [-1.0, 1.0]) {
    k.curve(50 + s * 38, 30, 50 + s * 44, 50, 50 + s * 38, 70, 3.5);
    k.curve(50 + s * 44, 22, 50 + s * 52, 50, 50 + s * 44, 78, 3);
  }
}

void heartGrow(Pen k) {
  k.shape(k.heartPath(50, 52, 42));
  k.shape(k.heartPath(50, 54, 29), body: k.tint(0.3), width: 3.5);
  k.heart(50, 56, 16);
}

void heartSparkle(Pen k) {
  heartPlain(k);
  k.sparkle(86, 16, 10);
  k.sparkle(12, 80, 7);
  k.sparkle(88, 78, 6);
}

void heartArrow(Pen k) {
  k.line(10, 84, 90, 20, 4.5);
  heartPlain(k, shine: false);
  k.line(10, 84, 28, 70, 4.5);
  k.poly([82, 18, 94, 14, 88, 28], close: true, paint: k.fill);
  k.poly([10, 84, 6, 74, 16, 80], width: 3);
  k.poly([10, 84, 20, 88, 14, 78], width: 3);
}

void heartRibbon(Pen k) {
  heartPlain(k, shine: false);
  k.line(50, 16, 50, 92, 6);
  k.c.drawLine(const Offset(50, 16), const Offset(50, 92), k.stroke(2.5, k.paper));
  k.ring(40, 18, 8, width: 3.5);
  k.ring(60, 18, 8, width: 3.5);
  k.dot(50, 20, 4);
}

void heartExclaim(Pen k) {
  k.heart(50, 30, 24);
  k.dot(50, 84, 9);
}

void fire(Pen k) {
  final outer = Path()
    ..moveTo(50, 96)
    ..cubicTo(20, 96, 12, 70, 22, 52)
    ..cubicTo(26, 62, 32, 64, 36, 62)
    ..cubicTo(30, 40, 42, 18, 58, 6)
    ..cubicTo(56, 26, 72, 36, 76, 50)
    ..cubicTo(78, 44, 80, 40, 80, 36)
    ..cubicTo(92, 56, 90, 96, 50, 96)
    ..close();
  k.shape(outer, body: k.tint(0.12));
  final inner = Path()
    ..moveTo(50, 92)
    ..cubicTo(34, 92, 32, 76, 40, 66)
    ..cubicTo(44, 74, 48, 74, 50, 70)
    ..cubicTo(48, 60, 54, 52, 60, 48)
    ..cubicTo(62, 62, 72, 70, 66, 84)
    ..cubicTo(62, 90, 56, 92, 50, 92)
    ..close();
  k.solid(inner);
}

void sparkles(Pen k) {
  k.sparkle(40, 54, 32);
  k.sparkle(78, 22, 16);
  k.sparkle(80, 76, 11);
}

void starOutline(Pen k) {
  k.star(50, 54, 44, dark: false, width: 5, inner: 0.48);
  k.star(50, 56, 20, inner: 0.48, width: 1);
}

void glowStar(Pen k) {
  for (var i = 0; i < 8; i++) {
    final a = rad(i * 45.0 + 22.5);
    k.line(50 + math.cos(a) * 38, 52 + math.sin(a) * 38, 50 + math.cos(a) * 47, 52 + math.sin(a) * 47, 3.5);
  }
  k.star(50, 52, 34, inner: 0.48);
  k.sparkle(40, 44, 5);
}

void hundred(Pen k) {
  k.withRotation(-8, () {
    k.line(14, 22, 20, 18, 5);
    k.line(20, 18, 20, 60, 5.5);
    k.oval(42, 39, 11, 20, k.stroke(5.5));
    k.oval(72, 39, 11, 20, k.stroke(5.5));
    k.line(12, 72, 88, 70, 5);
    k.line(18, 84, 82, 82, 5);
  });
}

void checkBox(Pen k) {
  k.shape(k.rrect(10, 10, 90, 90, 20), dark: true);
  k.poly([28, 52, 44, 68, 74, 34], width: 10, paint: k.stroke(10, k.paper));
}

void crossMark(Pen k) {
  k.line(18, 18, 82, 82, 16);
  k.line(82, 18, 18, 82, 16);
}

void exclaim(Pen k) {
  k.shape(Path()
    ..moveTo(38, 10)
    ..lineTo(62, 10)
    ..lineTo(56, 66)
    ..lineTo(44, 66)
    ..close(), dark: true);
  k.dot(50, 84, 9);
}

void question(Pen k) {
  final p = Path()
    ..moveTo(28, 34)
    ..cubicTo(28, 8, 74, 6, 74, 32)
    ..cubicTo(74, 48, 50, 48, 50, 64);
  k.c.drawPath(p, k.stroke(13));
  k.dot(50, 86, 9);
}

void zzz(Pen k) {
  k.z(28, 70, 14, 7);
  k.z(62, 40, 10, 6);
  k.z(84, 16, 7, 5);
}

void sweatDrops(Pen k) {
  k.shape(k.drop(30, 58, 22), body: k.tint(0.2));
  k.shape(k.drop(70, 36, 16), body: k.tint(0.2));
  k.shape(k.drop(72, 80, 11), body: k.tint(0.2));
}

void dash(Pen k) {
  k.cloud(66, 54, 26);
  k.line(8, 40, 32, 40, 4.5);
  k.line(4, 56, 30, 56, 4.5);
  k.line(10, 72, 34, 72, 4.5);
}

void boom(Pen k) {
  k.star(50, 50, 46, points: 9, inner: 0.62, dark: false, width: 5);
  k.star(50, 50, 24, points: 7, inner: 0.55, width: 2);
}

void partyPopper(Pen k) {
  final cone = Path()
    ..moveTo(10, 92)
    ..lineTo(34, 30)
    ..lineTo(72, 68)
    ..close();
  k.shape(cone);
  k.withClip(cone, () {
    k.line(20, 50, 50, 80, 5);
    k.line(26, 38, 60, 72, 5);
  });
  k.c.drawPath(cone, k.stroke());
  k.star(70, 16, 8, width: 2);
  k.dot(88, 36, 5);
  k.dot(52, 12, 4);
  k.curve(82, 54, 92, 56, 94, 66, 3.5);
  k.curve(44, 22, 42, 12, 48, 4, 3.5);
  k.sparkle(86, 86, 7);
}

void cake(Pen k) {
  k.shape(k.rrect(14, 50, 86, 92, 8));
  k.c.drawPath(Path()
    ..moveTo(14, 62)
    ..quadraticBezierTo(23, 72, 32, 62)
    ..quadraticBezierTo(41, 72, 50, 62)
    ..quadraticBezierTo(59, 72, 68, 62)
    ..quadraticBezierTo(77, 72, 86, 62), k.stroke(4));
  k.line(14, 78, 86, 78, 3);
  k.shape(k.rrect(46, 26, 54, 50, 3), body: k.tint(0.25), width: 3.5);
  k.shape(k.drop(50, 16, 8), dark: true, width: 2);
}

void gift(Pen k) {
  k.shape(k.rrect(14, 44, 86, 92, 6));
  k.shape(k.rrect(8, 32, 92, 48, 6));
  k.c.drawRect(const Rect.fromLTRB(44, 32, 56, 92), k.fill);
  k.shape(k.ellipse(38, 22, 12, 9));
  k.shape(k.ellipse(62, 22, 12, 9));
  k.dot(50, 28, 6);
}

void balloon(Pen k) {
  k.curve(50, 72, 40, 86, 52, 98, 3);
  final p = Path()
    ..moveTo(50, 72)
    ..cubicTo(18, 64, 16, 8, 50, 6)
    ..cubicTo(84, 8, 82, 64, 50, 72)
    ..close();
  k.shape(p, dark: true);
  k.oval(36, 26, 5, 9, Paint()..color = k.paper.withValues(alpha: 0.85));
  k.poly([44, 78, 50, 70, 56, 78], close: true, paint: k.fill);
}

void coffee(Pen k) {
  k.shape(Path()
    ..moveTo(14, 40)
    ..lineTo(74, 40)
    ..lineTo(70, 82)
    ..quadraticBezierTo(69, 92, 58, 92)
    ..lineTo(30, 92)
    ..quadraticBezierTo(19, 92, 18, 82)
    ..close());
  k.c.drawCircle(const Offset(78, 58), 11, k.stroke());
  k.oval(44, 44, 26, 5, k.fill);
  k.curve(34, 30, 28, 20, 36, 10, 3.5);
  k.curve(50, 30, 44, 20, 52, 10, 3.5);
}

void pizza(Pen k) {
  final p = Path()
    ..moveTo(50, 96)
    ..lineTo(12, 22)
    ..quadraticBezierTo(50, 6, 88, 22)
    ..close();
  k.shape(p, body: k.tint(0.1));
  k.shape(Path()
    ..moveTo(12, 22)
    ..quadraticBezierTo(50, 6, 88, 22)
    ..lineTo(84, 32)
    ..quadraticBezierTo(50, 18, 16, 32)
    ..close(), body: k.tint(0.3), width: 3.5);
  k.dot(40, 44, 7);
  k.dot(60, 50, 6);
  k.dot(48, 70, 5.5);
}

void donut(Pen k) {
  k.ring(50, 52, 42);
  final icing = Path()
    ..moveTo(14, 48)
    ..cubicTo(14, 14, 86, 14, 86, 48)
    ..cubicTo(86, 60, 78, 58, 76, 66)
    ..cubicTo(70, 74, 62, 64, 54, 72)
    ..cubicTo(44, 78, 40, 66, 30, 70)
    ..cubicTo(18, 72, 14, 60, 14, 48)
    ..close();
  k.shape(icing, dark: true, width: 3);
  k.ring(50, 50, 12);
  final s = k.stroke(3, k.paper);
  k.c.drawLine(const Offset(30, 32), const Offset(36, 30), s);
  k.c.drawLine(const Offset(64, 28), const Offset(68, 34), s);
  k.c.drawLine(const Offset(72, 48), const Offset(78, 46), s);
  k.c.drawLine(const Offset(26, 50), const Offset(28, 56), s);
  k.c.drawLine(const Offset(46, 26), const Offset(52, 28), s);
}

void moon(Pen k) {
  final outer = k.ellipse(50, 50, 40, 40);
  final bite = k.ellipse(70, 38, 32, 32);
  k.shape(Path.combine(PathOperation.difference, outer, bite), dark: true);
  k.sparkle(76, 70, 7);
  k.sparkle(86, 18, 5);
}

void sun(Pen k) {
  for (var i = 0; i < 12; i++) {
    final a = rad(i * 30.0);
    k.line(50 + math.cos(a) * 34, 50 + math.sin(a) * 34, 50 + math.cos(a) * 46, 50 + math.sin(a) * 46, 5);
  }
  k.ring(50, 50, 27);
  k.curve(40, 44, 43, 38, 46, 44, 3.5);
  k.curve(54, 44, 57, 38, 60, 44, 3.5);
  k.curve(42, 56, 50, 64, 58, 56, 3.5);
}

void cloudy(Pen k) => k.cloud(50, 54, 40);

void rain(Pen k) {
  k.cloud(50, 36, 38);
  for (final x in [28.0, 48.0, 68.0]) {
    k.line(x, 70, x - 6, 88, 4.5);
  }
}

void snowflake(Pen k) {
  for (var i = 0; i < 6; i++) {
    k.withRotation(i * 60.0, () {
      k.line(50, 50, 50, 8, 5);
      k.poly([40, 18, 50, 26, 60, 18], width: 4.5);
      k.poly([42, 32, 50, 38, 58, 32], width: 4);
    });
  }
  k.dot(50, 50, 6);
}

void bolt(Pen k) {
  k.shape(Path()
    ..moveTo(58, 4)
    ..lineTo(18, 56)
    ..lineTo(46, 56)
    ..lineTo(38, 96)
    ..lineTo(82, 40)
    ..lineTo(54, 40)
    ..close(), dark: true, width: 4);
}

void rainbow(Pen k) {
  final shades = [0.9, 0.55, 0.25, 0.08];
  for (var i = 0; i < 4; i++) {
    final r = 44.0 - i * 8;
    k.c.drawArc(Rect.fromCircle(center: const Offset(50, 76), radius: r - 4), math.pi, math.pi, false,
        Paint()
          ..color = Color.alphaBlend(k.ink.withValues(alpha: shades[i]), k.paper)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 8);
  }
  k.arc(50, 76, 44, 44, 180, 180, 3);
  k.arc(50, 76, 12, 12, 180, 180, 3);
  k.cloud(16, 78, 12, width: 3.5);
  k.cloud(84, 78, 12, width: 3.5);
}

void blossom(Pen k) {
  for (var i = 0; i < 5; i++) {
    k.withRotation(i * 72.0, () {
      final p = Path()
        ..moveTo(50, 50)
        ..cubicTo(30, 36, 34, 8, 46, 10)
        ..lineTo(50, 16)
        ..lineTo(54, 10)
        ..cubicTo(66, 8, 70, 36, 50, 50)
        ..close();
      k.shape(p, width: 4, body: k.tint(0.12));
    });
  }
  k.ring(50, 50, 9, dark: true, width: 3);
}

void clover(Pen k) {
  k.curve(50, 54, 58, 78, 70, 94, 5);
  for (var i = 0; i < 4; i++) {
    k.withRotation(i * 90.0 + 45, () {
      final p = k.heartPath(50, 30, 16);
      k.shape(p, dark: true, width: 3.5);
    }, cy: 52);
  }
}

void fishLogo(Pen k) {
  k.c.save();
  k.c.translate(-2, -4);
  FishPainter(color: k.ink, eyeColor: k.paper).paint(k.c, const Size(104, 104));
  k.c.restore();
}

void tropicalFish(Pen k) {
  final body = Path()
    ..moveTo(12, 50)
    ..cubicTo(24, 20, 62, 16, 78, 50)
    ..cubicTo(62, 84, 24, 80, 12, 50)
    ..close();
  final tail = Path()
    ..moveTo(74, 50)
    ..lineTo(94, 30)
    ..quadraticBezierTo(88, 50, 94, 70)
    ..close();
  k.shape(tail, dark: true, width: 4);
  k.shape(body);
  k.withClip(body, () {
    k.line(36, 10, 36, 90, 8);
    k.line(56, 10, 56, 90, 8);
  });
  k.c.drawPath(body, k.stroke());
  k.shape(Path()
    ..moveTo(34, 26)
    ..quadraticBezierTo(48, 4, 62, 28)
    ..close(), dark: true, width: 3);
  k.ring(24, 46, 6, width: 3);
  k.dot(25, 46, 3);
}

void whale(Pen k) {
  final p = Path()
    ..moveTo(8, 60)
    ..cubicTo(8, 30, 60, 26, 74, 52)
    ..quadraticBezierTo(82, 44, 90, 30)
    ..quadraticBezierTo(96, 40, 90, 50)
    ..quadraticBezierTo(96, 56, 94, 64)
    ..quadraticBezierTo(84, 60, 78, 64)
    ..cubicTo(66, 90, 8, 90, 8, 60)
    ..close();
  k.shape(p, dark: true);
  final belly = Path()
    ..moveTo(12, 66)
    ..cubicTo(26, 76, 50, 76, 70, 68)
    ..cubicTo(56, 86, 22, 86, 12, 66)
    ..close();
  k.c.drawPath(belly, k.blank);
  k.dot(26, 54, 3.5, k.blank);
  k.curve(30, 26, 26, 14, 18, 10, 3.5);
  k.curve(30, 26, 34, 14, 42, 10, 3.5);
  k.line(30, 26, 30, 12, 3.5);
}

void octopus(Pen k) {
  for (var i = 0; i < 5; i++) {
    final x = 18.0 + i * 16;
    k.c.drawPath(Path()
      ..moveTo(x + 4, 58)
      ..quadraticBezierTo(x - 4, 78, x + 6 * math.sin(i * 1.3), 94), k.stroke(8));
  }
  k.shape(k.ellipse(50, 42, 34, 32), body: k.tint(0.14));
  _eyeDot(k, 38, 44);
  _eyeDot(k, 62, 44);
  k.curve(44, 56, 50, 62, 56, 56, 3.5);
  k.oval(28, 54, 5, 3, k.tint(0.4));
  k.oval(72, 54, 5, 3, k.tint(0.4));
}

void _eyeDot(Pen k, double x, double y, [double s = 1]) {
  k.oval(x, y, 4.5 * s, 6 * s, k.fill);
  k.dot(x - 1.5 * s, y - 2.5 * s, 1.8 * s, k.blank);
}

void animalCat(Pen k) {
  drawFace(k, const FaceSpec(l: Eye.dot, mouth: Mouth.cat, extras: [Extra.ears, Extra.whiskers, Extra.blush]));
  k.poly([46, 64, 54, 64, 50, 68], close: true, paint: k.fill);
}

void animalDog(Pen k) {
  k.shape(k.ellipse(50, 54, 38, 36));
  for (final s in [-1.0, 1.0]) {
    k.withRotation(s * 18, () => k.shape(k.ellipse(50 + s * 34, 44, 11, 22), dark: true, width: 4), cx: 50 + s * 34, cy: 30);
  }
  k.shape(k.ellipse(50, 70, 16, 12), body: k.tint(0.1), width: 3.5);
  k.oval(50, 62, 7, 5, k.fill);
  k.line(50, 66, 50, 72, 3);
  k.curve(42, 74, 46, 78, 50, 72, 3);
  k.curve(50, 72, 54, 78, 58, 74, 3);
  _eyeDot(k, 36, 48);
  _eyeDot(k, 64, 48);
}

void animalBunny(Pen k) {
  for (final s in [-1.0, 1.0]) {
    k.withRotation(s * 10, () {
      k.shape(k.ellipse(50 + s * 16, 22, 9, 22), width: 4.5);
      k.oval(50 + s * 16, 24, 3.5, 14, k.tint(0.35));
    }, cx: 50 + s * 16, cy: 40);
  }
  k.shape(k.ellipse(50, 62, 36, 32));
  _eyeDot(k, 38, 60);
  _eyeDot(k, 62, 60);
  k.poly([46, 70, 54, 70, 50, 74], close: true, paint: k.fill);
  k.c.drawPath(Path()
    ..moveTo(44, 78)
    ..quadraticBezierTo(47, 82, 50, 76)
    ..quadraticBezierTo(53, 82, 56, 78), k.stroke(3));
  k.oval(26, 72, 6, 3.5, k.tint(0.3));
  k.oval(74, 72, 6, 3.5, k.tint(0.3));
}

void animalBear(Pen k) {
  for (final s in [-1.0, 1.0]) {
    k.ring(50 + s * 30, 22, 13);
    k.dot(50 + s * 30, 22, 6, k.tint(0.4));
  }
  k.shape(k.ellipse(50, 56, 40, 36), body: k.tint(0.12));
  k.shape(k.ellipse(50, 70, 15, 11), width: 3.5);
  k.oval(50, 65, 6, 4, k.fill);
  k.curve(44, 75, 50, 80, 56, 75, 3);
  _eyeDot(k, 34, 52);
  _eyeDot(k, 66, 52);
}

void animalPanda(Pen k) {
  k.dot(20, 22, 14);
  k.dot(80, 22, 14);
  k.shape(k.ellipse(50, 56, 40, 36));
  for (final s in [-1.0, 1.0]) {
    k.withRotation(s * -25, () => k.oval(50 + s * 17, 54, 10, 13, k.fill), cx: 50 + s * 17, cy: 54);
    k.dot(50 + s * 16, 53, 3.8, k.blank);
    k.dot(50 + s * 16, 53.5, 2, k.fill);
  }
  k.oval(50, 68, 6, 4, k.fill);
  k.curve(44, 76, 50, 80, 56, 76, 3);
}

void penguin(Pen k) {
  final body = k.ellipse(50, 54, 36, 42);
  k.shape(body, dark: true);
  final belly = Path()
    ..moveTo(50, 30)
    ..cubicTo(78, 30, 76, 92, 50, 92)
    ..cubicTo(24, 92, 22, 30, 50, 30)
    ..close();
  k.c.drawPath(belly, k.blank);
  k.dot(40, 40, 4.5);
  k.dot(60, 40, 4.5);
  k.dot(39, 38.5, 1.4, k.blank);
  k.dot(59, 38.5, 1.4, k.blank);
  k.shape(Path()
    ..moveTo(43, 48)
    ..lineTo(57, 48)
    ..lineTo(50, 56)
    ..close(), body: k.tint(0.4), width: 2.5);
  k.oval(32, 52, 5, 3, k.tint(0.3));
  k.oval(68, 52, 5, 3, k.tint(0.3));
  k.oval(38, 94, 9, 4, k.fill);
  k.oval(62, 94, 9, 4, k.fill);
}

void frog(Pen k) {
  k.ring(30, 30, 14);
  k.ring(70, 30, 14);
  k.shape(k.ellipse(50, 60, 42, 30), body: k.tint(0.1));
  k.c.drawCircle(const Offset(30, 30), 14, k.blank);
  k.c.drawCircle(const Offset(70, 30), 14, k.blank);
  k.c.drawCircle(const Offset(30, 30), 14, k.stroke());
  k.c.drawCircle(const Offset(70, 30), 14, k.stroke());
  _eyeDot(k, 30, 31, 1.2);
  _eyeDot(k, 70, 31, 1.2);
  k.curve(28, 62, 50, 78, 72, 62, 4.5);
  k.oval(22, 66, 6, 3.5, k.tint(0.35));
  k.oval(78, 66, 6, 3.5, k.tint(0.35));
}

void music(Pen k) {
  k.oval(26, 78, 12, 9, k.fill);
  k.oval(72, 68, 12, 9, k.fill);
  k.line(36, 78, 36, 20, 5.5);
  k.line(82, 68, 82, 12, 5.5);
  k.shape(Path()
    ..moveTo(36, 20)
    ..lineTo(82, 10)
    ..lineTo(82, 24)
    ..lineTo(36, 34)
    ..close(), dark: true, width: 3);
}

void gamepad(Pen k) {
  final p = Path()
    ..moveTo(26, 30)
    ..lineTo(74, 30)
    ..cubicTo(94, 30, 100, 84, 84, 84)
    ..cubicTo(74, 84, 70, 68, 62, 68)
    ..lineTo(38, 68)
    ..cubicTo(30, 68, 26, 84, 16, 84)
    ..cubicTo(0, 84, 6, 30, 26, 30)
    ..close();
  k.shape(p, dark: true);
  final w = k.stroke(5, k.paper);
  k.c.drawLine(const Offset(20, 48), const Offset(36, 48), w);
  k.c.drawLine(const Offset(28, 40), const Offset(28, 56), w);
  k.dot(68, 44, 4.5, k.blank);
  k.dot(78, 52, 4.5, k.blank);
}

void camera(Pen k) {
  k.shape(k.rrect(8, 28, 92, 84, 12));
  k.shape(k.rrect(30, 18, 54, 30, 4), dark: true, width: 3);
  k.ring(50, 56, 19, dark: true);
  k.ring(50, 56, 10, width: 3);
  k.dot(46, 52, 3, k.blank);
  k.dot(78, 40, 4);
}

void bulb(Pen k) {
  final p = Path()
    ..moveTo(38, 70)
    ..cubicTo(38, 58, 20, 52, 20, 36)
    ..cubicTo(20, 16, 36, 6, 50, 6)
    ..cubicTo(64, 6, 80, 16, 80, 36)
    ..cubicTo(80, 52, 62, 58, 62, 70)
    ..close();
  k.shape(p);
  k.shape(k.rrect(38, 72, 62, 86, 4), dark: true, width: 3);
  k.line(42, 92, 58, 92, 5);
  k.poly([42, 58, 46, 40, 50, 50, 54, 40, 58, 58], width: 3);
  k.arc(50, 36, 20, 20, 200, 50, 3);
}

void eyes(Pen k) {
  for (final x in [28.0, 72.0]) {
    k.shape(k.ellipse(x, 50, 20, 30));
    k.oval(x + 5, 52, 9, 12, k.fill);
    k.dot(x + 2, 47, 3, k.blank);
  }
}

void crown(Pen k) {
  final p = Path()
    ..moveTo(10, 30)
    ..lineTo(30, 52)
    ..lineTo(50, 18)
    ..lineTo(70, 52)
    ..lineTo(90, 30)
    ..lineTo(82, 80)
    ..lineTo(18, 80)
    ..close();
  k.shape(p, body: k.tint(0.12));
  k.shape(k.rrect(16, 78, 84, 90, 4), dark: true, width: 3);
  k.dot(10, 28, 6);
  k.dot(50, 16, 6);
  k.dot(90, 28, 6);
  k.dot(50, 62, 6);
}

void gem(Pen k) {
  final p = Path()
    ..moveTo(26, 16)
    ..lineTo(74, 16)
    ..lineTo(94, 38)
    ..lineTo(50, 92)
    ..lineTo(6, 38)
    ..close();
  k.shape(p, body: k.tint(0.1));
  k.poly([6, 38, 94, 38], width: 3.5);
  k.poly([26, 16, 36, 38, 50, 16, 64, 38, 74, 16], width: 3.5);
  k.poly([36, 38, 50, 92, 64, 38], width: 3.5);
  k.withClip(Path()
    ..moveTo(36, 38)
    ..lineTo(64, 38)
    ..lineTo(50, 92)
    ..close(), () => k.c.drawRect(const Rect.fromLTRB(0, 0, 100, 100), k.tint(0.35)));
}

void trophy(Pen k) {
  k.arc(20, 36, 12, 14, 90, 180, 5);
  k.arc(80, 36, 12, 14, -90, 180, 5);
  k.shape(Path()
    ..moveTo(22, 14)
    ..lineTo(78, 14)
    ..lineTo(76, 44)
    ..cubicTo(74, 62, 26, 62, 24, 44)
    ..close(), body: k.tint(0.2));
  k.shape(k.rrect(44, 60, 56, 76, 2), width: 3.5);
  k.shape(k.rrect(28, 76, 72, 92, 5), dark: true, width: 3.5);
  k.star(50, 34, 10, width: 2);
}

void rocket(Pen k) {
  k.withRotation(45, () {
    k.shape(Path()
      ..moveTo(40, 68)
      ..lineTo(26, 86)
      ..lineTo(40, 82)
      ..close(), dark: true, width: 3);
    k.shape(Path()
      ..moveTo(60, 68)
      ..lineTo(74, 86)
      ..lineTo(60, 82)
      ..close(), dark: true, width: 3);
    k.shape(Path()
      ..moveTo(50, 4)
      ..cubicTo(70, 20, 66, 60, 62, 82)
      ..lineTo(38, 82)
      ..cubicTo(34, 60, 30, 20, 50, 4)
      ..close());
    k.ring(50, 40, 8, width: 4, dark: true);
    k.shape(k.drop(50, 94, 8), body: k.tint(0.3), width: 3);
  });
}

void speech(Pen k) {
  final p = Path()
    ..addRRect(RRect.fromLTRBR(8, 14, 92, 72, const Radius.circular(24)));
  final tail = Path()
    ..moveTo(26, 64)
    ..lineTo(18, 92)
    ..lineTo(46, 68)
    ..close();
  k.shape(Path.combine(PathOperation.union, p, tail));
  k.dot(32, 43, 5.5);
  k.dot(50, 43, 5.5);
  k.dot(68, 43, 5.5);
}

void bubbles(Pen k) {
  for (final b in [(38.0, 60.0, 26.0), (74.0, 30.0, 16.0), (80.0, 76.0, 10.0), (26.0, 18.0, 8.0)]) {
    k.c.drawCircle(Offset(b.$1, b.$2), b.$3, k.stroke(4));
    k.arc(b.$1, b.$2, b.$3 * 0.6, b.$3 * 0.6, 200, 60, 3);
  }
}

void wave(Pen k) {
  final p = Path()
    ..moveTo(4, 90)
    ..cubicTo(4, 40, 40, 8, 74, 16)
    ..cubicTo(94, 20, 94, 44, 78, 46)
    ..cubicTo(66, 48, 64, 36, 72, 32)
    ..cubicTo(50, 28, 36, 56, 52, 72)
    ..cubicTo(62, 80, 80, 76, 96, 70)
    ..lineTo(96, 90)
    ..close();
  k.shape(p, body: k.tint(0.2));
  k.curve(20, 80, 40, 64, 60, 84, 3);
}

void skull(Pen k) {
  final p = Path()
    ..moveTo(50, 8)
    ..cubicTo(80, 8, 92, 30, 88, 54)
    ..cubicTo(86, 64, 76, 66, 72, 72)
    ..lineTo(72, 90)
    ..lineTo(28, 90)
    ..lineTo(28, 72)
    ..cubicTo(24, 66, 14, 64, 12, 54)
    ..cubicTo(8, 30, 20, 8, 50, 8)
    ..close();
  k.shape(p);
  k.oval(34, 48, 11, 12, k.fill);
  k.oval(66, 48, 11, 12, k.fill);
  k.poly([46, 70, 50, 62, 54, 70], close: true, paint: k.fill);
  for (final x in [39.0, 50.0, 61.0]) {
    k.line(x, 80, x, 90, 3);
  }
}

void ghost(Pen k) {
  final p = Path()
    ..moveTo(16, 92)
    ..lineTo(16, 44)
    ..cubicTo(16, 4, 84, 4, 84, 44)
    ..lineTo(84, 92)
    ..quadraticBezierTo(76, 82, 67, 92)
    ..quadraticBezierTo(58, 82, 50, 92)
    ..quadraticBezierTo(42, 82, 33, 92)
    ..quadraticBezierTo(24, 82, 16, 92)
    ..close();
  k.withRotation(-8, () {
    k.shape(p);
    k.oval(38, 42, 6, 9, k.fill);
    k.oval(62, 42, 6, 9, k.fill);
    k.oval(50, 64, 7, 9, k.fill);
    k.mitt(14, 58, 11, angle: 40);
  });
}

void alien(Pen k) {
  final p = Path()
    ..moveTo(50, 94)
    ..cubicTo(26, 90, 10, 60, 10, 40)
    ..cubicTo(10, 14, 30, 6, 50, 6)
    ..cubicTo(70, 6, 90, 14, 90, 40)
    ..cubicTo(90, 60, 74, 90, 50, 94)
    ..close();
  k.shape(p, body: k.tint(0.12));
  for (final s in [-1.0, 1.0]) {
    k.withRotation(s * 30, () => k.oval(50 + s * 20, 50, 12, 18, k.fill), cx: 50 + s * 20, cy: 50);
    k.dot(50 + s * 18, 44, 3, k.blank);
  }
  k.line(44, 78, 56, 78, 3.5);
}

void robot(Pen k) {
  k.line(50, 6, 50, 20, 4);
  k.dot(50, 6, 5);
  k.shape(k.rrect(12, 20, 88, 86, 16));
  k.shape(k.rrect(4, 42, 12, 66, 3), dark: true, width: 3);
  k.shape(k.rrect(88, 42, 96, 66, 3), dark: true, width: 3);
  k.shape(k.rrect(22, 32, 78, 62, 10), dark: true, width: 3);
  k.dot(38, 47, 6, k.blank);
  k.dot(62, 47, 6, k.blank);
  k.shape(k.rrect(32, 70, 68, 78, 3), width: 3);
  for (final x in [41.0, 50.0, 59.0]) {
    k.line(x, 70, x, 78, 2);
  }
}

void poop(Pen k) {
  final p = Path()
    ..moveTo(10, 88)
    ..cubicTo(2, 72, 14, 64, 22, 64)
    ..cubicTo(14, 54, 22, 42, 32, 42)
    ..cubicTo(28, 30, 40, 22, 52, 22)
    ..quadraticBezierTo(56, 14, 50, 4)
    ..cubicTo(72, 10, 74, 30, 68, 42)
    ..cubicTo(80, 42, 86, 54, 78, 64)
    ..cubicTo(88, 64, 98, 74, 90, 88)
    ..close();
  k.shape(p, body: k.tint(0.35));
  k.curve(24, 64, 50, 70, 76, 64, 3);
  k.curve(34, 43, 50, 48, 66, 43, 3);
  _eyeDot(k, 40, 54);
  _eyeDot(k, 60, 54);
  final m = Path()
    ..moveTo(38, 72)
    ..cubicTo(40, 86, 60, 86, 62, 72)
    ..close();
  k.shape(m, dark: true, width: 2.5);
}
