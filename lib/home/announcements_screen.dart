import 'package:flutter/material.dart';

import '../brand/badges.dart';
import '../brand/fish_logo.dart';
import '../core/data.dart';
import '../core/inbox.dart';
import '../core/motion.dart';
import '../core/prefs.dart';
import '../core/theme.dart';
import '../emoji/emoji_text.dart';
import '../ui/kit.dart';
import '../core/i18n.dart';

class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  @override
  void initState() {
    super.initState();
    Inbox.instance.addListener(_changed);
    Prefs.instance.announcementsSeen = DateTime.now();
    Inbox.instance.loadAnnouncements();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    Inbox.instance.removeListener(_changed);
    Prefs.instance.announcementsSeen = DateTime.now();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final items = Inbox.instance.announcements;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: TopBar(
        titleWidget: NameLine(
          name: 'Fishi',
          badges: const ['verified', 'official'],
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: p.ink),
        ),
      ),
      body: items.isEmpty
          ? Center(
              child: EmptyState(
                icon: FishLogo(size: 70, color: p.ink, eyeColor: p.paper),
                title: tr('Nothing new'),
                body: tr('Updates from the Fishi team show up here.'),
              ),
            )
          : ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(16, MediaQuery.paddingOf(context).top + 72, 16, 40),
              itemCount: items.length,
              itemBuilder: (context, i) {
                final a = items[i];
                return Reveal(
                  delay: Duration(milliseconds: 60 * i.clamp(0, 8)),
                  offset: const Offset(0, 24),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(22)),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(color: p.ink, shape: BoxShape.circle),
                          child: FishLogo(size: 28, color: p.paper, eyeColor: p.ink),
                        ),
                        const SizedBox(width: 8),
                        Text(tr('Fishi team'), style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: p.muted)),
                        const Spacer(),
                        Text(dayHeader(a.createdAt), style: TextStyle(fontSize: 12.5, color: p.muted, fontFamily: kMonoFont)),
                      ]),
                      const SizedBox(height: 12),
                      Text(a.title, style: TextStyle(fontFamily: kDisplayFont, fontSize: 20, fontWeight: FontWeight.w800, color: p.ink, letterSpacing: -0.4)),
                      const SizedBox(height: 6),
                      EmojiText(a.body, style: TextStyle(fontSize: 15.5, color: p.ink, height: 1.4)),
                    ]),
                  ),
                );
              },
            ),
    );
  }
}
