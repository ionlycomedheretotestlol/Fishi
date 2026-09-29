import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../brand/avatar.dart';
import '../brand/badges.dart';
import '../brand/fish_logo.dart';
import '../calls/call_center.dart';
import '../chat/chat_screen.dart';
import '../core/data.dart';
import '../core/inbox.dart';
import '../core/models.dart';
import '../core/motion.dart';
import '../core/notify.dart';
import '../core/prefs.dart';
import '../core/theme.dart';
import '../emoji/emoji_text.dart';
import '../settings/settings_screen.dart';
import '../ui/kit.dart';
import 'announcements_screen.dart';
import 'new_chat.dart';
import '../core/i18n.dart';

void openChat(BuildContext context, String chatId) {
  Navigator.of(context).push(MaterialPageRoute(builder: (_) => ChatScreen(chatId: chatId)));
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.preview});

  final List<ChatSummary>? preview;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _search = TextEditingController();
  StreamSubscription<String>? _taps;
  String _q = '';

  bool get _preview => widget.preview != null;

  @override
  void initState() {
    super.initState();
    if (!_preview) {
      Inbox.instance.addListener(_changed);
      Profiles.instance.addListener(_changed);
      _taps = Notify.taps.stream.listen(_onTap);
    }
  }

  void _onTap(String payload) {
    if (!mounted) return;
    if (payload.startsWith('chat:')) {
      final id = payload.substring(5);
      if (id == 'announcements') {
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AnnouncementsScreen()));
      } else if (Inbox.instance.openChatId != id) {
        openChat(context, id);
      }
    } else if (payload.startsWith('call:')) {
      CallCenter.instance.showIncomingById(payload.substring(5));
    }
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    Inbox.instance.removeListener(_changed);
    Profiles.instance.removeListener(_changed);
    _taps?.cancel();
    _search.dispose();
    super.dispose();
  }

  List<ChatSummary> get _all => widget.preview ?? Inbox.instance.chats;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final all = _all;
    final finn = all.where((c) => c.isFinn).firstOrNull;
    var rest = all.where((c) => !c.isFinn).toList()
      ..sort((a, b) {
        if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
        return b.lastMessageAt.compareTo(a.lastMessageAt);
      });
    final q = _q.trim().toLowerCase();
    if (q.isNotEmpty) {
      rest = rest.where((c) => c.title.toLowerCase().contains(q) || (c.other?.username.contains(q) ?? false)).toList();
    }
    final me = Profiles.instance.me;
    final loaded = _preview || Inbox.instance.loaded;
    final announcements = _preview ? const <Announcement>[] : Inbox.instance.announcements;
    final unseen = _preview ? 1 : Inbox.instance.unseenAnnouncements;

    return Scaffold(
      body: LargeTitleScroll(
        title: tr('Chats'),
        onRefresh: _preview ? null : Inbox.instance.refresh,
        leading: Tappable(
          scale: 0.88,
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
          child: Padding(padding: const EdgeInsets.all(6), child: Avatar(profile: me, size: 34)),
        ),
        actions: [
          CircleIcon(
            icon: Icons.edit_outlined,
            onTap: () => Navigator.of(context).push(sheetRoute(const NewChatSheet())),
          ),
        ],
        below: Padding(
          padding: const EdgeInsets.fromLTRB(16, 2, 16, 10),
          child: Reveal(
            delay: const Duration(milliseconds: 80),
            child: _SearchBar(controller: _search, onChanged: (v) => setState(() => _q = v)),
          ),
        ),
        slivers: [
          if (q.isEmpty) ...[
            if (finn != null)
              SliverToBoxAdapter(
                child: Reveal(
                  delay: const Duration(milliseconds: 120),
                  child: _ChatRow(chat: finn, onTap: () => openChat(context, finn.id), pinnedFinn: true),
                ),
              ),
            SliverToBoxAdapter(
              child: Reveal(
                delay: const Duration(milliseconds: 170),
                child: _FishiRow(
                  latest: announcements.firstOrNull,
                  unseen: unseen,
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AnnouncementsScreen())),
                ),
              ),
            ),
            SliverToBoxAdapter(child: Divider(height: 14, thickness: 6, color: p.soft.withValues(alpha: 0.6))),
          ],
          if (!loaded)
            const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(40), child: Center(child: Spinner())))
          else if (rest.isEmpty)
            SliverToBoxAdapter(
              child: EmptyState(
                icon: FishLogo(size: 64, color: p.muted, eyeColor: p.paper),
                title: q.isEmpty ? tr('No chats yet') : tr('No matches'),
                body: q.isEmpty ? tr('Tap the pencil to message someone by their username, or start a group.') : tr('Try another name.'),
              ),
            )
          else
            SliverList.builder(
              itemCount: rest.length,
              itemBuilder: (context, i) {
                final c = rest[i];
                return Reveal(
                  key: ValueKey(c.id),
                  delay: Duration(milliseconds: 200 + (i * 45).clamp(0, 400)),
                  child: _ChatRow(
                    chat: c,
                    onTap: () => openChat(context, c.id),
                    onLongPress: _preview ? null : () => _options(c),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  void _options(ChatSummary c) {
    HapticFeedback.mediumImpact();
    Navigator.of(context).push(sheetRoute(BottomSheetFrame(
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(c.title, textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Palette.of(context).ink)),
        const SizedBox(height: 16),
        Section(children: [
          RowTile(
            icon: c.pinned ? Icons.push_pin : Icons.push_pin_outlined,
            title: c.pinned ? tr('Unpin') : tr('Pin to top'),
            chevron: false,
            onTap: () {
              Navigator.of(context).pop();
              Inbox.instance.setPinned(c, !c.pinned);
            },
          ),
          RowTile(
            icon: c.muted ? Icons.notifications_active_outlined : Icons.notifications_off_outlined,
            title: c.muted ? tr('Unmute') : tr('Mute'),
            chevron: false,
            onTap: () {
              Navigator.of(context).pop();
              Inbox.instance.setMuted(c, !c.muted);
            },
          ),
        ]),
      ]),
    )));
  }
}

class _SearchBar extends StatefulWidget {
  const _SearchBar({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  State<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<_SearchBar> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final active = _focus.hasFocus || widget.controller.text.isNotEmpty;
    return Row(children: [
      Expanded(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: kSmooth,
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(color: p.soft, borderRadius: BorderRadius.circular(14)),
          child: Row(children: [
            Icon(Icons.search_rounded, size: 20, color: p.muted),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: widget.controller,
                focusNode: _focus,
                onChanged: widget.onChanged,
                style: TextStyle(fontSize: 16, color: p.ink),
                decoration: InputDecoration(
                  isCollapsed: true,
                  border: InputBorder.none,
                  hintText: tr('Search'),
                  hintStyle: TextStyle(color: p.muted, fontSize: 16),
                ),
              ),
            ),
          ]),
        ),
      ),
      AnimatedSize(
        duration: const Duration(milliseconds: 320),
        curve: kSmooth,
        child: active
            ? GestureDetector(
                onTap: () {
                  widget.controller.clear();
                  widget.onChanged('');
                  _focus.unfocus();
                },
                child: Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Text(tr('Cancel'), style: TextStyle(color: p.ink, fontSize: 16)),
                ),
              )
            : const SizedBox.shrink(),
      ),
    ]);
  }
}

class _ChatRow extends StatelessWidget {
  const _ChatRow({required this.chat, required this.onTap, this.onLongPress, this.pinnedFinn = false});

  final ChatSummary chat;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool pinnedFinn;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final other = chat.other;
    final senderName = chat.last?.senderId == null ? null : Profiles.instance[chat.last!.senderId!]?.displayName.split(' ').first;
    final preview = chat.last?.preview(group: chat.isGroup, senderName: senderName) ??
        (chat.isFinn ? tr('Ask me anything. Reply to a photo and ask about it.') : tr('Say hi'));
    final unread = chat.unread > 0;
    final badges = chat.isFinn ? const ['ai'] : (other?.badges ?? const <String>[]);
    return Tappable(
      scale: 0.985,
      onTap: onTap,
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 9, 16, 9),
        child: Row(children: [
          Stack(clipBehavior: Clip.none, children: [
            chat.isGroup
                ? _GroupAvatar(chat: chat)
                : chat.isFinn
                    ? const FinnAvatar(size: 54)
                    : Avatar(profile: other, size: 54),
            if (other != null && other.activeNow && !chat.isFinn)
              Positioned(
                right: 1,
                bottom: 1,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(color: p.ink, shape: BoxShape.circle, border: Border.all(color: p.paper, width: 2.5)),
                ),
              ),
          ]),
          const SizedBox(width: 13),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                  child: NameLine(
                    name: chat.title,
                    badges: badges,
                    style: TextStyle(fontSize: 16.5, fontWeight: unread ? FontWeight.w800 : FontWeight.w600, color: p.ink),
                  ),
                ),
                if (pinnedFinn || chat.pinned)
                  Padding(padding: const EdgeInsets.only(left: 6), child: Icon(Icons.push_pin, size: 13, color: p.muted)),
                if (chat.muted) Padding(padding: const EdgeInsets.only(left: 6), child: Icon(Icons.notifications_off, size: 13, color: p.muted)),
                const SizedBox(width: 6),
                if (chat.last != null)
                  Text(timeLabel(chat.last!.createdAt), style: TextStyle(fontSize: 13, color: unread ? p.ink : p.muted)),
              ]),
              const SizedBox(height: 3),
              Row(children: [
                Expanded(
                  child: EmojiText(
                    preview,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 14.5, height: 1.3, color: unread ? p.ink : p.muted, fontWeight: unread ? FontWeight.w500 : FontWeight.w400),
                  ),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 380),
                  switchInCurve: kSpring,
                  transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
                  child: unread
                      ? Container(
                          key: ValueKey(chat.unread),
                          margin: const EdgeInsets.only(left: 8),
                          constraints: const BoxConstraints(minWidth: 22),
                          height: 22,
                          padding: const EdgeInsets.symmetric(horizontal: 7),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(color: chat.muted ? p.muted : p.ink, borderRadius: BorderRadius.circular(11)),
                          child: Text(chat.unread > 99 ? '99+' : '${chat.unread}', style: TextStyle(color: p.paper, fontSize: 12.5, fontWeight: FontWeight.w700)),
                        )
                      : const SizedBox.shrink(),
                ),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _GroupAvatar extends StatelessWidget {
  const _GroupAvatar({required this.chat});
  final ChatSummary chat;

  @override
  Widget build(BuildContext context) {
    final url = chat.groupAvatarUrl;
    if (url != null) {
      return ClipOval(child: SizedBox.square(dimension: 54, child: Image.network(url, fit: BoxFit.cover)));
    }
    return Avatar(name: chat.title, size: 54, group: true);
  }
}

class _FishiRow extends StatelessWidget {
  const _FishiRow({required this.latest, required this.unseen, required this.onTap});

  final Announcement? latest;
  final int unseen;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Tappable(
      scale: 0.985,
      onTap: () {
        Prefs.instance.announcementsSeen = DateTime.now();
        onTap();
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 9, 16, 12),
        child: Row(children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(color: p.ink, shape: BoxShape.circle),
            child: FishLogo(size: 54, color: p.paper, eyeColor: p.ink),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                  child: NameLine(
                    name: 'Fishi',
                    badges: const ['verified', 'official'],
                    style: TextStyle(fontSize: 16.5, fontWeight: unseen > 0 ? FontWeight.w800 : FontWeight.w600, color: p.ink),
                  ),
                ),
                if (latest != null) Text(timeLabel(latest!.createdAt), style: TextStyle(fontSize: 13, color: p.muted)),
              ]),
              const SizedBox(height: 3),
              Row(children: [
                Expanded(
                  child: Text(
                    latest?.title ?? tr('News and updates from the Fishi team'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 14.5, color: unseen > 0 ? p.ink : p.muted),
                  ),
                ),
                if (unseen > 0)
                  Container(width: 10, height: 10, margin: const EdgeInsets.only(left: 8), decoration: BoxDecoration(color: p.ink, shape: BoxShape.circle)),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}
