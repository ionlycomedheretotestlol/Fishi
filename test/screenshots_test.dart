import 'dart:io';

import 'package:fishi/admin/admin_screen.dart';
import 'package:fishi/auth/auth_screens.dart';
import 'package:fishi/calls/call_screen.dart';
import 'package:fishi/chat/chat_controller.dart';
import 'package:fishi/chat/chat_screen.dart';
import 'package:fishi/core/data.dart';
import 'package:fishi/core/models.dart';
import 'package:fishi/core/prefs.dart';
import 'package:fishi/core/theme.dart';
import 'package:fishi/emoji/chibi.dart';
import 'package:fishi/home/home_screen.dart';
import 'package:fishi/onboarding/language_screen.dart';
import 'package:fishi/onboarding/permissions_screen.dart';
import 'package:fishi/settings/bubble_studio.dart';
import 'package:fishi/settings/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

final now = DateTime.now();
DateTime ago(int minutes) => now.subtract(Duration(minutes: minutes));

final me = Profile(id: 'me', username: 'maya', displayName: 'Maya Costa', bio: 'coffee, film cameras, long walks', bubble: const BubbleStyle(shape: BubbleShape.soft));
final leo = Profile(id: 'leo', username: 'leo', displayName: 'Leo Park', lastSeen: now, bubble: const BubbleStyle(shape: BubbleShape.cloud));
final ana = Profile(id: 'ana', username: 'ana_b', displayName: 'Ana Beatriz', badges: const ['verified'], bubble: const BubbleStyle(shape: BubbleShape.pill));
final sam = Profile(id: 'sam', username: 'sam', displayName: 'Sam Rivera', bubble: const BubbleStyle(shape: BubbleShape.bolt));
final june = Profile(id: 'june', username: 'june', displayName: 'June Lee', lastSeen: now);
final finn = Profile(id: 'finn', username: 'finn', displayName: 'Finn', isBot: true, badges: const ['ai']);

Future<void> loadFonts() async {
  Future<void> family(String name, List<String> files) async {
    final loader = FontLoader(name);
    for (final f in files) {
      loader.addFont(Future.value(ByteData.view(File(f).readAsBytesSync().buffer)));
    }
    await loader.load();
  }

  await family('Inter', [for (final w in [400, 500, 600, 700, 800]) 'assets/fonts/Inter-$w.ttf']);
  await family('InterTight', ['assets/fonts/InterTight-800.ttf']);
  await family('JetBrainsMono', ['assets/fonts/JetBrainsMono-400.ttf']);
  final root = Platform.environment['FLUTTER_ROOT'];
  if (root != null) {
    final icons = File('$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
    if (icons.existsSync()) await family('MaterialIcons', [icons.path]);
  }
}

Widget app(Widget home, Brightness b) => MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildTheme(b),
      locale: Prefs.instance.language == 'pt' ? const Locale('pt', 'BR') : const Locale('en'),
      supportedLocales: const [Locale('en'), Locale('pt', 'BR')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: home,
    );

Future<void> shoot(WidgetTester tester, String name, Widget home, {Brightness b = Brightness.light, String lang = 'en'}) async {
  Prefs.instance.language = lang;
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 2.75;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(app(home, b));
  for (var i = 0; i < 30; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  await expectLater(find.byType(MaterialApp), matchesGoldenFile('../docs/screenshots/$name.png'));
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 1));
}

List<ChatSummary> chats() => [
      ChatSummary(id: 'c0', kind: 'finn', lastMessageAt: ago(3), lastReadAt: now, other: finn,
          last: LastMessage(body: 'Found it. The ramen place on 5th opens at noon.', kind: 'text', senderId: 'finn', createdAt: ago(3), deleted: false)),
      ChatSummary(id: 'c1', kind: 'direct', lastMessageAt: ago(1), lastReadAt: ago(20), other: leo, unread: 2,
          last: LastMessage(body: 'wait you actually made sourdough?? 😍', kind: 'text', senderId: 'leo', createdAt: ago(1), deleted: false)),
      ChatSummary(id: 'c2', kind: 'group', name: 'Weekend trip', memberCount: 5, lastMessageAt: ago(14), lastReadAt: ago(20), unread: 5,
          last: LastMessage(body: 'I booked the cabin 🎉', kind: 'text', senderId: 'june', createdAt: ago(14), deleted: false)),
      ChatSummary(id: 'c3', kind: 'direct', lastMessageAt: ago(60 * 5), lastReadAt: now, other: ana,
          last: LastMessage(body: '', kind: 'audio', senderId: 'me', createdAt: ago(60 * 5), deleted: false)),
      ChatSummary(id: 'c4', kind: 'direct', lastMessageAt: ago(60 * 26), lastReadAt: now, other: sam, pinned: true,
          last: LastMessage(body: 'haha deal. see you then 👍', kind: 'text', senderId: 'sam', createdAt: ago(60 * 26), deleted: false)),
      ChatSummary(id: 'c5', kind: 'direct', lastMessageAt: ago(60 * 24 * 3), lastReadAt: now, other: june, muted: true,
          last: LastMessage(body: '', kind: 'image', senderId: 'june', createdAt: ago(60 * 24 * 3), deleted: false)),
    ];

Message msg(String id, String sender, String body, int minutes, {String? replyTo, String kind = 'text', Map<String, dynamic> meta = const {}}) =>
    Message(id: id, chatId: 'c1', senderId: sender, body: body, createdAt: ago(minutes), replyTo: replyTo, kind: kind, mediaMeta: meta);

ChatController directChat() {
  final c = ChatController('c1', previewMessages: [
    msg('m1', 'leo', 'are you up for dinner friday?', 40),
    msg('m2', 'me', 'yes!! somewhere quiet though', 39),
    msg('m3', 'me', 'this week has been a lot', 39),
    msg('m4', 'leo', 'fair. I know a spot', 38),
    msg('m5', 'me', '', 12, kind: 'audio', meta: {'duration_ms': 14000}),
    msg('m6', 'leo', 'ok that voice note made me laugh', 10, replyTo: 'm5'),
    msg('m7', 'me', 'also I made bread today', 3),
    msg('m8', 'leo', '😍🔥', 2),
    msg('m9', 'leo', 'wait you actually made sourdough??', 1),
  ])
    ..kind = 'direct';
  c.members['me'] = Member(userId: 'me', role: 'member', lastReadAt: now);
  c.members['leo'] = Member(userId: 'leo', role: 'member', lastReadAt: ago(2));
  c.reactions['m4'] = [const Reaction(messageId: 'm4', userId: 'me', emoji: '❤️')];
  c.reactions['m7'] = [const Reaction(messageId: 'm7', userId: 'leo', emoji: '😮')];
  return c;
}

ChatController groupChat() {
  Message g(String id, String sender, String body, int minutes, {String? replyTo}) =>
      Message(id: id, chatId: 'c2', senderId: sender, body: body, createdAt: ago(minutes), replyTo: replyTo);
  final c = ChatController('c2', previewMessages: [
    Message(id: 's1', chatId: 'c2', senderId: 'june', kind: 'system', body: 'created the group', createdAt: ago(200)),
    g('g1', 'june', 'ok cabin or beach house?', 60),
    g('g2', 'sam', 'cabin. obviously', 59),
    g('g3', 'ana', 'cabin 🍀 but only if there is a fireplace', 58),
    g('g4', 'me', '@june check if it has a hot tub', 50),
    g('g5', 'june', 'it has BOTH', 20, replyTo: 'g4'),
    g('g6', 'june', 'I booked the cabin 🎉', 14),
  ])
    ..kind = 'group'
    ..name = 'Weekend trip';
  for (final id in ['me', 'june', 'sam', 'ana', 'leo']) {
    c.members[id] = Member(userId: id, role: id == 'june' ? 'owner' : 'member', lastReadAt: ago(id == 'me' ? 0 : 16));
  }
  c.reactions['g6'] = [
    const Reaction(messageId: 'g6', userId: 'me', emoji: '🎉'),
    const Reaction(messageId: 'g6', userId: 'sam', emoji: '🎉'),
    const Reaction(messageId: 'g6', userId: 'ana', emoji: '❤️'),
  ];
  return c;
}

class EmojiSheet extends StatelessWidget {
  const EmojiSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Chibi emoji', style: TextStyle(fontFamily: kDisplayFont, fontSize: 30, fontWeight: FontWeight.w800, color: p.ink)),
            Text('${chibiAll.length} drawn in code', style: TextStyle(fontFamily: kMonoFont, fontSize: 14, color: p.muted)),
            const SizedBox(height: 10),
            Expanded(
              child: Wrap(spacing: 4, runSpacing: 4, children: [for (final d in chibiAll) Chibi(d, size: 30)]),
            ),
          ]),
        ),
      ),
    );
  }
}

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({'perms_asked': true, 'intro_seen': true});
    await Prefs.load();
    await loadFonts();
    previewUserId = 'me';
    for (final p in [me, leo, ana, sam, june, finn]) {
      Profiles.instance.put(p);
    }
  });

  testWidgets('language', (t) => shoot(t, 'language', LanguageScreen(onDone: () {})));
  testWidgets('welcome', (t) => shoot(t, 'welcome', const WelcomeScreen()));
  testWidgets('sign up', (t) => shoot(t, 'signup', const SignUpScreen()));
  testWidgets('permissions', (t) => shoot(t, 'permissions', PermissionsScreen(onDone: () {}), b: Brightness.dark));
  testWidgets('chats light', (t) => shoot(t, 'chats_light', HomeScreen(preview: chats())));
  testWidgets('chats dark', (t) => shoot(t, 'chats_dark', HomeScreen(preview: chats()), b: Brightness.dark));
  testWidgets('chats pt', (t) => shoot(t, 'chats_pt', HomeScreen(preview: chats()), lang: 'pt'));
  testWidgets('chat light', (t) => shoot(t, 'chat_light', ChatScreen(chatId: 'c1', preview: directChat())));
  testWidgets('chat dark', (t) async {
    Prefs.instance.chatBackground = true;
    await shoot(t, 'chat_dark', ChatScreen(chatId: 'c1', preview: directChat()), b: Brightness.dark);
    Prefs.instance.chatBackground = false;
  });
  testWidgets('group', (t) => shoot(t, 'group', ChatScreen(chatId: 'c2', preview: groupChat())));
  testWidgets('settings', (t) => shoot(t, 'settings', const SettingsScreen()));
  testWidgets('bubble studio', (t) => shoot(t, 'bubble_studio', const BubbleStudio(initial: BubbleStyle(shape: BubbleShape.fish)), b: Brightness.dark));
  testWidgets('call', (t) => shoot(
        t,
        'call',
        CallScreen(
          call: CallInfo(id: 'x', chatId: 'c1', startedBy: 'me', video: false, status: 'active', createdAt: now),
          title: 'Leo Park',
          outgoing: true,
          video: false,
          preview: true,
        ),
      ));
  testWidgets('admin', (t) => shoot(
        t,
        'admin',
        const AdminScreen(preview: {'users': 1284, 'active_today': 342, 'chats': 2931, 'messages': 48210, 'messages_today': 1876}),
      ));
  testWidgets('emoji', (t) => shoot(t, 'emoji', const EmojiSheet()));
}
