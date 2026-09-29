import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../brand/avatar.dart';
import '../brand/badges.dart';
import '../core/data.dart';
import '../core/inbox.dart';
import '../core/models.dart';
import '../core/motion.dart';
import '../core/theme.dart';
import '../home/new_chat.dart';
import '../ui/kit.dart';
import '../core/i18n.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key, this.preview});

  final Map<String, dynamic>? preview;

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  List<String> get _tabs => [tr('Stats'), tr('News'), 'Finn', tr('Safety'), tr('Badges')];
  final _pages = PageController();
  int _tab = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _go(int i) {
    HapticFeedback.selectionClick();
    setState(() => _tab = i);
    _pages.animateToPage(i, duration: const Duration(milliseconds: 460), curve: kSmooth);
  }

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Scaffold(
      appBar: const TopBar(title: 'Admin'),
      body: Column(children: [
        SizedBox(
          height: 50,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            children: [
              for (var i = 0; i < _tabs.length; i++)
                Reveal(
                  delay: Duration(milliseconds: 40 * i),
                  child: GestureDetector(
                    onTap: () => _go(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 280),
                      curve: kSmooth,
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: _tab == i ? p.ink : p.soft, borderRadius: BorderRadius.circular(17)),
                      child: Text(_tabs[i], style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _tab == i ? p.paper : p.ink)),
                    ),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: PageView(
            controller: _pages,
            onPageChanged: (i) => setState(() => _tab = i),
            children: [
              _StatsTab(preview: widget.preview),
              const _NewsTab(),
              const _FinnTab(),
              const _SafetyTab(),
              const _BadgesTab(),
            ],
          ),
        ),
      ]),
    );
  }
}

class _StatsTab extends StatefulWidget {
  const _StatsTab({this.preview});
  final Map<String, dynamic>? preview;

  @override
  State<_StatsTab> createState() => _StatsTabState();
}

class _StatsTabState extends State<_StatsTab> with AutomaticKeepAliveClientMixin {
  Map<String, dynamic>? _stats;
  bool _failed = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _stats = widget.preview;
    if (_stats == null) _load();
  }

  Future<void> _load() async {
    try {
      final s = await supa.rpc('admin_stats');
      if (mounted) setState(() => _stats = (s as Map).cast<String, dynamic>());
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final p = Palette.of(context);
    final s = _stats;
    if (s == null) return Center(child: _failed ? Text(tr('Could not load stats'), style: TextStyle(color: p.muted)) : const Spinner());
    final items = [
      (tr('People'), s['users'], Icons.people_alt_outlined),
      (tr('Active today'), s['active_today'], Icons.bolt_rounded),
      (tr('Chats'), s['chats'], Icons.forum_outlined),
      (tr('Messages'), s['messages'], Icons.chat_bubble_outline_rounded),
      (tr('Messages today'), s['messages_today'], Icons.today_outlined),
    ];
    return RefreshIndicator(
      color: p.ink,
      onRefresh: _load,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.25),
        itemCount: items.length,
        itemBuilder: (context, i) {
          final it = items[i];
          return Reveal(
            delay: Duration(milliseconds: 60 * i),
            scale: 0.85,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: i == 0 ? p.ink : p.card, borderRadius: BorderRadius.circular(22)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(it.$3, color: i == 0 ? p.paper : p.ink, size: 22),
                const Spacer(),
                CountUp(
                  value: (it.$2 as num?) ?? 0,
                  style: TextStyle(fontFamily: kDisplayFont, fontSize: 34, fontWeight: FontWeight.w800, color: i == 0 ? p.paper : p.ink, letterSpacing: -1),
                ),
                Text(it.$1, style: TextStyle(fontSize: 13.5, color: i == 0 ? p.paper.withValues(alpha: 0.7) : p.muted)),
              ]),
            ),
          );
        },
      ),
    );
  }
}

class _NewsTab extends StatefulWidget {
  const _NewsTab();

  @override
  State<_NewsTab> createState() => _NewsTabState();
}

class _NewsTabState extends State<_NewsTab> with AutomaticKeepAliveClientMixin {
  final _title = TextEditingController();
  final _body = TextEditingController();
  bool _busy = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    Inbox.instance.addListener(_changed);
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    Inbox.instance.removeListener(_changed);
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _post() async {
    setState(() => _busy = true);
    try {
      await supa.from('announcements').insert({'title': _title.text.trim(), 'body': _body.text.trim()});
      _title.clear();
      _body.clear();
      await Inbox.instance.loadAnnouncements();
      if (mounted) showToast(context, tr('Posted to everyone'));
    } catch (_) {
      if (mounted) showToast(context, tr('Could not post.'), error: true);
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _delete(Announcement a) async {
    final ok = await confirm(context, title: tr('Delete this post?'), body: a.title, action: tr('Delete'), danger: true);
    if (!ok) return;
    try {
      await supa.from('announcements').delete().eq('id', a.id);
      await Inbox.instance.loadAnnouncements();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final p = Palette.of(context);
    final items = Inbox.instance.announcements;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Reveal(child: FishiField(controller: _title, label: tr('Title'), maxLength: 80, onChanged: (_) => setState(() {}))),
        const SizedBox(height: 10),
        Reveal(
          delay: const Duration(milliseconds: 50),
          child: FishiField(controller: _body, label: tr('What is new?'), maxLines: 6, maxLength: 4000, textCapitalization: TextCapitalization.sentences, onChanged: (_) => setState(() {})),
        ),
        const SizedBox(height: 14),
        Reveal(
          delay: const Duration(milliseconds: 100),
          child: PillButton(
            label: tr('Post announcement'),
            icon: Icons.campaign_outlined,
            busy: _busy,
            onTap: _title.text.trim().isNotEmpty && _body.text.trim().isNotEmpty ? _post : null,
          ),
        ),
        const SizedBox(height: 24),
        for (var i = 0; i < items.length; i++)
          Reveal(
            key: ValueKey(items[i].id),
            delay: Duration(milliseconds: 140 + 40 * i),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
              decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(18)),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(items[i].title, style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700, color: p.ink)),
                    const SizedBox(height: 3),
                    Text(items[i].body, maxLines: 3, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14, color: p.muted)),
                    const SizedBox(height: 4),
                    Text(dayHeader(items[i].createdAt), style: TextStyle(fontSize: 12, color: p.muted)),
                  ]),
                ),
                CircleIcon(icon: Icons.delete_outline_rounded, size: 34, onTap: () => _delete(items[i])),
              ]),
            ),
          ),
      ],
    );
  }
}

class _FinnTab extends StatefulWidget {
  const _FinnTab();

  @override
  State<_FinnTab> createState() => _FinnTabState();
}

class _FinnTabState extends State<_FinnTab> with AutomaticKeepAliveClientMixin {
  final _key = TextEditingController();
  final _endpoint = TextEditingController();
  final _model = TextEditingController();
  final _audio = TextEditingController();
  final _prompt = TextEditingController();
  Map<String, dynamic>? _cfg;
  bool _busy = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in [_key, _endpoint, _model, _audio, _prompt]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final c = (await supa.rpc('admin_get_finn_config') as Map).cast<String, dynamic>();
      _endpoint.text = c['endpoint'] as String? ?? '';
      _model.text = c['model'] as String? ?? '';
      _audio.text = c['audio_model'] as String? ?? '';
      _prompt.text = c['system_prompt'] as String? ?? '';
      if (mounted) setState(() => _cfg = c);
    } catch (_) {
      if (mounted) setState(() => _cfg = {});
    }
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    try {
      await supa.rpc('admin_set_finn_config', params: {
        'new_api_key': _key.text.trim().isEmpty ? null : _key.text.trim(),
        'new_endpoint': _endpoint.text.trim(),
        'new_model': _model.text.trim(),
        'new_audio_model': _audio.text.trim(),
        'new_system_prompt': _prompt.text,
      });
      _key.clear();
      await _load();
      if (mounted) showToast(context, tr('Finn updated'));
    } catch (_) {
      if (mounted) showToast(context, tr('Could not save.'), error: true);
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final p = Palette.of(context);
    final c = _cfg;
    if (c == null) return const Center(child: Spinner());
    final hasKey = c['has_key'] == true;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Reveal(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(20)),
            child: Row(children: [
              const FinnAvatar(size: 48),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Finn', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: p.ink)),
                  Text(hasKey ? 'API key set (${c['key_hint'] ?? ''})' : tr('No API key. Finn will say he is busy.'), style: TextStyle(fontSize: 13.5, color: hasKey ? p.muted : p.danger)),
                ]),
              ),
            ]),
          ),
        ),
        const SizedBox(height: 14),
        Stagger(start: const Duration(milliseconds: 60), children: [
          FishiField(controller: _key, label: hasKey ? tr('Replace API key') : tr('API key'), obscure: true),
          const SizedBox(height: 10),
          FishiField(controller: _endpoint, label: tr('Endpoint'), keyboardType: TextInputType.url),
          const SizedBox(height: 10),
          FishiField(controller: _model, label: tr('Model')),
          const SizedBox(height: 10),
          FishiField(controller: _audio, label: tr('Audio model')),
          const SizedBox(height: 10),
          FishiField(controller: _prompt, label: tr('Extra system prompt'), maxLines: 8),
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 8, 6, 16),
            child: Text(tr('People never see these settings. Changes apply to the next Finn reply.'), style: TextStyle(fontSize: 13, color: p.muted)),
          ),
          PillButton(label: tr('Save Finn settings'), busy: _busy, onTap: _save),
        ]),
      ],
    );
  }
}

class _SafetyTab extends StatefulWidget {
  const _SafetyTab();

  @override
  State<_SafetyTab> createState() => _SafetyTabState();
}

class _SafetyTabState extends State<_SafetyTab> with AutomaticKeepAliveClientMixin {
  final _term = TextEditingController();
  List<String> _terms = [];
  List<Map<String, dynamic>> _flags = [];
  bool _loaded = false;
  bool _open = true;
  bool _dirty = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _term.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final t = await supa.rpc('admin_watch_terms');
      final f = await supa.rpc('admin_flags', params: {'only_open': _open});
      if (!mounted) return;
      setState(() {
        _terms = ((t as List?) ?? const []).cast<String>();
        _flags = ((f as List?) ?? const []).map((e) => (e as Map).cast<String, dynamic>()).toList();
        _loaded = true;
      });
    } catch (_) {
      if (mounted) setState(() => _loaded = true);
    }
  }

  void _add() {
    final t = _term.text.trim().toLowerCase();
    if (t.length < 2 || _terms.contains(t)) return;
    HapticFeedback.selectionClick();
    setState(() {
      _terms = [..._terms, t]..sort();
      _dirty = true;
    });
    _term.clear();
  }

  Future<void> _saveTerms() async {
    try {
      await supa.rpc('admin_set_watch_terms', params: {'terms': _terms});
      setState(() => _dirty = false);
      if (mounted) showToast(context, tr('Watch list saved'));
    } catch (_) {
      if (mounted) showToast(context, tr('Could not save.'), error: true);
    }
  }

  Future<void> _review(Map<String, dynamic> f) async {
    try {
      await supa.rpc('admin_review_flag', params: {'flag_id': f['id']});
      setState(() => _flags = _flags.where((x) => x['id'] != f['id']).toList());
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final p = Palette.of(context);
    if (!_loaded) return const Center(child: Spinner());
    return RefreshIndicator(
      color: p.ink,
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Reveal(
            child: Text(tr('Watch list'), style: TextStyle(fontFamily: kDisplayFont, fontSize: 20, fontWeight: FontWeight.w800, color: p.ink)),
          ),
          const SizedBox(height: 4),
          Text(tr('Only messages with these words or phrases get flagged. Ordinary swearing is never flagged. Under-18 age answers are flagged automatically.'),
              style: TextStyle(fontSize: 13, color: p.muted, height: 1.35)),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: FishiField(controller: _term, label: tr('Add a term'), onSubmitted: (_) => _add())),
            const SizedBox(width: 8),
            CircleIcon(icon: Icons.add_rounded, size: 46, filled: true, onTap: _add),
          ]),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final t in _terms)
              Reveal(
                key: ValueKey(t),
                scale: 0.6,
                offset: Offset.zero,
                child: GestureDetector(
                  onTap: () => setState(() {
                    _terms = _terms.where((x) => x != t).toList();
                    _dirty = true;
                  }),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(12, 7, 8, 7),
                    decoration: BoxDecoration(color: p.soft, borderRadius: BorderRadius.circular(16)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text(t, style: TextStyle(fontSize: 14, color: p.ink, fontFamily: kMonoFont)),
                      const SizedBox(width: 4),
                      Icon(Icons.close_rounded, size: 15, color: p.muted),
                    ]),
                  ),
                ),
              ),
          ]),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: kSmooth,
            child: _dirty
                ? Padding(padding: const EdgeInsets.only(top: 14), child: PillButton(label: tr('Save watch list'), onTap: _saveTerms))
                : const SizedBox(width: double.infinity),
          ),
          const SizedBox(height: 28),
          Row(children: [
            Expanded(child: Text(tr('Flagged'), style: TextStyle(fontFamily: kDisplayFont, fontSize: 20, fontWeight: FontWeight.w800, color: p.ink))),
            SizedBox(
              width: 170,
              child: Segmented<bool>(
                values: const [true, false],
                labels: [tr('Open'), tr('All')],
                value: _open,
                onChanged: (v) {
                  setState(() => _open = v);
                  _load();
                },
              ),
            ),
          ]),
          const SizedBox(height: 12),
          if (_flags.isEmpty)
            Padding(
              padding: const EdgeInsets.all(30),
              child: Center(child: Text(tr('Nothing flagged'), style: TextStyle(color: p.muted))),
            ),
          for (var i = 0; i < _flags.length; i++)
            Reveal(
              key: ValueKey(_flags[i]['id']),
              delay: Duration(milliseconds: 40 * i.clamp(0, 8)),
              child: _FlagCard(flag: _flags[i], onReviewed: () => _review(_flags[i])),
            ),
        ],
      ),
    );
  }
}

class _FlagCard extends StatelessWidget {
  const _FlagCard({required this.flag, required this.onReviewed});

  final Map<String, dynamic> flag;
  final VoidCallback onReviewed;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final ctx = ((flag['context'] as List?) ?? const []).map((e) => (e as Map).cast<String, dynamic>()).toList();
    final open = flag['status'] == 'open';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(20)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: p.danger.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
            child: Text(flag['matched'] as String? ?? '', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: p.danger)),
          ),
          const Spacer(),
          Text(dayHeader(DateTime.tryParse(flag['created_at'] as String? ?? '') ?? DateTime.now()), style: TextStyle(fontSize: 12, color: p.muted)),
        ]),
        const SizedBox(height: 10),
        for (final m in ctx)
          Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: m['flagged'] == true ? p.ink : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: RichText(
              text: TextSpan(style: TextStyle(fontSize: 14, color: m['flagged'] == true ? p.paper : p.ink, fontFamily: kTextFont), children: [
                TextSpan(text: '@${m['username']}  ', style: const TextStyle(fontWeight: FontWeight.w700)),
                TextSpan(text: (m['kind'] == 'text' ? m['body'] : '[${m['kind']}]') as String? ?? ''),
              ]),
            ),
          ),
        if (open) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Tappable(
              onTap: onReviewed,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(color: p.soft, borderRadius: BorderRadius.circular(14)),
                child: Text(tr('Mark reviewed'), style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: p.ink)),
              ),
            ),
          ),
        ],
      ]),
    );
  }
}

class _BadgesTab extends StatefulWidget {
  const _BadgesTab();

  @override
  State<_BadgesTab> createState() => _BadgesTabState();
}

class _BadgesTabState extends State<_BadgesTab> with AutomaticKeepAliveClientMixin {
  final _q = TextEditingController();
  List<Profile> _results = [];

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  Future<void> _search(String v) async {
    try {
      final r = await PeopleSearch.find(v);
      if (mounted) setState(() => _results = r);
    } catch (_) {}
  }

  Future<void> _toggle(Profile pr, String badge) async {
    final next = pr.badges.contains(badge) ? pr.badges.where((b) => b != badge).toList() : [...pr.badges, badge];
    try {
      await supa.rpc('admin_set_badges', params: {'target': pr.id, 'new_badges': next});
      await Profiles.instance.refresh(pr.id);
      final fresh = Profiles.instance[pr.id];
      if (fresh != null && mounted) setState(() => _results = _results.map((x) => x.id == pr.id ? fresh : x).toList());
    } catch (_) {
      if (mounted) showToast(context, tr('Could not change badges.'), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final p = Palette.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Reveal(child: FishiField(controller: _q, label: tr('Find someone'), prefix: '@', onChanged: _search)),
        const SizedBox(height: 12),
        for (final pr in _results)
          Reveal(
            key: ValueKey(pr.id),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(18)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Avatar(profile: pr, size: 38),
                  const SizedBox(width: 10),
                  Expanded(child: NameLine(name: pr.displayName, badges: pr.badges, style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700, color: p.ink))),
                ]),
                const SizedBox(height: 10),
                Wrap(spacing: 8, children: [
                  for (final b in const ['verified', 'staff', 'official'])
                    GestureDetector(
                      onTap: () => _toggle(pr, b),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 240),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: pr.badges.contains(b) ? p.ink : p.soft, borderRadius: BorderRadius.circular(14)),
                        child: Text(b, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: pr.badges.contains(b) ? p.paper : p.ink)),
                      ),
                    ),
                ]),
              ]),
            ),
          ),
      ],
    );
  }
}
