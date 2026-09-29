import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../brand/avatar.dart';
import '../brand/badges.dart';
import '../calls/call_center.dart';
import '../core/data.dart';
import '../core/inbox.dart';
import '../core/models.dart';
import '../core/motion.dart';
import '../core/prefs.dart';
import '../core/theme.dart';
import '../ui/kit.dart';
import 'chat_background.dart';
import 'chat_controller.dart';
import 'chat_info.dart';
import 'composer.dart';
import 'message_menu.dart';
import 'message_view.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.chatId, this.preview});

  final String chatId;
  final ChatController? preview;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  late final ChatController _c = widget.preview ?? ChatController(widget.chatId);
  final _scroll = ScrollController();
  final _text = TextEditingController();
  final _focus = FocusNode();
  Message? _reply;
  bool _showJump = false;
  int _newWhileAway = 0;
  int _lastCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _c.addListener(_changed);
    Prefs.instance.addListener(_changed);
    Profiles.instance.addListener(_changed);
    _scroll.addListener(_onScroll);
    _c.start();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _c.markRead();
  }

  void _changed() {
    if (!mounted) return;
    final count = _c.messages.length;
    if (count > _lastCount && _lastCount != 0 && _showJump) {
      final added = _c.messages.sublist(math.max(0, _lastCount)).where((m) => !m.mine).length;
      _newWhileAway += added;
    }
    _lastCount = count;
    setState(() {});
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final away = _scroll.offset > 280;
    if (away != _showJump) {
      setState(() {
        _showJump = away;
        if (!away) _newWhileAway = 0;
      });
    }
    if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 600) _c.loadMore();
  }

  void _toBottom() {
    if (!_scroll.hasClients) return;
    _scroll.animateTo(0, duration: const Duration(milliseconds: 520), curve: kSmooth);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _c.removeListener(_changed);
    Prefs.instance.removeListener(_changed);
    Profiles.instance.removeListener(_changed);
    if (widget.preview == null) _c.dispose();
    _scroll.dispose();
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _setReply(Message m) {
    HapticFeedback.selectionClick();
    setState(() => _reply = m);
    _focus.requestFocus();
  }

  void _menu(Message m, GlobalKey key) {
    final actions = <MenuAction>[
      MenuAction(Icons.reply_rounded, 'Reply', () => _setReply(m)),
      if (!_c.isFinn && m.senderId != Inbox.instance.finnId)
        MenuAction(Icons.auto_awesome_outlined, 'Ask Finn', () {
          _setReply(m);
          if (!_text.text.contains('@finn')) {
            _text.value = TextEditingValue(text: '@finn ${_text.text}', selection: TextSelection.collapsed(offset: 6 + _text.text.length));
          }
        }),
      if (m.body.isNotEmpty) MenuAction(Icons.copy_rounded, 'Copy', () => copyMessage(context, m)),
      if (m.mine && !m.deleted)
        MenuAction(Icons.undo_rounded, 'Unsend', () async {
          final ok = await _c.unsend(m);
          if (!ok && mounted) showToast(context, 'Could not unsend.', error: true);
        }, danger: true),
    ];
    showMessageMenu(
      context,
      bubbleKey: key,
      bubble: MessageBubble(message: m, controller: _c, tail: true, interactive: false),
      message: m,
      myReaction: myReactionOf(_c.reactions[m.id]),
      onReact: (e) {
        HapticFeedback.lightImpact();
        _c.react(m, e);
      },
      actions: actions,
    );
  }

  bool _gap(Message a, Message b, int minutes) => b.createdAt.difference(a.createdAt).inMinutes.abs() >= minutes;

  Widget? _footerFor(Message m, Message? lastMine) {
    if (lastMine == null || m.id != lastMine.id || m.pending || m.failed || m.deleted) return null;
    final p = Palette.of(context);
    final style = TextStyle(fontSize: 11.5, color: p.muted, fontWeight: FontWeight.w500);
    final readers = _c.readersOf(m);
    Widget child;
    if (_c.isGroup) {
      child = readers.isEmpty
          ? Text('Delivered', style: style)
          : Row(mainAxisSize: MainAxisSize.min, children: [
              for (final r in readers.take(3))
                Padding(padding: const EdgeInsets.only(left: 2), child: Avatar(profile: r, size: 14)),
              const SizedBox(width: 5),
              Text('Read by ${readers.length}', style: style),
            ]);
    } else if (_c.isFinn) {
      return null;
    } else {
      final other = _c.members.entries.where((e) => e.key != myId).firstOrNull?.value;
      child = readers.isEmpty || other == null ? Text('Delivered', style: style) : Text('Read ${timeLabel(other.lastReadAt)}', style: style);
    }
    return Padding(
      padding: const EdgeInsets.only(top: 3, right: 8),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (c, a) => FadeTransition(opacity: a, child: SizeTransition(sizeFactor: a, alignment: Alignment.topCenter, child: c)),
        child: KeyedSubtree(key: ValueKey(readers.length), child: child),
      ),
    );
  }

  void _openMention(String username) {
    if (username == 'finn') return;
    final p = _c.memberProfiles.where((x) => x.username == username).firstOrNull;
    if (p == null) return;
    showProfileSheet(context, p);
  }

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final msgs = _c.messages;
    Message? lastMine;
    for (final m in msgs.reversed) {
      if (m.mine && !m.isSystem) {
        lastMine = m;
        break;
      }
    }
    final typing = _c.typingNames;
    final itemCount = msgs.length + (typing.isNotEmpty ? 1 : 0) + 1;

    return Scaffold(
      backgroundColor: p.paper,
      body: Column(children: [
        _Header(controller: _c),
        Expanded(
          child: Stack(children: [
            if (Prefs.instance.chatBackground) Positioned.fill(child: ChatBackground(pattern: Prefs.instance.chatPattern, color: p.ink)),
            if (_c.loading)
              const Center(child: Spinner())
            else if (_c.failed)
              Center(child: EmptyState(icon: Icon(Icons.cloud_off_rounded, size: 48, color: p.muted), title: 'Could not load this chat', body: 'Check your connection.'))
            else if (msgs.isEmpty && typing.isEmpty)
              Center(
                child: EmptyState(
                  icon: _c.isFinn ? const FinnAvatar(size: 80) : (_c.isGroup ? Avatar(name: _c.title, size: 80, group: true) : Avatar(profile: _c.other, size: 80)),
                  title: _c.isFinn ? 'Hi, I am Finn' : 'Say hi to ${_c.title}',
                  body: _c.isFinn
                      ? 'Ask me anything. Reply to a photo or voice note and ask about it. I can also text people for you.'
                      : 'Messages you send show up here.',
                ),
              )
            else
              NotificationListener<ScrollStartNotification>(
                onNotification: (n) {
                  if (n.dragDetails != null && _focus.hasFocus) _focus.unfocus();
                  return false;
                },
                child: ListView.builder(
                  controller: _scroll,
                  reverse: true,
                  physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                  padding: const EdgeInsets.only(top: 12, bottom: 8),
                  itemCount: itemCount,
                  itemBuilder: (context, index) {
                    if (typing.isNotEmpty && index == 0) {
                      return _TypingRow(key: const ValueKey('typing'), names: typing, ids: _c.typingIds, group: _c.isGroup);
                    }
                    final i = msgs.length - 1 - (index - (typing.isNotEmpty ? 1 : 0));
                    if (i < 0) {
                      return Padding(
                        padding: const EdgeInsets.all(16),
                        child: Center(child: _c.loadingMore ? const Spinner(size: 18) : const SizedBox(height: 18)),
                      );
                    }
                    final m = msgs[i];
                    final prev = i > 0 ? msgs[i - 1] : null;
                    final next = i < msgs.length - 1 ? msgs[i + 1] : null;
                    final runStart = prev == null || prev.senderId != m.senderId || prev.isSystem || _gap(prev, m, 3);
                    final runEnd = next == null || next.senderId != m.senderId || next.isSystem || _gap(m, next, 3);
                    final day = prev == null || _gap(prev, m, 60);
                    final row = RepaintBoundary(
                      child: MessageRow(
                        key: ValueKey(m.id),
                        message: m,
                        controller: _c,
                        tail: runEnd,
                        showName: _c.isGroup && runStart,
                        showAvatar: runEnd,
                        fresh: _c.fresh.contains(m.id),
                        onReply: _setReply,
                        onMenu: _menu,
                        onMention: _openMention,
                        footer: _footerFor(m, lastMine),
                      ),
                    );
                    if (!day) return row;
                    return Column(mainAxisSize: MainAxisSize.min, children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 14, bottom: 6),
                        child: Text(dayHeader(m.createdAt), style: TextStyle(fontSize: 12, color: p.muted, fontWeight: FontWeight.w600, fontFamily: kMonoFont)),
                      ),
                      row,
                    ]);
                  },
                ),
              ),
            Positioned(
              right: 14,
              bottom: 14,
              child: IgnorePointer(
                ignoring: !_showJump,
                child: AnimatedScale(
                  scale: _showJump ? 1 : 0.4,
                  duration: const Duration(milliseconds: 380),
                  curve: _showJump ? kSpring : Curves.easeIn,
                  child: AnimatedOpacity(
                    opacity: _showJump ? 1 : 0,
                    duration: const Duration(milliseconds: 220),
                    child: Tappable(
                      onTap: _toBottom,
                      child: Container(
                        height: 42,
                        constraints: const BoxConstraints(minWidth: 42),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: p.card,
                          borderRadius: BorderRadius.circular(21),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 14, offset: const Offset(0, 4))],
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          if (_newWhileAway > 0) ...[
                            Text('$_newWhileAway new', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: p.ink)),
                            const SizedBox(width: 4),
                          ],
                          Icon(Icons.keyboard_arrow_down_rounded, color: p.ink),
                        ]),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ]),
        ),
        Composer(
          controller: _c,
          text: _text,
          focus: _focus,
          replyTo: _reply,
          onCancelReply: () => setState(() => _reply = null),
          onSent: () => Future.delayed(const Duration(milliseconds: 40), _toBottom),
        ),
      ]),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.controller});
  final ChatController controller;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final c = controller;
    final other = c.other;
    final typing = c.typingNames;
    String sub;
    if (typing.isNotEmpty) {
      sub = c.isGroup ? '${typing.join(', ')} typing...' : 'typing...';
    } else if (c.isFinn) {
      sub = 'Your AI buddy';
    } else if (c.isGroup) {
      sub = '${c.members.length} members';
    } else if (other?.activeNow ?? false) {
      sub = 'Active now';
    } else {
      sub = other == null ? '' : '@${other.username}';
    }
    final badges = c.isFinn ? const ['ai'] : (other?.badges ?? const <String>[]);
    return Glass(
      child: SizedBox(
        height: 60,
        child: Row(children: [
          const SizedBox(width: 4),
          Tappable(
            scale: 0.85,
            onTap: () => Navigator.of(context).maybePop(),
            child: Padding(padding: const EdgeInsets.all(10), child: Icon(Icons.arrow_back_ios_new_rounded, size: 21, color: p.ink)),
          ),
          Expanded(
            child: Tappable(
              scale: 0.98,
              onTap: c.loading || c.previewMessages != null
                  ? null
                  : () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ChatInfoScreen(controller: c))),
              child: Row(children: [
                Hero(
                  tag: 'avatar-${c.chatId}',
                  child: c.isFinn
                      ? FinnAvatar(size: 38, thinking: typing.isNotEmpty)
                      : c.isGroup
                          ? Avatar(name: c.title, size: 38, group: true)
                          : Avatar(profile: other, size: 38),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                    NameLine(name: c.title, badges: badges, style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w700, color: p.ink)),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 260),
                      transitionBuilder: (ch, a) => FadeTransition(
                        opacity: a,
                        child: SlideTransition(position: Tween(begin: const Offset(0, 0.5), end: Offset.zero).animate(a), child: ch),
                      ),
                      child: Text(sub, key: ValueKey(sub), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.5, color: p.muted)),
                    ),
                  ]),
                ),
              ]),
            ),
          ),
          if (!c.isFinn && !c.loading) ...[
            _HeaderIcon(icon: Icons.call_outlined, onTap: () => CallCenter.instance.start(context, c.chatId, video: false, title: c.title)),
            _HeaderIcon(icon: Icons.videocam_outlined, onTap: () => CallCenter.instance.start(context, c.chatId, video: true, title: c.title)),
          ],
          const SizedBox(width: 6),
        ]),
      ),
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  const _HeaderIcon({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Tappable(
      scale: 0.82,
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Padding(padding: const EdgeInsets.all(9), child: Icon(icon, color: p.ink, size: 24)),
    );
  }
}

class _TypingRow extends StatelessWidget {
  const _TypingRow({super.key, required this.names, required this.ids, required this.group});

  final List<String> names;
  final List<String> ids;
  final bool group;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final isFinn = ids.contains(Inbox.instance.finnId);
    return Reveal(
      duration: const Duration(milliseconds: 420),
      offset: const Offset(0, 14),
      scale: 0.7,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 4, 10, 8),
        child: Row(children: [
          if (group)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: isFinn ? const FinnAvatar(size: 28, thinking: true) : Avatar(profile: Profiles.instance[ids.first], size: 28),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(color: p.soft, borderRadius: BorderRadius.circular(20)),
            child: const _Dots(),
          ),
        ]),
      ),
    );
  }
}

class _Dots extends StatefulWidget {
  const _Dots();

  @override
  State<_Dots> createState() => _DotsState();
}

class _DotsState extends State<_Dots> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) => Row(mainAxisSize: MainAxisSize.min, children: [
        for (var i = 0; i < 3; i++)
          Builder(builder: (context) {
            final t = ((_c.value - i * 0.16) % 1.0);
            final up = math.sin((t.clamp(0.0, 0.5) / 0.5) * math.pi);
            return Transform.translate(
              offset: Offset(0, -4 * up),
              child: Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(color: p.muted.withValues(alpha: 0.5 + 0.5 * up), shape: BoxShape.circle),
              ),
            );
          }),
      ]),
    );
  }
}
