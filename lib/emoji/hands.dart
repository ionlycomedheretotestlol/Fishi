import 'package:flutter/material.dart';

import 'pen.dart';

Path _cap(double x1, double y1, double x2, double y2, double w) {
  final l = x1 < x2 ? x1 : x2;
  final r = x1 < x2 ? x2 : x1;
  final t = y1 < y2 ? y1 : y2;
  final b = y1 < y2 ? y2 : y1;
  return Path()..addRRect(RRect.fromLTRBR(l - w / 2, t - w / 2, r + w / 2, b + w / 2, Radius.circular(w / 2)));
}

void openHand(Pen k, List<bool> f, {double angle = 0, double cx = 50, double cy = 50, double scale = 1}) {
  k.c.save();
  k.c.translate(cx, cy);
  k.c.scale(scale);
  k.c.rotate(rad(angle));
  k.c.translate(-50, -50);
  const xs = [38.5, 47.0, 55.5, 64.0];
  const lens = [22.0, 25.0, 23.0, 18.0];
  var shape = Path()..addRRect(RRect.fromLTRBR(32, 44, 70, 84, const Radius.circular(14)));
  shape = Path.combine(PathOperation.union, shape, k.rrect(40, 78, 62, 98, 6));
  for (var i = 0; i < 4; i++) {
    final x = xs[i];
    final finger = f[i + 1] ? _cap(x, 48 - lens[i], x, 50, 9) : _cap(x, 44, x, 52, 9);
    shape = Path.combine(PathOperation.union, shape, finger);
  }
  final thumb = f[0]
      ? (Path()
        ..moveTo(34, 60)
        ..lineTo(20, 44)
        ..arcToPoint(const Offset(13, 51), radius: const Radius.circular(5))
        ..lineTo(30, 74)
        ..close())
      : _cap(36, 62, 52, 62, 10);
  if (f[0]) shape = Path.combine(PathOperation.union, shape, thumb);
  k.shape(shape, width: 4.5);
  if (!f[0]) k.shape(thumb, width: 3.5);
  for (var i = 0; i < 4; i++) {
    if (!f[i + 1]) k.line(xs[i], 50, xs[i], 53, 2.5);
  }
  k.line(44, 88, 58, 88, 2.5);
  k.c.restore();
}

void thumbHand(Pen k, {bool down = false}) {
  k.withRotation(down ? 180 : 0, () {
    var s = k.rrect(34, 44, 72, 84, 12);
    s = Path.combine(PathOperation.union, s, _cap(42, 18, 42, 50, 13));
    s = Path.combine(PathOperation.union, s, k.rrect(70, 48, 82, 82, 4));
    k.shape(s, width: 4.5);
    for (final y in [54.0, 63.0, 72.0]) {
      k.curve(50, y, 58, y + 2, 66, y, 2.8);
    }
    k.line(70, 50, 70, 80, 2.5);
  });
}

void fistFront(Pen k) {
  var s = k.rrect(28, 34, 72, 78, 14);
  s = Path.combine(PathOperation.union, s, k.rrect(38, 72, 62, 94, 6));
  k.shape(s, width: 4.5);
  for (final x in [39.0, 50.0, 61.0]) {
    k.line(x, 36, x, 48, 2.8);
  }
  k.shape(_cap(34, 58, 58, 58, 11), width: 3.5);
}

void okHand(Pen k) {
  var s = k.rrect(34, 46, 70, 84, 13);
  s = Path.combine(PathOperation.union, s, k.rrect(40, 78, 62, 98, 6));
  s = Path.combine(PathOperation.union, s, _cap(50, 22, 50, 50, 9));
  s = Path.combine(PathOperation.union, s, _cap(58.5, 22, 58.5, 50, 9));
  s = Path.combine(PathOperation.union, s, _cap(66, 28, 66, 50, 8.5));
  k.shape(s, width: 4.5);
  k.ring(34, 44, 11, width: 4.5);
  k.c.drawCircle(const Offset(34, 44), 4, k.blank);
  k.c.drawCircle(const Offset(34, 44), 4.6, k.stroke(3));
}

void prayHands(Pen k) {
  for (final side in [-1.0, 1.0]) {
    final p = Path()
      ..moveTo(50, 14)
      ..quadraticBezierTo(50 + side * 22, 30, 50 + side * 24, 64)
      ..lineTo(50 + side * 18, 92)
      ..lineTo(50, 92)
      ..close();
    k.shape(p, width: 4.5);
  }
  k.line(50, 16, 50, 92, 3);
  k.line(20, 30, 14, 24, 3);
  k.line(80, 30, 86, 24, 3);
  k.line(16, 44, 8, 42, 3);
  k.line(84, 44, 92, 42, 3);
}

void clapHands(Pen k) {
  openHand(k, const [true, true, true, true, true], angle: -30, cx: 40, cy: 56, scale: 0.72);
  openHand(k, const [true, true, true, true, true], angle: 22, cx: 62, cy: 52, scale: 0.72);
  k.line(18, 18, 24, 26, 3.5);
  k.line(34, 8, 36, 18, 3.5);
  k.line(82, 14, 76, 22, 3.5);
}

void raiseHands(Pen k) {
  openHand(k, const [true, true, true, true, true], angle: -14, cx: 28, cy: 56, scale: 0.6);
  k.c.save();
  k.c.translate(100, 0);
  k.c.scale(-1, 1);
  openHand(k, const [true, true, true, true, true], angle: -14, cx: 28, cy: 56, scale: 0.6);
  k.c.restore();
  k.line(40, 10, 42, 20, 3.5);
  k.line(50, 6, 50, 16, 3.5);
  k.line(60, 10, 58, 20, 3.5);
}

void waveHand(Pen k) {
  openHand(k, const [true, true, true, true, true], angle: 18, cx: 52, cy: 52, scale: 0.88);
  k.curve(12, 30, 8, 42, 12, 54, 3.5);
  k.curve(84, 18, 92, 26, 94, 36, 3.5);
}

void flexArm(Pen k) {
  final p = Path()
    ..moveTo(16, 92)
    ..lineTo(14, 60)
    ..quadraticBezierTo(18, 30, 52, 42)
    ..quadraticBezierTo(60, 26, 50, 16)
    ..quadraticBezierTo(62, 4, 74, 14)
    ..quadraticBezierTo(80, 30, 72, 50)
    ..quadraticBezierTo(90, 60, 84, 80)
    ..quadraticBezierTo(70, 96, 40, 92)
    ..close();
  k.shape(p, width: 4.5);
  k.curve(46, 56, 62, 50, 74, 60, 3);
  k.curve(56, 24, 60, 30, 66, 26, 2.5);
}

void heartHands(Pen k) {
  final p = k.heartPath(50, 50, 38);
  k.c.drawPath(p, k.stroke(15));
  k.c.drawPath(p, k.stroke(7, k.paper));
  k.line(22, 26, 28, 32, 2.5);
  k.line(78, 26, 72, 32, 2.5);
  k.line(50, 88, 50, 94, 2.5);
}

void crossedFingers(Pen k) {
  var s = k.rrect(32, 50, 70, 86, 13);
  s = Path.combine(PathOperation.union, s, k.rrect(40, 80, 62, 98, 6));
  for (final x in [59.0, 66.0]) {
    s = Path.combine(PathOperation.union, s, _cap(x, 46, x, 54, 8.5));
  }
  k.shape(s, width: 4.5);
  k.withRotation(10, () => k.shape(_cap(44, 16, 44, 56, 9.5), width: 4), cx: 44, cy: 56);
  k.withRotation(-14, () => k.shape(_cap(50, 18, 50, 56, 9.5), width: 4), cx: 50, cy: 56);
  k.shape(_cap(36, 66, 52, 66, 10), width: 3.5);
}
