import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../brand/avatar.dart';
import '../brand/badges.dart';
import '../chat/chat_screen.dart';
import '../core/data.dart';
import '../core/inbox.dart';
import '../core/motion.dart';
import '../core/theme.dart';
import '../ui/kit.dart';
import '../core/i18n.dart';

class PeopleSearch {
  static Future<List<Profile>> find(String q, {Set<String> exclude = const {}}) async {
    final term = q.trim().toLowerCase().replaceFirst('@', '');
    if (term.isEmpty) return [];
    final rows = await supa
        .from('profiles')
        .select()
        .or('username.ilike.${term.replaceAll(',', '')}%,display_name.ilike.%${term.replaceAll(',', '')}%')
        .neq('id', myId!)
        .order('username')
        .limit(25);
    final list = rows.map(Profile.fromJson).where((p) => !exclude.contains(p.id)).toList();
    list.sort((a, b) {
      final ax = a.username == term ? 0 : 1;
      final bx = b.username == term ? 0 : 1;
      return ax != bx ? ax - bx : a.username.compareTo(b.username);
    });
    for (final p in list) {
      Profiles.instance.put(p);
    }
    return list;
  }
}

class NewChatSheet extends StatefulWidget {
  const NewChatSheet({super.key});

  @override
  State<NewChatSheet> createState() => _NewChatSheetState();
}

class _NewChatSheetState extends State<NewChatSheet> {
  final _q = TextEditingController();
  Timer? _debounce;
  List<Profile> _results = [];
  bool _searching = false;
  String? _opening;

  @override
  void dispose() {
    _debounce?.cancel();
    _q.dispose();
    super.dispose();
  }

  void _onChanged(String v) {
    _debounce?.cancel();
    if (v.trim().isEmpty) {
      setState(() {
        _results = [];
        _searching = false;
      });
      return;
    }
    setState(() => _searching = true);
    _debounce = Timer(const Duration(milliseconds: 280), () async {
      try {
        final r = await PeopleSearch.find(v);
        if (mounted && _q.text == v) setState(() => _results = r);
      } catch (_) {}
      if (mounted) setState(() => _searching = false);
    });
  }

  Future<void> _open(Profile p) async {
    HapticFeedback.selectionClick();
    setState(() => _opening = p.id);
    try {
      final id = await supa.rpc('open_direct', params: {'other': p.id}) as String;
      Inbox.instance.refresh();
      if (!mounted) return;
      final nav = Navigator.of(context);
      nav.pop();
      nav.push(MaterialPageRoute(builder: (_) => ChatScreen(chatId: id)));
    } catch (_) {
      if (mounted) {
        setState(() => _opening = null);
        showToast(context, tr('Could not open that chat.'), error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return BottomSheetFrame(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.72,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Text(tr('New message'), style: TextStyle(fontFamily: kDisplayFont, fontSize: 22, fontWeight: FontWeight.w800, color: p.ink)),
            const Spacer(),
            CircleIcon(icon: Icons.close_rounded, size: 32, onTap: () => Navigator.of(context).pop()),
          ]),
          const SizedBox(height: 14),
          FishiField(controller: _q, label: tr('Username or name'), prefix: '@', autofocus: true, onChanged: _onChanged),
          const SizedBox(height: 10),
          Tappable(
            scale: 0.98,
            onTap: () {
              final nav = Navigator.of(context);
              nav.pop();
              nav.push(MaterialPageRoute(builder: (_) => const NewGroupScreen()));
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              child: Row(children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(color: p.ink, shape: BoxShape.circle),
                  child: Icon(Icons.group_add_outlined, color: p.paper, size: 22),
                ),
                const SizedBox(width: 12),
                Text(tr('New group'), style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w600, color: p.ink)),
              ]),
            ),
          ),
          Divider(color: p.line, height: 12),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 240),
              child: _searching && _results.isEmpty
                  ? const Center(key: ValueKey('s'), child: Spinner())
                  : _results.isEmpty
                      ? Center(
                          key: const ValueKey('e'),
                          child: Text(_q.text.isEmpty ? tr('Find people by their username.') : tr('Nobody found.'), style: TextStyle(color: p.muted, fontSize: 15)),
                        )
                      : ListView.builder(
                          key: ValueKey(_results.length),
                          itemCount: _results.length,
                          itemBuilder: (context, i) => Reveal(
                            delay: Duration(milliseconds: 30 * i.clamp(0, 10)),
                            child: PersonRow(
                              profile: _results[i],
                              trailing: _opening == _results[i].id ? const Spinner(size: 18) : null,
                              onTap: () => _open(_results[i]),
                            ),
                          ),
                        ),
            ),
          ),
        ]),
      ),
    );
  }
}

class PersonRow extends StatelessWidget {
  const PersonRow({super.key, required this.profile, this.onTap, this.trailing});

  final Profile profile;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Tappable(
      scale: 0.98,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(children: [
          Avatar(profile: profile, size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              NameLine(name: profile.displayName, badges: profile.badges, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: p.ink)),
              Text('@${profile.username}', style: TextStyle(fontSize: 13.5, color: p.muted)),
            ]),
          ),
          ?trailing,
        ]),
      ),
    );
  }
}

class NewGroupScreen extends StatefulWidget {
  const NewGroupScreen({super.key, this.addTo, this.existing = const {}});

  final String? addTo;
  final Set<String> existing;

  @override
  State<NewGroupScreen> createState() => _NewGroupScreenState();
}

class _NewGroupScreenState extends State<NewGroupScreen> {
  final _name = TextEditingController();
  final _q = TextEditingController();
  final _picked = <Profile>[];
  List<Profile> _results = [];
  Timer? _debounce;
  bool _busy = false;

  bool get _adding => widget.addTo != null;

  @override
  void dispose() {
    _debounce?.cancel();
    _name.dispose();
    _q.dispose();
    super.dispose();
  }

  void _search(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 260), () async {
      try {
        final r = await PeopleSearch.find(v, exclude: widget.existing);
        if (mounted) setState(() => _results = r.where((p) => !p.isBot).toList());
      } catch (_) {}
    });
  }

  void _toggle(Profile p) {
    HapticFeedback.selectionClick();
    setState(() {
      final i = _picked.indexWhere((x) => x.id == p.id);
      i >= 0 ? _picked.removeAt(i) : _picked.add(p);
    });
  }

  Future<void> _create() async {
    setState(() => _busy = true);
    try {
      if (_adding) {
        await supa.rpc('add_group_members', params: {'chat': widget.addTo, 'member_ids': _picked.map((p) => p.id).toList()});
        if (mounted) Navigator.of(context).pop(true);
        return;
      }
      final id = await supa.rpc('create_group', params: {
        'group_name': _name.text.trim(),
        'member_ids': _picked.map((p) => p.id).toList(),
      }) as String;
      await Inbox.instance.refresh();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => ChatScreen(chatId: id)));
    } catch (_) {
      if (mounted) {
        setState(() => _busy = false);
        showToast(context, _adding ? tr('Could not add people.') : tr('Could not create the group.'), error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final ok = _picked.isNotEmpty && (_adding || _name.text.trim().isNotEmpty);
    return Scaffold(
      appBar: TopBar(title: _adding ? tr('Add people') : tr('New group')),
      body: Column(children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
            children: [
              if (!_adding) ...[
                Reveal(child: FishiField(controller: _name, label: tr('Group name'), maxLength: 48, textCapitalization: TextCapitalization.sentences, onChanged: (_) => setState(() {}))),
                const SizedBox(height: 12),
              ],
              Reveal(
                delay: const Duration(milliseconds: 60),
                child: FishiField(controller: _q, label: tr('Add people'), prefix: '@', onChanged: _search),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 320),
                curve: kSmooth,
                alignment: Alignment.topLeft,
                child: _picked.isEmpty
                    ? const SizedBox(width: double.infinity)
                    : Padding(
                        padding: const EdgeInsets.only(top: 14),
                        child: Wrap(spacing: 8, runSpacing: 8, children: [
                          for (final x in _picked)
                            Reveal(
                              key: ValueKey(x.id),
                              scale: 0.6,
                              duration: const Duration(milliseconds: 420),
                              offset: Offset.zero,
                              child: GestureDetector(
                                onTap: () => _toggle(x),
                                child: Container(
                                  padding: const EdgeInsets.fromLTRB(4, 4, 10, 4),
                                  decoration: BoxDecoration(color: p.ink, borderRadius: BorderRadius.circular(20)),
                                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                                    Avatar(profile: x, size: 26),
                                    const SizedBox(width: 6),
                                    Text(x.displayName, style: TextStyle(color: p.paper, fontSize: 14, fontWeight: FontWeight.w600)),
                                    const SizedBox(width: 4),
                                    Icon(Icons.close_rounded, size: 15, color: p.paper),
                                  ]),
                                ),
                              ),
                            ),
                        ]),
                      ),
              ),
              const SizedBox(height: 10),
              for (var i = 0; i < _results.length; i++)
                Reveal(
                  key: ValueKey('r${_results[i].id}'),
                  delay: Duration(milliseconds: 30 * i.clamp(0, 10)),
                  child: PersonRow(
                    profile: _results[i],
                    onTap: () => _toggle(_results[i]),
                    trailing: AnimatedContainer(
                      duration: const Duration(milliseconds: 260),
                      curve: kSpring,
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _picked.any((x) => x.id == _results[i].id) ? p.ink : Colors.transparent,
                        border: Border.all(color: _picked.any((x) => x.id == _results[i].id) ? p.ink : p.muted, width: 2),
                      ),
                      child: _picked.any((x) => x.id == _results[i].id) ? Icon(Icons.check_rounded, size: 16, color: p.paper) : null,
                    ),
                  ),
                ),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 6, 18, 12),
            child: PillButton(
              label: _adding ? _picked.isNotEmpty ? tr('Add {n}', {'n': _picked.length}) : tr('Add') : tr('Create group'),
              busy: _busy,
              onTap: ok ? _create : null,
            ),
          ),
        ),
      ]),
    );
  }
}
