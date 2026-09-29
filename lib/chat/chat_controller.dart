import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../core/data.dart';
import '../core/inbox.dart';
import '../core/models.dart';
import '../core/i18n.dart';

const _uuid = Uuid();
final _mentionRe = RegExp(r'@([a-z0-9_]{3,20})', caseSensitive: false);

class ChatController extends ChangeNotifier {
  ChatController(this.chatId, {this.previewMessages});

  final String chatId;
  final List<Message>? previewMessages;

  String kind = 'direct';
  String? name;
  String? avatarPath;
  List<Message> messages = [];
  final Map<String, Message> byId = {};
  final Map<String, List<Reaction>> reactions = {};
  final Map<String, Member> members = {};
  final Map<String, DateTime> _typing = {};
  final Set<String> fresh = {};
  bool loading = true;
  bool hasMore = true;
  bool loadingMore = false;
  bool failed = false;
  bool _disposed = false;

  RealtimeChannel? _channel;
  Timer? _typingTick;
  DateTime _lastTypingSent = DateTime.fromMillisecondsSinceEpoch(0);

  bool get isGroup => kind == 'group';
  bool get isFinn => kind == 'finn';

  Profile? get other {
    if (isGroup) return null;
    final id = members.keys.where((id) => id != myId).firstOrNull;
    return id == null ? null : Profiles.instance[id];
  }

  String get title {
    if (isGroup) return name ?? tr('Group');
    if (isFinn) return 'Finn';
    return other?.displayName ?? Inbox.instance.chat(chatId)?.title ?? '';
  }

  Member? get myMember => members[myId];

  Set<String> get mentionable {
    final s = <String>{'finn'};
    for (final id in members.keys) {
      final p = Profiles.instance[id];
      if (p != null) s.add(p.username);
    }
    return s;
  }

  List<Profile> get memberProfiles =>
      members.keys.map((id) => Profiles.instance[id]).whereType<Profile>().toList()..sort((a, b) => a.displayName.compareTo(b.displayName));

  List<String> get typingNames {
    final now = DateTime.now();
    _typing.removeWhere((_, until) => until.isBefore(now));
    return _typing.keys.map((id) => id == Inbox.instance.finnId ? 'Finn' : (Profiles.instance[id]?.displayName.split(' ').first ?? tr('Someone'))).toList();
  }

  List<String> get typingIds => _typing.keys.toList();

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> start() async {
    if (previewMessages != null) {
      _setMessages(previewMessages!);
      loading = false;
      hasMore = false;
      _notify();
      return;
    }
    Inbox.instance.openChatId = chatId;
    try {
      final chat = await supa.from('chats').select().eq('id', chatId).single();
      kind = chat['kind'] as String;
      name = chat['name'] as String?;
      avatarPath = chat['avatar_path'] as String?;
      await _loadMembers();
      final rows = await supa.from('messages').select().eq('chat_id', chatId).order('created_at', ascending: false).limit(60);
      final list = rows.map(Message.fromJson).toList().reversed.toList();
      hasMore = rows.length == 60;
      _setMessages(list);
      await _loadExtras(list);
      loading = false;
      _notify();
      _subscribe();
      markRead();
    } catch (e) {
      loading = false;
      failed = true;
      _notify();
    }
    _typingTick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_typing.isNotEmpty) {
        final before = _typing.length;
        typingNames;
        if (_typing.length != before) _notify();
      }
    });
  }

  Future<void> _loadMembers() async {
    final rows = await supa.from('chat_members').select().eq('chat_id', chatId);
    members
      ..clear()
      ..addEntries(rows.map((r) => MapEntry(r['user_id'] as String, Member.fromJson(r))));
    await Profiles.instance.ensure(members.keys);
  }

  void _setMessages(List<Message> list) {
    messages = list;
    byId
      ..clear()
      ..addEntries(list.map((m) => MapEntry(m.id, m)));
  }

  Future<void> _loadExtras(List<Message> list) async {
    if (list.isEmpty) return;
    final ids = list.map((m) => m.id).toList();
    final senders = list.map((m) => m.senderId).toSet();
    await Profiles.instance.ensure(senders);
    final missing = list.map((m) => m.replyTo).whereType<String>().where((id) => !byId.containsKey(id)).toSet().toList();
    if (missing.isNotEmpty) {
      try {
        final rows = await supa.from('messages').select().inFilter('id', missing);
        for (final r in rows) {
          final m = Message.fromJson(r);
          _replyCache[m.id] = m;
        }
      } catch (_) {}
    }
    try {
      final rows = await supa.from('reactions').select().eq('chat_id', chatId).inFilter('message_id', ids);
      for (final r in rows) {
        final x = Reaction.fromJson(r);
        (reactions[x.messageId] ??= []).removeWhere((y) => y.userId == x.userId);
        reactions[x.messageId]!.add(x);
      }
    } catch (_) {}
  }

  final Map<String, Message> _replyCache = {};

  Message? replyTarget(String? id) => id == null ? null : (byId[id] ?? _replyCache[id]);

  Future<void> loadMore() async {
    if (loadingMore || !hasMore || messages.isEmpty || previewMessages != null) return;
    loadingMore = true;
    _notify();
    try {
      final rows = await supa
          .from('messages')
          .select()
          .eq('chat_id', chatId)
          .lt('created_at', messages.first.createdAt.toUtc().toIso8601String())
          .order('created_at', ascending: false)
          .limit(50);
      final older = rows.map(Message.fromJson).toList().reversed.toList();
      hasMore = rows.length == 50;
      for (final m in older) {
        byId[m.id] = m;
      }
      messages = [...older, ...messages];
      await _loadExtras(older);
    } catch (_) {}
    loadingMore = false;
    _notify();
  }

  void _subscribe() {
    final filter = PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'chat_id', value: chatId);
    _channel = supa.channel('room:$chatId', opts: const RealtimeChannelConfig(self: false))
      ..onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'messages',
        filter: filter,
        callback: (p) => _incoming(Message.fromJson(p.newRecord)),
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'messages',
        filter: filter,
        callback: (p) {
          final m = Message.fromJson(p.newRecord);
          final have = byId[m.id];
          if (have != null) {
            have.absorb(m);
            _notify();
          }
        },
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'reactions',
        filter: filter,
        callback: (p) => _putReaction(Reaction.fromJson(p.newRecord)),
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'reactions',
        filter: filter,
        callback: (p) => _putReaction(Reaction.fromJson(p.newRecord)),
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.delete,
        schema: 'public',
        table: 'reactions',
        callback: (p) {
          final mid = p.oldRecord['message_id'] as String?;
          final uid = p.oldRecord['user_id'] as String?;
          if (mid == null || uid == null || !reactions.containsKey(mid)) return;
          reactions[mid]!.removeWhere((r) => r.userId == uid);
          _notify();
        },
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'chat_members',
        filter: filter,
        callback: (p) {
          final uid = p.newRecord['user_id'] as String?;
          final m = uid == null ? null : members[uid];
          if (m == null) return;
          m.lastReadAt = DateTime.tryParse(p.newRecord['last_read_at'] as String? ?? '') ?? m.lastReadAt;
          _notify();
        },
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'chat_members',
        filter: filter,
        callback: (_) => _loadMembers().then((_) => _notify()),
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'chats',
        filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'id', value: chatId),
        callback: (p) {
          name = p.newRecord['name'] as String? ?? name;
          avatarPath = p.newRecord['avatar_path'] as String?;
          _notify();
        },
      )
      ..onBroadcast(
        event: 'typing',
        callback: (payload) {
          final data = payload['payload'] is Map ? (payload['payload'] as Map) : payload;
          final id = data['id'] as String?;
          if (id == null || id == myId) return;
          final stop = data['stop'] == true;
          if (stop) {
            _typing.remove(id);
          } else {
            _typing[id] = DateTime.now().add(Duration(seconds: id == Inbox.instance.finnId ? 5 : 4));
          }
          _notify();
        },
      )
      ..subscribe();
  }

  void _incoming(Message m) {
    final have = byId[m.id];
    if (have != null) {
      have.absorb(m);
      _notify();
      return;
    }
    Profiles.instance.ensure([m.senderId]);
    _typing.remove(m.senderId);
    byId[m.id] = m;
    fresh.add(m.id);
    messages = [...messages, m]..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    if (m.replyTo != null && replyTarget(m.replyTo) == null) {
      supa.from('messages').select().eq('id', m.replyTo!).maybeSingle().then((r) {
        if (r != null) {
          _replyCache[m.replyTo!] = Message.fromJson(r);
          _notify();
        }
      }, onError: (_) {});
    }
    _notify();
    markRead();
  }

  void _putReaction(Reaction r) {
    final list = reactions[r.messageId] ??= [];
    list.removeWhere((x) => x.userId == r.userId);
    list.add(r);
    _notify();
  }

  void markRead() {
    if (previewMessages != null) return;
    Inbox.instance.markRead(chatId);
    final me = myMember;
    if (me != null) me.lastReadAt = DateTime.now();
  }

  void typingPing({bool stop = false}) {
    final ch = _channel;
    if (ch == null) return;
    final now = DateTime.now();
    if (!stop && now.difference(_lastTypingSent).inMilliseconds < 2200) return;
    _lastTypingSent = stop ? DateTime.fromMillisecondsSinceEpoch(0) : now;
    ch.sendBroadcastMessage(event: 'typing', payload: {'id': myId, 'stop': stop});
  }

  List<String> _mentionIds(String body) {
    final names = _mentionRe.allMatches(body).map((m) => m.group(1)!.toLowerCase()).toSet();
    final ids = <String>[];
    for (final id in members.keys) {
      final p = Profiles.instance[id];
      if (p != null && names.contains(p.username)) ids.add(id);
    }
    final finn = Inbox.instance.finnId;
    if (finn != null && names.contains('finn') && !ids.contains(finn)) ids.add(finn);
    return ids;
  }

  bool _callsFinn(Message m) {
    if (isFinn) return true;
    final finn = Inbox.instance.finnId;
    return (finn != null && m.mentions.contains(finn)) || RegExp(r'(^|\W)@finn\b', caseSensitive: false).hasMatch(m.body);
  }

  Future<void> _insert(Message m) async {
    try {
      await supa.from('messages').insert(m.toInsert());
      m.pending = false;
      m.failed = false;
      _notify();
      if (_callsFinn(m)) {
        supa.functions.invoke('finn', body: {'message_id': m.id}).then((_) {}, onError: (_) {});
      }
    } catch (_) {
      m.pending = false;
      m.failed = true;
      _notify();
    }
  }

  void _addLocal(Message m) {
    byId[m.id] = m;
    fresh.add(m.id);
    messages = [...messages, m];
    _notify();
  }

  Future<void> sendText(String text, {String? replyTo}) async {
    final body = text.trim();
    if (body.isEmpty || myId == null) return;
    typingPing(stop: true);
    final m = Message(
      id: _uuid.v4(),
      chatId: chatId,
      senderId: myId!,
      body: body,
      replyTo: replyTo,
      mentions: _mentionIds(body),
      createdAt: DateTime.now(),
      pending: true,
    );
    _addLocal(m);
    await _insert(m);
  }

  Future<void> sendMedia({
    required String kind,
    required Uint8List bytes,
    required String ext,
    required String contentType,
    Map<String, dynamic> meta = const {},
    String caption = '',
    String? replyTo,
  }) async {
    if (myId == null) return;
    final id = _uuid.v4();
    final path = '$chatId/$id.$ext';
    final m = Message(
      id: id,
      chatId: chatId,
      senderId: myId!,
      kind: kind,
      body: caption,
      mediaPath: path,
      mediaMeta: meta,
      replyTo: replyTo,
      mentions: _mentionIds(caption),
      createdAt: DateTime.now(),
      pending: true,
      localBytes: bytes,
    );
    _addLocal(m);
    try {
      await supa.storage.from('media').uploadBinary(path, bytes, fileOptions: FileOptions(contentType: contentType, upsert: true));
    } catch (_) {
      m.pending = false;
      m.failed = true;
      _notify();
      return;
    }
    await _insert(m);
  }

  Future<void> retry(Message m) async {
    m.failed = false;
    m.pending = true;
    _notify();
    if (m.mediaPath != null && m.localBytes != null) {
      try {
        await supa.storage.from('media').uploadBinary(m.mediaPath!, m.localBytes!, fileOptions: const FileOptions(upsert: true));
      } catch (_) {
        m.pending = false;
        m.failed = true;
        _notify();
        return;
      }
    }
    await _insert(m);
  }

  void discard(Message m) {
    messages = messages.where((x) => x.id != m.id).toList();
    byId.remove(m.id);
    _notify();
  }

  Future<void> react(Message m, String emoji) async {
    final me = myId;
    if (me == null) return;
    final list = reactions[m.id] ??= [];
    final mine = list.where((r) => r.userId == me).firstOrNull;
    list.removeWhere((r) => r.userId == me);
    if (mine?.emoji == emoji) {
      _notify();
      try {
        await supa.from('reactions').delete().eq('message_id', m.id).eq('user_id', me);
      } catch (_) {}
      return;
    }
    list.add(Reaction(messageId: m.id, userId: me, emoji: emoji));
    _notify();
    try {
      await supa.from('reactions').upsert({'message_id': m.id, 'user_id': me, 'chat_id': chatId, 'emoji': emoji});
    } catch (_) {}
  }

  Future<bool> unsend(Message m) async {
    final before = (m.body, m.deletedAt);
    m.deletedAt = DateTime.now();
    m.body = '';
    _notify();
    try {
      await supa.from('messages').update({'deleted_at': DateTime.now().toUtc().toIso8601String(), 'body': ''}).eq('id', m.id);
      return true;
    } catch (_) {
      m.body = before.$1;
      m.deletedAt = before.$2;
      _notify();
      return false;
    }
  }

  List<Profile> readersOf(Message m) {
    final out = <Profile>[];
    for (final e in members.entries) {
      if (e.key == myId || e.key == Inbox.instance.finnId) continue;
      if (!e.value.lastReadAt.isBefore(m.createdAt)) {
        final p = Profiles.instance[e.key];
        if (p != null) out.add(p);
      }
    }
    return out;
  }

  @override
  void dispose() {
    _disposed = true;
    if (Inbox.instance.openChatId == chatId) Inbox.instance.openChatId = null;
    _typingTick?.cancel();
    final ch = _channel;
    if (ch != null) {
      typingPing(stop: true);
      supa.removeChannel(ch);
    }
    super.dispose();
  }
}
