import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'pen.dart';

enum Eye { dot, big, happy, closed, down, line, squeeze, heart, star, x, spiral, wide, half, up, side, teary, sleepy }

enum Mouth { none, smile, bigSmile, grin, beam, open, bigO, longO, small, flat, frown, openFrown, wavy, cat, tongue, kiss, teeth, smirk, zip, drool, confused, buck, tight }

enum Brow { none, angry, sad, raised, worried }

enum Extra {
  blush,
  sweat,
  sweats,
  tear,
  streams,
  halo,
  horns,
  zzz,
  hearts,
  heartKiss,
  steam,
  sunglasses,
  glasses,
  monocle,
  mask,
  thermometer,
  bandage,
  cowboy,
  party,
  handChin,
  handMouth,
  hug,
  cheeks,
  shush,
  anger,
  explode,
  snot,
  cursing,
  icicles,
  tissue,
  vomit,
  dizzy,
  fear,
  yawn,
  ears,
  whiskers,
  hot,
  nausea,
}

class FaceSpec {
  const FaceSpec({
    required this.l,
    Eye? r,
    this.mouth = Mouth.smile,
    this.brow = Brow.none,
    this.extras = const [],
    this.tilt = 0,
    this.shade = false,
  }) : r = r ?? l;

  final Eye l;
  final Eye r;
  final Mouth mouth;
  final Brow brow;
  final List<Extra> extras;
  final double tilt;
  final bool shade;
}

const _lx = 34.0;
const _rx = 66.0;
const _ey = 54.0;

Path headPath(Pen k) => k.ellipse(50, 53, 42, 39);

void drawFace(Pen k, FaceSpec f) {
  k.withRotation(f.tilt, () {
    final ex = f.extras;
    if (ex.contains(Extra.horns)) {
      k.shape(Path()
        ..moveTo(18, 30)
        ..quadraticBezierTo(8, 16, 12, 4)
        ..quadraticBezierTo(22, 14, 32, 20)
        ..close(), dark: true, width: 4);
      k.shape(Path()
        ..moveTo(82, 30)
        ..quadraticBezierTo(92, 16, 88, 4)
        ..quadraticBezierTo(78, 14, 68, 20)
        ..close(), dark: true, width: 4);
    }
    if (ex.contains(Extra.ears)) {
      for (final s in [-1.0, 1.0]) {
        final p = Path()
          ..moveTo(50 + s * 18, 18)
          ..lineTo(50 + s * 38, 2)
          ..lineTo(50 + s * 40, 32)
          ..close();
        k.shape(p, width: 4.5);
        k.solid(Path()
          ..moveTo(50 + s * 25, 17)
          ..lineTo(50 + s * 35, 10)
          ..lineTo(50 + s * 36, 24)
          ..close());
      }
    }
    if (ex.contains(Extra.explode)) {
      k.cloud(50, 16, 26, width: 4.5);
    }
    final head = headPath(k);
    k.shape(head, body: f.shade ? k.tint(0.18) : null);
    if (ex.contains(Extra.nausea)) {
      k.withClip(head, () => k.c.drawRect(const Rect.fromLTRB(0, 60, 100, 100), k.tint(0.3)));
      k.c.drawPath(head, k.stroke());
    }
    if (ex.contains(Extra.hot)) {
      k.withClip(head, () => k.c.drawRect(const Rect.fromLTRB(0, 0, 100, 100), k.tint(0.22)));
      k.c.drawPath(head, k.stroke());
    }
    if (ex.contains(Extra.fear)) {
      k.withClip(head, () {
        for (var i = 0; i < 5; i++) {
          k.line(36 + i * 7.0, 14, 36 + i * 7.0, 32, 3.5, k.tint(0.5).color);
        }
      });
    }
    if (ex.contains(Extra.icicles)) {
      k.withClip(head, () => k.c.drawRect(const Rect.fromLTRB(0, 0, 100, 34), k.tint(0.28)));
      k.c.drawPath(head, k.stroke());
    }
    if (ex.contains(Extra.blush)) {
      k.oval(22, 66, 7, 4, k.tint(0.3));
      k.oval(78, 66, 7, 4, k.tint(0.3));
    }
    if (ex.contains(Extra.whiskers)) {
      for (final s in [-1.0, 1.0]) {
        k.line(50 + s * 30, 66, 50 + s * 47, 62, 2.5);
        k.line(50 + s * 30, 71, 50 + s * 47, 73, 2.5);
      }
    }
    _eye(k, f.l, _lx, -1);
    _eye(k, f.r, _rx, 1);
    _brows(k, f.brow);
    _mouth(k, f.mouth);
    for (final e in ex) {
      _extra(k, e);
    }
  });
}

void _eye(Pen k, Eye e, double x, double side) {
  const y = _ey;
  switch (e) {
    case Eye.dot:
      k.oval(x, y, 5.5, 7.5, k.fill);
      k.dot(x - 1.8, y - 3, 2.2, k.blank);
    case Eye.big:
      k.oval(x, y, 7.5, 9.5, k.fill);
      k.dot(x - 2.5, y - 3.5, 3, k.blank);
      k.dot(x + 2.5, y + 3.5, 1.4, k.blank);
    case Eye.teary:
      k.oval(x, y, 8.5, 10.5, k.fill);
      k.dot(x - 2.5, y - 4, 3.6, k.blank);
      k.dot(x + 3, y + 1, 1.8, k.blank);
      k.arc(x, y + 2, 7.5, 7, 20, 140, 2.2);
      k.c.drawArc(Rect.fromCenter(center: Offset(x, y + 2), width: 15, height: 14), rad(25), rad(130), false, k.stroke(2.2, k.paper));
    case Eye.happy:
      k.curve(x - 7, y + 3, x, y - 9, x + 7, y + 3);
    case Eye.closed:
      k.curve(x - 7, y - 2, x, y + 8, x + 7, y - 2);
    case Eye.down:
      k.curve(x - 7, y + 1, x, y + 6, x + 7, y + 1);
    case Eye.sleepy:
      k.curve(x - 7, y + 1, x, y + 6, x + 7, y + 1);
      k.line(x - 8, y - 1, x + 8, y - 1, 3);
    case Eye.line:
      k.line(x - 7, y, x + 7, y);
    case Eye.squeeze:
      k.poly([x - 6 * side, y - 6, x + 5 * side, y, x - 6 * side, y + 6]);
    case Eye.heart:
      k.heart(x, y, 8.5);
    case Eye.star:
      k.star(x, y, 9.5, width: 2.5);
    case Eye.x:
      k.line(x - 6, y - 6, x + 6, y + 6);
      k.line(x + 6, y - 6, x - 6, y + 6);
    case Eye.spiral:
      final p = Path()..moveTo(x, y);
      for (var i = 1; i <= 28; i++) {
        final a = i * 0.45;
        final r = i * 0.3;
        p.lineTo(x + math.cos(a) * r, y + math.sin(a) * r);
      }
      k.c.drawPath(p, k.stroke(2.6));
    case Eye.wide:
      k.ring(x, y, 9.5, width: 3.5);
      k.dot(x, y + 1, 3.6);
    case Eye.half:
      k.withClip(Path()..addRect(Rect.fromLTRB(x - 12, y - 1, x + 12, y + 12)), () {
        k.oval(x + 2.5, y + 1, 5.5, 7, k.fill);
      });
      k.line(x - 8, y - 1, x + 8, y - 1, 4);
    case Eye.up:
      k.ring(x, y, 8.5, width: 3.5);
      k.dot(x, y - 4, 3.4);
    case Eye.side:
      k.ring(x, y, 8.5, width: 3.5);
      k.dot(x + 3.5, y - 3.5, 3.4);
  }
}

void _brows(Pen k, Brow b) {
  switch (b) {
    case Brow.none:
      return;
    case Brow.angry:
      k.line(_lx - 8, _ey - 15, _lx + 7, _ey - 9, 4.5);
      k.line(_rx + 8, _ey - 15, _rx - 7, _ey - 9, 4.5);
    case Brow.sad:
      k.line(_lx - 8, _ey - 10, _lx + 6, _ey - 15, 4);
      k.line(_rx + 8, _ey - 10, _rx - 6, _ey - 15, 4);
    case Brow.worried:
      k.curve(_lx - 8, _ey - 11, _lx, _ey - 17, _lx + 7, _ey - 15, 3.5);
      k.curve(_rx + 8, _ey - 11, _rx, _ey - 17, _rx - 7, _ey - 15, 3.5);
    case Brow.raised:
      k.line(_lx - 7, _ey - 12, _lx + 7, _ey - 12, 4);
      k.curve(_rx - 8, _ey - 15, _rx, _ey - 23, _rx + 8, _ey - 17, 4);
  }
}

void _mouth(Pen k, Mouth m) {
  switch (m) {
    case Mouth.none:
      return;
    case Mouth.smile:
      k.curve(42, 69, 50, 78, 58, 69, 4.5);
    case Mouth.bigSmile:
      final p = Path()
        ..moveTo(38, 67)
        ..cubicTo(38, 87, 62, 87, 62, 67)
        ..close();
      k.shape(p, dark: true, width: 3.5);
      k.withClip(p, () => k.oval(50, 82, 8, 5, k.tint(0.45)));
    case Mouth.grin:
      final p = Path()
        ..moveTo(37, 66)
        ..cubicTo(37, 86, 63, 86, 63, 66)
        ..close();
      k.shape(p, dark: true, width: 3.5);
      k.withClip(p, () => k.c.drawRect(const Rect.fromLTRB(30, 60, 70, 71.5), k.blank));
      k.c.drawPath(p, k.stroke(3.5));
    case Mouth.beam:
      final p = Path()
        ..moveTo(34, 66)
        ..cubicTo(36, 84, 64, 84, 66, 66)
        ..close();
      k.shape(p, width: 3.5);
      k.line(35, 71.5, 65, 71.5, 2.5);
      for (final x in [42.0, 50.0, 58.0]) {
        k.line(x, 67, x, 78, 2.2);
      }
    case Mouth.open:
      k.oval(50, 74, 5.5, 6.5, k.fill);
    case Mouth.small:
      k.oval(50, 73, 3, 3.5, k.fill);
    case Mouth.bigO:
      k.oval(50, 75, 8, 10, k.fill);
    case Mouth.longO:
      k.oval(50, 77, 6.5, 13, k.fill);
      k.oval(50, 83, 4, 5, k.tint(0.5));
    case Mouth.flat:
      k.line(43, 73, 57, 73, 4.5);
    case Mouth.tight:
      k.line(40, 73, 60, 73, 4.5);
      k.line(40, 73, 38, 70, 3.5);
      k.line(60, 73, 62, 70, 3.5);
    case Mouth.frown:
      k.curve(42, 77, 50, 68, 58, 77, 4.5);
    case Mouth.openFrown:
      final p = Path()
        ..moveTo(40, 81)
        ..cubicTo(40, 65, 60, 65, 60, 81)
        ..close();
      k.shape(p, dark: true, width: 3.5);
    case Mouth.wavy:
      final p = Path()..moveTo(37, 74);
      for (var i = 1; i <= 26; i++) {
        p.lineTo(37 + i.toDouble(), 74 + math.sin(i / 26 * math.pi * 3) * 3.2);
      }
      k.c.drawPath(p, k.stroke(4));
    case Mouth.cat:
      k.c.drawPath(Path()
        ..moveTo(40, 70)
        ..quadraticBezierTo(45, 78, 50, 71)
        ..quadraticBezierTo(55, 78, 60, 70), k.stroke(4));
    case Mouth.tongue:
      k.curve(40, 69, 50, 76, 60, 69, 4.5);
      final t = Path()
        ..moveTo(47, 72)
        ..lineTo(47, 80)
        ..arcToPoint(const Offset(59, 80), radius: const Radius.circular(6), clockwise: false)
        ..lineTo(59, 71)
        ..close();
      k.shape(t, width: 3.5, body: k.tint(0.3));
      k.line(53, 74, 53, 80, 2.2);
    case Mouth.kiss:
      k.c.drawPath(Path()
        ..moveTo(47, 65)
        ..quadraticBezierTo(57, 67, 50, 72)
        ..quadraticBezierTo(57, 77, 47, 79), k.stroke(4));
    case Mouth.teeth:
      final p = k.rrect(36, 66, 64, 80, 5);
      k.shape(p, width: 3.5);
      k.line(36, 73, 64, 73, 2.4);
      for (final x in [43.0, 50.0, 57.0]) {
        k.line(x, 66, x, 80, 2.4);
      }
    case Mouth.smirk:
      k.curve(42, 74, 52, 77, 60, 67, 4.5);
    case Mouth.zip:
      k.line(37, 73, 62, 73, 4);
      for (var x = 40.0; x <= 58; x += 4.5) {
        k.line(x, 69.5, x, 76.5, 2.2);
      }
      k.ring(64, 73, 3, width: 2.5);
    case Mouth.drool:
      k.oval(47, 73, 5, 5.5, k.fill);
      k.shape(k.drop(55, 84, 6), width: 2.5, body: k.tint(0.2));
    case Mouth.confused:
      k.line(42, 76, 58, 70, 4.5);
    case Mouth.buck:
      final p = Path()
        ..moveTo(38, 67)
        ..cubicTo(38, 85, 62, 85, 62, 67)
        ..close();
      k.shape(p, dark: true, width: 3.5);
      k.c.drawRect(const Rect.fromLTRB(44.5, 67, 49.3, 74), k.blank);
      k.c.drawRect(const Rect.fromLTRB(50.7, 67, 55.5, 74), k.blank);
  }
}

void _extra(Pen k, Extra e) {
  switch (e) {
    case Extra.blush || Extra.whiskers || Extra.horns || Extra.ears || Extra.explode || Extra.fear || Extra.icicles || Extra.hot || Extra.nausea:
      return;
    case Extra.sweat:
      k.shape(k.drop(83, 30, 9), width: 3, body: k.tint(0.15));
    case Extra.sweats:
      k.shape(k.drop(84, 28, 8), width: 3, body: k.tint(0.15));
      k.shape(k.drop(15, 40, 6), width: 3, body: k.tint(0.15));
      k.shape(k.drop(90, 50, 5), width: 2.5, body: k.tint(0.15));
    case Extra.tear:
      k.shape(k.drop(28, 70, 7), width: 3, body: k.tint(0.15));
    case Extra.streams:
      for (final x in [_lx, _rx]) {
        final p = Path()
          ..moveTo(x - 5, _ey + 6)
          ..quadraticBezierTo(x - 9, _ey + 26, x - 7, 94)
          ..lineTo(x + 5, 94)
          ..quadraticBezierTo(x + 3, _ey + 26, x + 5, _ey + 6)
          ..close();
        k.shape(p, width: 3, body: k.tint(0.2));
      }
    case Extra.halo:
      k.oval(50, 9, 25, 6.5, k.stroke(4.5));
    case Extra.zzz:
      k.z(80, 18, 5);
      k.z(92, 6, 3.5, 3);
    case Extra.hearts:
      k.heart(88, 26, 7);
      k.heart(12, 34, 6);
      k.heart(86, 82, 6);
    case Extra.heartKiss:
      k.heart(78, 78, 6.5);
    case Extra.steam:
      k.cloud(14, 80, 10, width: 3.5);
      k.cloud(86, 80, 10, width: 3.5);
    case Extra.sunglasses:
      for (final x in [_lx, _rx]) {
        final p = Path()
          ..moveTo(x - 13, _ey - 8)
          ..lineTo(x + 13, _ey - 8)
          ..quadraticBezierTo(x + 13, _ey + 11, x, _ey + 10)
          ..quadraticBezierTo(x - 13, _ey + 10, x - 13, _ey - 8)
          ..close();
        k.shape(p, dark: true, width: 3);
        k.line(x - 7, _ey - 3, x - 2, _ey - 3, 2.2, k.paper);
      }
      k.line(12, _ey - 6, 88, _ey - 6, 3.5);
    case Extra.glasses:
      k.c.drawCircle(const Offset(_lx, _ey), 12, k.stroke(3.5));
      k.c.drawCircle(const Offset(_rx, _ey), 12, k.stroke(3.5));
      k.line(_lx + 12, _ey, _rx - 12, _ey, 3.5);
      k.line(_lx - 12, _ey - 2, 10, _ey - 6, 3.5);
      k.line(_rx + 12, _ey - 2, 90, _ey - 6, 3.5);
    case Extra.monocle:
      k.c.drawCircle(const Offset(_rx, _ey), 13, k.stroke(3.5));
      k.curve(_rx + 6, _ey + 12, 80, 80, 74, 96, 2);
    case Extra.mask:
      final p = Path()
        ..moveTo(24, 62)
        ..quadraticBezierTo(50, 56, 76, 62)
        ..lineTo(74, 80)
        ..quadraticBezierTo(50, 94, 26, 80)
        ..close();
      k.shape(p, width: 3.5);
      k.line(30, 70, 70, 70, 2.2);
      k.line(32, 77, 68, 77, 2.2);
      k.line(24, 64, 10, 56, 3);
      k.line(76, 64, 90, 56, 3);
    case Extra.thermometer:
      k.withRotation(-35, () {
        k.shape(k.rrect(47, 68, 53, 98, 3), width: 3);
        k.dot(50, 96, 5);
      }, cx: 50, cy: 74);
    case Extra.bandage:
      k.withRotation(-30, () {
        k.shape(k.rrect(56, 14, 86, 25, 4), width: 3, body: k.tint(0.1));
        k.line(66, 17, 66, 22, 2);
        k.line(76, 17, 76, 22, 2);
      }, cx: 71, cy: 20);
    case Extra.cowboy:
      final crown = Path()
        ..moveTo(28, 22)
        ..quadraticBezierTo(30, 0, 42, 4)
        ..quadraticBezierTo(50, 10, 58, 4)
        ..quadraticBezierTo(70, 0, 72, 22)
        ..close();
      k.shape(crown, dark: true, width: 3.5);
      k.shape(Path()
        ..moveTo(4, 18)
        ..quadraticBezierTo(50, 36, 96, 18)
        ..quadraticBezierTo(50, 28, 4, 18)
        ..close(), dark: true, width: 4);
    case Extra.party:
      k.withRotation(-18, () {
        final hat = Path()
          ..moveTo(36, 22)
          ..lineTo(50, -8)
          ..lineTo(64, 22)
          ..close();
        k.shape(hat, width: 3.5);
        k.withClip(hat, () {
          k.line(30, 10, 70, 2, 4);
          k.line(30, 20, 70, 12, 4);
        });
        k.dot(50, -8, 4);
      }, cx: 50, cy: 20);
      k.withRotation(-20, () {
        final horn = Path()
          ..moveTo(55, 74)
          ..lineTo(88, 66)
          ..lineTo(88, 84)
          ..close();
        k.shape(horn, width: 3.5, body: k.tint(0.2));
      }, cx: 55, cy: 74);
    case Extra.handChin:
      k.mitt(64, 86, 16, angle: -20);
    case Extra.handMouth:
      k.mitt(52, 78, 17, angle: 10);
    case Extra.yawn:
      k.mitt(60, 80, 15, angle: -10);
    case Extra.hug:
      k.mitt(16, 80, 15, angle: 30);
      k.mitt(84, 80, 15, angle: -30);
    case Extra.cheeks:
      k.mitt(13, 70, 15, angle: 20);
      k.mitt(87, 70, 15, angle: -20);
    case Extra.shush:
      k.shape(k.rrect(45, 60, 55, 92, 5), width: 3.5);
      k.shape(k.rrect(40, 82, 60, 98, 7), width: 3.5);
    case Extra.anger:
      for (final a in [0.0, 90.0, 180.0, 270.0]) {
        k.withRotation(a, () => k.curve(84, 16, 88, 20, 92, 16, 3.5), cx: 88, cy: 20);
      }
    case Extra.snot:
      k.c.drawCircle(const Offset(62, 66), 7, k.stroke(2.5));
      k.dot(59.5, 63.5, 1.6);
    case Extra.cursing:
      k.shape(k.rrect(32, 64, 68, 82, 5), dark: true, width: 3);
      final w = k.stroke(2.2, k.paper);
      k.c.drawLine(const Offset(38, 69), const Offset(38, 77), w);
      k.c.drawLine(const Offset(41, 69), const Offset(41, 77), w);
      k.c.drawLine(const Offset(36, 71), const Offset(43, 71), w);
      k.c.drawLine(const Offset(36, 75), const Offset(43, 75), w);
      k.c.drawLine(const Offset(49, 68), const Offset(49, 74), w);
      k.c.drawCircle(const Offset(49, 77.5), 1.2, Paint()..color = k.paper);
      k.c.drawCircle(const Offset(59, 73), 4, w);
    case Extra.tissue:
      k.withRotation(-15, () {
        final p = Path()
          ..moveTo(60, 64)
          ..lineTo(88, 60)
          ..lineTo(92, 88)
          ..lineTo(64, 92)
          ..close();
        k.shape(p, width: 3);
        k.curve(66, 72, 76, 68, 84, 72, 2);
      }, cx: 75, cy: 76);
    case Extra.vomit:
      final p = Path()
        ..moveTo(42, 74)
        ..quadraticBezierTo(34, 90, 30, 100)
        ..lineTo(70, 100)
        ..quadraticBezierTo(66, 90, 58, 74)
        ..close();
      k.shape(p, width: 3.5, body: k.tint(0.35));
      k.dot(44, 90, 2.5, k.blank);
      k.dot(55, 94, 2, k.blank);
    case Extra.dizzy:
      k.star(16, 20, 6, width: 2);
      k.star(84, 16, 5, width: 2);
      k.star(92, 44, 4, width: 2);
  }
}
