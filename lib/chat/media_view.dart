import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

import '../core/data.dart';
import '../core/models.dart';
import '../core/theme.dart';
import 'message_view.dart';

class MediaViewer extends StatefulWidget {
  const MediaViewer({super.key, required this.message});

  final Message message;

  @override
  State<MediaViewer> createState() => _MediaViewerState();
}

class _MediaViewerState extends State<MediaViewer> with SingleTickerProviderStateMixin {
  late final AnimationController _drag = AnimationController.unbounded(vsync: this);
  final _tc = TransformationController();
  bool _chrome = true;

  @override
  void dispose() {
    _drag.dispose();
    _tc.dispose();
    super.dispose();
  }

  bool get _zoomed => _tc.value.getMaxScaleOnAxis() > 1.01;

  void _end(DragEndDetails d) {
    final v = d.primaryVelocity ?? 0;
    if (_drag.value.abs() > 120 || v.abs() > 900) {
      Navigator.of(context).pop();
      return;
    }
    _drag.animateWith(SpringSimulation(const SpringDescription(mass: 1, stiffness: 380, damping: 28), _drag.value, 0, v));
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.message;
    final sender = Profiles.instance[m.senderId];
    return AnimatedBuilder(
      animation: _drag,
      builder: (context, child) {
        final t = (1 - _drag.value.abs() / 400).clamp(0.0, 1.0);
        return Scaffold(
          backgroundColor: Colors.black.withValues(alpha: t),
          body: Stack(children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: () => setState(() => _chrome = !_chrome),
                onVerticalDragUpdate: _zoomed ? null : (d) => _drag.value += d.delta.dy,
                onVerticalDragEnd: _zoomed ? null : _end,
                child: Transform.translate(
                  offset: Offset(0, _drag.value),
                  child: Transform.scale(
                    scale: 0.85 + 0.15 * t,
                    child: InteractiveViewer(
                      transformationController: _tc,
                      maxScale: 5,
                      onInteractionEnd: (_) => setState(() {}),
                      child: Center(
                        child: Hero(tag: 'media-${m.id}', child: MediaImage(message: m, fit: BoxFit.contain)),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOutCubic,
              top: _chrome ? 0 : -120,
              left: 0,
              right: 0,
              child: Opacity(
                opacity: t,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(children: [
                      Tappable(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(color: Colors.white12, shape: BoxShape.circle),
                          child: const Icon(Icons.close_rounded, color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(m.mine ? 'You' : (sender?.displayName ?? ''), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                          Text(dayHeader(m.createdAt), style: const TextStyle(color: Colors.white60, fontSize: 13)),
                        ]),
                      ),
                    ]),
                  ),
                ),
              ),
            ),
          ]),
        );
      },
    );
  }
}
