import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import '../core/motion.dart';
import '../core/notify.dart';
import '../core/prefs.dart';
import '../core/theme.dart';
import '../ui/kit.dart';

class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _Perm {
  const _Perm(this.icon, this.title, this.body, this.permission);
  final IconData icon;
  final String title;
  final String body;
  final Permission permission;
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  static const _perms = [
    _Perm(Icons.notifications_none_rounded, 'Notifications', 'Know when a message or call comes in.', Permission.notification),
    _Perm(Icons.mic_none_rounded, 'Microphone', 'Voice notes and calls.', Permission.microphone),
    _Perm(Icons.videocam_outlined, 'Camera', 'Video calls and photos.', Permission.camera),
  ];

  final _granted = <Permission, bool>{};
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    for (final p in _perms) {
      try {
        _granted[p.permission] = await p.permission.isGranted;
      } catch (_) {
        _granted[p.permission] = false;
      }
    }
    if (mounted) setState(() {});
  }

  Future<void> _ask(Permission perm) async {
    HapticFeedback.selectionClick();
    try {
      final PermissionStatus s;
      if (perm == Permission.notification) {
        s = await perm.request();
        if (!s.isGranted) await Notify.requestPermission();
      } else {
        s = await perm.request();
      }
      if (s.isPermanentlyDenied && mounted) {
        showToast(context, 'Turn it on in system settings.');
        await openAppSettings();
      }
    } catch (_) {}
    await _check();
  }

  Future<void> _allowAll() async {
    setState(() => _busy = true);
    try {
      await [Permission.notification, Permission.microphone, Permission.camera].request();
    } catch (_) {}
    await _check();
    if (!mounted) return;
    setState(() => _busy = false);
    _finish();
  }

  void _finish() {
    Prefs.instance.permissionsAsked = true;
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final all = _perms.every((x) => _granted[x.permission] == true);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const SizedBox(height: 30),
            Reveal(
              scale: 0.5,
              duration: const Duration(milliseconds: 800),
              child: Center(child: _Rings(color: p.ink)),
            ),
            const SizedBox(height: 26),
            Reveal(
              delay: const Duration(milliseconds: 120),
              child: Text('A few permissions', textAlign: TextAlign.center, style: TextStyle(fontFamily: kDisplayFont, fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -0.8, color: p.ink)),
            ),
            const SizedBox(height: 8),
            Reveal(
              delay: const Duration(milliseconds: 180),
              child: Text('Fishi only uses these when you do something that needs them.', textAlign: TextAlign.center, style: TextStyle(fontSize: 15.5, color: p.muted, height: 1.35)),
            ),
            const SizedBox(height: 30),
            for (var i = 0; i < _perms.length; i++)
              Reveal(
                delay: Duration(milliseconds: 260 + i * 90),
                offset: const Offset(0, 24),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _PermTile(perm: _perms[i], granted: _granted[_perms[i].permission] == true, onTap: () => _ask(_perms[i].permission)),
                ),
              ),
            const Spacer(),
            Reveal(
              delay: const Duration(milliseconds: 600),
              offset: const Offset(0, 30),
              child: PillButton(label: all ? 'Continue' : 'Allow all', busy: _busy, onTap: all ? _finish : _allowAll),
            ),
            const SizedBox(height: 8),
            Reveal(
              delay: const Duration(milliseconds: 660),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 250),
                opacity: all ? 0 : 1,
                child: TextButton(
                  onPressed: all ? null : _finish,
                  child: Text('Not now', style: TextStyle(color: p.muted, fontSize: 15)),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _PermTile extends StatelessWidget {
  const _PermTile({required this.perm, required this.granted, required this.onTap});

  final _Perm perm;
  final bool granted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Tappable(
      scale: 0.98,
      onTap: granted ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(20)),
        child: Row(children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: p.soft, borderRadius: BorderRadius.circular(14)),
            child: Icon(perm.icon, color: p.ink),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(perm.title, style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w600, color: p.ink)),
              const SizedBox(height: 2),
              Text(perm.body, style: TextStyle(fontSize: 13.5, color: p.muted)),
            ]),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 420),
            switchInCurve: kSpring,
            transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
            child: granted
                ? Container(
                    key: const ValueKey(true),
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(color: p.ink, shape: BoxShape.circle),
                    child: Icon(Icons.check_rounded, size: 18, color: p.paper),
                  )
                : Container(
                    key: const ValueKey(false),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(color: p.soft, borderRadius: BorderRadius.circular(14)),
                    child: Text('Allow', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: p.ink)),
                  ),
          ),
        ]),
      ),
    );
  }
}

class _Rings extends StatefulWidget {
  const _Rings({required this.color});
  final Color color;

  @override
  State<_Rings> createState() => _RingsState();
}

class _RingsState extends State<_Rings> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return SizedBox.square(
      dimension: 110,
      child: Stack(alignment: Alignment.center, children: [
        for (var i = 0; i < 3; i++)
          AnimatedBuilder(
            animation: _c,
            builder: (context, _) {
              final t = (_c.value + i / 3) % 1;
              return Opacity(
                opacity: (1 - t) * 0.5,
                child: Transform.scale(
                  scale: 0.5 + t * 0.6,
                  child: Container(
                    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: widget.color, width: 2)),
                  ),
                ),
              );
            },
          ),
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(color: p.ink, shape: BoxShape.circle),
          child: Icon(Icons.lock_open_rounded, color: p.paper, size: 26),
        ),
      ]),
    );
  }
}
