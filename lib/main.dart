import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'intro/boot_screen.dart';
import 'login_screen.dart';
import 'rooms_screen.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: const String.fromEnvironment('SUPABASE_URL'),
    publishableKey: const String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY'),
  );
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.transparent,
  ));
  debugPrint('working');
  runApp(const FishiApp());
}

final supabase = Supabase.instance.client;

class FishiApp extends StatelessWidget {
  const FishiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fishi',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.bg,
        colorScheme: const ColorScheme.dark(primary: AppColors.mine, onPrimary: AppColors.bg, surface: AppColors.bg),
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
        pageTransitionsTheme: const PageTransitionsTheme(builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        }),
      ),
      home: BootScreen(next: (_) => const Gate()),
    );
  }
}

class Gate extends StatefulWidget {
  const Gate({super.key});

  @override
  State<Gate> createState() => _GateState();
}

class _GateState extends State<Gate> {
  Map<String, dynamic>? _profile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = supabase.auth.currentUser;
    if (user != null) {
      try {
        _profile = await supabase.from('profiles').select().eq('id', user.id).maybeSingle();
      } catch (_) {}
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold();
    final profile = _profile;
    if (profile == null) {
      return LoginScreen(onDone: (p) => setState(() => _profile = p));
    }
    return RoomsScreen(profile: profile);
  }
}
