import 'dart:typed_data';

import 'data.dart';
import 'i18n.dart';

DateTime? _time(dynamic v) => v == null ? null : DateTime.tryParse(v as String);

class LastMessage {
  const LastMessage({required this.body, required this.kind, required this.senderId, required this.createdAt, required this.deleted});

  factory LastMessage.fromJson(Map<String, dynamic> j) => LastMessage(
        body: (j['body'] as String?) ?? '',
        kind: (j['kind'] as String?) ?? 'text',
        senderId: j['sender_id'] as String?,
        createdAt: _time(j['created_at']) ?? DateTime.now(),
        deleted: (j['deleted'] as bool?) ?? false,
      );

  final String body;
  final String kind;
  final String? senderId;
  final DateTime createdAt;
  final bool deleted;

  String preview({bool group = false, String? senderName}) {
    final mine = senderId == myId;
    final who = mine ? tr('You: ') : (group && senderName != null ? '$senderName: ' : '');
    if (deleted) return mine ? tr('You unsent a message') : tr('Message unsent');
    return switch (kind) {
      'image' => '$who${tr('Photo')}',
      'video' => '$who${tr('Video')}',
      'audio' => '$who${tr('Voice message')}',
      'call' => body.isEmpty ? tr('Call') : callText(body),
      'system' => tr(body),
      _ => '$who$body',
    };
  }
}

class ChatSummary {
  ChatSummary({
    required this.id,
    required this.kind,
    this.name,
    this.avatarPath,
    required this.lastMessageAt,
    this.muted = false,
    this.pinned = false,
    required this.lastReadAt,
    this.other,
    this.memberCount = 2,
    this.last,
    this.unread = 0,
  });

  factory ChatSummary.fromJson(Map<String, dynamic> j) => ChatSummary(
        id: j['id'] as String,
        kind: j['kind'] as String,
        name: j['name'] as String?,
        avatarPath: j['avatar_path'] as String?,
        lastMessageAt: _time(j['last_message_at']) ?? DateTime.now(),
        muted: (j['muted'] as bool?) ?? false,
        pinned: (j['pinned'] as bool?) ?? false,
        lastReadAt: _time(j['last_read_at']) ?? DateTime.now(),
        other: j['other'] is Map ? Profile.fromJson((j['other'] as Map).cast<String, dynamic>()) : null,
        memberCount: (j['member_count'] as num?)?.toInt() ?? 2,
        last: j['last'] is Map ? LastMessage.fromJson((j['last'] as Map).cast<String, dynamic>()) : null,
        unread: (j['unread'] as num?)?.toInt() ?? 0,
      );

  final String id;
  final String kind;
  final String? name;
  final String? avatarPath;
  DateTime lastMessageAt;
  bool muted;
  bool pinned;
  DateTime lastReadAt;
  final Profile? other;
  final int memberCount;
  LastMessage? last;
  int unread;

  bool get isGroup => kind == 'group';
  bool get isFinn => kind == 'finn';
  String get title => isGroup ? (name ?? tr('Group')) : (isFinn ? 'Finn' : other?.displayName ?? tr('Chat'));
  String? get groupAvatarUrl => avatarPath == null ? null : supa.storage.from('avatars').getPublicUrl(avatarPath!);
}

class Message {
  Message({
    required this.id,
    required this.chatId,
    required this.senderId,
    this.kind = 'text',
    this.body = '',
    this.mediaPath,
    this.mediaMeta = const {},
    this.replyTo,
    this.mentions = const [],
    this.editedAt,
    this.deletedAt,
    required this.createdAt,
    this.pending = false,
    this.failed = false,
    this.localBytes,
  });

  factory Message.fromJson(Map<String, dynamic> j) => Message(
        id: j['id'] as String,
        chatId: j['chat_id'] as String,
        senderId: j['sender_id'] as String,
        kind: (j['kind'] as String?) ?? 'text',
        body: (j['body'] as String?) ?? '',
        mediaPath: j['media_path'] as String?,
        mediaMeta: j['media_meta'] is Map ? (j['media_meta'] as Map).cast<String, dynamic>() : const {},
        replyTo: j['reply_to'] as String?,
        mentions: ((j['mentions'] as List?) ?? const []).cast<String>(),
        editedAt: _time(j['edited_at']),
        deletedAt: _time(j['deleted_at']),
        createdAt: _time(j['created_at']) ?? DateTime.now(),
      );

  final String id;
  final String chatId;
  final String senderId;
  final String kind;
  String body;
  final String? mediaPath;
  final Map<String, dynamic> mediaMeta;
  final String? replyTo;
  final List<String> mentions;
  DateTime? editedAt;
  DateTime? deletedAt;
  final DateTime createdAt;
  bool pending;
  bool failed;
  final Uint8List? localBytes;

  bool get mine => senderId == myId;
  bool get deleted => deletedAt != null;
  bool get isSystem => kind == 'system' || kind == 'call';
  bool get viaFinn => mediaMeta['via'] == 'finn';

  Map<String, dynamic> toInsert() => {
        'id': id,
        'chat_id': chatId,
        'sender_id': senderId,
        'kind': kind,
        'body': body,
        'media_path': mediaPath,
        'media_meta': mediaMeta.isEmpty ? null : mediaMeta,
        'reply_to': replyTo,
        'mentions': mentions,
      };

  void absorb(Message m) {
    body = m.body;
    editedAt = m.editedAt;
    deletedAt = m.deletedAt;
    pending = false;
    failed = false;
  }
}

class Reaction {
  const Reaction({required this.messageId, required this.userId, required this.emoji});

  factory Reaction.fromJson(Map<String, dynamic> j) =>
      Reaction(messageId: j['message_id'] as String, userId: j['user_id'] as String, emoji: j['emoji'] as String);

  final String messageId;
  final String userId;
  final String emoji;
}

class Member {
  Member({required this.userId, required this.role, required this.lastReadAt});

  factory Member.fromJson(Map<String, dynamic> j) => Member(
        userId: j['user_id'] as String,
        role: (j['role'] as String?) ?? 'member',
        lastReadAt: _time(j['last_read_at']) ?? DateTime.fromMillisecondsSinceEpoch(0),
      );

  final String userId;
  final String role;
  DateTime lastReadAt;

  bool get canManage => role == 'owner' || role == 'admin';
}

class Announcement {
  const Announcement({required this.id, required this.title, required this.body, required this.createdAt});

  factory Announcement.fromJson(Map<String, dynamic> j) => Announcement(
        id: j['id'] as String,
        title: j['title'] as String,
        body: j['body'] as String,
        createdAt: _time(j['created_at']) ?? DateTime.now(),
      );

  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
}

class CallInfo {
  const CallInfo({required this.id, required this.chatId, required this.startedBy, required this.video, required this.status, required this.createdAt});

  factory CallInfo.fromJson(Map<String, dynamic> j) => CallInfo(
        id: j['id'] as String,
        chatId: j['chat_id'] as String,
        startedBy: j['started_by'] as String,
        video: (j['video'] as bool?) ?? false,
        status: (j['status'] as String?) ?? 'ringing',
        createdAt: _time(j['created_at']) ?? DateTime.now(),
      );

  final String id;
  final String chatId;
  final String startedBy;
  final bool video;
  final String status;
  final DateTime createdAt;
}
