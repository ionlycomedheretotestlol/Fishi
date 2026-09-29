import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:livekit_client/livekit_client.dart';

import '../brand/avatar.dart';
import '../core/data.dart';
import '../core/inbox.dart';
import '../core/models.dart';
import '../core/motion.dart';
import '../core/theme.dart';
import 'call_center.dart';
import '../core/i18n.dart';

class CallScreen extends StatefulWidget {
  const CallScreen({super.key, required this.call, required this.title, required this.outgoing, required this.video, this.preview = false});

  final CallInfo call;
  final String title;
  final bool outgoing;
  final bool video;
  final bool preview;

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> with TickerProviderStateMixin {
  Room? _room;
  EventsListener<RoomEvent>? _events;
  StreamSubscription<CallInfo>? _updates;
  Timer? _clock;
  Timer? _timeout;
  bool _connected = false;
  bool _ended = false;
  bool _mic = true;
  late bool _cam = widget.video;
  late bool _speaker = widget.video;
  bool _front = true;
  String _status = '';
  DateTime? _since;
  Duration _elapsed = Duration.zero;
  late final AnimationController _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))..repeat();
  late final AnimationController _pip = AnimationController.unbounded(vsync: this);
  Offset _pipPos = const Offset(-1, -1);
  Offset _pipFrom = Offset.zero;
  Offset _pipTo = Offset.zero;

  @override
  void initState() {
    super.initState();
    _status = widget.outgoing ? tr('Calling...') : tr('Connecting...');
    if (widget.preview) {
      _status = '';
      _connected = true;
      _since = DateTime.now().subtract(const Duration(minutes: 2, seconds: 14));
      _elapsed = const Duration(minutes: 2, seconds: 14);
      return;
    }
    CallCenter.instance.activeCallId = widget.call.id;
    _updates = CallCenter.instance.updates.where((c) => c.id == widget.call.id).listen(_onUpdate);
    _join();
    if (widget.outgoing) {
      _timeout = Timer(const Duration(seconds: 45), () {
        if (!_connected) _hangUp(reason: tr('No answer'));
      });
    }
    _pip.addListener(() {
      final t = _pip.value;
      setState(() => _pipPos = Offset.lerp(_pipFrom, _pipTo, t)!);
    });
  }

  void _onUpdate(CallInfo c) {
    if (c.status == 'declined') _end(tr('Declined'));
    if (c.status == 'missed' && !_connected) _end(tr('No answer'));
    if (c.status == 'ended' && (_room?.remoteParticipants.isEmpty ?? true)) _end(tr('Call ended'));
    if (c.status == 'active' && widget.outgoing && !_connected) setState(() => _status = tr('Connecting...'));
  }

  Future<void> _join() async {
    try {
      final res = await supa.functions.invoke('livekit-token', body: {'chat_id': widget.call.chatId});
      final data = (res.data as Map).cast<String, dynamic>();
      final room = Room(roomOptions: const RoomOptions(adaptiveStream: true, dynacast: true));
      _room = room;
      _events = room.createListener()
        ..on<ParticipantConnectedEvent>((_) => _refresh())
        ..on<ParticipantDisconnectedEvent>((_) {
          _refresh();
          if (room.remoteParticipants.isEmpty && _connected) _hangUp();
        })
        ..on<TrackSubscribedEvent>((_) => _refresh())
        ..on<TrackUnsubscribedEvent>((_) => _refresh())
        ..on<TrackMutedEvent>((_) => _refresh())
        ..on<TrackUnmutedEvent>((_) => _refresh())
        ..on<ActiveSpeakersChangedEvent>((_) => _refresh())
        ..on<RoomDisconnectedEvent>((_) {
          if (!_ended) _end(tr('Call ended'));
        });
      await room.connect(data['url'] as String, data['token'] as String);
      await room.localParticipant?.setMicrophoneEnabled(true);
      if (_cam) {
        try {
          await room.localParticipant?.setCameraEnabled(true);
        } catch (_) {
          _cam = false;
        }
      }
      try {
        await AudioManager.instance.setSpeakerOutputPreferred(_speaker);
      } catch (_) {}
      if (widget.outgoing) {
        _status = tr('Ringing...');
      }
      _refresh();
    } catch (_) {
      _end(tr('Could not connect'));
    }
  }

  void _refresh() {
    if (!mounted || _ended) return;
    final room = _room;
    if (room != null && room.remoteParticipants.isNotEmpty && !_connected) {
      _connected = true;
      _since = DateTime.now();
      _timeout?.cancel();
      HapticFeedback.mediumImpact();
      _clock = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() => _elapsed = DateTime.now().difference(_since!));
      });
    }
    setState(() {});
  }

  Future<void> _hangUp({String? reason}) async {
    if (_ended) return;
    HapticFeedback.mediumImpact();
    final room = _room;
    final others = room?.remoteParticipants.length ?? 0;
    CallCenter.instance.finish(
      widget.call,
      connected: _connected,
      duration: _elapsed,
      video: widget.video,
      lastOut: others <= 1,
    );
    _end(reason ?? tr('Call ended'));
  }

  Future<void> _end(String reason) async {
    if (_ended) return;
    _ended = true;
    _clock?.cancel();
    _timeout?.cancel();
    if (mounted) setState(() => _status = reason);
    final room = _room;
    _room = null;
    await _events?.dispose();
    try {
      await room?.disconnect();
      await room?.dispose();
    } catch (_) {}
    if (CallCenter.instance.activeCallId == widget.call.id) CallCenter.instance.activeCallId = null;
    await Future.delayed(const Duration(milliseconds: 900));
    if (mounted) Navigator.of(context).maybePop();
  }

  @override
  void dispose() {
    _updates?.cancel();
    _clock?.cancel();
    _timeout?.cancel();
    _pulse.dispose();
    _pip.dispose();
    if (!_ended && !widget.preview) {
      _ended = true;
      CallCenter.instance.finish(widget.call, connected: _connected, duration: _elapsed, video: widget.video, lastOut: (_room?.remoteParticipants.length ?? 0) <= 1);
      _events?.dispose();
      _room?.disconnect();
      if (CallCenter.instance.activeCallId == widget.call.id) CallCenter.instance.activeCallId = null;
    }
    super.dispose();
  }

  Future<void> _toggleMic() async {
    _mic = !_mic;
    setState(() {});
    await _room?.localParticipant?.setMicrophoneEnabled(_mic);
  }

  Future<void> _toggleCam() async {
    _cam = !_cam;
    setState(() {});
    try {
      await _room?.localParticipant?.setCameraEnabled(_cam);
    } catch (_) {
      setState(() => _cam = false);
    }
  }

  Future<void> _flip() async {
    _front = !_front;
    final track = _room?.localParticipant?.videoTrackPublications.firstOrNull?.track;
    try {
      await track?.setCameraPosition(_front ? CameraPosition.front : CameraPosition.back);
    } catch (_) {}
    setState(() {});
  }

  Future<void> _toggleSpeaker() async {
    _speaker = !_speaker;
    setState(() {});
    try {
      await AudioManager.instance.setSpeakerOutputPreferred(_speaker);
    } catch (_) {}
  }

  VideoTrack? _remoteVideo() {
    final room = _room;
    if (room == null) return null;
    for (final p in room.remoteParticipants.values) {
      for (final pub in p.videoTrackPublications) {
        final t = pub.track;
        if (t != null && !pub.muted && pub.subscribed) return t;
      }
    }
    return null;
  }

  VideoTrack? _localVideo() {
    if (!_cam) return null;
    return _room?.localParticipant?.videoTrackPublications.firstOrNull?.track;
  }

  void _snapPip(Size screen, Size pip, EdgeInsets pad) {
    final left = 16.0;
    final right = screen.width - pip.width - 16;
    final top = pad.top + 16;
    final bottom = screen.height - pip.height - pad.bottom - 150;
    final x = _pipPos.dx + pip.width / 2 < screen.width / 2 ? left : right;
    final y = _pipPos.dy + pip.height / 2 < screen.height / 2 ? top : bottom;
    _pipFrom = _pipPos;
    _pipTo = Offset(x, y);
    _pip.value = 0;
    _pip.animateWith(SpringSimulation(const SpringDescription(mass: 1, stiffness: 260, damping: 22), 0, 1, 0));
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final size = mq.size;
    final remote = _remoteVideo();
    final local = _localVideo();
    final chat = Inbox.instance.chat(widget.call.chatId);
    final peer = chat?.other;
    final group = chat?.isGroup ?? false;
    const pipSize = Size(108, 156);
    if (_pipPos.dx < 0) _pipPos = Offset(size.width - pipSize.width - 16, mq.padding.top + 16);
    final count = (_room?.remoteParticipants.length ?? 0) + 1;

    return Theme(
      data: buildTheme(Brightness.dark),
      child: Scaffold(
        backgroundColor: const Color(0xFF0B0B0C),
        body: Stack(children: [
          Positioned.fill(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child: remote != null
                  ? VideoTrackRenderer(remote, key: ValueKey(remote.sid), fit: VideoViewFit.cover)
                  : _AvatarStage(
                      key: const ValueKey('stage'),
                      pulse: _pulse,
                      ringing: !_connected,
                      child: group ? Avatar(name: widget.title, size: 132, group: true) : Avatar(profile: peer, name: widget.title, size: 132),
                    ),
            ),
          ),
          Positioned(
            top: mq.padding.top + (remote != null ? 16 : size.height * 0.1 + 170),
            left: 24,
            right: 24,
            child: Reveal(
              delay: const Duration(milliseconds: 150),
              child: Column(children: [
                Text(widget.title,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontFamily: kDisplayFont, fontSize: remote != null ? 22 : 30, fontWeight: FontWeight.w800, color: Colors.white, shadows: const [Shadow(blurRadius: 12, color: Colors.black54)])),
                const SizedBox(height: 6),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  child: Text(
                    _connected && !_ended ? '${_fmt(_elapsed)}${group ? '  ·  ${tr('{n} in call', {'n': count})}' : ''}' : _status,
                    key: ValueKey(_connected && !_ended ? 'clock' : _status),
                    style: TextStyle(fontSize: 16, color: Colors.white.withValues(alpha: 0.75)),
                  ),
                ),
              ]),
            ),
          ),
          if (local != null)
            Positioned(
              left: _pipPos.dx,
              top: _pipPos.dy,
              child: GestureDetector(
                onPanUpdate: (d) => setState(() => _pipPos += d.delta),
                onPanEnd: (_) => _snapPip(size, pipSize, mq.padding),
                onDoubleTap: _flip,
                child: Reveal(
                  scale: 0.5,
                  child: Container(
                    width: pipSize.width,
                    height: pipSize.height,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white24, width: 1.5),
                      boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 18)],
                    ),
                    child: VideoTrackRenderer(local, fit: VideoViewFit.cover, mirrorMode: _front ? VideoViewMirrorMode.mirror : VideoViewMirrorMode.off),
                  ),
                ),
              ),
            ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                child: Container(
                  padding: EdgeInsets.fromLTRB(20, 18, 20, mq.padding.bottom + 22),
                  color: Colors.black.withValues(alpha: 0.35),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                    _Control(index: 0, icon: _mic ? Icons.mic_rounded : Icons.mic_off_rounded, on: !_mic, label: _mic ? tr('Mute') : tr('Unmute'), onTap: _toggleMic),
                    _Control(index: 1, icon: _cam ? Icons.videocam_rounded : Icons.videocam_off_rounded, on: _cam, label: tr('Camera'), onTap: _toggleCam),
                    if (_cam) _Control(index: 2, icon: Icons.cameraswitch_rounded, on: false, label: tr('Flip'), onTap: _flip),
                    _Control(index: 3, icon: _speaker ? Icons.volume_up_rounded : Icons.hearing_rounded, on: _speaker, label: tr('Speaker'), onTap: _toggleSpeaker),
                    _Control(index: 4, icon: Icons.call_end_rounded, danger: true, on: false, label: tr('End'), onTap: () => widget.preview ? Navigator.of(context).maybePop() : _hangUp()),
                  ]),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  String _fmt(Duration d) {
    final h = d.inHours;
    final m = (d.inMinutes % 60).toString().padLeft(h > 0 ? 2 : 1, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }
}

class _AvatarStage extends StatelessWidget {
  const _AvatarStage({super.key, required this.pulse, required this.ringing, required this.child});

  final Animation<double> pulse;
  final bool ringing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(center: Alignment(0, -0.35), radius: 1.1, colors: [Color(0xFF2A2A2D), Color(0xFF0B0B0C)]),
      ),
      child: Stack(children: [
        Positioned(
          top: MediaQuery.paddingOf(context).top + size.height * 0.1,
          left: 0,
          right: 0,
          child: SizedBox(
            height: 150,
            child: Stack(alignment: Alignment.center, children: [
              for (var i = 0; i < 3; i++)
                AnimatedBuilder(
                  animation: pulse,
                  builder: (context, _) {
                    final t = (pulse.value + i / 3) % 1;
                    return Opacity(
                      opacity: ringing ? (1 - t) * 0.35 : 0.0,
                      child: Transform.scale(
                        scale: 1 + t * 0.9,
                        child: Container(
                          width: 132,
                          height: 132,
                          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.5)),
                        ),
                      ),
                    );
                  },
                ),
              Reveal(scale: 0.6, duration: const Duration(milliseconds: 800), child: child),
            ]),
          ),
        ),
      ]),
    );
  }
}

class _Control extends StatelessWidget {
  const _Control({required this.index, required this.icon, required this.on, required this.label, required this.onTap, this.danger = false});

  final int index;
  final IconData icon;
  final bool on;
  final bool danger;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Reveal(
      delay: Duration(milliseconds: 200 + index * 50),
      offset: const Offset(0, 40),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            curve: kSmooth,
            width: danger ? 64 : 56,
            height: danger ? 64 : 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: danger ? const Color(0xFFEA4A45) : (on ? Colors.white : Colors.white.withValues(alpha: 0.14)),
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
              child: Icon(icon, key: ValueKey(icon), color: danger ? Colors.white : (on ? Colors.black : Colors.white), size: danger ? 30 : 26),
            ),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.white70)),
        ]),
      ),
    );
  }
}
