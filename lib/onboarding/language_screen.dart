import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../brand/fish_logo.dart';
import '../core/i18n.dart';
import '../core/motion.dart';
import '../core/prefs.dart';
import '../core/theme.dart';
import '../ui/kit.dart';

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> with SingleTickerProviderStateMixin {
  late String _lang = PlatformDispatcher.instance.locale.languageCode == 'pt' ? 'pt' : 'en';
  late final AnimationController _float = AnimationController(vsync: this, duration: const Duration(seconds: 5))..repeat();
  bool _leaving = false;

  @override
  void dispose() {
    _float.dispose();
    super.dispose();
  }

  void _pick(String v) {
    if (v == _lang) return;
    HapticFeedback.selectionClick();
    setState(() => _lang = v);
  }

  void _go() {
    if (_leaving) return;
    _leaving = true;
    HapticFeedback.lightImpact();
    Prefs.instance.language = _lang;
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final pt = _lang == 'pt';
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(children: [
            const Spacer(flex: 2),
            Reveal(
              scale: 0.5,
              duration: const Duration(milliseconds: 900),
              child: AnimatedBuilder(
                animation: _float,
                builder: (context, child) {
                  final t = _float.value * math.pi * 2;
                  return Transform.translate(offset: Offset(math.sin(t) * 5, math.sin(t * 2) * 4), child: child);
                },
                child: FishLogo(size: 96, color: p.ink, eyeColor: p.paper),
              ),
            ),
            const SizedBox(height: 22),
            Reveal(
              delay: const Duration(milliseconds: 120),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 320),
                transitionBuilder: (c, a) => FadeTransition(
                  opacity: a,
                  child: SlideTransition(position: Tween(begin: const Offset(0, 0.25), end: Offset.zero).animate(a), child: c),
                ),
                child: Text(
                  pt ? 'Escolha seu idioma' : 'Choose your language',
                  key: ValueKey(pt),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: kDisplayFont, fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -0.8, color: p.ink),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Reveal(
              delay: const Duration(milliseconds: 180),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 320),
                child: Text(
                  pt ? 'Você pode mudar isso depois nos Ajustes.' : 'You can change this later in Settings.',
                  key: ValueKey(pt),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15.5, color: p.muted),
                ),
              ),
            ),
            const Spacer(),
            Reveal(
              delay: const Duration(milliseconds: 260),
              offset: const Offset(0, 30),
              child: _LangCard(greeting: 'Hello', name: 'English', selected: !pt, onTap: () => _pick('en')),
            ),
            const SizedBox(height: 12),
            Reveal(
              delay: const Duration(milliseconds: 330),
              offset: const Offset(0, 30),
              child: _LangCard(greeting: 'Olá', name: 'Português (Brasil)', selected: pt, onTap: () => _pick('pt')),
            ),
            const Spacer(flex: 2),
            Reveal(
              delay: const Duration(milliseconds: 420),
              offset: const Offset(0, 30),
              child: PillButton(label: pt ? 'Continuar' : 'Continue', onTap: _go),
            ),
            const SizedBox(height: 18),
          ]),
        ),
      ),
    );
  }
}

class _LangCard extends StatelessWidget {
  const _LangCard({required this.greeting, required this.name, required this.selected, required this.onTap});

  final String greeting;
  final String name;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Tappable(
      scale: 0.97,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 360),
        curve: kSmooth,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: selected ? p.ink : p.card,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: selected ? p.ink : p.line),
        ),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 300),
                style: TextStyle(fontFamily: kDisplayFont, fontSize: 26, fontWeight: FontWeight.w800, color: selected ? p.paper : p.ink),
                child: Text(greeting),
              ),
              const SizedBox(height: 2),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 300),
                style: TextStyle(fontFamily: kTextFont, fontSize: 15, color: selected ? p.paper.withValues(alpha: 0.75) : p.muted),
                child: Text(name),
              ),
            ]),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: kSpring,
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected ? p.paper : Colors.transparent,
              border: Border.all(color: selected ? p.paper : p.muted, width: 2),
            ),
            child: AnimatedScale(
              scale: selected ? 1 : 0,
              duration: const Duration(milliseconds: 420),
              curve: kSpring,
              child: Icon(Icons.check_rounded, size: 18, color: p.ink),
            ),
          ),
        ]),
      ),
    );
  }
}

String languageName(String code) => code == 'pt' ? 'Português (Brasil)' : 'English';

bool languageChosen() => Prefs.instance.language != null && supportedLanguages.contains(Prefs.instance.language);
