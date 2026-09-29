import 'package:flutter/material.dart';

import '../brand/avatar.dart';
import '../brand/badges.dart';
import '../calls/call_center.dart';
import '../core/data.dart';
import '../core/inbox.dart';
import '../core/motion.dart';
import '../core/theme.dart';
import '../emoji/emoji_text.dart';
import '../home/new_chat.dart';
import '../ui/kit.dart';
import 'chat_controller.dart';
import 'chat_screen.dart';
import '../core/i18n.dart';

void showProfileSheet(BuildContext context, Profile p) {
  Navigator.of(context).push(sheetRoute(_ProfileSheet(profile: p)));
}

class _ProfileSheet extends StatelessWidget {
  const _ProfileSheet({required this.profile});
  final Profile profile;

  @override
  Widget build(BuildContext context) {
    final pal = Palette.of(context);
    return BottomSheetFrame(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Reveal(scale: 0.6, child: Avatar(profile: profile, size: 92)),
        const SizedBox(height: 12),
        Reveal(
          delay: const Duration(milliseconds: 60),
          child: NameLine(name: profile.displayName, badges: profile.badges, style: TextStyle(fontFamily: kDisplayFont, fontSize: 24, fontWeight: FontWeight.w800, color: pal.ink)),
        ),
        Reveal(
          delay: const Duration(milliseconds: 100),
          child: Text('@${profile.username}', style: TextStyle(fontSize: 15, color: pal.muted, fontFamily: kMonoFont)),
        ),
        if (profile.bio.isNotEmpty)
          Reveal(
            delay: const Duration(milliseconds: 140),
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: EmojiText(profile.bio, style: TextStyle(fontSize: 15, color: pal.ink, height: 1.35)),
            ),
          ),
        const SizedBox(height: 20),
        if (profile.id != myId && !profile.isBot)
          Reveal(
            delay: const Duration(milliseconds: 180),
            child: PillButton(
              label: tr('Message'),
              icon: Icons.chat_bubble_outline_rounded,
              onTap: () async {
                final nav = Navigator.of(context);
                try {
                  final id = await supa.rpc('open_direct', params: {'other': profile.id}) as String;
                  nav.pop();
                  nav.push(MaterialPageRoute(builder: (_) => ChatScreen(chatId: id)));
                } catch (_) {}
              },
            ),
          ),
      ]),
    );
  }
}

class ChatInfoScreen extends StatefulWidget {
  const ChatInfoScreen({super.key, required this.controller});

  final ChatController controller;

  @override
  State<ChatInfoScreen> createState() => _ChatInfoScreenState();
}

class _ChatInfoScreenState extends State<ChatInfoScreen> {
  ChatController get c => widget.controller;

  @override
  void initState() {
    super.initState();
    c.addListener(_changed);
    Inbox.instance.addListener(_changed);
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    c.removeListener(_changed);
    Inbox.instance.removeListener(_changed);
    super.dispose();
  }

  Future<void> _rename() async {
    final ctl = TextEditingController(text: c.name ?? '');
    final name = await Navigator.of(context).push<String>(sheetRoute(BottomSheetFrame(
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        FishiField(controller: ctl, label: tr('Group name'), autofocus: true, maxLength: 48),
        const SizedBox(height: 14),
        Builder(builder: (context) => PillButton(label: tr('Save'), onTap: () => Navigator.of(context).pop(ctl.text.trim()))),
      ]),
    )));
    if (name == null || name.isEmpty) return;
    try {
      await supa.from('chats').update({'name': name}).eq('id', c.chatId);
      c.name = name;
      Inbox.instance.refresh();
      setState(() {});
    } catch (_) {
      if (mounted) showToast(context, tr('Only group admins can rename.'), error: true);
    }
  }

  Future<void> _leave() async {
    final ok = await confirm(context, title: tr('Leave {name}?', {'name': c.title}), body: tr('You will stop getting messages from this group.'), action: tr('Leave'), danger: true);
    if (!ok) return;
    try {
      await supa.rpc('leave_group', params: {'chat': c.chatId});
      await Inbox.instance.refresh();
      if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
    } catch (_) {
      if (mounted) showToast(context, tr('Could not leave.'), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final summary = Inbox.instance.chat(c.chatId);
    final other = c.other;
    final canManage = c.myMember?.canManage ?? false;
    return Scaffold(
      appBar: const TopBar(title: ''),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 40),
        children: [
          const SizedBox(height: 10),
          Center(
            child: Hero(
              tag: 'avatar-${c.chatId}',
              child: c.isFinn
                  ? const FinnAvatar(size: 104)
                  : c.isGroup
                      ? Avatar(name: c.title, size: 104, group: true)
                      : Avatar(profile: other, size: 104),
            ),
          ),
          const SizedBox(height: 14),
          Reveal(
            delay: const Duration(milliseconds: 80),
            child: Center(
              child: NameLine(
                name: c.title,
                badges: c.isFinn ? const ['ai'] : (other?.badges ?? const []),
                style: TextStyle(fontFamily: kDisplayFont, fontSize: 26, fontWeight: FontWeight.w800, color: p.ink, letterSpacing: -0.5),
              ),
            ),
          ),
          if (other != null && !c.isGroup)
            Reveal(
              delay: const Duration(milliseconds: 120),
              child: Center(child: Text('@${other.username}', style: TextStyle(fontSize: 15, color: p.muted, fontFamily: kMonoFont))),
            ),
          if (other != null && other.bio.isNotEmpty && !c.isGroup)
            Reveal(
              delay: const Duration(milliseconds: 150),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(40, 10, 40, 0),
                child: EmojiText(other.bio, style: TextStyle(fontSize: 15, color: p.ink, height: 1.35)),
              ),
            ),
          const SizedBox(height: 20),
          if (!c.isFinn)
            Reveal(
              delay: const Duration(milliseconds: 180),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                _Action(icon: Icons.call_outlined, label: tr('Call'), onTap: () => CallCenter.instance.start(context, c.chatId, video: false, title: c.title)),
                const SizedBox(width: 12),
                _Action(icon: Icons.videocam_outlined, label: tr('Video'), onTap: () => CallCenter.instance.start(context, c.chatId, video: true, title: c.title)),
                const SizedBox(width: 12),
                _Action(
                  icon: (summary?.muted ?? false) ? Icons.notifications_off_outlined : Icons.notifications_none_rounded,
                  label: (summary?.muted ?? false) ? tr('Unmute') : tr('Mute'),
                  onTap: summary == null ? null : () => Inbox.instance.setMuted(summary, !summary.muted),
                ),
              ]),
            ),
          const SizedBox(height: 18),
          if (c.isGroup) ...[
            Reveal(
              delay: const Duration(milliseconds: 220),
              child: Section(
                title: tr('{n} members', {'n': c.members.length}),
                children: [
                  if (canManage)
                    RowTile(
                      icon: Icons.person_add_alt_1_outlined,
                      title: tr('Add people'),
                      onTap: () async {
                        final added = await Navigator.of(context).push<bool>(MaterialPageRoute(
                          builder: (_) => NewGroupScreen(addTo: c.chatId, existing: c.members.keys.toSet()),
                        ));
                        if (added == true && context.mounted) showToast(context, tr('Added'));
                      },
                    ),
                  for (final m in c.memberProfiles)
                    Tappable(
                      scale: 0.985,
                      onTap: () => showProfileSheet(context, m),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                        child: Row(children: [
                          Avatar(profile: m, size: 36),
                          const SizedBox(width: 12),
                          Expanded(
                            child: NameLine(
                              name: m.id == myId ? '${m.displayName} ${tr('(you)')}' : m.displayName,
                              badges: m.badges,
                              style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600, color: p.ink),
                            ),
                          ),
                          if ((c.members[m.id]?.role ?? 'member') != 'member')
                            Text(tr(c.members[m.id]!.role), style: TextStyle(fontSize: 13, color: p.muted)),
                        ]),
                      ),
                    ),
                ],
              ),
            ),
            Reveal(
              delay: const Duration(milliseconds: 260),
              child: Section(children: [
                if (canManage) RowTile(icon: Icons.edit_outlined, title: tr('Rename group'), onTap: _rename),
                RowTile(icon: Icons.logout_rounded, title: tr('Leave group'), danger: true, onTap: _leave, chevron: false),
              ]),
            ),
          ],
          if (c.isFinn)
            Reveal(
              delay: const Duration(milliseconds: 200),
              child: Section(
                title: tr('About Finn'),
                footer: tr('Finn remembers things you tell him to. Ask him to forget anytime. Mention @finn in any chat to bring him in.'),
                children: [
                  RowTile(icon: Icons.image_outlined, title: tr('Reply to a photo and ask about it')),
                  RowTile(icon: Icons.graphic_eq_rounded, title: tr('He can listen to voice notes')),
                  RowTile(icon: Icons.send_outlined, title: tr('Ask him to text someone for you')),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({required this.icon, required this.label, this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Tappable(
      scale: 0.92,
      onTap: onTap,
      child: Container(
        width: 92,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(18)),
        child: Column(children: [
          Icon(icon, color: p.ink),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: p.ink)),
        ]),
      ),
    );
  }
}
