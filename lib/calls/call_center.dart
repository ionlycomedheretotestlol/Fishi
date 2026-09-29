import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import '../core/data.dart';
import '../core/inbox.dart';
import '../core/models.dart';
import '../core/notify.dart';
import '../core/motion.dart';
import '../ui/kit.dart';
import 'call_screen.dart';
import 'incoming_call_screen.dart';

class CallCenter {
  CallCenter._();
  static final instance = CallCenter._();

  StreamSubscription<CallInfo>? _sub;
  final _updates = StreamController<CallInfo>.broadcast();
  Stream<CallInfo> get updates => _updates.stream;

  String? activeCallId;
  String? ringingId;
  Timer? _ringTimer;
  final _ring1 = AudioPlayer();
  final _ring2 = AudioPlayer();

  void listen() {
    _sub ??= Inbox.instance.calls.listen(_onCall);
  }

  void stop() {
    _sub?.cancel();
    _sub = null;
    _stopRing();
  }

  void _onCall(CallInfo c) {
    _updates.add(c);
    if (c.status == 'ringing' &&
        c.startedBy != myId &&
        activeCallId == null &&
        ringingId == null &&
        DateTime.now().difference(c.createdAt).inSeconds.abs() < 50) {
      _showIncoming(c);
    }
    if (c.status != 'ringing' && ringingId == c.id) {
      _stopRing();
      Notify.cancelCall(c.id);
    }
  }

  Future<void> showIncomingById(String id) async {
    try {
      final row = await supa.from('calls').select().eq('id', id).maybeSingle();
      if (row == null) return;
      final c = CallInfo.fromJson(row);
      if (c.status == 'ringing' && ringingId == null && activeCallId == null) _showIncoming(c);
    } catch (_) {}
  }

  Future<void> _showIncoming(CallInfo c) async {
    ringingId = c.id;
    await Profiles.instance.ensure([c.startedBy]);
    final caller = Profiles.instance[c.startedBy];
    final chat = Inbox.instance.chat(c.chatId);
    final title = chat?.isGroup == true ? '${caller?.displayName ?? 'Someone'} in ${chat!.title}' : (caller?.displayName ?? 'Someone');
    if (!Notify.foreground) Notify.call(callId: c.id, chatId: c.chatId, title: title, video: c.video);
    _startRing();
    final nav = navigatorKey.currentState;
    if (nav == null) return;
    await nav.push(fadeRoute(IncomingCallScreen(call: c, caller: caller, title: title)));
    if (ringingId == c.id) ringingId = null;
    _stopRing();
    Notify.cancelCall(c.id);
  }

  void _startRing() {
    _stopRing();
    for (final p in [_ring1, _ring2]) {
      p.setPlayerMode(PlayerMode.lowLatency);
    }
    void once() {
      _ring1.play(AssetSource('sounds/ding1.wav'));
      HapticFeedback.heavyImpact();
      Future.delayed(const Duration(milliseconds: 380), () {
        if (_ringTimer != null) _ring2.play(AssetSource('sounds/ding2.wav'));
      });
    }

    once();
    _ringTimer = Timer.periodic(const Duration(milliseconds: 1800), (_) => once());
  }

  void _stopRing() {
    _ringTimer?.cancel();
    _ringTimer = null;
    _ring1.stop();
    _ring2.stop();
  }

  Future<bool> _permissions(BuildContext context, bool video) async {
    final mic = await Permission.microphone.request();
    if (!mic.isGranted) {
      if (context.mounted) showToast(context, 'Fishi needs the microphone for calls.', error: true);
      return false;
    }
    if (video) {
      final cam = await Permission.camera.request();
      if (!cam.isGranted && context.mounted) showToast(context, 'Camera is off. Starting with voice only.');
    }
    return true;
  }

  Future<void> start(BuildContext context, String chatId, {required bool video, required String title}) async {
    if (activeCallId != null) {
      showToast(context, 'You are already in a call.');
      return;
    }
    if (!await _permissions(context, video)) return;
    try {
      final existing = await supa
          .from('calls')
          .select()
          .eq('chat_id', chatId)
          .inFilter('status', ['ringing', 'active'])
          .gte('created_at', DateTime.now().subtract(const Duration(hours: 2)).toUtc().toIso8601String())
          .order('created_at', ascending: false)
          .limit(1);
      CallInfo call;
      var joining = false;
      if (existing.isNotEmpty && Inbox.instance.chat(chatId)?.isGroup == true) {
        call = CallInfo.fromJson(existing.first);
        joining = true;
      } else {
        final row = await supa.from('calls').insert({'chat_id': chatId, 'video': video}).select().single();
        call = CallInfo.fromJson(row);
      }
      if (!context.mounted) return;
      await Navigator.of(context, rootNavigator: true).push(fadeRoute(CallScreen(call: call, title: title, outgoing: !joining, video: video)));
    } catch (_) {
      if (context.mounted) showToast(context, 'Could not start the call.', error: true);
    }
  }

  Future<void> accept(BuildContext context, CallInfo call, String title) async {
    _stopRing();
    Notify.cancelCall(call.id);
    if (!await _permissions(context, call.video)) return;
    try {
      await supa.from('calls').update({'status': 'active'}).eq('id', call.id).eq('status', 'ringing');
    } catch (_) {}
    if (!context.mounted) return;
    Navigator.of(context).pushReplacement(fadeRoute(CallScreen(call: call, title: title, outgoing: false, video: call.video)));
  }

  Future<void> decline(CallInfo call) async {
    _stopRing();
    Notify.cancelCall(call.id);
    final group = Inbox.instance.chat(call.chatId)?.isGroup ?? false;
    if (group) return;
    try {
      await supa.from('calls').update({'status': 'declined', 'ended_at': DateTime.now().toUtc().toIso8601String()}).eq('id', call.id).eq('status', 'ringing');
    } catch (_) {}
  }

  Future<void> finish(CallInfo call, {required bool connected, required Duration duration, required bool video, bool lastOut = true}) async {
    final now = DateTime.now().toUtc().toIso8601String();
    try {
      if (!connected) {
        final rows = await supa.from('calls').update({'status': 'missed', 'ended_at': now}).eq('id', call.id).eq('status', 'ringing').select();
        if (rows.isNotEmpty) {
          await supa.from('messages').insert({
            'chat_id': call.chatId,
            'kind': 'call',
            'body': video ? 'Missed video call' : 'Missed voice call',
            'media_meta': {'video': video, 'missed': true, 'call_id': call.id},
          });
        }
        return;
      }
      if (!lastOut) return;
      final rows = await supa.from('calls').update({'status': 'ended', 'ended_at': now}).eq('id', call.id).eq('status', 'active').select();
      if (rows.isNotEmpty) {
        final mins = duration.inMinutes;
        final secs = (duration.inSeconds % 60).toString().padLeft(2, '0');
        await supa.from('messages').insert({
          'chat_id': call.chatId,
          'kind': 'call',
          'body': '${video ? 'Video call' : 'Voice call'} · $mins:$secs',
          'media_meta': {'video': video, 'duration_s': duration.inSeconds, 'call_id': call.id},
        });
      }
    } catch (_) {}
  }
}
