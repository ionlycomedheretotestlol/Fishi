import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../chat/bubble_shape.dart';
import '../core/data.dart';
import '../core/motion.dart';
import '../core/theme.dart';
import '../emoji/emoji_text.dart';
import '../ui/kit.dart';
import '../core/i18n.dart';

const _swatches = [
  Color(0xFF141414),
  Color(0xFF4A4A4C),
  Color(0xFF8C8A85),
  Color(0xFFD9D6D0),
  Color(0xFFF2F0EC),
  Color(0xFF2F5D8A),
  Color(0xFF3F7D5C),
  Color(0xFFB5523B),
  Color(0xFF8E5BB5),
  Color(0xFFD9A441),
];

class BubbleStudio extends StatefulWidget {
  const BubbleStudio({super.key, this.initial});

  final BubbleStyle? initial;

  @override
  State<BubbleStudio> createState() => _BubbleStudioState();
}

class _BubbleStudioState extends State<BubbleStudio> {
  late BubbleStyle _style = widget.initial ?? Profiles.instance.me?.bubble ?? const BubbleStyle();
  bool _busy = false;
  bool _custom = false;
  int _bump = 0;

  void _set(BubbleStyle s) {
    HapticFeedback.selectionClick();
    setState(() {
      _style = s;
      _bump++;
    });
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    try {
      await supa.from('profiles').update({'bubble': _style.toJson()}).eq('id', myId!);
      await Profiles.instance.refresh(myId!);
      if (mounted) {
        showToast(context, tr('Everyone sees your new bubble now'));
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (mounted) {
        setState(() => _busy = false);
        showToast(context, tr('Could not save.'), error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Scaffold(
      appBar: TopBar(title: tr('Bubble studio')),
      body: Column(children: [
        Expanded(
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 20),
            children: [
              Reveal(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                  padding: const EdgeInsets.fromLTRB(12, 18, 12, 18),
                  decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(24)),
                  child: _Preview(style: _style, bump: _bump),
                ),
              ),
              Reveal(
                delay: const Duration(milliseconds: 80),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(30, 10, 30, 10),
                  child: Text(tr('Shape'), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: p.muted)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.count(
                  crossAxisCount: 4,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.9,
                  children: [
                    for (var i = 0; i < BubbleShape.values.length; i++)
                      Reveal(
                        delay: Duration(milliseconds: 120 + i * 40),
                        scale: 0.7,
                        child: _ShapeTile(
                          shape: BubbleShape.values[i],
                          selected: _style.shape == BubbleShape.values[i],
                          color: _style.color,
                          onTap: () => _set(_style.copyWith(shape: BubbleShape.values[i])),
                        ),
                      ),
                  ],
                ),
              ),
              Reveal(
                delay: const Duration(milliseconds: 300),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(30, 22, 30, 10),
                  child: Text(tr('Color'), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: p.muted)),
                ),
              ),
              Reveal(
                delay: const Duration(milliseconds: 340),
                child: SizedBox(
                  height: 52,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _Swatch(
                        color: null,
                        selected: _style.color == null && !_custom,
                        onTap: () {
                          setState(() => _custom = false);
                          _set(_style.copyWith(clearColor: true));
                        },
                      ),
                      for (final c in _swatches)
                        _Swatch(
                          color: c,
                          selected: _style.color?.toARGB32() == c.toARGB32() && !_custom,
                          onTap: () {
                            setState(() => _custom = false);
                            _set(_style.copyWith(color: c));
                          },
                        ),
                      _Swatch(
                        color: null,
                        custom: true,
                        selected: _custom,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _custom = !_custom);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 380),
                curve: kSmooth,
                child: _custom
                    ? Padding(
                        padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                        child: ColorPicker(
                          color: _style.color ?? p.ink,
                          onChanged: (c) => setState(() => _style = _style.copyWith(color: c)),
                        ),
                      )
                    : const SizedBox(width: double.infinity),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(30, 16, 30, 0),
                child: Text(tr('Your bubble shows up like this for everyone you talk to.'), style: TextStyle(fontSize: 13, color: p.muted)),
              ),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 6, 18, 12),
            child: PillButton(label: tr('Use this bubble'), busy: _busy, onTap: _save),
          ),
        ),
      ]),
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview({required this.style, required this.bump});

  final BubbleStyle style;
  final int bump;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    Widget mine(String text, {bool tail = true}) {
      final fg = bubbleText(style, p, mine: true);
      return Align(
        alignment: Alignment.centerRight,
        child: TweenAnimationBuilder<double>(
          key: ValueKey('$bump$text'),
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 620),
          curve: Curves.elasticOut,
          builder: (context, t, child) => Transform.scale(scale: 0.85 + 0.15 * t, alignment: Alignment.centerRight, child: child),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: BubbleBox(
              key: ValueKey('${style.shape}${style.color}'),
              style: style,
              mine: true,
              tail: tail,
              child: EmojiText(text, style: TextStyle(fontSize: 16.5, color: fg)),
            ),
          ),
        ),
      );
    }

    const other = BubbleStyle();
    return Column(children: [
      Align(
        alignment: Alignment.centerLeft,
        child: BubbleBox(
          style: other,
          mine: false,
          tail: true,
          child: Text(tr('ok show me the new bubble'), style: TextStyle(fontSize: 16.5, color: bubbleText(other, p, mine: false))),
        ),
      ),
      const SizedBox(height: 10),
      mine(tr('ta-da'), tail: false),
      const SizedBox(height: 3),
      mine(tr('everyone sees it like this 🐟')),
    ]);
  }
}

class _ShapeTile extends StatelessWidget {
  const _ShapeTile({required this.shape, required this.selected, required this.color, required this.onTap});

  final BubbleShape shape;
  final bool selected;
  final Color? color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final style = BubbleStyle(shape: shape, color: color);
    return Tappable(
      scale: 0.9,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: kSmooth,
        decoration: BoxDecoration(
          color: p.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: selected ? p.ink : p.line, width: selected ? 2.2 : 1),
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          AnimatedScale(
            scale: selected ? 1.1 : 1,
            duration: const Duration(milliseconds: 420),
            curve: kSpring,
            child: SizedBox(
              width: 50,
              height: 30,
              child: CustomPaint(painter: BubblePainter(style: style, color: bubbleFill(style, p, mine: true), mine: true, tail: true)),
            ),
          ),
          const SizedBox(height: 8),
          Text(shape.label, style: TextStyle(fontSize: 12.5, fontWeight: selected ? FontWeight.w700 : FontWeight.w500, color: p.ink)),
        ]),
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.color, required this.selected, required this.onTap, this.custom = false});

  final Color? color;
  final bool selected;
  final bool custom;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: kSpring,
        width: 44,
        height: 44,
        margin: const EdgeInsets.only(right: 8),
        padding: EdgeInsets.all(selected ? 4 : 0),
        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: selected ? p.ink : Colors.transparent, width: 2)),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color ?? (custom ? null : p.ink),
            gradient: custom
                ? const SweepGradient(colors: [Colors.red, Colors.yellow, Colors.green, Colors.cyan, Colors.blue, Colors.purple, Colors.red])
                : null,
            border: Border.all(color: p.line),
          ),
          child: color == null && !custom ? Icon(Icons.auto_awesome, size: 16, color: p.paper) : null,
        ),
      ),
    );
  }
}

class ColorPicker extends StatefulWidget {
  const ColorPicker({super.key, required this.color, required this.onChanged});

  final Color color;
  final ValueChanged<Color> onChanged;

  @override
  State<ColorPicker> createState() => _ColorPickerState();
}

class _ColorPickerState extends State<ColorPicker> {
  late HSVColor _hsv = HSVColor.fromColor(widget.color);

  void _emit(HSVColor h) {
    setState(() => _hsv = h);
    widget.onChanged(h.toColor());
  }

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Column(children: [
      LayoutBuilder(builder: (context, c) {
        final w = c.maxWidth;
        const h = 170.0;
        void pick(Offset o) => _emit(_hsv.withSaturation((o.dx / w).clamp(0.0, 1.0)).withValue(1 - (o.dy / h).clamp(0.0, 1.0)));
        return GestureDetector(
          onPanDown: (d) => pick(d.localPosition),
          onPanUpdate: (d) => pick(d.localPosition),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: SizedBox(
              width: w,
              height: h,
              child: Stack(children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [Colors.white, HSVColor.fromAHSV(1, _hsv.hue, 1, 1).toColor()]),
                    ),
                  ),
                ),
                const Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black]),
                    ),
                  ),
                ),
                Positioned(
                  left: _hsv.saturation * w - 12,
                  top: (1 - _hsv.value) * h - 12,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _hsv.toColor(),
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
                    ),
                  ),
                ),
              ]),
            ),
          ),
        );
      }),
      const SizedBox(height: 14),
      LayoutBuilder(builder: (context, c) {
        final w = c.maxWidth;
        void pick(double x) => _emit(_hsv.withHue((x / w).clamp(0.0, 1.0) * 359.9));
        return GestureDetector(
          onPanDown: (d) => pick(d.localPosition.dx),
          onPanUpdate: (d) => pick(d.localPosition.dx),
          child: SizedBox(
            height: 30,
            child: Stack(clipBehavior: Clip.none, alignment: Alignment.centerLeft, children: [
              Container(
                height: 16,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: LinearGradient(colors: [for (var hue = 0; hue <= 360; hue += 60) HSVColor.fromAHSV(1, hue.toDouble() % 360, 1, 1).toColor()]),
                ),
              ),
              Positioned(
                left: _hsv.hue / 360 * w - 14,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: HSVColor.fromAHSV(1, _hsv.hue, 1, 1).toColor(),
                    border: Border.all(color: p.paper, width: 3),
                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
                  ),
                ),
              ),
            ]),
          ),
        );
      }),
    ]);
  }
}
