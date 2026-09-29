import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../brand/fish_logo.dart';
import '../core/data.dart';
import '../core/motion.dart';
import '../core/theme.dart';
import '../ui/kit.dart';
import '../core/i18n.dart';

String get moderationLine =>
    tr('Fishi is for adults 18 and over. Messages that match our safety terms can be reviewed by the Fishi team. Normal chats stay private.');

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _float = AnimationController(vsync: this, duration: const Duration(seconds: 5))..repeat();

  @override
  void dispose() {
    _float.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Scaffold(
      body: Stack(children: [
        Positioned.fill(child: _DriftingBubbles(animation: _float, color: p.ink)),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 26),
            child: Column(children: [
              const Spacer(flex: 3),
              Reveal(
                scale: 0.6,
                duration: const Duration(milliseconds: 900),
                child: AnimatedBuilder(
                  animation: _float,
                  builder: (context, child) {
                    final t = _float.value * math.pi * 2;
                    return Transform.translate(
                      offset: Offset(math.sin(t) * 6, math.sin(t * 2) * 5),
                      child: Transform.rotate(angle: math.sin(t) * 0.05, child: child),
                    );
                  },
                  child: FishLogo(size: 130, color: p.ink, eyeColor: p.paper),
                ),
              ),
              const SizedBox(height: 18),
              Reveal(
                delay: const Duration(milliseconds: 160),
                child: Text('Fishi', style: TextStyle(fontFamily: kDisplayFont, fontSize: 52, fontWeight: FontWeight.w800, letterSpacing: -2, color: p.ink)),
              ),
              const SizedBox(height: 6),
              Reveal(
                delay: const Duration(milliseconds: 240),
                child: Text(tr('Messaging that feels calm.'), style: TextStyle(fontSize: 17, color: p.muted)),
              ),
              const Spacer(flex: 4),
              Reveal(
                delay: const Duration(milliseconds: 360),
                offset: const Offset(0, 30),
                child: PillButton(label: tr('Create account'), onTap: () => Navigator.of(context).push(fadeRoute(const SignUpScreen()))),
              ),
              const SizedBox(height: 12),
              Reveal(
                delay: const Duration(milliseconds: 430),
                offset: const Offset(0, 30),
                child: PillButton(label: tr('I already have one'), secondary: true, onTap: () => Navigator.of(context).push(fadeRoute(const SignInScreen()))),
              ),
              const SizedBox(height: 18),
              Reveal(
                delay: const Duration(milliseconds: 520),
                child: Text(tr('18+ only'), style: TextStyle(fontSize: 13, color: p.muted, letterSpacing: 0.3)),
              ),
              const SizedBox(height: 14),
            ]),
          ),
        ),
      ]),
    );
  }
}

class _DriftingBubbles extends StatelessWidget {
  const _DriftingBubbles({required this.animation, required this.color});

  final Animation<double> animation;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(painter: _DriftPainter(animation: animation, color: color)),
    );
  }
}

class _DriftPainter extends CustomPainter {
  _DriftPainter({required this.animation, required this.color}) : super(repaint: animation);

  final Animation<double> animation;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(11);
    final paint = Paint()
      ..color = color.withValues(alpha: 0.07)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final t = animation.value;
    for (var i = 0; i < 16; i++) {
      final x = rnd.nextDouble() * size.width;
      final speed = 0.5 + rnd.nextDouble() * 0.8;
      final r = 5 + rnd.nextDouble() * 16;
      final phase = rnd.nextDouble();
      final y = size.height + 40 - ((t * speed + phase) % 1.0) * (size.height + 80);
      canvas.drawCircle(Offset(x + math.sin((t + phase) * math.pi * 4) * 10, y), r, paint);
    }
  }

  @override
  bool shouldRepaint(_DriftPainter old) => old.color != color;
}

class _AuthFrame extends StatelessWidget {
  const _AuthFrame({required this.title, required this.subtitle, required this.children});

  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 6, 0, 0),
              child: Tappable(
                onTap: () => Navigator.of(context).maybePop(),
                child: Padding(padding: const EdgeInsets.all(10), child: Icon(Icons.arrow_back_ios_new_rounded, size: 21, color: p.ink)),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 30),
              children: [
                Reveal(
                  offset: const Offset(0, 12),
                  child: Text(title, style: TextStyle(fontFamily: kDisplayFont, fontSize: 34, fontWeight: FontWeight.w800, letterSpacing: -1, color: p.ink)),
                ),
                const SizedBox(height: 6),
                Reveal(
                  delay: const Duration(milliseconds: 60),
                  child: Text(subtitle, style: TextStyle(fontSize: 16, color: p.muted, height: 1.35)),
                ),
                const SizedBox(height: 26),
                Stagger(start: const Duration(milliseconds: 120), children: children),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

String? usernameProblem(String u) {
  if (u.isEmpty) return null;
  if (u.length < 3) return tr('At least 3 characters');
  if (u.length > 20) return tr('At most 20 characters');
  if (!RegExp(r'^[a-z0-9_]+$').hasMatch(u)) return tr('Letters, numbers and _ only');
  if (u.startsWith('_') || u.endsWith('_') || u.contains('__')) return tr('Underscores can only go in the middle');
  return null;
}

enum _Avail { idle, checking, ok, taken }

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _name = TextEditingController();
  final _user = TextEditingController();
  final _pass = TextEditingController();
  _Avail _avail = _Avail.idle;
  Timer? _debounce;
  int _checkId = 0;
  bool _adult = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _debounce?.cancel();
    _name.dispose();
    _user.dispose();
    _pass.dispose();
    super.dispose();
  }

  void _onUsername(String v) {
    _debounce?.cancel();
    final u = v.trim().toLowerCase();
    if (u.isEmpty || usernameProblem(u) != null) {
      setState(() => _avail = _Avail.idle);
      return;
    }
    setState(() => _avail = _Avail.checking);
    final id = ++_checkId;
    _debounce = Timer(const Duration(milliseconds: 380), () async {
      try {
        final ok = await supa.rpc('username_available', params: {'name': u});
        if (!mounted || id != _checkId) return;
        setState(() => _avail = ok == true ? _Avail.ok : _Avail.taken);
        if (ok != true) HapticFeedback.lightImpact();
      } catch (_) {
        if (mounted && id == _checkId) setState(() => _avail = _Avail.idle);
      }
    });
  }

  bool get _valid =>
      _name.text.trim().isNotEmpty && _avail == _Avail.ok && _pass.text.length >= 6 && _adult && usernameProblem(_user.text.trim()) == null;

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    final username = _user.text.trim().toLowerCase();
    try {
      final res = await supa.auth.signUp(
        email: emailFor(username),
        password: _pass.text,
        data: {'username': username, 'display_name': _name.text.trim()},
      );
      final uid = res.user?.id;
      if (uid != null) {
        await supa.from('profiles').update({'adult_confirmed_at': DateTime.now().toUtc().toIso8601String()}).eq('id', uid);
      }
      if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
    } on AuthException catch (e) {
      final m = e.message.toLowerCase();
      setState(() {
        _busy = false;
        if (m.contains('username_unavailable') || m.contains('database error') || m.contains('already registered')) {
          _avail = _Avail.taken;
          _error = tr('That username is not available.');
        } else if (m.contains('password')) {
          _error = e.message;
        } else {
          _error = tr('Could not create your account. Check your connection and try again.');
        }
      });
    } catch (_) {
      setState(() {
        _busy = false;
        _error = tr('Could not create your account. Check your connection and try again.');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final uProblem = usernameProblem(_user.text.trim());
    return _AuthFrame(
      title: tr('Create account'),
      subtitle: tr('Pick a name people will see and a username they can find you by.'),
      children: [
        FishiField(
          controller: _name,
          label: tr('Your name'),
          maxLength: 40,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.name],
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        FishiField(
          controller: _user,
          label: tr('Username'),
          prefix: '@',
          maxLength: 20,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.newUsername],
          inputFormatters: [
            FilteringTextInputFormatter.deny(RegExp(r'\s')),
            TextInputFormatter.withFunction((o, n) => n.copyWith(text: n.text.toLowerCase())),
          ],
          onChanged: _onUsername,
          error: uProblem ?? (_avail == _Avail.taken ? tr('That username is taken') : null),
          suffix: _AvailIcon(state: _avail),
        ),
        const SizedBox(height: 12),
        FishiField(
          controller: _pass,
          label: tr('Password'),
          obscure: true,
          autofillHints: const [AutofillHints.newPassword],
          onChanged: (_) => setState(() {}),
        ),
        Padding(padding: const EdgeInsets.fromLTRB(4, 10, 4, 0), child: _StrengthBar(password: _pass.text)),
        const SizedBox(height: 22),
        _AdultCard(value: _adult, onChanged: (v) => setState(() => _adult = v)),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.shield_outlined, size: 17, color: p.muted),
            const SizedBox(width: 8),
            Expanded(child: Text(moderationLine, style: TextStyle(fontSize: 13, color: p.muted, height: 1.4))),
          ]),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 280),
          curve: kSmooth,
          child: _error == null
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: p.danger, fontSize: 14.5)),
                ),
        ),
        const SizedBox(height: 22),
        PillButton(label: tr('Create account'), busy: _busy, onTap: _valid ? _submit : null),
      ],
    );
  }
}

class _AvailIcon extends StatelessWidget {
  const _AvailIcon({required this.state});
  final _Avail state;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return SizedBox(
      width: 36,
      height: 36,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 320),
        switchInCurve: kSpring,
        transitionBuilder: (c, a) => ScaleTransition(scale: a, child: FadeTransition(opacity: a, child: c)),
        child: switch (state) {
          _Avail.idle => const SizedBox.shrink(key: ValueKey(0)),
          _Avail.checking => const Center(key: ValueKey(1), child: Spinner(size: 18)),
          _Avail.ok => Container(
              key: const ValueKey(2),
              margin: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: p.ink, shape: BoxShape.circle),
              child: Icon(Icons.check_rounded, size: 16, color: p.paper),
            ),
          _Avail.taken => Container(
              key: const ValueKey(3),
              margin: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: p.danger, shape: BoxShape.circle),
              child: const Icon(Icons.close_rounded, size: 16, color: Colors.white),
            ),
        },
      ),
    );
  }
}

class _StrengthBar extends StatelessWidget {
  const _StrengthBar({required this.password});
  final String password;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    var score = 0;
    if (password.length >= 6) score++;
    if (password.length >= 10) score++;
    if (RegExp(r'[0-9]').hasMatch(password) && RegExp(r'[a-zA-Z]').hasMatch(password)) score++;
    if (RegExp(r'[^a-zA-Z0-9]').hasMatch(password) || RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (password.isEmpty) score = 0;
    final label = password.isEmpty
        ? tr('At least 6 characters')
        : password.length < 6
            ? tr('Too short')
            : [tr('Weak'), tr('Okay'), tr('Good'), tr('Strong'), tr('Strong')][score];
    return Row(children: [
      for (var i = 0; i < 4; i++)
        Expanded(
          child: TweenAnimationBuilder<double>(
            tween: Tween(end: i < score ? 1 : 0),
            duration: Duration(milliseconds: 300 + i * 60),
            curve: kSmooth,
            builder: (context, t, _) => Container(
              height: 4,
              margin: const EdgeInsets.only(right: 5),
              decoration: BoxDecoration(color: Color.lerp(p.line, p.ink, t), borderRadius: BorderRadius.circular(2)),
            ),
          ),
        ),
      const SizedBox(width: 6),
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: Text(label, key: ValueKey(label), style: TextStyle(fontSize: 12.5, color: p.muted)),
      ),
    ]);
  }
}

class _AdultCard extends StatelessWidget {
  const _AdultCard({required this.value, required this.onChanged});
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Tappable(
      scale: 0.98,
      onTap: () {
        HapticFeedback.selectionClick();
        onChanged(!value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: kSmooth,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: value ? p.ink : p.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: value ? p.ink : p.line),
        ),
        child: Row(children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: kSpring,
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: value ? p.paper : Colors.transparent,
              border: Border.all(color: value ? p.paper : p.muted, width: 2),
            ),
            child: AnimatedScale(
              scale: value ? 1 : 0,
              duration: const Duration(milliseconds: 380),
              curve: kSpring,
              child: Icon(Icons.check_rounded, size: 17, color: p.ink),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 300),
              style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600, color: value ? p.paper : p.ink, fontFamily: kTextFont),
              child: Text(tr('I am 18 or older')),
            ),
          ),
        ]),
      ),
    );
  }
}

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _user = TextEditingController();
  final _pass = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _user.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await supa.auth.signInWithPassword(email: emailFor(_user.text.trim().replaceFirst('@', '')), password: _pass.text);
      if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
    } on AuthException catch (e) {
      setState(() {
        _busy = false;
        _error = e.message.toLowerCase().contains('invalid') ? tr('Wrong username or password.') : tr('Could not sign in. Try again.');
      });
      HapticFeedback.heavyImpact();
    } catch (_) {
      setState(() {
        _busy = false;
        _error = tr('Could not sign in. Check your connection.');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return _AuthFrame(
      title: tr('Welcome back'),
      subtitle: tr('Sign in with your username.'),
      children: [
        FishiField(
          controller: _user,
          label: tr('Username'),
          prefix: '@',
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.username],
          inputFormatters: [TextInputFormatter.withFunction((o, n) => n.copyWith(text: n.text.toLowerCase()))],
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        FishiField(
          controller: _pass,
          label: tr('Password'),
          obscure: true,
          autofillHints: const [AutofillHints.password],
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) {
            if (_user.text.isNotEmpty && _pass.text.isNotEmpty) _submit();
          },
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 280),
          curve: kSmooth,
          child: _error == null
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: p.danger, fontSize: 14.5)),
                ),
        ),
        const SizedBox(height: 26),
        PillButton(label: tr('Sign in'), busy: _busy, onTap: _user.text.trim().isNotEmpty && _pass.text.isNotEmpty ? _submit : null),
      ],
    );
  }
}

class AgeConfirmScreen extends StatefulWidget {
  const AgeConfirmScreen({super.key, required this.onDone});
  final VoidCallback onDone;

  @override
  State<AgeConfirmScreen> createState() => _AgeConfirmScreenState();
}

class _AgeConfirmScreenState extends State<AgeConfirmScreen> {
  bool _adult = false;
  bool _busy = false;

  Future<void> _go() async {
    setState(() => _busy = true);
    try {
      await supa.from('profiles').update({'adult_confirmed_at': DateTime.now().toUtc().toIso8601String()}).eq('id', myId!);
      await Profiles.instance.loadMe();
      widget.onDone();
    } catch (_) {
      if (mounted) {
        setState(() => _busy = false);
        showToast(context, tr('Could not save. Try again.'), error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(children: [
            const Spacer(),
            Reveal(scale: 0.6, child: FishLogo(size: 90, color: p.ink, eyeColor: p.paper)),
            const SizedBox(height: 20),
            Reveal(
              delay: const Duration(milliseconds: 100),
              child: Text(tr('One quick thing'), style: TextStyle(fontFamily: kDisplayFont, fontSize: 28, fontWeight: FontWeight.w800, color: p.ink)),
            ),
            const SizedBox(height: 10),
            Reveal(
              delay: const Duration(milliseconds: 160),
              child: Text(moderationLine, textAlign: TextAlign.center, style: TextStyle(fontSize: 15, color: p.muted, height: 1.4)),
            ),
            const Spacer(),
            Reveal(delay: const Duration(milliseconds: 240), child: _AdultCard(value: _adult, onChanged: (v) => setState(() => _adult = v))),
            const SizedBox(height: 14),
            Reveal(
              delay: const Duration(milliseconds: 300),
              child: PillButton(label: tr('Continue'), busy: _busy, onTap: _adult ? _go : null),
            ),
            const SizedBox(height: 10),
            Reveal(
              delay: const Duration(milliseconds: 340),
              child: PillButton(label: tr('Sign out'), secondary: true, onTap: () => supa.auth.signOut()),
            ),
          ]),
        ),
      ),
    );
  }
}
