import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'prefs.dart';

class Notify {
  Notify._();

  static final _plugin = FlutterLocalNotificationsPlugin();
  static final taps = StreamController<String>.broadcast();
  static bool _ready = false;
  static bool foreground = true;

  static const _messages = AndroidNotificationDetails(
    'messages',
    'Messages',
    channelDescription: 'New messages in your chats',
    importance: Importance.high,
    priority: Priority.high,
    icon: 'ic_notification',
    color: Color(0xFF141414),
    category: AndroidNotificationCategory.message,
  );

  static const _calls = AndroidNotificationDetails(
    'calls',
    'Calls',
    channelDescription: 'Incoming voice and video calls',
    importance: Importance.max,
    priority: Priority.max,
    icon: 'ic_notification',
    color: Color(0xFF141414),
    category: AndroidNotificationCategory.call,
    fullScreenIntent: true,
    ongoing: true,
    autoCancel: false,
    timeoutAfter: 45000,
  );

  static Future<void> init() async {
    if (_ready) return;
    try {
      await _plugin.initialize(
        settings: const InitializationSettings(android: AndroidInitializationSettings('ic_notification')),
        onDidReceiveNotificationResponse: (r) {
          final payload = r.payload;
          if (payload != null) taps.add(payload);
        },
      );
      _ready = true;
      final launch = await _plugin.getNotificationAppLaunchDetails();
      final payload = launch?.notificationResponse?.payload;
      if ((launch?.didNotificationLaunchApp ?? false) && payload != null) {
        Future.delayed(const Duration(seconds: 3), () => taps.add(payload));
      }
    } catch (_) {}
  }

  static Future<bool> requestPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    return (await android?.requestNotificationsPermission()) ?? false;
  }

  static int _idFor(String key) => key.hashCode & 0x7fffffff;

  static Future<void> message({required String chatId, required String title, required String body}) async {
    if (!_ready || !Prefs.instance.notifications) return;
    try {
      await _plugin.show(
        id: _idFor(chatId),
        title: title,
        body: body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _messages.channelId,
            _messages.channelName,
            channelDescription: _messages.channelDescription,
            importance: _messages.importance,
            priority: _messages.priority,
            icon: _messages.icon,
            color: _messages.color,
            category: _messages.category,
            playSound: Prefs.instance.sounds,
            styleInformation: BigTextStyleInformation(body),
            groupKey: 'fishi.messages',
          ),
        ),
        payload: 'chat:$chatId',
      );
    } catch (_) {}
  }

  static Future<void> call({required String callId, required String chatId, required String title, required bool video}) async {
    if (!_ready) return;
    try {
      await _plugin.show(
        id: _idFor(callId),
        title: title,
        body: video ? 'Incoming video call' : 'Incoming voice call',
        notificationDetails: const NotificationDetails(android: _calls),
        payload: 'call:$callId',
      );
    } catch (_) {}
  }

  static Future<void> cancelChat(String chatId) async {
    if (!_ready) return;
    try {
      await _plugin.cancel(id: _idFor(chatId));
    } catch (_) {}
  }

  static Future<void> cancelCall(String callId) async {
    if (!_ready) return;
    try {
      await _plugin.cancel(id: _idFor(callId));
    } catch (_) {}
  }
}
