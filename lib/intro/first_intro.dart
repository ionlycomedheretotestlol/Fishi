import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import '../brand/avatar.dart';
import '../brand/fish_logo.dart';
import '../chat/bubble_shape.dart';
import '../core/data.dart';
import '../core/motion.dart';
import '../core/theme.dart';
import '../core/i18n.dart';

class FirstIntro extends StatefulWidget {
  const FirstIntro({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  State<FirstIntro> createState() => _FirstIntroState();
}

class _FirstIntroState extends State<FirstIntro> with SingleTickerProviderStateMixin {
  static const scene = 3.6;
  static const total = scene * 4 + 0.8;
  late final AnimationController _c =
      AnimationController(vsync: this, duration: Duration(milliseconds: (total * 1000).round()));
  final _music = AudioPlayer();
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _music.setAudioContext(AudioContextConfig(focus: AudioContextConfigFocus.mixWithOthers).build());
    _music.play(AssetSource('sounds/intro.wav'));
    _c.forward().whenComplete(_finish);
  }

  void _finish() {
    if (_done) return;
    _done = true;
    _music.setVolume(0);
    widget.onDone();
  }

  @override
  void dispose() {
    _c.dispose();
    _music.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _finish,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final secs = _c.value * total;
          final i = (secs / scene).floor().clamp(0, 3);
          final local = ((secs - i * scene) / scene).clamp(0.0, 1.0);
          final out = secs > scene * 4 ? ((secs - scene * 4) / 0.8).clamp(0.0, 1.0) : 0.0;
          final dark = i >= 2 && !(i == 2 && local < 0.35);
          final theme = buildTheme(dark ? Brightness.dark : Brightness.light);
          return Theme(
            data: theme,
            child: Builder(builder: (context) {
              final p = Palette.of(context);
              return Opacity(
                opacity: 1 - out,
                child: Scaffold(
                  backgroundColor: p.paper,
                  body: Stack(children: [
                    if (i == 2) _ThemeWipe(t: local),
                    Positioned.fill(child: _Bubbles(t: secs / total, color: p.ink)),
                    Center(
                      child: switch (i) {
                        0 => _SceneLogo(t: local),
                        1 => _SceneBubbles(t: local),
                        2 => _SceneTheme(t: local),
                        _ => _SceneFinn(t: local),
                      },
                    ),
                    Positioned(
                      bottom: 40 + MediaQuery.paddingOf(context).bottom,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (var k = 0; k < 4; k++)
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 400),
                              curve: kSmooth,
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              width: k == i ? 22 : 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: p.ink.withValues(alpha: k == i ? 0.9 : 0.25),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Positioned(
                      top: MediaQuery.paddingOf(context).top + 12,
                      right: 20,
                      child: Text(tr('Tap to skip'), style: TextStyle(color: p.muted, fontSize: 13)),
                    ),
                  ]),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

double _seg(double t, double a, double b, [Curve c = kSmooth]) => c.transform(((t - a) / (b - a)).clamp(0.0, 1.0));

class _Caption extends StatelessWidget {
  const _Caption({required this.title, required this.sub, required this.t});

  final String title;
  final String sub;
  final double t;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final a = _seg(t, 0.25, 0.5);
    final b = _seg(t, 0.33, 0.6);
    final exit = _seg(t, 0.88, 1.0, Curves.easeIn);
    return Opacity(
      opacity: (1 - exit),
      child: Column(children: [
        Opacity(
          opacity: a,
          child: Transform.translate(
            offset: Offset(0, 16 * (1 - a)),
            child: Text(title, style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700, letterSpacing: -0.8, color: p.ink)),
          ),
        ),
        const SizedBox(height: 8),
        Opacity(
          opacity: b,
          child: Transform.translate(
            offset: Offset(0, 12 * (1 - b)),
            child: Text(sub, textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: p.muted, height: 1.35)),
          ),
        ),
      ]),
    );
  }
}

class _SceneLogo extends StatelessWidget {
  const _SceneLogo({required this.t});
  final double t;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final swim = _seg(t, 0, 0.45);
    final exit = _seg(t, 0.88, 1.0, Curves.easeIn);
    final x = (1 - swim) * -260;
    final y = math.sin(swim * math.pi * 2) * 18 * (1 - swim);
    final tilt = math.sin(swim * math.pi * 2) * 0.18 * (1 - swim);
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Transform.translate(
        offset: Offset(x, y - exit * 30),
        child: Transform.rotate(
          angle: tilt,
          child: Opacity(
            opacity: (swim * 1.4).clamp(0, 1) * (1 - exit),
            child: FishLogo(size: 150, color: p.ink, eyeColor: p.paper),
          ),
        ),
      ),
      const SizedBox(height: 18),
      _Caption(title: tr('Say hi to Fishi'), sub: tr('Messaging that feels calm.'), t: t),
    ]);
  }
}

class _SceneBubbles extends StatelessWidget {
  const _SceneBubbles({required this.t});
  final double t;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    const shapes = [BubbleShape.classic, BubbleShape.cloud, BubbleShape.fish, BubbleShape.pill, BubbleShape.bolt, BubbleShape.soft];
    final k = (t * 6.5).floor().clamp(0, shapes.length - 1);
    final phase = (t * 6.5) % 1;
    final pop = Curves.elasticOut.transform((phase * 1.6).clamp(0, 1));
    final enter = _seg(t, 0, 0.18, kSpring);
    final exit = _seg(t, 0.88, 1.0, Curves.easeIn);
    final style = BubbleStyle(shape: shapes[k]);
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Opacity(
        opacity: enter * (1 - exit),
        child: Transform.scale(
          scale: (0.85 + 0.15 * pop) * (0.6 + 0.4 * enter),
          child: BubbleBox(
            style: style,
            mine: true,
            tail: true,
            child: Text(tr('hey, this one is mine'), style: TextStyle(fontSize: 19, color: bubbleText(style, p, mine: true))),
          ),
        ),
      ),
      const SizedBox(height: 14),
      Opacity(
        opacity: _seg(t, 0.12, 0.3) * (1 - exit),
        child: BubbleBox(
          style: const BubbleStyle(),
          mine: false,
          tail: true,
          child: Text(tr('cute. everyone sees it?'), style: TextStyle(fontSize: 17, color: bubbleText(const BubbleStyle(), p, mine: false))),
        ),
      ),
      const SizedBox(height: 34),
      _Caption(title: tr('Your bubble. Your shape.'), sub: tr('Pick a style. Everyone sees it.'), t: t),
    ]);
  }
}

class _ThemeWipe extends StatelessWidget {
  const _ThemeWipe({required this.t});
  final double t;

  @override
  Widget build(BuildContext context) {
    final r = _seg(t, 0.12, 0.42, Curves.easeInOutCubic);
    if (r >= 1) return const SizedBox.shrink();
    final size = MediaQuery.sizeOf(context);
    final max = math.sqrt(size.width * size.width + size.height * size.height);
    return Positioned.fill(
      child: CustomPaint(
        painter: _WipePainter(
          radius: r * max,
          light: Palette.light.paper,
          dark: Palette.dark.paper,
          center: Offset(size.width / 2, size.height / 2),
        ),
      ),
    );
  }
}

class _WipePainter extends CustomPainter {
  _WipePainter({required this.radius, required this.light, required this.dark, required this.center});
  final double radius;
  final Color light;
  final Color dark;
  final Offset center;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = light);
    canvas.drawCircle(center, radius, Paint()..color = dark);
  }

  @override
  bool shouldRepaint(_WipePainter old) => old.radius != radius;
}

class _SceneTheme extends StatelessWidget {
  const _SceneTheme({required this.t});
  final double t;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final spin = _seg(t, 0.1, 0.45);
    final exit = _seg(t, 0.88, 1.0, Curves.easeIn);
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Opacity(
        opacity: 1 - exit,
        child: Transform.rotate(
          angle: spin * math.pi,
          child: SizedBox.square(
            dimension: 110,
            child: CustomPaint(painter: _YinYang(ink: p.ink, paper: p.paper)),
          ),
        ),
      ),
      const SizedBox(height: 26),
      _Caption(title: tr('Calm white. Calm black.'), sub: tr('Light, dark, or follow your phone.'), t: t),
    ]);
  }
}

class _YinYang extends CustomPainter {
  _YinYang({required this.ink, required this.paper});
  final Color ink;
  final Color paper;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    final c = size.center(Offset.zero);
    canvas.drawCircle(c, r, Paint()..color = paper);
    canvas.drawPath(
      Path()
        ..moveTo(c.dx, c.dy - r)
        ..arcToPoint(Offset(c.dx, c.dy + r), radius: Radius.circular(r))
        ..arcToPoint(Offset(c.dx, c.dy), radius: Radius.circular(r / 2))
        ..arcToPoint(Offset(c.dx, c.dy - r), radius: Radius.circular(r / 2), clockwise: false),
      Paint()..color = ink,
    );
    canvas.drawCircle(c, r, Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3);
  }

  @override
  bool shouldRepaint(_YinYang old) => old.ink != ink;
}

class _SceneFinn extends StatelessWidget {
  const _SceneFinn({required this.t});
  final double t;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final pop = _seg(t, 0.0, 0.25, kSpring);
    final ask = _seg(t, 0.2, 0.36, kSpring);
    final answer = _seg(t, 0.5, 0.66, kSpring);
    final thinking = t > 0.36 && t < 0.5;
    final exit = _seg(t, 0.9, 1.0, Curves.easeIn);
    return Opacity(
      opacity: 1 - exit,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Transform.scale(scale: 0.4 + 0.6 * pop, child: FinnAvatar(size: 96, thinking: thinking)),
          const SizedBox(height: 26),
          Align(
            alignment: Alignment.centerRight,
            child: Opacity(
              opacity: ask,
              child: Transform.scale(
                scale: 0.8 + 0.2 * ask,
                alignment: Alignment.bottomRight,
                child: BubbleBox(
                  style: const BubbleStyle(),
                  mine: true,
                  tail: true,
                  child: Text(tr('@finn what is this?'), style: TextStyle(fontSize: 17, color: bubbleText(const BubbleStyle(), p, mine: true))),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Opacity(
              opacity: answer,
              child: Transform.scale(
                scale: 0.8 + 0.2 * answer,
                alignment: Alignment.bottomLeft,
                child: BubbleBox(
                  style: const BubbleStyle(),
                  mine: false,
                  tail: true,
                  child: Text(tr("That's a sourdough loaf. A good one."), style: TextStyle(fontSize: 17, color: bubbleText(const BubbleStyle(), p, mine: false))),
                ),
              ),
            ),
          ),
          const SizedBox(height: 30),
          _Caption(title: tr('Meet Finn'), sub: tr('Reply to anything and ask. Or let him text for you.'), t: t),
        ]),
      ),
    );
  }
}

class _Bubbles extends StatelessWidget {
  const _Bubbles({required this.t, required this.color});
  final double t;
  final Color color;

  @override
  Widget build(BuildContext context) => CustomPaint(painter: _BubblesPainter(t: t, color: color));
}

class _BubblesPainter extends CustomPainter {
  _BubblesPainter({required this.t, required this.color});
  final double t;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(7);
    final paint = Paint()
      ..color = color.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (var i = 0; i < 18; i++) {
      final x = rnd.nextDouble() * size.width;
      final speed = 0.6 + rnd.nextDouble();
      final r = 4 + rnd.nextDouble() * 12;
      final y = size.height + 40 - ((t * speed + rnd.nextDouble()) % 1.0) * (size.height + 80);
      canvas.drawCircle(Offset(x + math.sin(t * 20 + i) * 8, y), r, paint);
    }
  }

  @override
  bool shouldRepaint(_BubblesPainter old) => old.t != t || old.color != color;
}
