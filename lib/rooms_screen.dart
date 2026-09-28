import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import 'chat_screen.dart';
import 'main.dart';
import 'theme.dart';

class RoomsScreen extends StatefulWidget {
  const RoomsScreen({super.key, required this.profile});

  final Map<String, dynamic> profile;

  @override
  State<RoomsScreen> createState() => _RoomsScreenState();
}

class _RoomsScreenState extends State<RoomsScreen> {
  final _rooms = <Map<String, dynamic>>[];
  final _name = TextEditingController();
  late final RealtimeChannel _channel;

  @override
  void initState() {
    super.initState();
    _load();
    _channel = supabase
        .channel('rooms')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'rooms',
          callback: (payload) {
            final room = payload.newRecord;
            if (_rooms.any((r) => r['id'] == room['id'])) return;
            setState(() => _rooms.insert(0, room));
          },
        )
        .subscribe();
  }

  Future<void> _load() async {
    final data = await supabase.from('rooms').select().order('created_at', ascending: false);
    if (!mounted) return;
    setState(() {
      final ids = _rooms.map((r) => r['id']).toSet();
      _rooms.addAll(data.where((r) => !ids.contains(r['id'])));
    });
  }

  @override
  void dispose() {
    supabase.removeChannel(_channel);
    _name.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    _name.clear();
    final room = {
      'id': const Uuid().v4(),
      'name': name,
      'created_by': widget.profile['id'],
      'created_at': DateTime.now().toUtc().toIso8601String(),
    };
    setState(() => _rooms.insert(0, room));
    _open(room);
    try {
      await supabase.from('rooms').insert({'id': room['id'], 'name': name});
    } catch (_) {
      if (mounted) setState(() => _rooms.removeWhere((r) => r['id'] == room['id']));
    }
  }

  void _open(Map<String, dynamic> room) {
    FocusScope.of(context).unfocus();
    Navigator.of(context).push(CupertinoPageRoute(
      builder: (_) => ChatScreen(room: room, profile: widget.profile),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          SliverPadding(
            padding: EdgeInsets.fromLTRB(16, top + 16, 16, 8),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  const Expanded(
                    child: Text('Chats',
                        style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, letterSpacing: -0.5)),
                  ),
                  Text(widget.profile['username'] ?? '', style: const TextStyle(color: AppColors.muted)),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            sliver: SliverToBoxAdapter(
              child: CupertinoSearchTextField(
                controller: _name,
                placeholder: 'New chat',
                prefixIcon: const Icon(CupertinoIcons.add),
                onSubmitted: (_) => _create(),
                style: const TextStyle(color: AppColors.text),
                backgroundColor: AppColors.panel,
              ),
            ),
          ),
          SliverList.builder(
            itemCount: _rooms.length,
            itemBuilder: (context, i) => _RoomTile(room: _rooms[i], onTap: () => _open(_rooms[i])),
          ),
          SliverToBoxAdapter(child: SizedBox(height: MediaQuery.paddingOf(context).bottom + 16)),
        ],
      ),
    );
  }
}

class _RoomTile extends StatefulWidget {
  const _RoomTile({required this.room, required this.onTap});

  final Map<String, dynamic> room;
  final VoidCallback onTap;

  @override
  State<_RoomTile> createState() => _RoomTileState();
}

class _RoomTileState extends State<_RoomTile> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final name = (widget.room['name'] as String?) ?? '';
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: _down ? AppColors.theirs : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFA1A1A6), Color(0xFF6C6C70)],
                ),
              ),
              child: Text(name.isEmpty ? '' : name[0].toUpperCase(),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500)),
            ),
            const Icon(CupertinoIcons.chevron_right, size: 16, color: AppColors.muted),
          ],
        ),
      ),
    );
  }
}
