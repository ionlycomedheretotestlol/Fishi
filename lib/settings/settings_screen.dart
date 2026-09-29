import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../admin/admin_screen.dart';
import '../brand/avatar.dart';
import '../brand/badges.dart';
import '../chat/bubble_shape.dart';
import '../chat/chat_background.dart';
import '../core/data.dart';
import '../core/inbox.dart';
import '../core/motion.dart';
import '../core/prefs.dart';
import '../core/theme.dart';
import '../ui/kit.dart';
import 'bubble_studio.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    Prefs.instance.addListener(_changed);
    Profiles.instance.addListener(_changed);
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    Prefs.instance.removeListener(_changed);
    Profiles.instance.removeListener(_changed);
    super.dispose();
  }

  Future<void> _signOut() async {
    final ok = await confirm(context, title: 'Sign out?', action: 'Sign out', danger: true);
    if (!ok) return;
    await Inbox.instance.stop();
    await supa.auth.signOut();
    if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final me = Profiles.instance.me;
    final prefs = Prefs.instance;
    var i = 0;
    Duration d() => Duration(milliseconds: 60 + 50 * i++);
    return Scaffold(
      body: LargeTitleScroll(
        title: 'Settings',
        leading: Tappable(
          scale: 0.85,
          onTap: () => Navigator.of(context).maybePop(),
          child: Padding(padding: const EdgeInsets.all(8), child: Icon(Icons.arrow_back_ios_new_rounded, size: 21, color: p.ink)),
        ),
        slivers: [
          SliverToBoxAdapter(
            child: Reveal(
              delay: d(),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
                child: Tappable(
                  scale: 0.98,
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfileEditScreen())),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(22)),
                    child: Row(children: [
                      Avatar(profile: me, size: 64),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          NameLine(
                            name: me?.displayName ?? '',
                            badges: me?.badges ?? const [],
                            style: TextStyle(fontFamily: kDisplayFont, fontSize: 21, fontWeight: FontWeight.w800, color: p.ink),
                          ),
                          const SizedBox(height: 2),
                          Text('@${me?.username ?? ''}', style: TextStyle(fontSize: 14.5, color: p.muted, fontFamily: kMonoFont)),
                          if ((me?.bio ?? '').isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(me!.bio, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14, color: p.ink)),
                            ),
                        ]),
                      ),
                      Icon(Icons.chevron_right_rounded, color: p.muted),
                    ]),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Reveal(
              delay: d(),
              child: Section(title: 'Look', children: [
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Theme', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: p.ink)),
                    const SizedBox(height: 10),
                    Segmented<ThemeMode>(
                      values: const [ThemeMode.system, ThemeMode.light, ThemeMode.dark],
                      labels: const ['Auto', 'Light', 'Dark'],
                      value: prefs.themeMode,
                      onChanged: (v) => prefs.themeMode = v,
                    ),
                  ]),
                ),
                RowTile(
                  icon: Icons.chat_bubble_outline_rounded,
                  title: 'Bubble studio',
                  subtitle: me?.bubble.shape.label ?? 'Classic',
                  trailing: Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: SizedBox(
                      width: 44,
                      height: 26,
                      child: CustomPaint(
                        painter: BubblePainter(style: me?.bubble ?? const BubbleStyle(), color: bubbleFill(me?.bubble ?? const BubbleStyle(), p, mine: true), mine: true, tail: true),
                      ),
                    ),
                  ),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BubbleStudio())),
                ),
                RowTile(
                  icon: Icons.texture_rounded,
                  title: 'Chat background',
                  chevron: false,
                  trailing: FishiSwitch(value: prefs.chatBackground, onChanged: (v) => prefs.chatBackground = v),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 360),
                  curve: kSmooth,
                  child: prefs.chatBackground
                      ? Padding(
                          padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
                          child: Row(children: [
                            for (var k = 0; k < chatPatterns.length; k++)
                              Expanded(
                                child: Tappable(
                                  onTap: () => prefs.chatPattern = k,
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 260),
                                    curve: kSmooth,
                                    height: 74,
                                    margin: EdgeInsets.only(right: k < chatPatterns.length - 1 ? 8 : 0),
                                    clipBehavior: Clip.antiAlias,
                                    decoration: BoxDecoration(
                                      color: p.paper,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(color: prefs.chatPattern == k ? p.ink : p.line, width: prefs.chatPattern == k ? 2 : 1),
                                    ),
                                    child: Stack(children: [
                                      Positioned.fill(child: ChatBackground(pattern: k, color: p.ink)),
                                      Positioned(
                                        left: 8,
                                        bottom: 6,
                                        child: Text(chatPatterns[k], style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: p.ink)),
                                      ),
                                    ]),
                                  ),
                                ),
                              ),
                          ]),
                        )
                      : const SizedBox(width: double.infinity),
                ),
              ]),
            ),
          ),
          SliverToBoxAdapter(
            child: Reveal(
              delay: d(),
              child: Section(title: 'Alerts', children: [
                RowTile(
                  icon: Icons.notifications_none_rounded,
                  title: 'Notifications',
                  chevron: false,
                  trailing: FishiSwitch(value: prefs.notifications, onChanged: (v) => prefs.notifications = v),
                ),
                RowTile(
                  icon: Icons.volume_up_outlined,
                  title: 'Sounds',
                  chevron: false,
                  trailing: FishiSwitch(value: prefs.sounds, onChanged: (v) => prefs.sounds = v),
                ),
              ]),
            ),
          ),
          if (Profiles.instance.isAdmin)
            SliverToBoxAdapter(
              child: Reveal(
                delay: d(),
                child: Section(title: 'Staff', children: [
                  RowTile(
                    icon: Icons.shield_outlined,
                    title: 'Admin panel',
                    subtitle: 'Stats, announcements, Finn, safety',
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminScreen())),
                  ),
                ]),
              ),
            ),
          SliverToBoxAdapter(
            child: Reveal(
              delay: d(),
              child: Section(
                footer: 'Fishi is for adults 18 and over. Messages matching safety terms can be reviewed by the Fishi team.',
                children: [RowTile(icon: Icons.logout_rounded, title: 'Sign out', danger: true, chevron: false, onTap: _signOut)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final me = Profiles.instance.me;
  late final _name = TextEditingController(text: me?.displayName ?? '');
  late final _bio = TextEditingController(text: me?.bio ?? '');
  bool _busy = false;
  bool _uploading = false;

  @override
  void dispose() {
    _name.dispose();
    _bio.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    try {
      final file = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 800, maxHeight: 800, imageQuality: 86);
      if (file == null) return;
      setState(() => _uploading = true);
      final bytes = await file.readAsBytes();
      final path = '$myId/${DateTime.now().millisecondsSinceEpoch}.jpg';
      await supa.storage.from('avatars').uploadBinary(path, bytes, fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true));
      await supa.from('profiles').update({'avatar_path': path}).eq('id', myId!);
      await Profiles.instance.refresh(myId!);
    } catch (_) {
      if (mounted) showToast(context, 'Could not update your photo.', error: true);
    }
    if (mounted) setState(() => _uploading = false);
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    setState(() => _busy = true);
    try {
      await supa.from('profiles').update({'display_name': name, 'bio': _bio.text.trim()}).eq('id', myId!);
      await Profiles.instance.refresh(myId!);
      if (mounted) {
        showToast(context, 'Saved');
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (mounted) {
        setState(() => _busy = false);
        showToast(context, 'Could not save.', error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final current = Profiles.instance.me;
    return Scaffold(
      appBar: const TopBar(title: 'Profile'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        children: [
          Center(
            child: Tappable(
              onTap: _uploading ? null : _pickAvatar,
              child: Stack(children: [
                Reveal(scale: 0.6, child: Avatar(profile: current, size: 110)),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(color: p.ink, shape: BoxShape.circle, border: Border.all(color: p.paper, width: 3)),
                    child: _uploading ? Padding(padding: const EdgeInsets.all(8), child: Spinner(size: 14, color: p.paper)) : Icon(Icons.camera_alt_rounded, size: 16, color: p.paper),
                  ),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 26),
          Stagger(children: [
            FishiField(controller: _name, label: 'Name', maxLength: 40, textCapitalization: TextCapitalization.words),
            const SizedBox(height: 12),
            FishiField(controller: _bio, label: 'Bio', maxLength: 160, maxLines: 4, textCapitalization: TextCapitalization.sentences),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 6),
              child: Text('@${current?.username ?? ''} · usernames cannot be changed', style: TextStyle(fontSize: 13, color: p.muted)),
            ),
            const SizedBox(height: 24),
            PillButton(label: 'Save', busy: _busy, onTap: _save),
          ]),
        ],
      ),
    );
  }
}
