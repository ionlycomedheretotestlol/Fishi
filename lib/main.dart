import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth/auth_screens.dart';
import 'calls/call_center.dart';
import 'core/data.dart';
import 'core/inbox.dart';
import 'core/motion.dart';
import 'core/notify.dart';
import 'core/prefs.dart';
import 'core/theme.dart';
import 'home/home_screen.dart';
import 'intro/boot_screen.dart';
import 'intro/first_intro.dart';
import 'onboarding/permissions_screen.dart';
import 'ui/kit.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Prefs.load();
  await Supabase.initialize(
    url: const String.fromEnvironment('SUPABASE_URL'),
    publishableKey: const String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY'),
  );
  await Notify.init();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  runApp(const FishiApp());
}

class FishiApp extends StatefulWidget {
  const FishiApp({super.key});

  @override
  State<FishiApp> createState() => _FishiAppState();
}

class _FishiAppState extends State<FishiApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    Notify.foreground = state == AppLifecycleState.resumed;
    if (state == AppLifecycleState.resumed && myId != null) {
      Inbox.instance.touchSeen();
      Inbox.instance.refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Prefs.instance,
      builder: (context, _) => MaterialApp(
        title: 'Fishi',
        debugShowCheckedModeBanner: false,
        navigatorKey: navigatorKey,
        theme: buildTheme(Brightness.light),
        darkTheme: buildTheme(Brightness.dark),
        themeMode: Prefs.instance.themeMode,
        themeAnimationDuration: const Duration(milliseconds: 420),
        themeAnimationCurve: kSmooth,
        builder: (context, child) {
          final dark = Theme.of(context).brightness == Brightness.dark;
          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
              statusBarBrightness: dark ? Brightness.dark : Brightness.light,
              systemNavigationBarColor: Colors.transparent,
              systemNavigationBarIconBrightness: dark ? Brightness.light : Brightness.dark,
            ),
            child: child!,
          );
        },
        home: const Launch(),
      ),
    );
  }
}

class Launch extends StatelessWidget {
  const Launch({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Prefs.instance.introSeen) {
      return FirstIntro(onDone: () {
        Prefs.instance.introSeen = true;
        Navigator.of(context).pushReplacement(fadeRoute(BootScreen(next: (_) => const Gate())));
      });
    }
    return BootScreen(next: (_) => const Gate());
  }
}

enum _Stage { loading, signedOut, age, permissions, home }

class Gate extends StatefulWidget {
  const Gate({super.key});

  @override
  State<Gate> createState() => _GateState();
}

class _GateState extends State<Gate> {
  StreamSubscription<AuthState>? _auth;
  _Stage _stage = _Stage.loading;
  String? _startedFor;

  @override
  void initState() {
    super.initState();
    _auth = supa.auth.onAuthStateChange.listen((s) {
      if (s.event == AuthChangeEvent.signedOut) {
        _startedFor = null;
        CallCenter.instance.stop();
        Inbox.instance.stop();
      }
      _resolve();
    });
    _resolve();
  }

  @override
  void dispose() {
    _auth?.cancel();
    super.dispose();
  }

  Future<void> _resolve() async {
    final uid = myId;
    if (uid == null) {
      _set(_Stage.signedOut);
      return;
    }
    if (_startedFor != uid) {
      _startedFor = uid;
      _set(_Stage.loading);
      await Inbox.instance.start();
      CallCenter.instance.listen();
    }
    final me = Profiles.instance.me;
    if (me != null && !me.adultConfirmed) {
      _set(_Stage.age);
    } else if (!Prefs.instance.permissionsAsked) {
      _set(_Stage.permissions);
    } else {
      _set(_Stage.home);
    }
  }

  void _set(_Stage s) {
    if (mounted && s != _stage) setState(() => _stage = s);
  }

  @override
  Widget build(BuildContext context) {
    final child = switch (_stage) {
      _Stage.loading => const Scaffold(key: ValueKey('loading'), body: Center(child: Spinner())),
      _Stage.signedOut => const WelcomeScreen(key: ValueKey('welcome')),
      _Stage.age => AgeConfirmScreen(key: const ValueKey('age'), onDone: _resolve),
      _Stage.permissions => PermissionsScreen(key: const ValueKey('perms'), onDone: _resolve),
      _Stage.home => const HomeScreen(key: ValueKey('home')),
    };
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 560),
      switchInCurve: kSmooth,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (c, a) => FadeTransition(
        opacity: a,
        child: ScaleTransition(scale: Tween(begin: 0.96, end: 1.0).animate(a), child: c),
      ),
      child: child,
    );
  }
}
