import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../core/motion.dart';
import '../core/theme.dart';
import 'chibi.dart';

final _mention = RegExp(r'@[a-z0-9_]{3,20}', caseSensitive: false);

List<InlineSpan> richSpans(
  String text,
  TextStyle style, {
  Set<String>? mentionable,
  TextStyle? mentionStyle,
  void Function(String username)? onMention,
}) {
  final spans = <InlineSpan>[];
  final size = (style.fontSize ?? 16) * 1.25;
  var buf = StringBuffer();

  void flushText() {
    if (buf.isEmpty) return;
    final s = buf.toString();
    buf = StringBuffer();
    var last = 0;
    for (final m in _mention.allMatches(s)) {
      final name = m.group(0)!.substring(1).toLowerCase();
      if (mentionable != null && !mentionable.contains(name)) continue;
      if (m.start > last) spans.add(TextSpan(text: s.substring(last, m.start), style: style));
      spans.add(TextSpan(
        text: m.group(0),
        style: mentionStyle ?? style.copyWith(fontWeight: FontWeight.w700),
        recognizer: onMention == null ? null : (TapGestureRecognizer()..onTap = () => onMention(name)),
      ));
      last = m.end;
    }
    if (last < s.length) spans.add(TextSpan(text: s.substring(last), style: style));
  }

  for (final g in text.characters) {
    final def = chibiFor(g);
    if (def == null) {
      buf.write(g);
      continue;
    }
    flushText();
    spans.add(WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 1),
        child: Chibi(def, size: size, ink: style.color),
      ),
    ));
  }
  flushText();
  return spans;
}

class EmojiText extends StatelessWidget {
  const EmojiText(this.text, {super.key, required this.style, this.maxLines, this.overflow, this.mentionable, this.mentionStyle, this.onMention});

  final String text;
  final TextStyle style;
  final int? maxLines;
  final TextOverflow? overflow;
  final Set<String>? mentionable;
  final TextStyle? mentionStyle;
  final void Function(String username)? onMention;

  @override
  Widget build(BuildContext context) {
    if (!containsChibi(text) && !text.contains('@')) {
      return Text(text, style: style, maxLines: maxLines, overflow: overflow);
    }
    return Text.rich(
      TextSpan(children: richSpans(text, style, mentionable: mentionable, mentionStyle: mentionStyle, onMention: onMention)),
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

class EmojiPicker extends StatefulWidget {
  const EmojiPicker({super.key, required this.onPick, this.height = 300});

  final ValueChanged<String> onPick;
  final double height;

  @override
  State<EmojiPicker> createState() => _EmojiPickerState();
}

class _EmojiPickerState extends State<EmojiPicker> {
  String _group = chibiGroups.first;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final items = chibiAll.where((d) => d.group == _group).toList();
    return SizedBox(
      height: widget.height,
      child: Column(children: [
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            children: [
              for (final g in chibiGroups)
                GestureDetector(
                  onTap: () => setState(() => _group = g),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 260),
                    curve: kSmooth,
                    margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: g == _group ? p.ink : p.soft, borderRadius: BorderRadius.circular(16)),
                    child: Text(g, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: g == _group ? p.paper : p.muted)),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            switchInCurve: kSmooth,
            transitionBuilder: (c, a) => FadeTransition(
              opacity: a,
              child: SlideTransition(position: Tween(begin: const Offset(0, 0.04), end: Offset.zero).animate(a), child: c),
            ),
            child: GridView.builder(
              key: ValueKey(_group),
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 52, mainAxisSpacing: 4, crossAxisSpacing: 4),
              itemCount: items.length,
              itemBuilder: (context, i) => _PickCell(def: items[i], index: i, onTap: () => widget.onPick(items[i].char)),
            ),
          ),
        ),
      ]),
    );
  }
}

class _PickCell extends StatelessWidget {
  const _PickCell({required this.def, required this.index, required this.onTap});

  final ChibiDef def;
  final int index;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Reveal(
      delay: Duration(milliseconds: (index * 8).clamp(0, 240)),
      duration: const Duration(milliseconds: 380),
      offset: const Offset(0, 8),
      scale: 0.6,
      child: Tappable(
        scale: 0.8,
        onTap: onTap,
        child: Padding(padding: const EdgeInsets.all(6), child: Chibi(def, size: 36)),
      ),
    );
  }
}
