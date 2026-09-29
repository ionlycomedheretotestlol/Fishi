import 'package:flutter/material.dart';

import 'faces.dart';
import 'hands.dart';
import 'pen.dart';
import 'things.dart';

typedef Draw = void Function(Pen k);

class ChibiDef {
  const ChibiDef(this.char, this.name, this.group, this.draw);

  final String char;
  final String name;
  final String group;
  final Draw draw;
}

ChibiDef _f(String char, String name, FaceSpec spec, [String group = 'Faces']) =>
    ChibiDef(char, name, group, (k) => drawFace(k, spec));

ChibiDef _t(String char, String name, String group, Draw draw) => ChibiDef(char, name, group, draw);

final List<ChibiDef> chibiAll = [
  _f('😀', 'grinning', const FaceSpec(l: Eye.dot, mouth: Mouth.grin)),
  _f('😃', 'smiley', const FaceSpec(l: Eye.big, mouth: Mouth.bigSmile)),
  _f('😄', 'smile', const FaceSpec(l: Eye.happy, mouth: Mouth.bigSmile, extras: [Extra.blush])),
  _f('😁', 'beaming', const FaceSpec(l: Eye.happy, mouth: Mouth.beam)),
  _f('😆', 'laughing', const FaceSpec(l: Eye.squeeze, mouth: Mouth.bigSmile)),
  _f('😅', 'sweat smile', const FaceSpec(l: Eye.happy, mouth: Mouth.bigSmile, extras: [Extra.sweat])),
  _f('😂', 'joy', const FaceSpec(l: Eye.squeeze, mouth: Mouth.bigSmile, extras: [Extra.streams])),
  _f('🤣', 'rolling', const FaceSpec(l: Eye.squeeze, mouth: Mouth.bigSmile, extras: [Extra.streams], tilt: -24)),
  _f('🙂', 'slight smile', const FaceSpec(l: Eye.dot, mouth: Mouth.smile)),
  _f('🙃', 'upside down', const FaceSpec(l: Eye.dot, mouth: Mouth.smile, tilt: 180)),
  _f('😉', 'wink', const FaceSpec(l: Eye.dot, r: Eye.happy, mouth: Mouth.smile)),
  _f('😊', 'blush', const FaceSpec(l: Eye.closed, mouth: Mouth.smile, extras: [Extra.blush])),
  _f('😇', 'angel', const FaceSpec(l: Eye.closed, mouth: Mouth.smile, extras: [Extra.halo, Extra.blush])),
  _f('🥰', 'in love', const FaceSpec(l: Eye.closed, mouth: Mouth.smile, extras: [Extra.blush, Extra.hearts])),
  _f('😍', 'heart eyes', const FaceSpec(l: Eye.heart, mouth: Mouth.bigSmile)),
  _f('🤩', 'star struck', const FaceSpec(l: Eye.star, mouth: Mouth.grin)),
  _f('😘', 'blow kiss', const FaceSpec(l: Eye.dot, r: Eye.happy, mouth: Mouth.kiss, extras: [Extra.heartKiss])),
  _f('😗', 'kissing', const FaceSpec(l: Eye.dot, mouth: Mouth.kiss)),
  _f('😚', 'kiss closed', const FaceSpec(l: Eye.closed, mouth: Mouth.kiss, extras: [Extra.blush])),
  _f('😋', 'yum', const FaceSpec(l: Eye.happy, mouth: Mouth.tongue, extras: [Extra.blush])),
  _f('😛', 'tongue', const FaceSpec(l: Eye.dot, mouth: Mouth.tongue)),
  _f('😜', 'wink tongue', const FaceSpec(l: Eye.dot, r: Eye.happy, mouth: Mouth.tongue)),
  _f('🤪', 'zany', const FaceSpec(l: Eye.wide, r: Eye.dot, mouth: Mouth.tongue, tilt: -8)),
  _f('😝', 'squint tongue', const FaceSpec(l: Eye.squeeze, mouth: Mouth.tongue)),
  _f('🤗', 'hug', const FaceSpec(l: Eye.happy, mouth: Mouth.smile, extras: [Extra.blush, Extra.hug])),
  _f('🤭', 'giggle', const FaceSpec(l: Eye.happy, mouth: Mouth.none, extras: [Extra.blush, Extra.handMouth])),
  _f('🤫', 'shush', const FaceSpec(l: Eye.dot, mouth: Mouth.none, extras: [Extra.shush])),
  _f('🤔', 'thinking', const FaceSpec(l: Eye.side, mouth: Mouth.flat, brow: Brow.raised, extras: [Extra.handChin])),
  _f('🤐', 'zipped', const FaceSpec(l: Eye.dot, mouth: Mouth.zip)),
  _f('🤨', 'raised brow', const FaceSpec(l: Eye.dot, mouth: Mouth.flat, brow: Brow.raised)),
  _f('😐', 'neutral', const FaceSpec(l: Eye.dot, mouth: Mouth.flat)),
  _f('😑', 'blank', const FaceSpec(l: Eye.line, mouth: Mouth.flat)),
  _f('😶', 'no mouth', const FaceSpec(l: Eye.dot, mouth: Mouth.none)),
  _f('😏', 'smirk', const FaceSpec(l: Eye.half, mouth: Mouth.smirk)),
  _f('😒', 'unamused', const FaceSpec(l: Eye.half, mouth: Mouth.frown)),
  _f('🙄', 'eye roll', const FaceSpec(l: Eye.up, mouth: Mouth.flat)),
  _f('😬', 'grimace', const FaceSpec(l: Eye.dot, mouth: Mouth.teeth)),
  _f('😌', 'relieved', const FaceSpec(l: Eye.closed, mouth: Mouth.smile, brow: Brow.worried)),
  _f('😔', 'pensive', const FaceSpec(l: Eye.down, mouth: Mouth.frown, brow: Brow.sad)),
  _f('😪', 'sleepy', const FaceSpec(l: Eye.down, mouth: Mouth.small, extras: [Extra.snot])),
  _f('🤤', 'drooling', const FaceSpec(l: Eye.closed, mouth: Mouth.drool)),
  _f('😴', 'sleeping', const FaceSpec(l: Eye.down, mouth: Mouth.small, extras: [Extra.zzz])),
  _f('😷', 'mask', const FaceSpec(l: Eye.closed, mouth: Mouth.none, extras: [Extra.mask])),
  _f('🤒', 'fever', const FaceSpec(l: Eye.dot, mouth: Mouth.small, brow: Brow.sad, extras: [Extra.thermometer, Extra.hot])),
  _f('🤕', 'hurt', const FaceSpec(l: Eye.dot, mouth: Mouth.frown, brow: Brow.sad, extras: [Extra.bandage])),
  _f('🤢', 'nauseated', const FaceSpec(l: Eye.squeeze, mouth: Mouth.wavy, extras: [Extra.nausea])),
  _f('🤮', 'vomiting', const FaceSpec(l: Eye.squeeze, mouth: Mouth.bigO, extras: [Extra.nausea, Extra.vomit])),
  _f('🤧', 'sneezing', const FaceSpec(l: Eye.squeeze, mouth: Mouth.none, extras: [Extra.tissue])),
  _f('🥵', 'hot', const FaceSpec(l: Eye.down, mouth: Mouth.tongue, extras: [Extra.hot, Extra.sweats])),
  _f('🥶', 'cold', const FaceSpec(l: Eye.dot, mouth: Mouth.teeth, brow: Brow.sad, extras: [Extra.icicles])),
  _f('🥴', 'woozy', const FaceSpec(l: Eye.half, r: Eye.down, mouth: Mouth.wavy, extras: [Extra.blush], tilt: 10)),
  _f('😵', 'dizzy', const FaceSpec(l: Eye.x, mouth: Mouth.open, extras: [Extra.dizzy])),
  _f('🤯', 'mind blown', const FaceSpec(l: Eye.wide, mouth: Mouth.bigO, extras: [Extra.explode])),
  _f('🤠', 'cowboy', const FaceSpec(l: Eye.dot, mouth: Mouth.grin, extras: [Extra.cowboy])),
  _f('🥳', 'party', const FaceSpec(l: Eye.closed, mouth: Mouth.none, extras: [Extra.blush, Extra.party])),
  _f('😎', 'cool', const FaceSpec(l: Eye.dot, mouth: Mouth.smile, extras: [Extra.sunglasses])),
  _f('🤓', 'nerd', const FaceSpec(l: Eye.dot, mouth: Mouth.buck, extras: [Extra.glasses])),
  _f('🧐', 'monocle', const FaceSpec(l: Eye.dot, r: Eye.wide, mouth: Mouth.flat, brow: Brow.raised, extras: [Extra.monocle])),
  _f('😕', 'confused', const FaceSpec(l: Eye.dot, mouth: Mouth.confused)),
  _f('😟', 'worried', const FaceSpec(l: Eye.dot, mouth: Mouth.frown, brow: Brow.worried)),
  _f('🙁', 'slight frown', const FaceSpec(l: Eye.dot, mouth: Mouth.frown)),
  _f('😮', 'open mouth', const FaceSpec(l: Eye.dot, mouth: Mouth.open)),
  _f('😯', 'hushed', const FaceSpec(l: Eye.dot, mouth: Mouth.small, brow: Brow.worried)),
  _f('😲', 'astonished', const FaceSpec(l: Eye.wide, mouth: Mouth.bigO)),
  _f('😳', 'flushed', const FaceSpec(l: Eye.wide, mouth: Mouth.flat, extras: [Extra.blush])),
  _f('🥺', 'pleading', const FaceSpec(l: Eye.teary, mouth: Mouth.frown, brow: Brow.worried)),
  _f('😦', 'frowning', const FaceSpec(l: Eye.dot, mouth: Mouth.openFrown)),
  _f('😧', 'anguished', const FaceSpec(l: Eye.dot, mouth: Mouth.openFrown, brow: Brow.sad)),
  _f('😨', 'fearful', const FaceSpec(l: Eye.dot, mouth: Mouth.openFrown, brow: Brow.worried, extras: [Extra.fear])),
  _f('😰', 'anxious', const FaceSpec(l: Eye.dot, mouth: Mouth.openFrown, brow: Brow.sad, extras: [Extra.fear, Extra.sweat])),
  _f('😥', 'sad relieved', const FaceSpec(l: Eye.down, mouth: Mouth.frown, brow: Brow.sad, extras: [Extra.sweat])),
  _f('😢', 'crying', const FaceSpec(l: Eye.dot, mouth: Mouth.frown, brow: Brow.sad, extras: [Extra.tear])),
  _f('😭', 'sobbing', const FaceSpec(l: Eye.squeeze, mouth: Mouth.bigO, extras: [Extra.streams])),
  _f('😱', 'scream', const FaceSpec(l: Eye.wide, mouth: Mouth.longO, extras: [Extra.fear, Extra.cheeks])),
  _f('😖', 'confounded', const FaceSpec(l: Eye.squeeze, mouth: Mouth.wavy)),
  _f('😣', 'persevering', const FaceSpec(l: Eye.squeeze, mouth: Mouth.tight)),
  _f('😞', 'disappointed', const FaceSpec(l: Eye.down, mouth: Mouth.frown)),
  _f('😓', 'downcast', const FaceSpec(l: Eye.down, mouth: Mouth.flat, extras: [Extra.sweat])),
  _f('😩', 'weary', const FaceSpec(l: Eye.squeeze, mouth: Mouth.openFrown, brow: Brow.sad)),
  _f('😫', 'tired', const FaceSpec(l: Eye.squeeze, mouth: Mouth.bigO, brow: Brow.sad)),
  _f('🥱', 'yawning', const FaceSpec(l: Eye.closed, mouth: Mouth.bigO, extras: [Extra.yawn])),
  _f('😤', 'huffing', const FaceSpec(l: Eye.happy, mouth: Mouth.frown, brow: Brow.angry, extras: [Extra.steam])),
  _f('😡', 'pouting', const FaceSpec(l: Eye.dot, mouth: Mouth.frown, brow: Brow.angry, extras: [Extra.anger], shade: true)),
  _f('😠', 'angry', const FaceSpec(l: Eye.dot, mouth: Mouth.frown, brow: Brow.angry)),
  _f('🤬', 'cursing', const FaceSpec(l: Eye.dot, mouth: Mouth.none, brow: Brow.angry, extras: [Extra.cursing], shade: true)),
  _f('😈', 'devil', const FaceSpec(l: Eye.dot, mouth: Mouth.grin, brow: Brow.angry, extras: [Extra.horns])),
  _f('👿', 'angry devil', const FaceSpec(l: Eye.dot, mouth: Mouth.frown, brow: Brow.angry, extras: [Extra.horns], shade: true)),
  _t('💀', 'skull', 'Faces', skull),
  _t('👻', 'ghost', 'Faces', ghost),
  _t('👽', 'alien', 'Faces', alien),
  _t('🤖', 'robot', 'Faces', robot),
  _t('💩', 'poop', 'Faces', poop),
  _f('😺', 'cat smile', const FaceSpec(l: Eye.dot, mouth: Mouth.bigSmile, extras: [Extra.ears, Extra.whiskers])),
  _f('😸', 'cat grin', const FaceSpec(l: Eye.happy, mouth: Mouth.beam, extras: [Extra.ears, Extra.whiskers])),
  _f('😹', 'cat joy', const FaceSpec(l: Eye.squeeze, mouth: Mouth.bigSmile, extras: [Extra.ears, Extra.whiskers, Extra.streams])),
  _f('😻', 'cat heart eyes', const FaceSpec(l: Eye.heart, mouth: Mouth.bigSmile, extras: [Extra.ears, Extra.whiskers])),
  _f('😼', 'cat smirk', const FaceSpec(l: Eye.half, mouth: Mouth.smirk, extras: [Extra.ears, Extra.whiskers])),
  _f('😽', 'cat kiss', const FaceSpec(l: Eye.closed, mouth: Mouth.kiss, extras: [Extra.ears, Extra.whiskers, Extra.blush])),
  _f('🙀', 'cat weary', const FaceSpec(l: Eye.wide, mouth: Mouth.longO, extras: [Extra.ears, Extra.whiskers, Extra.cheeks])),
  _f('😿', 'cat crying', const FaceSpec(l: Eye.dot, mouth: Mouth.frown, brow: Brow.sad, extras: [Extra.ears, Extra.whiskers, Extra.tear])),
  _f('😾', 'cat pouting', const FaceSpec(l: Eye.dot, mouth: Mouth.frown, brow: Brow.angry, extras: [Extra.ears, Extra.whiskers])),
  _t('❤️', 'heart', 'Hearts', (k) => heartPlain(k)),
  _t('🖤', 'black heart', 'Hearts', (k) => heartPlain(k, shine: false)),
  _t('🤍', 'white heart', 'Hearts', (k) => heartPlain(k, dark: false)),
  _t('💔', 'broken heart', 'Hearts', heartBroken),
  _t('💕', 'two hearts', 'Hearts', heartsTwo),
  _t('💞', 'revolving hearts', 'Hearts', heartsRevolving),
  _t('💓', 'beating heart', 'Hearts', heartBeat),
  _t('💗', 'growing heart', 'Hearts', heartGrow),
  _t('💖', 'sparkling heart', 'Hearts', heartSparkle),
  _t('💘', 'heart arrow', 'Hearts', heartArrow),
  _t('💝', 'heart ribbon', 'Hearts', heartRibbon),
  _t('❣️', 'heart exclamation', 'Hearts', heartExclaim),
  _t('👍', 'thumbs up', 'Hands', (k) => thumbHand(k)),
  _t('👎', 'thumbs down', 'Hands', (k) => thumbHand(k, down: true)),
  _t('👋', 'wave', 'Hands', waveHand),
  _t('👏', 'clap', 'Hands', clapHands),
  _t('🙌', 'raised hands', 'Hands', raiseHands),
  _t('🙏', 'pray', 'Hands', prayHands),
  _t('👌', 'ok', 'Hands', okHand),
  _t('✌️', 'peace', 'Hands', (k) => openHand(k, const [false, true, true, false, false], angle: -8)),
  _t('🤞', 'crossed fingers', 'Hands', crossedFingers),
  _t('🤟', 'love you', 'Hands', (k) => openHand(k, const [true, true, false, false, true])),
  _t('🤘', 'rock on', 'Hands', (k) => openHand(k, const [false, true, false, false, true])),
  _t('🤙', 'call me', 'Hands', (k) => openHand(k, const [true, false, false, false, true], angle: 20)),
  _t('☝️', 'index up', 'Hands', (k) => openHand(k, const [false, true, false, false, false])),
  _t('👇', 'point down', 'Hands', (k) => openHand(k, const [false, true, false, false, false], angle: 180)),
  _t('👉', 'point right', 'Hands', (k) => openHand(k, const [false, true, false, false, false], angle: 90)),
  _t('👈', 'point left', 'Hands', (k) => openHand(k, const [false, true, false, false, false], angle: -90)),
  _t('✋', 'raised hand', 'Hands', (k) => openHand(k, const [true, true, true, true, true])),
  _t('✊', 'fist', 'Hands', fistFront),
  _t('👊', 'punch', 'Hands', (k) => k.withRotation(-20, () => fistFront(k))),
  _t('💪', 'muscle', 'Hands', flexArm),
  _t('🫶', 'heart hands', 'Hands', heartHands),
  _t('👀', 'eyes', 'Hands', eyes),
  _t('🐟', 'fish', 'Nature', fishLogo),
  _t('🐠', 'tropical fish', 'Nature', tropicalFish),
  _t('🐳', 'whale', 'Nature', whale),
  _t('🐙', 'octopus', 'Nature', octopus),
  _t('🐱', 'cat', 'Nature', animalCat),
  _t('🐶', 'dog', 'Nature', animalDog),
  _t('🐰', 'bunny', 'Nature', animalBunny),
  _t('🐻', 'bear', 'Nature', animalBear),
  _t('🐼', 'panda', 'Nature', animalPanda),
  _t('🐧', 'penguin', 'Nature', penguin),
  _t('🐸', 'frog', 'Nature', frog),
  _t('🌸', 'blossom', 'Nature', blossom),
  _t('🍀', 'clover', 'Nature', clover),
  _t('☀️', 'sun', 'Nature', sun),
  _t('🌙', 'moon', 'Nature', moon),
  _t('☁️', 'cloud', 'Nature', cloudy),
  _t('🌧️', 'rain', 'Nature', rain),
  _t('❄️', 'snowflake', 'Nature', snowflake),
  _t('⚡', 'lightning', 'Nature', bolt),
  _t('🌈', 'rainbow', 'Nature', rainbow),
  _t('🌊', 'wave', 'Nature', wave),
  _t('🫧', 'bubbles', 'Nature', bubbles),
  _t('🔥', 'fire', 'Things', fire),
  _t('✨', 'sparkles', 'Things', sparkles),
  _t('⭐', 'star', 'Things', starOutline),
  _t('🌟', 'glowing star', 'Things', glowStar),
  _t('💯', 'hundred', 'Things', hundred),
  _t('✅', 'check', 'Things', checkBox),
  _t('❌', 'cross', 'Things', crossMark),
  _t('❗', 'exclamation', 'Things', exclaim),
  _t('❓', 'question', 'Things', question),
  _t('💤', 'zzz', 'Things', zzz),
  _t('💦', 'drops', 'Things', sweatDrops),
  _t('💨', 'dash', 'Things', dash),
  _t('💥', 'boom', 'Things', boom),
  _t('💬', 'speech', 'Things', speech),
  _t('🎉', 'party popper', 'Things', partyPopper),
  _t('🎂', 'cake', 'Things', cake),
  _t('🎁', 'gift', 'Things', gift),
  _t('🎈', 'balloon', 'Things', balloon),
  _t('☕', 'coffee', 'Things', coffee),
  _t('🍕', 'pizza', 'Things', pizza),
  _t('🍩', 'donut', 'Things', donut),
  _t('🎵', 'music', 'Things', music),
  _t('🎮', 'game', 'Things', gamepad),
  _t('📷', 'camera', 'Things', camera),
  _t('💡', 'idea', 'Things', bulb),
  _t('👑', 'crown', 'Things', crown),
  _t('💎', 'gem', 'Things', gem),
  _t('🏆', 'trophy', 'Things', trophy),
  _t('🚀', 'rocket', 'Things', rocket),
];

const chibiGroups = ['Faces', 'Hearts', 'Hands', 'Nature', 'Things'];

String _norm(String s) => s.replaceAll('️', '');

final Map<String, ChibiDef> _byChar = {for (final d in chibiAll) _norm(d.char): d};

ChibiDef? chibiFor(String grapheme) => _byChar[_norm(grapheme)];

class ChibiPainter extends CustomPainter {
  ChibiPainter(this.def, this.ink, this.paper);

  final ChibiDef def;
  final Color ink;
  final Color paper;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide / 100;
    canvas.save();
    canvas.translate((size.width - 100 * s) / 2, (size.height - 100 * s) / 2);
    canvas.scale(s);
    def.draw(Pen(canvas, ink, paper));
    canvas.restore();
  }

  @override
  bool shouldRepaint(ChibiPainter old) => old.def != def || old.ink != ink || old.paper != paper;
}

class Chibi extends StatelessWidget {
  const Chibi(this.def, {super.key, this.size = 24, this.ink, this.paper});

  final ChibiDef def;
  final double size;
  final Color? ink;
  final Color? paper;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final i = ink ?? (dark ? const Color(0xFFF2F0EC) : const Color(0xFF141414));
    final pa = paper ?? (i.computeLuminance() > 0.5 ? const Color(0xFF1C1C1E) : const Color(0xFFFFFFFF));
    return RepaintBoundary(
      child: CustomPaint(size: Size.square(size), painter: ChibiPainter(def, i, pa)),
    );
  }
}

class ChibiChar extends StatelessWidget {
  const ChibiChar(this.char, {super.key, this.size = 24});

  final String char;
  final double size;

  @override
  Widget build(BuildContext context) {
    final d = chibiFor(char);
    if (d == null) return SizedBox.square(dimension: size, child: Center(child: Text(char, style: TextStyle(fontSize: size * 0.8))));
    return Chibi(d, size: size);
  }
}

int? emojiOnlyCount(String text) {
  final t = text.trim();
  if (t.isEmpty) return null;
  var n = 0;
  for (final g in t.characters) {
    if (g.trim().isEmpty) continue;
    if (chibiFor(g) == null) return null;
    n++;
    if (n > 3) return null;
  }
  return n == 0 ? null : n;
}

bool containsChibi(String text) => text.characters.any((g) => _byChar.containsKey(_norm(g)));
