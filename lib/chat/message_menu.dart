import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/data.dart';
import '../core/models.dart';
import '../core/motion.dart';
import '../core/theme.dart';
import '../emoji/chibi.dart';
import '../emoji/emoji_text.dart';
import '../ui/kit.dart';
import '../core/i18n.dart';

const quickReactions = ['❤️', '😂', '👍', '👎', '😮', '😢'];

class MenuAction {
  const MenuAction(this.icon, this.label, this.onTap, {this.danger = false});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;
}

Future<void> showMessageMenu(
  BuildContext context, {
  required GlobalKey bubbleKey,
  required Widget bubble,
  required Message message,
  required String? myReaction,
  required ValueChanged<String> onReact,
  required List<MenuAction> actions,
}) async {
  final box = bubbleKey.currentContext?.findRenderObject() as RenderBox?;
  if (box == null || !box.attached) return;
  final rect = box.localToGlobal(Offset.zero) & box.size;
  await Navigator.of(context).push(PageRouteBuilder(
    opaque: false,
    barrierDismissible: true,
    transitionDuration: const Duration(milliseconds: 460),
    reverseTransitionDuration: const Duration(milliseconds: 260),
    pageBuilder: (context, a, _) => _MessageMenu(
      animation: a,
      rect: rect,
      bubble: bubble,
      mine: message.mine,
      myReaction: myReaction,
      onReact: onReact,
      actions: actions,
    ),
  ));
}

class _MessageMenu extends StatefulWidget {
  const _MessageMenu({
    required this.animation,
    required this.rect,
    required this.bubble,
    required this.mine,
    required this.myReaction,
    required this.onReact,
    required this.actions,
  });

  final Animation<double> animation;
  final Rect rect;
  final Widget bubble;
  final bool mine;
  final String? myReaction;
  final ValueChanged<String> onReact;
  final List<MenuAction> actions;

  @override
  State<_MessageMenu> createState() => _MessageMenuState();
}

class _MessageMenuState extends State<_MessageMenu> {
  bool _picker = false;

  void _close([VoidCallback? then]) {
    Navigator.of(context).pop();
    if (then != null) Future.delayed(const Duration(milliseconds: 120), then);
  }

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final mq = MediaQuery.of(context);
    final size = mq.size;
    const barH = 58.0;
    final menuH = widget.actions.length * 50.0 + 12;
    final topLimit = mq.padding.top + 12 + barH + 10;
    final bottomLimit = size.height - mq.padding.bottom - 16 - menuH - 10;
    final bubbleH = widget.rect.height.clamp(0.0, size.height * 0.45);
    var top = widget.rect.top;
    if (top < topLimit) top = topLimit;
    if (top + bubbleH > bottomLimit) top = (bottomLimit - bubbleH).clamp(topLimit, double.infinity);
    final shift = top - widget.rect.top;
    final alignRight = widget.mine;
    final hPad = 12.0;

    return AnimatedBuilder(
      animation: widget.animation,
      builder: (context, _) {
        final raw = widget.animation.value;
        final reversing = widget.animation.status == AnimationStatus.reverse;
        final t = reversing ? Curves.easeIn.transform(raw) : kSmooth.transform(raw);
        final pop = reversing ? t : kSpring.transform(raw);
        return Stack(children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: _close,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16 * t, sigmaY: 16 * t),
                child: Container(color: p.paper.withValues(alpha: 0.45 * t)),
              ),
            ),
          ),
          Positioned(
            left: widget.rect.left,
            top: widget.rect.top + shift * t,
            width: widget.rect.width,
            height: bubbleH,
            child: IgnorePointer(
              child: Transform.scale(
                scale: 1 + 0.035 * pop,
                alignment: alignRight ? Alignment.centerRight : Alignment.centerLeft,
                child: OverflowBox(
                  alignment: Alignment.topLeft,
                  maxHeight: double.infinity,
                  child: SizedBox(width: widget.rect.width, child: widget.bubble),
                ),
              ),
            ),
          ),
          Positioned(
            top: top - barH - 8,
            left: alignRight ? null : hPad,
            right: alignRight ? hPad : null,
            child: Opacity(
              opacity: t.clamp(0.0, 1.0),
              child: Transform.scale(
                scale: 0.6 + 0.4 * pop,
                alignment: alignRight ? Alignment.bottomRight : Alignment.bottomLeft,
                child: _ReactionBar(
                  selected: widget.myReaction,
                  onPick: (e) => _close(() => widget.onReact(e)),
                  onMore: () => setState(() => _picker = true),
                ),
              ),
            ),
          ),
          Positioned(
            top: top + bubbleH + 10,
            left: alignRight ? null : hPad,
            right: alignRight ? hPad : null,
            width: 230,
            child: Opacity(
              opacity: t.clamp(0.0, 1.0),
              child: Transform.translate(
                offset: Offset(0, -16 * (1 - pop)),
                child: Transform.scale(
                  scale: 0.8 + 0.2 * pop,
                  alignment: alignRight ? Alignment.topRight : Alignment.topLeft,
                  child: Material(
                    color: p.card,
                    borderRadius: BorderRadius.circular(18),
                    elevation: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.14), blurRadius: 24, offset: const Offset(0, 8))],
                      ),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        for (final a in widget.actions)
                          Tappable(
                            scale: 0.97,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              _close(a.onTap);
                            },
                            child: SizedBox(
                              height: 50,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Row(children: [
                                  Expanded(
                                    child: Text(a.label, style: TextStyle(fontSize: 16, color: a.danger ? p.danger : p.ink)),
                                  ),
                                  Icon(a.icon, size: 20, color: a.danger ? p.danger : p.ink),
                                ]),
                              ),
                            ),
                          ),
                      ]),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (_picker)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Reveal(
                offset: const Offset(0, 80),
                scale: 1,
                child: Container(
                  padding: EdgeInsets.only(bottom: mq.padding.bottom, top: 10),
                  decoration: BoxDecoration(
                    color: p.card,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 24)],
                  ),
                  child: EmojiPicker(height: 320, onPick: (e) => _close(() => widget.onReact(e))),
                ),
              ),
            ),
        ]);
      },
    );
  }
}

class _ReactionBar extends StatelessWidget {
  const _ReactionBar({required this.selected, required this.onPick, required this.onMore});

  final String? selected;
  final ValueChanged<String> onPick;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(29),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.14), blurRadius: 24, offset: const Offset(0, 8))],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        for (var i = 0; i < quickReactions.length; i++)
          Reveal(
            delay: Duration(milliseconds: 40 + i * 35),
            duration: const Duration(milliseconds: 460),
            offset: const Offset(0, 10),
            scale: 0.3,
            child: Tappable(
              scale: 0.75,
              onTap: () {
                HapticFeedback.lightImpact();
                onPick(quickReactions[i]);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 2),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: quickReactions[i] == selected ? p.soft : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Chibi(chibiFor(quickReactions[i])!, size: 32),
              ),
            ),
          ),
        Reveal(
          delay: Duration(milliseconds: 40 + quickReactions.length * 35),
          scale: 0.3,
          offset: const Offset(0, 10),
          child: Tappable(
            scale: 0.8,
            onTap: onMore,
            child: Container(
              margin: const EdgeInsets.only(left: 2, right: 2),
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: p.soft, shape: BoxShape.circle),
              child: Icon(Icons.add_rounded, color: p.ink, size: 22),
            ),
          ),
        ),
      ]),
    );
  }
}

String copyText(Message m) => m.body;

void copyMessage(BuildContext context, Message m) {
  Clipboard.setData(ClipboardData(text: copyText(m)));
  showToast(context, tr('Copied'));
}

String? myReactionOf(List<Reaction>? list) => list?.where((r) => r.userId == myId).firstOrNull?.emoji;
