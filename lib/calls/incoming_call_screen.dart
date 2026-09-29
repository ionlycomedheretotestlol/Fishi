import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../brand/avatar.dart';
import '../core/data.dart';
import '../core/models.dart';
import '../core/motion.dart';
import '../core/theme.dart';
import 'call_center.dart';
import '../core/i18n.dart';

class IncomingCallScreen extends StatefulWidget {
  const IncomingCallScreen({super.key, required this.call, required this.caller, required this.title});

  final CallInfo call;
  final Profile? caller;
  final String title;

  @override
  State<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<IncomingCallScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))..repeat();
  StreamSubscription<CallInfo>? _sub;
  Timer? _timeout;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _sub = CallCenter.instance.updates.where((c) => c.id == widget.call.id).listen((c) {
      if (c.status != 'ringing' && !_done) _close();
    });
    _timeout = Timer(const Duration(seconds: 50), _close);
  }

  void _close() {
    if (_done) return;
    _done = true;
    if (mounted) Navigator.of(context).maybePop();
  }

  @override
  void dispose() {
    _c.dispose();
    _sub?.cancel();
    _timeout?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return Theme(
      data: buildTheme(Brightness.dark),
      child: Scaffold(
        backgroundColor: const Color(0xFF0B0B0C),
        body: Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(center: Alignment(0, -0.4), radius: 1.2, colors: [Color(0xFF2C2C2F), Color(0xFF0B0B0C)]),
          ),
          child: Column(children: [
            SizedBox(height: mq.padding.top + mq.size.height * 0.1),
            SizedBox(
              height: 190,
              child: Stack(alignment: Alignment.center, children: [
                for (var i = 0; i < 3; i++)
                  AnimatedBuilder(
                    animation: _c,
                    builder: (context, _) {
                      final t = (_c.value + i / 3) % 1;
                      return Opacity(
                        opacity: (1 - t) * 0.4,
                        child: Transform.scale(
                          scale: 1 + t,
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.5)),
                          ),
                        ),
                      );
                    },
                  ),
                AnimatedBuilder(
                  animation: _c,
                  builder: (context, child) => Transform.rotate(angle: math.sin(_c.value * math.pi * 8) * 0.03, child: child),
                  child: Reveal(scale: 0.5, duration: const Duration(milliseconds: 800), child: Avatar(profile: widget.caller, name: widget.title, size: 120)),
                ),
              ]),
            ),
            const SizedBox(height: 18),
            Reveal(
              delay: const Duration(milliseconds: 120),
              child: Text(widget.title,
                  textAlign: TextAlign.center, style: const TextStyle(fontFamily: kDisplayFont, fontSize: 30, fontWeight: FontWeight.w800, color: Colors.white)),
            ),
            const SizedBox(height: 6),
            Reveal(
              delay: const Duration(milliseconds: 180),
              child: Text(widget.call.video ? tr('Fishi video call') : tr('Fishi voice call'), style: const TextStyle(fontSize: 16, color: Colors.white60)),
            ),
            const Spacer(),
            Padding(
              padding: EdgeInsets.fromLTRB(40, 0, 40, mq.padding.bottom + 50),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                _Big(
                  delay: 260,
                  color: const Color(0xFFEA4A45),
                  icon: Icons.call_end_rounded,
                  label: tr('Decline'),
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    CallCenter.instance.decline(widget.call);
                    _close();
                  },
                ),
                _Big(
                  delay: 320,
                  color: Colors.white,
                  iconColor: Colors.black,
                  icon: widget.call.video ? Icons.videocam_rounded : Icons.call_rounded,
                  label: tr('Accept'),
                  wiggle: _c,
                  onTap: () {
                    if (_done) return;
                    _done = true;
                    HapticFeedback.mediumImpact();
                    CallCenter.instance.accept(context, widget.call, widget.title);
                  },
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

class _Big extends StatelessWidget {
  const _Big({required this.delay, required this.color, required this.icon, required this.label, required this.onTap, this.iconColor = Colors.white, this.wiggle});

  final int delay;
  final Color color;
  final Color iconColor;
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Animation<double>? wiggle;

  @override
  Widget build(BuildContext context) {
    Widget button = Container(
      width: 74,
      height: 74,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle, boxShadow: [BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 24)]),
      child: Icon(icon, color: iconColor, size: 34),
    );
    if (wiggle != null) {
      button = AnimatedBuilder(
        animation: wiggle!,
        child: button,
        builder: (context, child) {
          final t = (wiggle!.value * 2) % 1;
          final bounce = t < 0.25 ? math.sin(t / 0.25 * math.pi) : 0.0;
          return Transform.translate(offset: Offset(0, -8 * bounce), child: child);
        },
      );
    }
    return Reveal(
      delay: Duration(milliseconds: delay),
      offset: const Offset(0, 60),
      child: GestureDetector(
        onTap: onTap,
        child: Column(children: [
          button,
          const SizedBox(height: 10),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14)),
        ]),
      ),
    );
  }
}
