import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/motion.dart';
import '../core/theme.dart';
import '../core/i18n.dart';

class Spinner extends StatefulWidget {
  const Spinner({super.key, this.size = 20, this.color, this.stroke = 2.4});

  final double size;
  final Color? color;
  final double stroke;

  @override
  State<Spinner> createState() => _SpinnerState();
}

class _SpinnerState extends State<Spinner> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Palette.of(context).ink;
    return RepaintBoundary(
      child: RotationTransition(
        turns: _c,
        child: CustomPaint(
          size: Size.square(widget.size),
          painter: _ArcPainter(color: color, stroke: widget.stroke),
        ),
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  _ArcPainter({required this.color, required this.stroke});
  final Color color;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final r = Rect.fromLTWH(stroke / 2, stroke / 2, size.width - stroke, size.height - stroke);
    canvas.drawArc(r, 0, math.pi * 2, false, Paint()
      ..color = color.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke);
    canvas.drawArc(r, -math.pi / 2, math.pi * 0.7, false, Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = stroke);
  }

  @override
  bool shouldRepaint(_ArcPainter old) => old.color != color;
}

class PillButton extends StatelessWidget {
  const PillButton({super.key, required this.label, this.onTap, this.busy = false, this.secondary = false, this.icon, this.danger = false});

  final String label;
  final VoidCallback? onTap;
  final bool busy;
  final bool secondary;
  final bool danger;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final enabled = onTap != null && !busy;
    final bg = secondary ? Colors.transparent : (danger ? p.danger : p.ink);
    final fg = secondary ? (danger ? p.danger : p.ink) : p.paper;
    return Tappable(
      onTap: enabled
          ? () {
              HapticFeedback.selectionClick();
              onTap!();
            }
          : null,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 220),
        opacity: onTap == null ? 0.35 : 1,
        child: Container(
          height: 54,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(27),
            border: secondary ? Border.all(color: p.line, width: 1.5) : null,
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            switchInCurve: kSmooth,
            transitionBuilder: (child, a) => FadeTransition(
              opacity: a,
              child: ScaleTransition(scale: Tween(begin: 0.7, end: 1.0).animate(a), child: child),
            ),
            child: busy
                ? Spinner(key: const ValueKey('b'), color: fg)
                : Row(
                    key: ValueKey(label),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[Icon(icon, color: fg, size: 20), const SizedBox(width: 8)],
                      Text(label, style: TextStyle(color: fg, fontSize: 17, fontWeight: FontWeight.w600, letterSpacing: -0.2)),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class FishiField extends StatefulWidget {
  const FishiField({
    super.key,
    required this.controller,
    required this.label,
    this.obscure = false,
    this.suffix,
    this.prefix,
    this.onChanged,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
    this.autofocus = false,
    this.maxLength,
    this.maxLines = 1,
    this.inputFormatters,
    this.focusNode,
    this.autofillHints,
    this.textCapitalization = TextCapitalization.none,
    this.error,
  });

  final TextEditingController controller;
  final String label;
  final bool obscure;
  final Widget? suffix;
  final String? prefix;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;
  final int? maxLength;
  final int? maxLines;
  final List<TextInputFormatter>? inputFormatters;
  final FocusNode? focusNode;
  final Iterable<String>? autofillHints;
  final TextCapitalization textCapitalization;
  final String? error;

  @override
  State<FishiField> createState() => _FishiFieldState();
}

class _FishiFieldState extends State<FishiField> {
  late final FocusNode _focus = widget.focusNode ?? FocusNode();
  bool _hide = true;

  @override
  void initState() {
    super.initState();
    _focus.addListener(_rebuild);
    widget.controller.addListener(_rebuild);
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _focus.removeListener(_rebuild);
    widget.controller.removeListener(_rebuild);
    if (widget.focusNode == null) _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final focused = _focus.hasFocus;
    final floated = focused || widget.controller.text.isNotEmpty;
    final hasError = widget.error != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: kSmooth,
          padding: const EdgeInsets.fromLTRB(18, 8, 10, 8),
          constraints: const BoxConstraints(minHeight: 62),
          decoration: BoxDecoration(
            color: p.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: hasError ? p.danger : (focused ? p.ink : p.line),
              width: focused || hasError ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    AnimatedAlign(
                      duration: const Duration(milliseconds: 260),
                      curve: kSmooth,
                      alignment: floated ? Alignment.topLeft : Alignment.centerLeft,
                      child: AnimatedScale(
                        duration: const Duration(milliseconds: 260),
                        curve: kSmooth,
                        alignment: Alignment.centerLeft,
                        scale: floated ? 0.76 : 1,
                        child: Text(widget.label, style: TextStyle(color: p.muted, fontSize: 16.5)),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Row(
                        children: [
                          if (widget.prefix != null)
                            AnimatedOpacity(
                              duration: const Duration(milliseconds: 200),
                              opacity: floated ? 1 : 0,
                              child: Text(widget.prefix!, style: TextStyle(color: p.muted, fontSize: 17)),
                            ),
                          Expanded(
                            child: TextField(
                              controller: widget.controller,
                              focusNode: _focus,
                              obscureText: widget.obscure && _hide,
                              onChanged: widget.onChanged,
                              keyboardType: widget.keyboardType,
                              textInputAction: widget.textInputAction,
                              onSubmitted: widget.onSubmitted,
                              autofocus: widget.autofocus,
                              maxLength: widget.maxLength,
                              maxLines: widget.obscure ? 1 : widget.maxLines,
                              minLines: 1,
                              inputFormatters: widget.inputFormatters,
                              autofillHints: widget.autofillHints,
                              textCapitalization: widget.textCapitalization,
                              autocorrect: false,
                              style: TextStyle(fontSize: 17, color: p.ink),
                              decoration: const InputDecoration(
                                isCollapsed: true,
                                border: InputBorder.none,
                                counterText: '',
                                contentPadding: EdgeInsets.symmetric(vertical: 6),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.obscure)
                Tappable(
                  onTap: () => setState(() => _hide = !_hide),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
                      child: Icon(
                        _hide ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        key: ValueKey(_hide),
                        color: p.muted,
                        size: 21,
                      ),
                    ),
                  ),
                ),
              if (widget.suffix != null) widget.suffix!,
            ],
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 260),
          curve: kSmooth,
          alignment: Alignment.topLeft,
          child: hasError
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(18, 6, 18, 0),
                  child: Text(widget.error!, style: TextStyle(color: p.danger, fontSize: 13.5)),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}

class FishiSwitch extends StatelessWidget {
  const FishiSwitch({super.key, required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.selectionClick();
        onChanged(!value);
      },
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: value ? 1 : 0),
        duration: const Duration(milliseconds: 420),
        curve: kSpring,
        builder: (context, t, _) {
          final tc = t.clamp(0.0, 1.0);
          return Container(
            width: 52,
            height: 32,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: Color.lerp(p.soft, p.ink, tc),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Align(
              alignment: Alignment(-1 + 2 * t, 0),
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: Color.lerp(p.card, p.paper, tc),
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 6, offset: const Offset(0, 2))],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class Segmented<T> extends StatelessWidget {
  const Segmented({super.key, required this.values, required this.labels, required this.value, required this.onChanged});

  final List<T> values;
  final List<String> labels;
  final T value;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final index = values.indexOf(value);
    return Container(
      height: 40,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: p.soft, borderRadius: BorderRadius.circular(20)),
      child: LayoutBuilder(builder: (context, c) {
        final w = c.maxWidth / values.length;
        return Stack(children: [
          AnimatedPositioned(
            duration: const Duration(milliseconds: 460),
            curve: kSpring,
            left: w * index,
            top: 0,
            bottom: 0,
            width: w,
            child: Container(
              decoration: BoxDecoration(
                color: p.card,
                borderRadius: BorderRadius.circular(17),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 8, offset: const Offset(0, 2))],
              ),
            ),
          ),
          Row(children: [
            for (var i = 0; i < values.length; i++)
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onChanged(values[i]);
                  },
                  child: Center(
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: TextStyle(
                        fontFamily: kTextFont,
                        color: i == index ? p.ink : p.muted,
                        fontSize: 14.5,
                        fontWeight: i == index ? FontWeight.w600 : FontWeight.w500,
                      ),
                      child: Text(labels[i]),
                    ),
                  ),
                ),
              ),
          ]),
        ]);
      }),
    );
  }
}

class Section extends StatelessWidget {
  const Section({super.key, this.title, required this.children, this.footer});

  final String? title;
  final List<Widget> children;
  final String? footer;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
              child: Text(title!.toUpperCase(), style: TextStyle(color: p.muted, fontSize: 12.5, letterSpacing: 0.8, fontWeight: FontWeight.w600)),
            ),
          Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(20)),
            child: Column(
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  if (i > 0) Divider(height: 0.5, thickness: 0.5, indent: 56, color: p.line),
                  children[i],
                ],
              ],
            ),
          ),
          if (footer != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
              child: Text(footer!, style: TextStyle(color: p.muted, fontSize: 13, height: 1.35)),
            ),
        ],
      ),
    );
  }
}

class RowTile extends StatelessWidget {
  const RowTile({super.key, required this.icon, required this.title, this.subtitle, this.trailing, this.onTap, this.danger = false, this.chevron = true});

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool danger;
  final bool chevron;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final color = danger ? p.danger : p.ink;
    return Tappable(
      scale: 0.985,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(color: danger ? p.danger.withValues(alpha: 0.12) : p.soft, borderRadius: BorderRadius.circular(9)),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 16, color: color, fontWeight: FontWeight.w500)),
                  if (subtitle != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(subtitle!, style: TextStyle(fontSize: 13, color: p.muted)),
                    ),
                ],
              ),
            ),
            ?trailing,
            if (trailing == null && onTap != null && chevron) Icon(Icons.chevron_right_rounded, color: p.muted, size: 22),
          ],
        ),
      ),
    );
  }
}

class CircleIcon extends StatelessWidget {
  const CircleIcon({super.key, required this.icon, this.onTap, this.size = 38, this.filled = false, this.tooltip});

  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final bool filled;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Tappable(
      scale: 0.88,
      onTap: onTap == null
          ? null
          : () {
              HapticFeedback.selectionClick();
              onTap!();
            },
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: filled ? p.ink : p.soft, shape: BoxShape.circle),
        child: Icon(icon, size: size * 0.5, color: filled ? p.paper : p.ink, semanticLabel: tooltip),
      ),
    );
  }
}

class LargeTitleScroll extends StatefulWidget {
  const LargeTitleScroll({
    super.key,
    required this.title,
    required this.slivers,
    this.leading,
    this.actions = const [],
    this.below,
    this.controller,
    this.onRefresh,
  });

  final String title;
  final List<Widget> slivers;
  final Widget? leading;
  final List<Widget> actions;
  final Widget? below;
  final ScrollController? controller;
  final Future<void> Function()? onRefresh;

  @override
  State<LargeTitleScroll> createState() => _LargeTitleScrollState();
}

class _LargeTitleScrollState extends State<LargeTitleScroll> {
  late final ScrollController _sc = widget.controller ?? ScrollController();
  final _offset = ValueNotifier(0.0);

  @override
  void initState() {
    super.initState();
    _sc.addListener(() => _offset.value = _sc.hasClients ? _sc.offset : 0);
  }

  @override
  void dispose() {
    if (widget.controller == null) _sc.dispose();
    _offset.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final top = MediaQuery.paddingOf(context).top;
    Widget scroll = CustomScrollView(
      controller: _sc,
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      slivers: [
        SliverToBoxAdapter(child: SizedBox(height: top + 52)),
        SliverToBoxAdapter(
          child: ValueListenableBuilder<double>(
            valueListenable: _offset,
            builder: (context, o, child) {
              final pull = (-o).clamp(0.0, 120.0);
              final fade = (1 - o / 40).clamp(0.0, 1.0);
              return Opacity(
                opacity: fade,
                child: Transform.scale(
                  alignment: Alignment.centerLeft,
                  scale: 1 + pull / 900,
                  child: child,
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: Reveal(
                offset: const Offset(-14, 0),
                child: Text(widget.title,
                    style: TextStyle(fontFamily: kDisplayFont, fontSize: 34, fontWeight: FontWeight.w800, letterSpacing: -1, color: p.ink)),
              ),
            ),
          ),
        ),
        if (widget.below != null) SliverToBoxAdapter(child: widget.below),
        ...widget.slivers,
        SliverToBoxAdapter(child: SizedBox(height: MediaQuery.paddingOf(context).bottom + 30)),
      ],
    );
    if (widget.onRefresh != null) {
      scroll = RefreshIndicator(
        onRefresh: widget.onRefresh!,
        color: p.ink,
        backgroundColor: p.card,
        edgeOffset: top + 40,
        child: scroll,
      );
    }
    return Stack(children: [
      scroll,
      Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: ValueListenableBuilder<double>(
          valueListenable: _offset,
          builder: (context, o, _) {
            final t = ((o - 20) / 30).clamp(0.0, 1.0);
            return ClipRect(
              child: BackdropFilter(
                enabled: t > 0.02,
                filter: ImageFilter.blur(sigmaX: 26 * t, sigmaY: 26 * t),
                child: Container(
                  padding: EdgeInsets.only(top: top),
                  height: top + 52,
                  decoration: BoxDecoration(
                    color: p.paper.withValues(alpha: 0.78 * t + (1 - t) * 0.0),
                    border: Border(bottom: BorderSide(color: p.line.withValues(alpha: t), width: 0.5)),
                  ),
                  child: Row(children: [
                    const SizedBox(width: 8),
                    SizedBox(width: 48, child: widget.leading),
                    Expanded(
                      child: Center(
                        child: Opacity(
                          opacity: t,
                          child: Transform.translate(
                            offset: Offset(0, 8 * (1 - t)),
                            child: Text(widget.title, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: p.ink)),
                          ),
                        ),
                      ),
                    ),
                    Row(mainAxisSize: MainAxisSize.min, children: widget.actions),
                    const SizedBox(width: 12),
                  ]),
                ),
              ),
            );
          },
        ),
      ),
    ]);
  }
}

class TopBar extends StatelessWidget implements PreferredSizeWidget {
  const TopBar({super.key, this.title, this.titleWidget, this.actions = const [], this.onBack});

  final String? title;
  final Widget? titleWidget;
  final List<Widget> actions;
  final VoidCallback? onBack;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final canPop = Navigator.of(context).canPop();
    return Glass(
      child: SizedBox(
        height: 56,
        child: Row(children: [
          const SizedBox(width: 6),
          if (canPop || onBack != null)
            Tappable(
              scale: 0.85,
              onTap: onBack ?? () => Navigator.of(context).maybePop(),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(Icons.arrow_back_ios_new_rounded, size: 21, color: p.ink),
              ),
            )
          else
            const SizedBox(width: 40),
          Expanded(
            child: Center(
              child: titleWidget ?? Text(title ?? '', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: p.ink)),
            ),
          ),
          SizedBox(
            width: math.max(40, actions.length * 44.0),
            child: Row(mainAxisAlignment: MainAxisAlignment.end, children: actions),
          ),
          const SizedBox(width: 8),
        ]),
      ),
    );
  }
}

OverlayEntry? _toast;

void showToast(BuildContext context, String message, {bool error = false}) {
  _toast?.remove();
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;
  late OverlayEntry entry;
  entry = OverlayEntry(builder: (context) => _Toast(message: message, error: error, onDone: () {
        if (_toast == entry) _toast = null;
        entry.remove();
      }));
  _toast = entry;
  overlay.insert(entry);
  if (error) HapticFeedback.heavyImpact();
}

class _Toast extends StatefulWidget {
  const _Toast({required this.message, required this.error, required this.onDone});

  final String message;
  final bool error;
  final VoidCallback onDone;

  @override
  State<_Toast> createState() => _ToastState();
}

class _ToastState extends State<_Toast> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
    reverseDuration: const Duration(milliseconds: 280),
  );
  bool _removed = false;

  @override
  void initState() {
    super.initState();
    _c.forward();
    Future.delayed(const Duration(milliseconds: 2600), () async {
      if (!mounted) return;
      await _c.reverse();
      if (!_removed) {
        _removed = true;
        widget.onDone();
      }
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Positioned(
      top: MediaQuery.paddingOf(context).top + 10,
      left: 20,
      right: 20,
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, child) {
            final t = _c.status == AnimationStatus.reverse ? Curves.easeIn.transform(_c.value) : kSpring.transform(_c.value);
            return Opacity(
              opacity: _c.value.clamp(0.0, 1.0),
              child: Transform.translate(offset: Offset(0, -40 * (1 - t)), child: Transform.scale(scale: 0.9 + 0.1 * t, child: child)),
            );
          },
          child: Center(
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                decoration: BoxDecoration(
                  color: widget.error ? p.danger : p.ink,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 18, offset: const Offset(0, 6))],
                ),
                child: Text(widget.message, textAlign: TextAlign.center, style: TextStyle(color: widget.error ? Colors.white : p.paper, fontSize: 14.5, fontWeight: FontWeight.w500)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, this.body});

  final Widget icon;
  final String title;
  final String? body;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Reveal(scale: 0.7, child: icon),
        const SizedBox(height: 16),
        Reveal(delay: const Duration(milliseconds: 80), child: Text(title, textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: p.ink))),
        if (body != null)
          Reveal(
            delay: const Duration(milliseconds: 140),
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(body!, textAlign: TextAlign.center, style: TextStyle(fontSize: 15, color: p.muted, height: 1.35)),
            ),
          ),
      ]),
    );
  }
}

Future<bool> confirm(BuildContext context, {required String title, String? body, required String action, bool danger = false}) async {
  final ok = await Navigator.of(context).push<bool>(sheetRoute(_ConfirmSheet(title: title, body: body, action: action, danger: danger)));
  return ok ?? false;
}

class _ConfirmSheet extends StatelessWidget {
  const _ConfirmSheet({required this.title, this.body, required this.action, required this.danger});

  final String title;
  final String? body;
  final String action;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return BottomSheetFrame(
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(title, textAlign: TextAlign.center, style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: p.ink)),
        if (body != null) ...[
          const SizedBox(height: 8),
          Text(body!, textAlign: TextAlign.center, style: TextStyle(fontSize: 15, color: p.muted, height: 1.35)),
        ],
        const SizedBox(height: 22),
        PillButton(label: action, danger: danger, onTap: () => Navigator.of(context).pop(true)),
        const SizedBox(height: 10),
        PillButton(label: tr('Cancel'), secondary: true, onTap: () => Navigator.of(context).pop(false)),
      ]),
    );
  }
}

class BottomSheetFrame extends StatelessWidget {
  const BottomSheetFrame({super.key, required this.child, this.padding = const EdgeInsets.fromLTRB(22, 10, 22, 18)});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final mq = MediaQuery.of(context);
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: EdgeInsets.only(bottom: mq.viewInsets.bottom),
        child: Material(
          color: p.paper,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          clipBehavior: Clip.antiAlias,
          child: SafeArea(
            top: false,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: mq.size.height * 0.9),
              child: Padding(
                padding: padding,
                child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Center(
                    child: Container(
                      width: 38,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(color: p.line, borderRadius: BorderRadius.circular(3)),
                    ),
                  ),
                  Flexible(child: child),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CountUp extends StatelessWidget {
  const CountUp({super.key, required this.value, this.style});

  final num value;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: const Duration(milliseconds: 1100),
      curve: kSmooth,
      builder: (context, v, _) => Text(v.round().toString(), style: style),
    );
  }
}
