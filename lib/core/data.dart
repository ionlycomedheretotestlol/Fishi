import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

SupabaseClient get supa => Supabase.instance.client;
String? get myId => supa.auth.currentUser?.id;

const emailDomain = 'u.fishi.app';
String emailFor(String username) => '${username.toLowerCase()}@$emailDomain';

enum BubbleShape { classic, soft, pill, square, cloud, fish, outline, bolt }

extension BubbleShapeInfo on BubbleShape {
  String get label => switch (this) {
        BubbleShape.classic => 'Classic',
        BubbleShape.soft => 'Soft',
        BubbleShape.pill => 'Pill',
        BubbleShape.square => 'Block',
        BubbleShape.cloud => 'Cloud',
        BubbleShape.fish => 'Fish',
        BubbleShape.outline => 'Outline',
        BubbleShape.bolt => 'Zap',
      };
}

class BubbleStyle {
  const BubbleStyle({this.shape = BubbleShape.classic, this.color});

  final BubbleShape shape;
  final Color? color;

  factory BubbleStyle.fromJson(dynamic j) {
    if (j is! Map) return const BubbleStyle();
    final shape = BubbleShape.values.where((s) => s.name == j['shape']).firstOrNull ?? BubbleShape.classic;
    final hex = j['color'] as String?;
    return BubbleStyle(shape: shape, color: hex == null ? null : Color(int.parse(hex, radix: 16)));
  }

  Map<String, dynamic> toJson() => {
        'shape': shape.name,
        'color': color?.toARGB32().toRadixString(16).padLeft(8, '0'),
      };

  BubbleStyle copyWith({BubbleShape? shape, Color? color, bool clearColor = false}) =>
      BubbleStyle(shape: shape ?? this.shape, color: clearColor ? null : (color ?? this.color));
}

class Profile {
  Profile({
    required this.id,
    required this.username,
    required this.displayName,
    this.bio = '',
    this.avatarPath,
    this.bubble = const BubbleStyle(),
    this.badges = const [],
    this.isBot = false,
    this.lastSeen,
    this.adultConfirmed = false,
  });

  factory Profile.fromJson(Map<String, dynamic> j) => Profile(
        id: j['id'] as String,
        username: j['username'] as String,
        displayName: j['display_name'] as String,
        bio: (j['bio'] as String?) ?? '',
        avatarPath: j['avatar_path'] as String?,
        bubble: BubbleStyle.fromJson(j['bubble']),
        badges: ((j['badges'] as List?) ?? const []).cast<String>(),
        isBot: (j['is_bot'] as bool?) ?? false,
        lastSeen: j['last_seen'] == null ? null : DateTime.tryParse(j['last_seen'] as String),
        adultConfirmed: j['adult_confirmed_at'] != null,
      );

  final String id;
  final String username;
  final String displayName;
  final String bio;
  final String? avatarPath;
  final BubbleStyle bubble;
  final List<String> badges;
  final bool isBot;
  final DateTime? lastSeen;
  final bool adultConfirmed;

  bool get isFinn => username == 'finn';
  bool get isOfficial => badges.contains('official');
  bool get activeNow => lastSeen != null && DateTime.now().difference(lastSeen!).inMinutes < 3;

  String? get avatarUrl =>
      avatarPath == null ? null : supa.storage.from('avatars').getPublicUrl(avatarPath!);
}

class Profiles extends ChangeNotifier {
  Profiles._();
  static final instance = Profiles._();

  final _map = <String, Profile>{};
  final _loading = <String>{};
  Profile? me;
  bool isAdmin = false;

  Profile? operator [](String id) => _map[id];

  void put(Profile p) {
    _map[p.id] = p;
    if (p.id == myId) me = p;
    notifyListeners();
  }

  Future<void> loadMe() async {
    final id = myId;
    if (id == null) return;
    final row = await supa.from('profiles').select().eq('id', id).maybeSingle();
    if (row != null) put(Profile.fromJson(row));
    try {
      isAdmin = (await supa.rpc('is_admin')) == true;
    } catch (_) {
      isAdmin = false;
    }
    notifyListeners();
  }

  Future<void> ensure(Iterable<String> ids) async {
    final missing = ids.where((id) => !_map.containsKey(id) && !_loading.contains(id)).toSet().toList();
    if (missing.isEmpty) return;
    _loading.addAll(missing);
    try {
      final rows = await supa.from('profiles').select().inFilter('id', missing);
      for (final r in rows) {
        _map[r['id'] as String] = Profile.fromJson(r);
      }
      notifyListeners();
    } finally {
      _loading.removeAll(missing);
    }
  }

  Future<void> refresh(String id) async {
    final row = await supa.from('profiles').select().eq('id', id).maybeSingle();
    if (row != null) put(Profile.fromJson(row));
  }

  void clear() {
    _map.clear();
    me = null;
    isAdmin = false;
  }
}

class MediaUrls {
  static final _cache = <String, (String, DateTime)>{};

  static Future<String?> get(String path) async {
    final hit = _cache[path];
    if (hit != null && hit.$2.isAfter(DateTime.now())) return hit.$1;
    try {
      final url = await supa.storage.from('media').createSignedUrl(path, 3600);
      _cache[path] = (url, DateTime.now().add(const Duration(minutes: 55)));
      return url;
    } catch (_) {
      return null;
    }
  }
}

String timeLabel(DateTime t) {
  final local = t.toLocal();
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(local.year, local.month, local.day);
  final hm = '${local.hour % 12 == 0 ? 12 : local.hour % 12}:${local.minute.toString().padLeft(2, '0')} ${local.hour < 12 ? 'AM' : 'PM'}';
  if (day == today) return hm;
  if (today.difference(day).inDays == 1) return 'Yesterday';
  if (today.difference(day).inDays < 7) {
    return const ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'][local.weekday - 1];
  }
  return '${local.month}/${local.day}/${local.year % 100}';
}

String dayHeader(DateTime t) {
  final local = t.toLocal();
  final label = timeLabel(t);
  final hm = '${local.hour % 12 == 0 ? 12 : local.hour % 12}:${local.minute.toString().padLeft(2, '0')} ${local.hour < 12 ? 'AM' : 'PM'}';
  return label == hm ? 'Today $hm' : '$label $hm';
}
