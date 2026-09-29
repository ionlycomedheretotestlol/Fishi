import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';

import '../brand/avatar.dart';
import '../core/data.dart';
import '../core/inbox.dart';
import '../core/models.dart';
import '../core/motion.dart';
import '../core/theme.dart';
import '../emoji/chibi.dart';
import '../emoji/emoji_text.dart';
import '../ui/kit.dart';
import 'bubble_shape.dart';
import 'chat_controller.dart';
import 'media_view.dart';
import 'voice.dart';
import '../core/i18n.dart';

BubbleStyle styleFor(String senderId) {
  if (senderId == Inbox.instance.finnId) return const BubbleStyle(shape: BubbleShape.fish);
  return Profiles.instance[senderId]?.bubble ?? const BubbleStyle();
}

String snippet(Message m) {
  if (m.deleted) return tr('Unsent message');
  return switch (m.kind) {
    'image' => m.body.isEmpty ? tr('Photo') : tr('Photo: {text}', {'text': m.body}),
    'video' => tr('Video'),
    'audio' => tr('Voice message'),
    _ => m.body,
  };
}

class MessageRow extends StatefulWidget {
  const MessageRow({
    super.key,
    required this.message,
    required this.controller,
    required this.tail,
    required this.showName,
    required this.showAvatar,
    required this.fresh,
    required this.onReply,
    required this.onMenu,
    this.footer,
    this.onMention,
  });

  final Message message;
  final ChatController controller;
  final bool tail;
  final bool showName;
  final bool showAvatar;
  final bool fresh;
  final ValueChanged<Message> onReply;
  final void Function(Message m, GlobalKey key) onMenu;
  final Widget? footer;
  final void Function(String username)? onMention;

  @override
  State<MessageRow> createState() => _MessageRowState();
}

class _MessageRowState extends State<MessageRow> with TickerProviderStateMixin {
  late final AnimationController _enter = AnimationController(vsync: this, duration: const Duration(milliseconds: 560));
  late final AnimationController _swipe = AnimationController.unbounded(vsync: this);
  final _bubbleKey = GlobalKey();
  bool _armed = false;

  static const _threshold = 64.0;

  @override
  void initState() {
    super.initState();
    if (widget.fresh) {
      _enter.forward();
    } else {
      _enter.value = 1;
    }
  }

  @override
  void dispose() {
    _enter.dispose();
    _swipe.dispose();
    super.dispose();
  }

  void _dragUpdate(DragUpdateDetails d) {
    final next = (_swipe.value + d.delta.dx * (1 - (_swipe.value / 120).clamp(0.0, 0.8))).clamp(0.0, 100.0);
    _swipe.value = next;
    final armed = next >= _threshold;
    if (armed != _armed) {
      _armed = armed;
      if (armed) HapticFeedback.mediumImpact();
    }
  }

  void _dragEnd(DragEndDetails d) {
    if (_armed) widget.onReply(widget.message);
    _armed = false;
    final sim = SpringSimulation(const SpringDescription(mass: 1, stiffness: 420, damping: 26), _swipe.value, 0, d.primaryVelocity ?? 0);
    _swipe.animateWith(sim);
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.message;
    final p = Palette.of(context);
    if (m.isSystem) return _SystemLine(message: m, controller: widget.controller);

    final mine = m.mine;
    final sender = Profiles.instance[m.senderId];
    final isFinnMsg = m.senderId == Inbox.instance.finnId;
    final group = widget.controller.isGroup;

    Widget bubble = KeyedSubtree(
      key: _bubbleKey,
      child: MessageBubble(message: m, controller: widget.controller, tail: widget.tail, onMention: widget.onMention),
    );

    bubble = GestureDetector(
      onLongPress: m.deleted || m.pending
          ? null
          : () {
              HapticFeedback.mediumImpact();
              widget.onMenu(m, _bubbleKey);
            },
      onTap: m.failed ? () => _failedMenu(context) : null,
      child: bubble,
    );

    final reacts = widget.controller.reactions[m.id] ?? const <Reaction>[];

    Widget column = Column(
      crossAxisAlignment: mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.showName && !mine)
          Padding(
            padding: const EdgeInsets.only(left: 14, bottom: 3, top: 4),
            child: Text(
              isFinnMsg ? 'Finn' : (sender?.displayName ?? ''),
              style: TextStyle(fontSize: 12.5, color: p.muted, fontWeight: FontWeight.w600),
            ),
          ),
        if (m.viaFinn)
          Padding(
            padding: const EdgeInsets.only(right: 12, bottom: 3),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const FinnAvatar(size: 14),
              const SizedBox(width: 4),
              Text(tr('sent with Finn'), style: TextStyle(fontSize: 11.5, color: p.muted)),
            ]),
          ),
        bubble,
        if (reacts.isNotEmpty)
          Transform.translate(
            offset: const Offset(0, -6),
            child: _ReactionPills(reactions: reacts, onTap: (e) => widget.controller.react(m, e), mine: mine),
          ),
        if (m.failed)
          Padding(
            padding: const EdgeInsets.only(top: 3, right: 6),
            child: Text(tr('Not sent. Tap to retry.'), style: TextStyle(fontSize: 12, color: p.danger)),
          ),
        ?widget.footer,
      ],
    );

    final maxW = MediaQuery.sizeOf(context).width * 0.76;
    Widget row = Row(
      mainAxisAlignment: mine ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (!mine && group)
          SizedBox(
            width: 34,
            child: widget.showAvatar
                ? Padding(
                    padding: EdgeInsets.only(bottom: reacts.isEmpty ? 2 : 18),
                    child: isFinnMsg ? const FinnAvatar(size: 28) : Avatar(profile: sender, size: 28),
                  )
                : null,
          ),
        ConstrainedBox(constraints: BoxConstraints(maxWidth: maxW), child: column),
      ],
    );

    row = GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragUpdate: m.deleted || m.pending ? null : _dragUpdate,
      onHorizontalDragEnd: m.deleted || m.pending ? null : _dragEnd,
      child: AnimatedBuilder(
        animation: _swipe,
        child: row,
        builder: (context, child) {
          final dx = _swipe.value;
          final t = (dx / _threshold).clamp(0.0, 1.0);
          return Stack(clipBehavior: Clip.none, alignment: Alignment.centerLeft, children: [
            Positioned(
              left: 8,
              child: Opacity(
                opacity: t,
                child: Transform.scale(
                  scale: 0.5 + 0.5 * (dx >= _threshold ? 1.1 : t),
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(color: dx >= _threshold ? p.ink : p.soft, shape: BoxShape.circle),
                    child: Icon(Icons.reply_rounded, size: 18, color: dx >= _threshold ? p.paper : p.ink),
                  ),
                ),
              ),
            ),
            Transform.translate(offset: Offset(dx, 0), child: child),
          ]);
        },
      ),
    );

    return AnimatedBuilder(
      animation: _enter,
      child: Padding(
        padding: EdgeInsets.only(left: 10, right: 10, top: widget.showName ? 6 : 1.5, bottom: widget.tail ? 6 : 1.5),
        child: row,
      ),
      builder: (context, child) {
        if (_enter.value >= 1) return child!;
        final t = kSpring.transform(_enter.value);
        final o = Curves.easeOut.transform((_enter.value * 1.6).clamp(0.0, 1.0));
        return Opacity(
          opacity: o,
          child: Transform.translate(
            offset: Offset(0, 26 * (1 - t)),
            child: Transform.scale(
              alignment: mine ? Alignment.bottomRight : Alignment.bottomLeft,
              scale: 0.72 + 0.28 * t,
              child: child,
            ),
          ),
        );
      },
    );
  }

  void _failedMenu(BuildContext context) {
    Navigator.of(context).push(sheetRoute(BottomSheetFrame(
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        PillButton(
          label: tr('Try again'),
          onTap: () {
            Navigator.of(context).pop();
            widget.controller.retry(widget.message);
          },
        ),
        const SizedBox(height: 10),
        PillButton(
          label: tr('Delete'),
          secondary: true,
          danger: true,
          onTap: () {
            Navigator.of(context).pop();
            widget.controller.discard(widget.message);
          },
        ),
      ]),
    )));
  }
}

class MessageBubble extends StatelessWidget {
  const MessageBubble({super.key, required this.message, required this.controller, required this.tail, this.onMention, this.interactive = true});

  final Message message;
  final ChatController controller;
  final bool tail;
  final bool interactive;
  final void Function(String username)? onMention;

  @override
  Widget build(BuildContext context) {
    final m = message;
    final p = Palette.of(context);
    final mine = m.mine;
    if (m.deleted) {
      final who = mine ? tr('You') : (Profiles.instance[m.senderId]?.displayName.split(' ').first ?? tr('Someone'));
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: p.line, width: 1.2),
        ),
        child: Text(tr('{who} unsent a message', {'who': who}), style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: p.muted)),
      );
    }

    final style = styleFor(m.senderId);
    final fg = bubbleText(style, p, mine: mine);
    final reply = controller.replyTarget(m.replyTo);

    final emojiCount = m.kind == 'text' && reply == null ? emojiOnlyCount(m.body) : null;
    if (emojiCount != null) {
      final size = emojiCount == 1 ? 64.0 : (emojiCount == 2 ? 54.0 : 46.0);
      return Opacity(
        opacity: m.pending ? 0.6 : 1,
        child: Wrap(
          spacing: 4,
          children: [
            for (final g in m.body.trim().characters)
              if (g.trim().isNotEmpty) _PopIn(child: ChibiChar(g, size: size)),
          ],
        ),
      );
    }

    final textStyle = TextStyle(fontSize: 16.5, color: fg, height: 1.3);
    final mentionStyle = textStyle.copyWith(fontWeight: FontWeight.w800, decoration: TextDecoration.underline, decorationColor: fg.withValues(alpha: 0.5));

    Widget? quote;
    if (reply != null) {
      final who = reply.mine ? tr('You') : (reply.senderId == Inbox.instance.finnId ? 'Finn' : Profiles.instance[reply.senderId]?.displayName ?? '');
      quote = Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.fromLTRB(9, 5, 9, 6),
        decoration: BoxDecoration(
          color: fg.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border(left: BorderSide(color: fg.withValues(alpha: 0.7), width: 3)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (reply.kind == 'image' && reply.mediaPath != null && !reply.deleted)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ClipRRect(borderRadius: BorderRadius.circular(6), child: SizedBox.square(dimension: 34, child: MediaImage(message: reply, fit: BoxFit.cover))),
            ),
          Flexible(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text(who, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: fg.withValues(alpha: 0.85))),
              EmojiText(snippet(reply), maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13.5, color: fg.withValues(alpha: 0.75))),
            ]),
          ),
        ]),
      );
    }

    Widget content;
    switch (m.kind) {
      case 'image':
        final w = (m.mediaMeta['w'] as num?)?.toDouble() ?? 3;
        final h = (m.mediaMeta['h'] as num?)?.toDouble() ?? 4;
        final ratio = (w / h).clamp(0.5, 2.0);
        final img = Hero(
          tag: 'media-${m.id}',
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: AspectRatio(
              aspectRatio: ratio,
              child: Stack(fit: StackFit.expand, children: [
                MediaImage(message: m, fit: BoxFit.cover),
                if (m.pending) Container(color: Colors.black26, child: const Center(child: Spinner(color: Colors.white))),
              ]),
            ),
          ),
        );
        final imgBox = ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 250, maxHeight: 340),
          child: GestureDetector(
            onTap: interactive && !m.pending ? () => Navigator.of(context).push(fadeRoute(MediaViewer(message: m))) : null,
            child: img,
          ),
        );
        if (m.body.isEmpty && quote == null) return Opacity(opacity: m.pending ? 0.85 : 1, child: imgBox);
        content = Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          ?quote,
          ClipRRect(borderRadius: BorderRadius.circular(14), child: imgBox),
          if (m.body.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: EmojiText(m.body, style: textStyle, mentionable: controller.mentionable, mentionStyle: mentionStyle, onMention: onMention),
            ),
        ]);
      case 'audio':
        content = Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          ?quote,
          VoiceBubbleBody(message: m, color: fg),
        ]);
      case 'video':
        content = Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.play_circle_outline_rounded, color: fg),
          const SizedBox(width: 6),
          Text(tr('Video'), style: textStyle),
        ]);
      default:
        content = Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          ?quote,
          EmojiText(m.body, style: textStyle, mentionable: controller.mentionable, mentionStyle: mentionStyle, onMention: onMention),
        ]);
    }

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: m.pending ? 0.62 : 1,
      child: BubbleBox(style: style, mine: mine, tail: tail, child: content),
    );
  }
}

class _PopIn extends StatelessWidget {
  const _PopIn({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 700),
      curve: Curves.elasticOut,
      builder: (context, t, c) => Transform.scale(scale: 0.3 + 0.7 * t, child: c),
      child: child,
    );
  }
}

class MediaImage extends StatelessWidget {
  const MediaImage({super.key, required this.message, this.fit = BoxFit.cover});

  final Message message;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final bytes = message.localBytes;
    if (bytes != null) return Image.memory(bytes, fit: fit, gaplessPlayback: true);
    final path = message.mediaPath;
    if (path == null) return Container(color: p.soft);
    return FutureBuilder<String?>(
      future: MediaUrls.get(path),
      builder: (context, snap) {
        final url = snap.data;
        if (url == null) return _Shimmer(color: p.soft);
        return CachedNetworkImage(
          imageUrl: url,
          cacheKey: path,
          fit: fit,
          fadeInDuration: const Duration(milliseconds: 260),
          fadeInCurve: kSmooth,
          placeholder: (_, _) => _Shimmer(color: p.soft),
          errorWidget: (_, _, _) => Container(color: p.soft, child: Icon(Icons.broken_image_outlined, color: p.muted)),
        );
      },
    );
  }
}

class _Shimmer extends StatefulWidget {
  const _Shimmer({required this.color});
  final Color color;

  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) => Opacity(
        opacity: 0.6 + 0.4 * math.sin(_c.value * math.pi),
        child: Container(color: widget.color),
      ),
    );
  }
}

class _ReactionPills extends StatelessWidget {
  const _ReactionPills({required this.reactions, required this.onTap, required this.mine});

  final List<Reaction> reactions;
  final ValueChanged<String> onTap;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final counts = <String, int>{};
    for (final r in reactions) {
      counts[r.emoji] = (counts[r.emoji] ?? 0) + 1;
    }
    final mineEmoji = reactions.where((r) => r.userId == myId).firstOrNull?.emoji;
    return Padding(
      padding: EdgeInsets.only(left: mine ? 0 : 12, right: mine ? 12 : 0),
      child: Wrap(spacing: 4, children: [
        for (final e in counts.entries)
          _PopIn(
            key: ValueKey('${e.key}${e.value}'),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                onTap(e.key);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: e.key == mineEmoji ? p.ink : p.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: p.paper, width: 2),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 4, offset: const Offset(0, 1))],
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  chibiFor(e.key) != null
                      ? Chibi(chibiFor(e.key)!, size: 18, ink: e.key == mineEmoji ? p.paper : p.ink)
                      : Text(e.key, style: const TextStyle(fontSize: 14)),
                  if (e.value > 1) ...[
                    const SizedBox(width: 3),
                    Text('${e.value}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: e.key == mineEmoji ? p.paper : p.ink)),
                  ],
                ]),
              ),
            ),
          ),
      ]),
    );
  }
}

class _SystemLine extends StatelessWidget {
  const _SystemLine({required this.message, required this.controller});

  final Message message;
  final ChatController controller;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final m = message;
    final who = m.mine ? tr('You') : (Profiles.instance[m.senderId]?.displayName ?? tr('Someone'));
    if (m.kind == 'call') {
      final video = m.mediaMeta['video'] == true;
      final missed = m.mediaMeta['missed'] == true;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Center(
          child: Reveal(
            scale: 0.8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(18), border: Border.all(color: p.line)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(
                  missed ? Icons.phone_missed_rounded : (video ? Icons.videocam_rounded : Icons.call_rounded),
                  size: 17,
                  color: missed ? p.danger : p.ink,
                ),
                const SizedBox(width: 8),
                Text(m.body.isEmpty ? tr('Call') : callText(m.body), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: p.ink)),
                const SizedBox(width: 8),
                Text(timeLabel(m.createdAt), style: TextStyle(fontSize: 12, color: p.muted)),
              ]),
            ),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 30),
      child: Text('$who ${tr(m.body)}', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: p.muted)),
    );
  }
}
