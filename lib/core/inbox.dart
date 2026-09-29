import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'data.dart';
import 'models.dart';
import 'notify.dart';
import 'prefs.dart';
import 'i18n.dart';

final navigatorKey = GlobalKey<NavigatorState>();

class Inbox extends ChangeNotifier {
  Inbox._();
  static final instance = Inbox._();

  List<ChatSummary> chats = [];
  List<Announcement> announcements = [];
  bool loaded = false;
  String? openChatId;
  String? finnId;

  RealtimeChannel? _channel;
  Timer? _refreshSoon;
  Timer? _heartbeat;
  bool _started = false;

  final _messages = StreamController<Message>.broadcast();
  final _calls = StreamController<CallInfo>.broadcast();
  Stream<Message> get messages => _messages.stream;
  Stream<CallInfo> get calls => _calls.stream;

  ChatSummary? chat(String id) => chats.where((c) => c.id == id).firstOrNull;

  int get unseenAnnouncements {
    final seen = Prefs.instance.announcementsSeen;
    return announcements.where((a) => a.createdAt.isAfter(seen)).length;
  }

  Future<void> start() async {
    if (_started) return;
    _started = true;
    await Profiles.instance.loadMe();
    try {
      finnId = await supa.rpc('finn_id') as String?;
    } catch (_) {}
    await refresh();
    await loadAnnouncements();
    _subscribe();
    touchSeen();
    _heartbeat = Timer.periodic(const Duration(seconds: 60), (_) => touchSeen());
  }

  Future<void> stop() async {
    _started = false;
    _heartbeat?.cancel();
    _refreshSoon?.cancel();
    final ch = _channel;
    _channel = null;
    if (ch != null) await supa.removeChannel(ch);
    chats = [];
    announcements = [];
    loaded = false;
    Profiles.instance.clear();
    notifyListeners();
  }

  void touchSeen() {
    if (myId == null || !Notify.foreground) return;
    supa.from('profiles').update({'last_seen': DateTime.now().toUtc().toIso8601String()}).eq('id', myId!).then((_) {}, onError: (_) {});
  }

  Future<void> refresh() async {
    try {
      final rows = (await supa.rpc('my_chats')) as List? ?? const [];
      var list = rows.map((r) => ChatSummary.fromJson((r as Map).cast<String, dynamic>())).toList();
      if (!list.any((c) => c.isFinn)) {
        try {
          await supa.rpc('open_finn');
          final again = (await supa.rpc('my_chats')) as List? ?? const [];
          list = again.map((r) => ChatSummary.fromJson((r as Map).cast<String, dynamic>())).toList();
        } catch (_) {}
      }
      chats = list;
      loaded = true;
      for (final c in chats) {
        final o = c.other;
        if (o != null) Profiles.instance.put(o);
      }
      notifyListeners();
    } catch (_) {
      loaded = true;
      notifyListeners();
    }
  }

  Future<void> loadAnnouncements() async {
    try {
      final rows = await supa.from('announcements').select().order('created_at', ascending: false).limit(50);
      announcements = rows.map(Announcement.fromJson).toList();
      notifyListeners();
    } catch (_) {}
  }

  void _scheduleRefresh() {
    _refreshSoon?.cancel();
    _refreshSoon = Timer(const Duration(milliseconds: 600), refresh);
  }

  void _subscribe() {
    final me = myId;
    if (me == null) return;
    _channel = supa.channel('inbox:$me')
      ..onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'messages',
        callback: (p) => _onMessage(Message.fromJson(p.newRecord)),
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'messages',
        callback: (p) {
          final m = Message.fromJson(p.newRecord);
          final c = chat(m.chatId);
          if (c != null && c.last != null && c.last!.createdAt.isAtSameMomentAs(m.createdAt)) _scheduleRefresh();
        },
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'chat_members',
        filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'user_id', value: me),
        callback: (_) => _scheduleRefresh(),
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'announcements',
        callback: (p) {
          final a = Announcement.fromJson(p.newRecord);
          announcements = [a, ...announcements.where((x) => x.id != a.id)];
          notifyListeners();
          Notify.message(chatId: 'announcements', title: 'Fishi', body: a.title);
        },
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.delete,
        schema: 'public',
        table: 'announcements',
        callback: (_) => loadAnnouncements(),
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'calls',
        callback: (p) {
          if (p.newRecord.isEmpty) return;
          _calls.add(CallInfo.fromJson(p.newRecord));
        },
      )
      ..subscribe((status, _) {
        if (status == RealtimeSubscribeStatus.subscribed && loaded) _scheduleRefresh();
      });
  }

  void _onMessage(Message m) {
    _messages.add(m);
    final c = chat(m.chatId);
    if (c == null) {
      _scheduleRefresh();
      return;
    }
    c.last = LastMessage(body: m.body, kind: m.kind, senderId: m.senderId, createdAt: m.createdAt, deleted: false);
    c.lastMessageAt = m.createdAt;
    final open = openChatId == m.chatId && Notify.foreground;
    if (!m.mine && !open) c.unread += 1;
    chats.sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));
    notifyListeners();
    if (!m.mine && !open && !c.muted && m.kind != 'system') _notify(c, m);
  }

  Future<void> _notify(ChatSummary c, Message m) async {
    await Profiles.instance.ensure([m.senderId]);
    final sender = Profiles.instance[m.senderId];
    final name = sender?.displayName ?? tr('Someone');
    final mentioned = m.mentions.contains(myId);
    final body = LastMessage(body: m.body, kind: m.kind, senderId: m.senderId, createdAt: m.createdAt, deleted: false).preview();
    await Notify.message(
      chatId: c.id,
      title: c.isGroup ? '${mentioned ? '@ ' : ''}${tr('{name} in {group}', {'name': name, 'group': c.title})}' : name,
      body: body,
    );
  }

  void markRead(String chatId) {
    final c = chat(chatId);
    if (c != null && c.unread > 0) {
      c.unread = 0;
      notifyListeners();
    }
    Notify.cancelChat(chatId);
    final me = myId;
    if (me == null) return;
    supa
        .from('chat_members')
        .update({'last_read_at': DateTime.now().toUtc().toIso8601String()})
        .eq('chat_id', chatId)
        .eq('user_id', me)
        .then((_) {}, onError: (_) {});
  }

  Future<void> setPinned(ChatSummary c, bool v) async {
    c.pinned = v;
    notifyListeners();
    await supa.from('chat_members').update({'pinned': v}).eq('chat_id', c.id).eq('user_id', myId!);
  }

  Future<void> setMuted(ChatSummary c, bool v) async {
    c.muted = v;
    notifyListeners();
    await supa.from('chat_members').update({'muted': v}).eq('chat_id', c.id).eq('user_id', myId!);
  }
}
