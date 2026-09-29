import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import 'brand/send_bubble.dart';
import 'main.dart';
import 'theme.dart';

const _page = 100;
const _groupGap = Duration(minutes: 2);

class Message {
  Message({
    required this.id,
    required this.userId,
    required this.body,
    required this.createdAt,
    this.pending = false,
    this.failed = false,
    this.fresh = false,
  });

  factory Message.fromRow(Map<String, dynamic> r, {bool fresh = false}) => Message(
        id: r['id'] as String,
        userId: r['user_id'] as String,
        body: r['body'] as String,
        createdAt: DateTime.parse(r['created_at'] as String),
        fresh: fresh,
      );

  final String id;
  final String userId;
  final String body;
  DateTime createdAt;
  bool pending;
  bool failed;
  final bool fresh;
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.room, required this.profile});

  final Map<String, dynamic> room;
  final Map<String, dynamic> profile;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messages = <Message>[];
  final _names = <String, String>{};
  final _typing = <String, (String, DateTime)>{};
  final _text = TextEditingController();
  final _focus = FocusNode();
  late final RealtimeChannel _channel;
  Timer? _sweep;
  DateTime _lastTypingSent = DateTime.fromMillisecondsSinceEpoch(0);
  bool _loaded = false;

  String get _me => widget.profile['id'] as String;
  String get _roomId => widget.room['id'] as String;

  @override
  void initState() {
    super.initState();
    _names[_me] = widget.profile['username'] as String;
    _text.addListener(() => setState(() {}));
    _load();

    _channel = supabase
        .channel('room:$_roomId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'room_id', value: _roomId),
          callback: (payload) {
            final m = Message.fromRow(payload.newRecord, fresh: true);
            setState(() {
              _merge([m]);
              _typing.remove(m.userId);
            });
            _loadNames([m.userId]);
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: 'messages',
          callback: (payload) =>
              setState(() => _messages.removeWhere((m) => m.id == payload.oldRecord['id'])),
        )
        .onBroadcast(
          event: 'typing',
          callback: (payload) {
            final id = payload['id'] as String?;
            if (id == null || id == _me) return;
            setState(() => _typing[id] = (payload['name'] as String? ?? '', DateTime.now()));
          },
        )
        .subscribe();

    _sweep = Timer.periodic(const Duration(seconds: 1), (_) {
      final now = DateTime.now();
      final before = _typing.length;
      _typing.removeWhere((_, v) => now.difference(v.$2) > const Duration(seconds: 3));
      if (_typing.length != before) setState(() {});
    });
  }

  @override
  void dispose() {
    _sweep?.cancel();
    supabase.removeChannel(_channel);
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final rows = await supabase
          .from('messages')
          .select()
          .eq('room_id', _roomId)
          .order('created_at', ascending: false)
          .limit(_page);
      final list = rows.map(Message.fromRow).toList();
      if (!mounted) return;
      setState(() => _merge(list));
      _loadNames(list.map((m) => m.userId).toSet());
    } finally {
      if (mounted) setState(() => _loaded = true);
    }
  }

  Future<void> _loadNames(Iterable<String> ids) async {
    final missing = ids.where((id) => !_names.containsKey(id)).toList();
    if (missing.isEmpty) return;
    final rows = await supabase.from('profiles').select('id, username').inFilter('id', missing);
    if (!mounted) return;
    setState(() {
      for (final r in rows) {
        _names[r['id'] as String] = r['username'] as String;
      }
    });
  }

  void _merge(List<Message> incoming) {
    for (final m in incoming) {
      final i = _messages.indexWhere((x) => x.id == m.id);
      if (i == -1) {
        _messages.add(m);
      } else {
        _messages[i]
          ..createdAt = m.createdAt
          ..pending = false
          ..failed = false;
      }
    }
    _messages.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  void _onChanged(String value) {
    final now = DateTime.now();
    if (value.isNotEmpty && now.difference(_lastTypingSent) > const Duration(milliseconds: 1500)) {
      _lastTypingSent = now;
      _channel.sendBroadcastMessage(
        event: 'typing',
        payload: {'id': _me, 'name': widget.profile['username']},
      );
    }
  }

  Future<void> _send() async {
    final body = _text.text.trim();
    if (body.isEmpty) return;
    HapticFeedback.lightImpact();
    final msg = Message(
      id: const Uuid().v4(),
      userId: _me,
      body: body,
      createdAt: DateTime.now().toUtc(),
      pending: true,
      fresh: true,
    );
    _text.clear();
    _lastTypingSent = DateTime.fromMillisecondsSinceEpoch(0);
    setState(() => _messages.insert(0, msg));

    bool failed = false;
    try {
      await supabase.from('messages').insert({'id': msg.id, 'room_id': _roomId, 'body': body});
    } catch (_) {
      failed = true;
    }
    if (!mounted) return;
    setState(() {
      msg.pending = false;
      msg.failed = failed;
    });
  }

  void _retry(Message m) {
    setState(() => _messages.remove(m));
    _text.text = m.body;
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final typers = _typing.values.map((v) => v.$1).toList();
    final canSend = _text.text.trim().isNotEmpty;

    return Scaffold(
      body: Column(
        children: [
          GlassBar(
            child: SizedBox(
              height: 52,
              child: Row(
                children: [
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    onPressed: () => Navigator.of(context).maybePop(),
                    child: const Icon(CupertinoIcons.back, color: AppColors.mine, size: 28),
                  ),
                  Expanded(
                    child: Text(
                      widget.room['name'] as String? ?? '',
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 44),
                ],
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: _loaded && _messages.isEmpty && typers.isEmpty
                  ? const Center(child: Text('Say hi', style: TextStyle(color: AppColors.muted)))
                  : ListView.builder(
                      reverse: true,
                      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                      itemCount: _messages.length + 1,
                      itemBuilder: (context, i) {
                        if (i == 0) return _TypingIndicator(names: typers);
                        final idx = i - 1;
                        final m = _messages[idx];
                        final newer = idx > 0 ? _messages[idx - 1] : null;
                        final older = idx + 1 < _messages.length ? _messages[idx + 1] : null;
                        final mine = m.userId == _me;
                        final first = older == null || older.userId != m.userId || _gap(older, m);
                        final last = newer == null || newer.userId != m.userId || _gap(m, newer);
                        return _Bubble(
                          key: ValueKey(m.id),
                          message: m,
                          mine: mine,
                          sender: !mine && first ? _names[m.userId] : null,
                          tail: last,
                          onRetry: () => _retry(m),
                        );
                      },
                    ),
            ),
          ),
          GlassBar(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: CupertinoTextField(
                      controller: _text,
                      focusNode: _focus,
                      placeholder: 'Message',
                      minLines: 1,
                      maxLines: 6,
                      maxLength: 4000,
                      keyboardType: TextInputType.multiline,
                      textCapitalization: TextCapitalization.sentences,
                      onChanged: _onChanged,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      style: const TextStyle(color: AppColors.text, fontSize: 16),
                      placeholderStyle: const TextStyle(color: AppColors.muted, fontSize: 16),
                      decoration: BoxDecoration(
                        color: AppColors.bg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.line),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SendBubbleButton(enabled: canSend, onTap: _send, size: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

bool _gap(Message a, Message b) => b.createdAt.difference(a.createdAt).abs() > _groupGap;

class _Bubble extends StatelessWidget {
  const _Bubble({
    super.key,
    required this.message,
    required this.mine,
    required this.sender,
    required this.tail,
    required this.onRetry,
  });

  final Message message;
  final bool mine;
  final String? sender;
  final bool tail;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    const r = Radius.circular(18);
    const small = Radius.circular(6);
    final color = message.failed ? AppColors.danger : (mine ? AppColors.mine : AppColors.theirs);

    final content = Padding(
      padding: EdgeInsets.only(top: 2, bottom: tail ? 8 : 0),
      child: Column(
        crossAxisAlignment: mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (sender != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 2),
              child: Text(sender!, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
            ),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.75),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: message.pending ? 0.7 : 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.only(
                    topLeft: r,
                    topRight: r,
                    bottomLeft: !mine && tail ? small : r,
                    bottomRight: mine && tail ? small : r,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
                  child: Text(
                    message.body,
                    style: TextStyle(fontSize: 16, height: 1.3, color: mine ? AppColors.bg : AppColors.text),
                  ),
                ),
              ),
            ),
          ),
          if (message.failed)
            GestureDetector(
              onTap: onRetry,
              child: const Padding(
                padding: EdgeInsets.only(top: 3),
                child: Text('Not sent. Tap to edit', style: TextStyle(fontSize: 12, color: AppColors.danger)),
              ),
            ),
        ],
      ),
    );

    final aligned = Align(alignment: mine ? Alignment.centerRight : Alignment.centerLeft, child: content);
    if (!message.fresh) return RepaintBoundary(child: aligned);

    return RepaintBoundary(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOutBack,
        child: aligned,
        builder: (context, t, child) => Opacity(
          opacity: t.clamp(0, 1),
          child: Transform.translate(
            offset: Offset(0, (1 - t) * 14),
            child: Transform.scale(
              scale: 0.9 + 0.1 * t,
              alignment: mine ? Alignment.bottomRight : Alignment.bottomLeft,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator({required this.names});

  final List<String> names;

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));

  @override
  void didUpdateWidget(covariant _TypingIndicator old) {
    super.didUpdateWidget(old);
    _sync();
  }

  @override
  void initState() {
    super.initState();
    _sync();
  }

  void _sync() {
    if (widget.names.isNotEmpty && !_c.isAnimating) {
      _c.repeat();
    } else if (widget.names.isEmpty && _c.isAnimating) {
      _c.stop();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final show = widget.names.isNotEmpty;
    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      alignment: Alignment.bottomLeft,
      child: !show
          ? const SizedBox(width: double.infinity)
          : Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 4),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.theirs,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: AnimatedBuilder(
                      animation: _c,
                      builder: (context, _) => Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(3, (i) {
                          final phase = (_c.value - i * 0.15) % 1;
                          final wave = math.max(0.0, math.sin(phase * math.pi * 2.5));
                          return Container(
                            margin: EdgeInsets.only(left: i == 0 ? 0 : 4),
                            width: 7,
                            height: 7,
                            transform: Matrix4.translationValues(0, -3 * wave, 0),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.muted.withValues(alpha: 0.35 + 0.65 * wave),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(widget.names.join(', '),
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                  ),
                ],
              ),
            ),
    );
  }
}
