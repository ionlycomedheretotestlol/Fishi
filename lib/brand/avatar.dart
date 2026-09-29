import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../core/data.dart';
import '../core/theme.dart';
import 'fish_logo.dart';

class Avatar extends StatelessWidget {
  const Avatar({super.key, this.profile, this.name, this.size = 44, this.group = false});

  final Profile? profile;
  final String? name;
  final double size;
  final bool group;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final pr = profile;
    if (pr != null && pr.isFinn) return FinnAvatar(size: size);
    if (pr != null && pr.isOfficial) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: p.ink),
        child: FishLogo(size: size, color: p.paper, eyeColor: p.ink),
      );
    }
    final url = pr?.avatarUrl;
    final label = (name ?? pr?.displayName ?? '?').trim();
    final initials = label.isEmpty
        ? '?'
        : label.split(RegExp(r'\s+')).take(2).map((w) => w.characters.first.toUpperCase()).join();
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [p.muted.withValues(alpha: 0.55), p.muted],
        ),
      ),
      alignment: Alignment.center,
      child: url != null
          ? CachedNetworkImage(imageUrl: url, fit: BoxFit.cover, width: size, height: size, fadeInDuration: const Duration(milliseconds: 180))
          : group
              ? Icon(Icons.people_alt_rounded, color: Colors.white, size: size * 0.5)
              : Text(initials, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: size * 0.38)),
    );
  }
}

class FinnAvatar extends StatefulWidget {
  const FinnAvatar({super.key, this.size = 44, this.thinking = false});

  final double size;
  final bool thinking;

  @override
  State<FinnAvatar> createState() => _FinnAvatarState();
}

class _FinnAvatarState extends State<FinnAvatar> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final t = _c.value;
          final bob = math.sin(t * math.pi * 2) * widget.size * 0.03;
          final speed = widget.thinking ? 3 : 1;
          final blinkPhase = (t * speed * 2) % 1;
          final blink = blinkPhase > 0.92 ? math.sin((blinkPhase - 0.92) / 0.08 * math.pi) : 0.0;
          final look = Offset(math.sin(t * math.pi * 2 * speed) * 0.4, math.cos(t * math.pi * 4) * 0.2);
          return Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(shape: BoxShape.circle, color: p.soft),
            child: Transform.translate(
              offset: Offset(0, bob),
              child: CustomPaint(
                painter: FishPainter(color: p.ink, eyeColor: p.soft, blink: blink, pupil: look),
              ),
            ),
          );
        },
      ),
    );
  }
}
