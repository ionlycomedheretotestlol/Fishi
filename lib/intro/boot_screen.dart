import 'dart:math' as math;
import 'dart:ui';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../brand/fish_logo.dart';
import '../theme.dart';

class BootScreen extends StatefulWidget {
  const BootScreen({super.key, required this.next});

  final WidgetBuilder next;

  @override
  State<BootScreen> createState() => _BootScreenState();
}

class _BootScreenState extends State<BootScreen> with SingleTickerProviderStateMixin {
  static const _total = Duration(milliseconds: 2300);
  late final AnimationController _c = AnimationController(vsync: this, duration: _total);
  final _ding1 = AudioPlayer();
  final _ding2 = AudioPlayer();
  bool _played1 = false;
  bool _played2 = false;
  bool _left = false;

  @override
  void initState() {
    super.initState();
    for (final p in [_ding1, _ding2]) {
      p.setPlayerMode(PlayerMode.lowLatency);
      p.setAudioContext(AudioContextConfig(focus: AudioContextConfigFocus.mixWithOthers).build());
    }
    _ding1.setSource(AssetSource('sounds/ding1.wav'));
    _ding2.setSource(AssetSource('sounds/ding2.wav'));
    _c.addListener(_tick);
    Future.delayed(const Duration(milliseconds: 180), () {
      if (mounted) _c.forward();
    });
  }

  void _tick() {
    final ms = _c.value * _total.inMilliseconds;
    if (!_played1 && ms >= 0) {
      _played1 = true;
      _ding1.resume();
      HapticFeedback.lightImpact();
    }
    if (!_played2 && ms >= 700) {
      _played2 = true;
      _ding2.resume();
      HapticFeedback.mediumImpact();
    }
    if (!_left && _c.isCompleted) {
      _left = true;
      Navigator.of(context).pushReplacement(PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 520),
        pageBuilder: (context, _, _) => widget.next(context),
        transitionsBuilder: (context, a, _, child) {
          final t = Curves.easeOutCubic.transform(a.value);
          return Opacity(
            opacity: t,
            child: Transform.scale(scale: 0.96 + 0.04 * t, child: child),
          );
        },
      ));
    }
  }

  @override
  void dispose() {
    _c.dispose();
    _ding1.dispose();
    _ding2.dispose();
    super.dispose();
  }

  double _seg(double ms, double start, double len, [Curve curve = Curves.linear]) {
    final v = ((ms - start) / len).clamp(0.0, 1.0);
    return curve.transform(v);
  }

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Scaffold(
      backgroundColor: p.paper,
      body: Center(
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final ms = _c.value * _total.inMilliseconds;
            final back = _seg(ms, 0, 620, Curves.easeOutQuint);
            final front = _seg(ms, 700, 620, Curves.easeOutQuint);
            final settle = _seg(ms, 1150, 520, Curves.elasticOut);
            final blinkT = _seg(ms, 1500, 260);
            final blink = math.sin(blinkT * math.pi);
            final exit = _seg(ms, 1950, 350, Curves.easeInCubic);
            const size = 168.0;

            Widget half(FishHalf h, double t, double dir) {
              final blur = (1 - t) * 14;
              return Transform.translate(
                offset: Offset(dir * (1 - t) * 46, 0),
                child: Transform.rotate(
                  angle: dir * (1 - t) * 0.12,
                  child: Opacity(
                    opacity: t,
                    child: ImageFiltered(
                      enabled: blur > 0.3,
                      imageFilter: ImageFilter.blur(sigmaX: blur, sigmaY: blur * 0.4),
                      child: CustomPaint(
                        size: const Size.square(size),
                        painter: FishPainter(color: p.ink, eyeColor: p.paper, half: h, blink: h == FishHalf.front ? blink : 0),
                      ),
                    ),
                  ),
                ),
              );
            }

            final pulse = 1 + 0.06 * math.sin(settle * math.pi) * (1 - settle);
            return Opacity(
              opacity: 1 - exit,
              child: Transform.scale(
                scale: pulse * (1 + exit * 0.35),
                child: SizedBox.square(
                  dimension: size,
                  child: Stack(children: [
                    if (back > 0) half(FishHalf.back, back, -1),
                    if (front > 0) half(FishHalf.front, front, 1),
                  ]),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
