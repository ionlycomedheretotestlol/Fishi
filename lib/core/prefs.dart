import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Prefs extends ChangeNotifier {
  Prefs._(this._p);

  static late Prefs instance;
  final SharedPreferences _p;

  static Future<void> load() async {
    instance = Prefs._(await SharedPreferences.getInstance());
  }

  ThemeMode get themeMode => ThemeMode.values[_p.getInt('theme') ?? 0];
  set themeMode(ThemeMode v) {
    _p.setInt('theme', v.index);
    notifyListeners();
  }

  bool get introSeen => _p.getBool('intro_seen') ?? false;
  set introSeen(bool v) => _p.setBool('intro_seen', v);

  bool get permissionsAsked => _p.getBool('perms_asked') ?? false;
  set permissionsAsked(bool v) => _p.setBool('perms_asked', v);

  bool get chatBackground => _p.getBool('chat_bg') ?? false;
  set chatBackground(bool v) {
    _p.setBool('chat_bg', v);
    notifyListeners();
  }

  bool get notifications => _p.getBool('notifs') ?? true;
  set notifications(bool v) {
    _p.setBool('notifs', v);
    notifyListeners();
  }

  bool get sounds => _p.getBool('sounds') ?? true;
  set sounds(bool v) {
    _p.setBool('sounds', v);
    notifyListeners();
  }
}
