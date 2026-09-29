import 'dart:async';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/data.dart';
import '../core/models.dart';
import '../core/theme.dart';

class VoicePlayer extends ChangeNotifier {
  VoicePlayer._();

  static final instance = VoicePlayer._();
  AudioPlayer? _audio;
  AudioPlayer get _player => _audio ??= _create();
  String? current;
  bool loading = false;
  Duration position = Duration.zero;
  Duration duration = Duration.zero;

  AudioPlayer _create() {
    final player = AudioPlayer();
    player.onPositionChanged.listen((p) {
      position = p;
      notifyListeners();
    });
    player.onDurationChanged.listen((d) {
      duration = d;
      notifyListeners();
    });
    player.onPlayerComplete.listen((_) {
      current = null;
      position = Duration.zero;
      notifyListeners();
    });
    return player;
  }

  Future<void> toggle(Message m) async {
    if (current == m.id) {
      await _player.stop();
      current = null;
      position = Duration.zero;
      notifyListeners();
      return;
    }
    await _player.stop();
    current = m.id;
    position = Duration.zero;
    duration = Duration(milliseconds: (m.mediaMeta['duration_ms'] as num?)?.toInt() ?? 0);
    loading = true;
    notifyListeners();
    try {
      if (m.localBytes != null) {
        await _player.play(BytesSource(m.localBytes!, mimeType: 'audio/mp4'));
      } else {
        final url = await MediaUrls.get(m.mediaPath!);
        if (url == null) throw Exception('no url');
        await _player.play(UrlSource(url));
      }
    } catch (_) {
      current = null;
    }
    loading = false;
    notifyListeners();
  }

  Future<void> stop() async {
    await _audio?.stop();
    current = null;
    notifyListeners();
  }
}

String clock(Duration d) => '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

List<double> waveOf(Message m) {
  final raw = m.mediaMeta['wave'];
  if (raw is List && raw.isNotEmpty) return raw.map((e) => (e as num).toDouble().clamp(0.05, 1.0)).toList();
  final rnd = math.Random(m.id.hashCode);
  return List.generate(32, (_) => 0.15 + rnd.nextDouble() * 0.7);
}

class VoiceBubbleBody extends StatelessWidget {
  const VoiceBubbleBody({super.key, required this.message, required this.color});

  final Message message;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final vp = VoicePlayer.instance;
    return ListenableBuilder(
      listenable: vp,
      builder: (context, _) {
        final playing = vp.current == message.id;
        final total = Duration(milliseconds: (message.mediaMeta['duration_ms'] as num?)?.toInt() ?? 0);
        final dur = playing && vp.duration > Duration.zero ? vp.duration : total;
        final progress = playing && dur.inMilliseconds > 0 ? (vp.position.inMilliseconds / dur.inMilliseconds).clamp(0.0, 1.0) : 0.0;
        return SizedBox(
          width: 210,
          child: Row(children: [
            GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                vp.toggle(message);
              },
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(shape: BoxShape.circle, color: color.withValues(alpha: 0.16)),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
                  child: Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded, key: ValueKey(playing), color: color, size: 22),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SizedBox(
                height: 30,
                child: CustomPaint(painter: WavePainter(wave: waveOf(message), progress: progress, color: color)),
              ),
            ),
            const SizedBox(width: 8),
            Text(clock(playing ? vp.position : total), style: TextStyle(fontSize: 12.5, color: color)),
          ]),
        );
      },
    );
  }
}

class WavePainter extends CustomPainter {
  WavePainter({required this.wave, required this.progress, required this.color});

  final List<double> wave;
  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (wave.isEmpty) return;
    final n = wave.length;
    final gap = size.width / n;
    final w = math.max(2.0, gap * 0.55);
    for (var i = 0; i < n; i++) {
      final h = math.max(3.0, wave[i] * size.height);
      final x = i * gap + gap / 2;
      final done = (i + 0.5) / n <= progress;
      canvas.drawLine(
        Offset(x, (size.height - h) / 2),
        Offset(x, (size.height + h) / 2),
        Paint()
          ..color = done ? color : color.withValues(alpha: 0.38)
          ..strokeWidth = w
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(WavePainter old) => old.progress != progress || old.color != color || old.wave != wave;
}
