import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../brand/avatar.dart';
import '../brand/send_bubble.dart';
import '../core/data.dart';
import '../core/inbox.dart';
import '../core/models.dart';
import '../core/motion.dart';
import '../core/theme.dart';
import '../emoji/emoji_text.dart';
import '../ui/kit.dart';
import 'chat_controller.dart';
import 'message_view.dart';
import 'voice.dart';
import '../core/i18n.dart';

class Composer extends StatefulWidget {
  const Composer({
    super.key,
    required this.controller,
    required this.text,
    required this.focus,
    required this.replyTo,
    required this.onCancelReply,
    required this.onSent,
  });

  final ChatController controller;
  final TextEditingController text;
  final FocusNode focus;
  final Message? replyTo;
  final VoidCallback onCancelReply;
  final VoidCallback onSent;

  @override
  State<Composer> createState() => _ComposerState();
}

class _ComposerState extends State<Composer> with TickerProviderStateMixin {
  bool _emoji = false;
  List<Profile> _suggest = [];

  final _rec = AudioRecorder();
  bool _recording = false;
  DateTime? _recStart;
  final List<double> _levels = [];
  StreamSubscription<Amplitude>? _ampSub;
  Timer? _recTick;

  @override
  void initState() {
    super.initState();
    widget.text.addListener(_onText);
    widget.focus.addListener(_onFocus);
  }

  @override
  void dispose() {
    widget.text.removeListener(_onText);
    widget.focus.removeListener(_onFocus);
    _ampSub?.cancel();
    _recTick?.cancel();
    _rec.dispose();
    super.dispose();
  }

  void _onFocus() {
    if (widget.focus.hasFocus && _emoji) setState(() => _emoji = false);
  }

  void _onText() {
    if (widget.text.text.isNotEmpty) widget.controller.typingPing();
    _updateSuggest();
    setState(() {});
  }

  void _updateSuggest() {
    final sel = widget.text.selection;
    final text = widget.text.text;
    final end = sel.isValid ? sel.baseOffset.clamp(0, text.length) : text.length;
    final before = text.substring(0, end);
    final m = RegExp(r'(^|\s)@([a-zA-Z0-9_]*)$').firstMatch(before);
    if (m == null) {
      if (_suggest.isNotEmpty) _suggest = [];
      return;
    }
    final q = m.group(2)!.toLowerCase();
    final people = <Profile>[
      ...widget.controller.memberProfiles.where((p) => p.id != myId && !p.isFinn),
    ];
    final finnId = Inbox.instance.finnId;
    final finn = finnId == null ? null : Profiles.instance[finnId];
    if (finn != null && !widget.controller.isFinn) people.insert(0, finn);
    _suggest = people
        .where((p) => q.isEmpty || p.username.startsWith(q) || p.displayName.toLowerCase().startsWith(q))
        .take(5)
        .toList();
  }

  void _insertMention(Profile p) {
    HapticFeedback.selectionClick();
    final text = widget.text.text;
    final sel = widget.text.selection;
    final end = sel.isValid ? sel.baseOffset.clamp(0, text.length) : text.length;
    final before = text.substring(0, end);
    final start = before.lastIndexOf('@');
    final next = '${text.substring(0, start)}@${p.username} ${text.substring(end)}';
    widget.text.value = TextEditingValue(text: next, selection: TextSelection.collapsed(offset: start + p.username.length + 2));
    setState(() => _suggest = []);
  }

  void _insertEmoji(String e) {
    HapticFeedback.selectionClick();
    final text = widget.text.text;
    final sel = widget.text.selection;
    final start = sel.isValid ? sel.start : text.length;
    final end = sel.isValid ? sel.end : text.length;
    widget.text.value = TextEditingValue(
      text: text.replaceRange(start, end, e),
      selection: TextSelection.collapsed(offset: start + e.length),
    );
  }

  void _send() {
    final t = widget.text.text;
    if (t.trim().isEmpty) return;
    HapticFeedback.lightImpact();
    widget.controller.sendText(t, replyTo: widget.replyTo?.id);
    widget.text.clear();
    widget.onCancelReply();
    widget.onSent();
  }

  Future<void> _attach() async {
    widget.focus.unfocus();
    final source = await Navigator.of(context).push<ImageSource>(sheetRoute(BottomSheetFrame(
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Section(children: [
          RowTile(icon: Icons.photo_library_outlined, title: tr('Photo library'), chevron: false, onTap: () => Navigator.of(context).pop(ImageSource.gallery)),
          RowTile(icon: Icons.photo_camera_outlined, title: tr('Take a photo'), chevron: false, onTap: () => Navigator.of(context).pop(ImageSource.camera)),
        ]),
      ]),
    )));
    if (source == null) return;
    try {
      final file = await ImagePicker().pickImage(source: source, maxWidth: 2048, maxHeight: 2048, imageQuality: 84);
      if (file == null) return;
      final bytes = await file.readAsBytes();
      var w = 3, h = 4;
      try {
        final codec = await ui.instantiateImageCodec(bytes);
        final frame = await codec.getNextFrame();
        w = frame.image.width;
        h = frame.image.height;
        frame.image.dispose();
      } catch (_) {}
      final ext = file.name.toLowerCase().endsWith('.png') ? 'png' : 'jpg';
      final caption = widget.text.text.trim();
      widget.text.clear();
      widget.controller.sendMedia(
        kind: 'image',
        bytes: bytes,
        ext: ext,
        contentType: ext == 'png' ? 'image/png' : 'image/jpeg',
        meta: {'w': w, 'h': h},
        caption: caption,
        replyTo: widget.replyTo?.id,
      );
      widget.onCancelReply();
      widget.onSent();
    } catch (_) {
      if (mounted) showToast(context, tr('Could not open photos.'), error: true);
    }
  }

  Future<void> _startRecording() async {
    try {
      if (!await _rec.hasPermission()) {
        if (mounted) showToast(context, tr('Allow the microphone to send voice notes.'), error: true);
        return;
      }
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await VoicePlayer.instance.stop();
      await _rec.start(const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 64000, sampleRate: 44100, numChannels: 1), path: path);
      HapticFeedback.mediumImpact();
      _levels.clear();
      _ampSub = _rec.onAmplitudeChanged(const Duration(milliseconds: 90)).listen((a) {
        final v = ((a.current + 48) / 48).clamp(0.04, 1.0);
        setState(() => _levels.add(v));
      });
      _recTick = Timer.periodic(const Duration(milliseconds: 250), (_) => setState(() {}));
      setState(() {
        _recording = true;
        _recStart = DateTime.now();
        _emoji = false;
      });
      widget.focus.unfocus();
    } catch (_) {
      if (mounted) showToast(context, tr('Could not start recording.'), error: true);
    }
  }

  Future<void> _stopRecording({required bool send}) async {
    _ampSub?.cancel();
    _recTick?.cancel();
    final started = _recStart;
    String? path;
    try {
      path = await _rec.stop();
    } catch (_) {}
    setState(() => _recording = false);
    if (!send || path == null || started == null) {
      HapticFeedback.lightImpact();
      return;
    }
    final ms = DateTime.now().difference(started).inMilliseconds;
    if (ms < 700) {
      if (mounted) showToast(context, tr('Hold on a little longer.'));
      return;
    }
    try {
      final bytes = await File(path).readAsBytes();
      const bars = 36;
      final wave = List<double>.generate(bars, (i) {
        if (_levels.isEmpty) return 0.2;
        final a = (i * _levels.length / bars).floor();
        final b = math.max(a + 1, ((i + 1) * _levels.length / bars).floor());
        final slice = _levels.sublist(a, math.min(b, _levels.length));
        return slice.isEmpty ? 0.1 : slice.reduce(math.max);
      }).map((v) => double.parse(v.toStringAsFixed(2))).toList();
      HapticFeedback.lightImpact();
      widget.controller.sendMedia(
        kind: 'audio',
        bytes: bytes,
        ext: 'm4a',
        contentType: 'audio/mp4',
        meta: {'duration_ms': ms, 'wave': wave},
        replyTo: widget.replyTo?.id,
      );
      widget.onCancelReply();
      widget.onSent();
    } catch (_) {
      if (mounted) showToast(context, tr('Could not send voice note.'), error: true);
    }
  }

  void _toggleEmoji() {
    HapticFeedback.selectionClick();
    if (_emoji) {
      setState(() => _emoji = false);
      widget.focus.requestFocus();
    } else {
      widget.focus.unfocus();
      setState(() => _emoji = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final hasText = widget.text.text.trim().isNotEmpty;
    final reply = widget.replyTo;
    return Glass(
      top: false,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: kSmooth,
          child: _suggest.isEmpty
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
                  child: Column(children: [
                    for (var i = 0; i < _suggest.length; i++)
                      Reveal(
                        key: ValueKey(_suggest[i].id),
                        delay: Duration(milliseconds: 30 * i),
                        offset: const Offset(0, 10),
                        child: Tappable(
                          scale: 0.98,
                          onTap: () => _insertMention(_suggest[i]),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
                            child: Row(children: [
                              _suggest[i].isFinn ? const FinnAvatar(size: 30) : Avatar(profile: _suggest[i], size: 30),
                              const SizedBox(width: 10),
                              Text(_suggest[i].displayName, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: p.ink)),
                              const SizedBox(width: 6),
                              Text('@${_suggest[i].username}', style: TextStyle(fontSize: 14, color: p.muted, fontFamily: kMonoFont)),
                            ]),
                          ),
                        ),
                      ),
                  ]),
                ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 320),
          curve: kSmooth,
          child: reply == null
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 10, 0),
                  child: Row(children: [
                    Container(width: 3, height: 34, decoration: BoxDecoration(color: p.ink, borderRadius: BorderRadius.circular(2))),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(
                          tr('Replying to {name}', {'name': reply.mine ? tr('yourself') : (reply.senderId == Inbox.instance.finnId ? 'Finn' : Profiles.instance[reply.senderId]?.displayName ?? '')}),
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: p.ink),
                        ),
                        EmojiText(snippet(reply), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13.5, color: p.muted)),
                      ]),
                    ),
                    CircleIcon(icon: Icons.close_rounded, size: 28, onTap: widget.onCancelReply),
                  ]),
                ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            switchInCurve: kSmooth,
            transitionBuilder: (c, a) => FadeTransition(
              opacity: a,
              child: SlideTransition(position: Tween(begin: const Offset(0, 0.3), end: Offset.zero).animate(a), child: c),
            ),
            child: _recording ? _recordBar(p) : _inputRow(p, hasText),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 340),
          curve: kSmooth,
          child: _emoji ? EmojiPicker(height: 290, onPick: _insertEmoji) : const SizedBox(width: double.infinity),
        ),
      ]),
    );
  }

  Widget _inputRow(Palette p, bool hasText) {
    return Row(key: const ValueKey('input'), crossAxisAlignment: CrossAxisAlignment.end, children: [
      Padding(
        padding: const EdgeInsets.only(bottom: 3),
        child: CircleIcon(icon: Icons.add_rounded, size: 38, onTap: _attach),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.only(left: 16, right: 4),
          decoration: BoxDecoration(
            color: p.card,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: p.line),
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 11),
                child: TextField(
                  controller: widget.text,
                  focusNode: widget.focus,
                  minLines: 1,
                  maxLines: 6,
                  textCapitalization: TextCapitalization.sentences,
                  keyboardType: TextInputType.multiline,
                  style: TextStyle(fontSize: 16.5, color: p.ink, height: 1.25),
                  decoration: InputDecoration(
                    isCollapsed: true,
                    border: InputBorder.none,
                    hintText: widget.controller.isFinn ? tr('Ask Finn') : tr('Message'),
                    hintStyle: TextStyle(color: p.muted, fontSize: 16.5),
                  ),
                ),
              ),
            ),
            _FieldIcon(icon: _emoji ? Icons.keyboard_outlined : Icons.sentiment_satisfied_alt_outlined, onTap: _toggleEmoji),
            AnimatedSize(
              duration: const Duration(milliseconds: 260),
              curve: kSmooth,
              child: hasText ? const SizedBox(height: 40) : _FieldIcon(icon: Icons.mic_none_rounded, onTap: _startRecording),
            ),
          ]),
        ),
      ),
      const SizedBox(width: 8),
      SendBubbleButton(enabled: hasText, onTap: _send),
    ]);
  }

  Widget _recordBar(Palette p) {
    final started = _recStart ?? DateTime.now();
    final elapsed = DateTime.now().difference(started);
    return Row(key: const ValueKey('rec'), children: [
      CircleIcon(icon: Icons.delete_outline_rounded, size: 40, onTap: () => _stopRecording(send: false)),
      const SizedBox(width: 8),
      Expanded(
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(22), border: Border.all(color: p.line)),
          child: Row(children: [
            _Pulse(color: p.danger),
            const SizedBox(width: 10),
            Text(clock(elapsed), style: TextStyle(fontSize: 15, color: p.ink, fontFamily: kMonoFont)),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 26,
                child: CustomPaint(
                  painter: WavePainter(
                    wave: _levels.length > 40 ? _levels.sublist(_levels.length - 40) : _levels,
                    progress: 1,
                    color: p.ink,
                  ),
                ),
              ),
            ),
          ]),
        ),
      ),
      const SizedBox(width: 8),
      SendBubbleButton(enabled: true, onTap: () => _stopRecording(send: true)),
    ]);
  }
}

class _FieldIcon extends StatelessWidget {
  const _FieldIcon({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Tappable(
      scale: 0.82,
      onTap: onTap,
      child: SizedBox(
        width: 38,
        height: 42,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          transitionBuilder: (c, a) => RotationTransition(turns: Tween(begin: 0.8, end: 1.0).animate(a), child: ScaleTransition(scale: a, child: c)),
          child: Icon(icon, key: ValueKey(icon), color: p.muted, size: 23),
        ),
      ),
    );
  }
}

class _Pulse extends StatefulWidget {
  const _Pulse({required this.color});
  final Color color;

  @override
  State<_Pulse> createState() => _PulseState();
}

class _PulseState extends State<_Pulse> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.35, end: 1.0).animate(_c),
      child: ScaleTransition(
        scale: Tween(begin: 0.8, end: 1.1).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut)),
        child: Container(width: 10, height: 10, decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle)),
      ),
    );
  }
}
