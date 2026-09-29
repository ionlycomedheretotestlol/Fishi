"""Builds Fishi's three typefaces from stroke skeletons.

Every glyph is a set of centerlines. Each family strokes them with its own
pen (width, caps, joins, spacing) and writes an OpenType CFF font.

    python3 tool/fonts/build_fonts.py
"""

import math
import os

import pathops
from fontTools.fontBuilder import FontBuilder
from fontTools.pens.t2CharStringPen import T2CharStringPen

OUT = os.path.join(os.path.dirname(__file__), '..', '..', 'assets', 'fonts')

X = 520
CAP = 720
ASC = 740
DESC = -200


def arc(cx, cy, rx, ry, a0, a1):
    return ('A', cx, cy, rx, ry, a0, a1)


def ell(cx, cy, rx, ry):
    return [('M', cx + rx, cy), arc(cx, cy, rx, ry, 0, 360), ('Z',)]


def poly(*pts):
    out = [('M',) + pts[0]]
    out += [('L',) + p for p in pts[1:]]
    return out


def dot(x, y):
    return [('M', x, y), ('L', x, y + 0.5)]


def arc_from(cx, cy, rx, ry, a0, a1):
    t = math.radians(a0)
    return [('M', cx + rx * math.cos(t), cy + ry * math.sin(t)), arc(cx, cy, rx, ry, a0, a1)]


G = {}


def glyph(ch, *strokes, width=None):
    G[ch] = (list(strokes), width)


# lowercase
glyph('a', ell(235, 260, 235, 260), poly((470, 520), (470, 0)))
glyph('b', poly((0, ASC), (0, 0)), ell(235, 260, 235, 260))
glyph('c', arc_from(245, 260, 245, 260, 40, 320))
glyph('d', ell(235, 260, 235, 260), poly((470, ASC), (470, 0)))
glyph('e', [('M', 10, 260), ('L', 480, 260), arc(245, 260, 235, 260, 0, 320)])
glyph('f', [('M', 110, 0), ('L', 110, 580), ('Q', 110, ASC, 270, ASC)], poly((0, 500), (270, 500)))
glyph('g', ell(235, 260, 235, 260), [('M', 470, 520), ('L', 470, 0), arc(235, 0, 235, 200, 0, -155)])
glyph('h', poly((0, ASC), (0, 0)), [('M', 0, 300), arc(220, 300, 220, 220, 180, 0), ('L', 440, 0)])
glyph('i', poly((0, X), (0, 0)), dot(0, 690))
glyph('j', [('M', 150, X), ('L', 150, -60), arc(40, -60, 110, 140, 0, -160)], dot(150, 690))
glyph('k', poly((0, ASC), (0, 0)), poly((400, X), (0, 170)), poly((150, 300), (420, 0)))
glyph('l', [('M', 0, ASC), ('L', 0, 110), ('Q', 0, 0, 100, 0)])
glyph('m', poly((0, X), (0, 0)), [('M', 0, 330), arc(175, 330, 175, 190, 180, 0), ('L', 350, 0)],
      [('M', 350, 330), arc(525, 330, 175, 190, 180, 0), ('L', 700, 0)])
glyph('n', poly((0, X), (0, 0)), [('M', 0, 300), arc(220, 300, 220, 220, 180, 0), ('L', 440, 0)])
glyph('o', ell(255, 260, 255, 260))
glyph('p', poly((0, X), (0, DESC)), ell(235, 260, 235, 260))
glyph('q', ell(235, 260, 235, 260), poly((470, X), (470, DESC)))
glyph('r', poly((0, X), (0, 0)), [('M', 0, 300), arc(210, 300, 210, 220, 180, 70)])
glyph('s', [('M', 395, 430), arc(210, 392, 190, 128, 12, 270), arc(210, 132, 200, 132, 90, -168)])
glyph('t', [('M', 120, 690), ('L', 120, 110), ('Q', 120, 0, 250, 0)], poly((0, 500), (270, 500)))
glyph('u', [('M', 0, X), ('L', 0, 220), arc(220, 220, 220, 220, 180, 360)], poly((440, X), (440, 0)))
glyph('v', poly((0, X), (230, 0), (460, X)))
glyph('w', poly((0, X), (170, 0), (340, 420), (510, 0), (680, X)))
glyph('x', poly((0, X), (420, 0)), poly((420, X), (0, 0)))
glyph('y', poly((0, X), (230, 20)), poly((460, X), (140, DESC)))
glyph('z', poly((20, X), (420, X), (0, 0), (420, 0)))

# uppercase
glyph('A', poly((0, 0), (280, CAP), (560, 0)), poly((105, 240), (455, 240)))
glyph('B', [('M', 0, 380), ('L', 280, 380), arc(280, 550, 170, 170, -90, 90), ('L', 0, CAP), ('L', 0, 0), ('L', 300, 0),
            arc(300, 190, 190, 190, -90, 90), ('L', 0, 380)])
glyph('C', arc_from(360, 360, 360, 360, 42, 318))
glyph('D', [('M', 0, 0), ('L', 0, CAP), ('L', 230, CAP), arc(230, 360, 350, 360, 90, -90), ('L', 0, 0)])
glyph('E', poly((440, CAP), (0, CAP), (0, 0), (440, 0)), poly((0, 370), (390, 370)))
glyph('F', poly((440, CAP), (0, CAP), (0, 0)), poly((0, 370), (390, 370)))
glyph('G', [('M', 440, 340), ('L', 710, 340), ('L', 710, 300), arc(360, 360, 350, 360, -10, -318)])
glyph('H', poly((0, 0), (0, CAP)), poly((540, 0), (540, CAP)), poly((0, 370), (540, 370)))
glyph('I', poly((0, 0), (0, CAP)))
glyph('J', [('M', 360, CAP), ('L', 360, 220), arc(180, 220, 180, 220, 0, -180), ('L', 0, 270)])
glyph('K', poly((0, 0), (0, CAP)), poly((490, CAP), (0, 250)), poly((170, 410), (510, 0)))
glyph('L', poly((0, CAP), (0, 0), (420, 0)))
glyph('M', poly((0, 0), (0, CAP), (340, 180), (680, CAP), (680, 0)))
glyph('N', poly((0, 0), (0, CAP), (560, 0), (560, CAP)))
glyph('O', ell(380, 360, 380, 360))
glyph('P', [('M', 0, 0), ('L', 0, CAP), ('L', 270, CAP), arc(270, 530, 190, 190, 90, -90), ('L', 0, 340)])
glyph('Q', ell(380, 360, 380, 360), poly((480, 170), (720, -60)))
glyph('R', [('M', 0, 0), ('L', 0, CAP), ('L', 270, CAP), arc(270, 530, 190, 190, 90, -90), ('L', 0, 340)],
      poly((250, 340), (500, 0)))
glyph('S', [('M', 490, 610), arc(265, 545, 235, 175, 16, 270), arc(265, 185, 265, 185, 90, -166)])
glyph('T', poly((0, CAP), (540, CAP)), poly((270, CAP), (270, 0)))
glyph('U', [('M', 0, CAP), ('L', 0, 270), arc(270, 270, 270, 270, 180, 360), ('L', 540, CAP)])
glyph('V', poly((0, CAP), (300, 0), (600, CAP)))
glyph('W', poly((0, CAP), (210, 0), (420, 560), (630, 0), (840, CAP)))
glyph('X', poly((0, CAP), (540, 0)), poly((540, CAP), (0, 0)))
glyph('Y', poly((0, CAP), (280, 330), (560, CAP)), poly((280, 330), (280, 0)))
glyph('Z', poly((20, CAP), (510, CAP), (0, 0), (510, 0)))

# digits
glyph('0', ell(260, 350, 260, 350))
glyph('1', poly((60, 590), (190, 700), (190, 0)))
glyph('2', [('M', 20, 520), arc(240, 500, 225, 200, 172, -32), ('L', 10, 0), ('L', 480, 0)])
glyph('3', [('M', 30, 610), arc(235, 530, 205, 170, 160, -90), arc(240, 190, 240, 190, 90, -160)])
glyph('4', poly((380, 0), (380, 700), (0, 220), (510, 220)))
glyph('5', [('M', 450, 700), ('L', 60, 700), ('L', 40, 370), arc(255, 235, 240, 235, 146, -150)])
glyph('6', ell(250, 230, 250, 230), [('M', 0, 230), ('C', 0, 520, 170, 700, 410, 700)])
glyph('7', poly((0, 700), (480, 700), (140, 0)))
glyph('8', ell(240, 532, 200, 168), ell(240, 190, 240, 190))
glyph('9', ell(250, 470, 250, 230), [('M', 500, 470), ('C', 500, 180, 330, 0, 90, 0)])

# punctuation and symbols
glyph(' ', width=240)
glyph('.', dot(0, 0))
glyph(',', poly((10, 20), (-40, -130)))
glyph('!', poly((0, CAP), (0, 230)), dot(0, 0))
glyph('?', [('M', 10, 560), arc(200, 540, 195, 180, 170, -60), ('L', 200, 310), ('L', 200, 230)], dot(200, 0))
glyph("'", poly((0, CAP), (0, 540)))
glyph('"', poly((0, CAP), (0, 540)), poly((150, CAP), (150, 540)))
glyph('’', poly((20, CAP), (-20, 560)))
glyph('‘', poly((-20, CAP), (20, 560)))
glyph('“', poly((-20, CAP), (20, 560)), poly((130, CAP), (170, 560)))
glyph('”', poly((20, CAP), (-20, 560)), poly((170, CAP), (130, 560)))
glyph(':', dot(0, 0), dot(0, 420))
glyph(';', poly((10, 20), (-40, -130)), dot(10, 420))
glyph('-', poly((0, 300), (300, 300)))
glyph('–', poly((0, 300), (480, 300)))
glyph('—', poly((0, 300), (880, 300)))
glyph('_', poly((0, -130), (480, -130)))
glyph('(', arc_from(300, 300, 300, 500, 118, 242))
glyph(')', arc_from(0, 300, 300, 500, 62, -62))
glyph('[', poly((170, 780), (0, 780), (0, -170), (170, -170)))
glyph(']', poly((0, 780), (170, 780), (170, -170), (0, -170)))
glyph('{', [('M', 220, 780), ('Q', 90, 780, 90, 660), ('L', 90, 400), ('Q', 90, 300, 0, 300), ('Q', 90, 300, 90, 200),
            ('L', 90, -50), ('Q', 90, -170, 220, -170)])
glyph('}', [('M', 0, 780), ('Q', 130, 780, 130, 660), ('L', 130, 400), ('Q', 130, 300, 220, 300), ('Q', 130, 300, 130, 200),
            ('L', 130, -50), ('Q', 130, -170, 0, -170)])
glyph('/', poly((0, -120), (380, 780)))
glyph('\\', poly((0, 780), (380, -120)))
glyph('|', poly((0, -200), (0, 780)))
glyph('@', [('M', 470, 470), ('L', 470, 240), ('Q', 470, 130, 580, 130), ('Q', 730, 130, 730, 330),
            arc(380, 330, 350, 380, 0, 300)], ell(370, 330, 110, 140))
glyph('#', poly((140, 0), (220, 700)), poly((340, 0), (420, 700)), poly((0, 230), (500, 230)), poly((50, 470), (550, 470)))
glyph('$', [('M', 420, 560), arc(240, 520, 190, 140, 14, 270), arc(240, 170, 215, 150, 90, -166)], poly((240, -80), (240, 800)))
glyph('%', ell(110, 580, 110, 130), ell(450, 140, 110, 130), poly((40, 0), (520, 720)))
glyph('&', [('M', 560, 0), ('L', 170, 430), ('C', 40, 570, 120, 720, 260, 720), ('C', 410, 720, 440, 560, 330, 470),
            ('L', 110, 300), ('C', -30, 190, 40, 0, 240, 0), ('C', 400, 0, 490, 130, 520, 270)])
glyph('*', poly((200, 720), (200, 420)), poly((60, 650), (340, 490)), poly((340, 650), (60, 490)))
glyph('+', poly((0, 300), (440, 300)), poly((220, 80), (220, 520)))
glyph('=', poly((0, 200), (440, 200)), poly((0, 400), (440, 400)))
glyph('<', poly((440, 530), (0, 300), (440, 70)))
glyph('>', poly((0, 530), (440, 300), (0, 70)))
glyph('^', poly((0, 470), (210, 720), (420, 470)))
glyph('~', [('M', 0, 270), ('C', 80, 380, 170, 380, 240, 300), ('C', 310, 220, 400, 220, 480, 330)])
glyph('`', poly((0, 750), (120, 630)))
glyph('·', dot(0, 290))
glyph('•', ell(0, 300, 60, 60))
glyph('…', dot(0, 0), dot(200, 0), dot(400, 0))
glyph('°', ell(110, 610, 110, 110))

MONO_SERIFS = {
    'i': [poly((-140, X), (0, X), (0, 0)), poly((-160, 0), (160, 0)), dot(0, 690)],
    'l': [poly((-140, ASC), (0, ASC), (0, 0)), poly((-160, 0), (160, 0))],
    'I': [poly((0, 0), (0, CAP)), poly((-180, CAP), (180, CAP)), poly((-180, 0), (180, 0))],
    'j': [[('M', -120, X), ('L', 150, X), ('L', 150, -60), arc(40, -60, 110, 140, 0, -160)], dot(150, 690)],
    '1': [poly((0, 570), (190, 700), (190, 0)), poly((0, 0), (380, 0))],
}


def add_stroke(path, cmds):
    cur = None
    for c in cmds:
        op = c[0]
        if op == 'M':
            path.moveTo(c[1], c[2])
            cur = (c[1], c[2])
        elif op == 'L':
            path.lineTo(c[1], c[2])
            cur = (c[1], c[2])
        elif op == 'Q':
            path.quadTo(c[1], c[2], c[3], c[4])
            cur = (c[3], c[4])
        elif op == 'C':
            path.cubicTo(c[1], c[2], c[3], c[4], c[5], c[6])
            cur = (c[5], c[6])
        elif op == 'Z':
            path.close()
        elif op == 'A':
            _, cx, cy, rx, ry, a0, a1 = c
            t0 = math.radians(a0)
            start = (cx + rx * math.cos(t0), cy + ry * math.sin(t0))
            if cur is None:
                path.moveTo(*start)
            elif abs(cur[0] - start[0]) > 0.5 or abs(cur[1] - start[1]) > 0.5:
                path.lineTo(*start)
            steps = max(1, int(math.ceil(abs(a1 - a0) / 90.0)))
            d = math.radians(a1 - a0) / steps
            k = 4.0 / 3.0 * math.tan(d / 4.0)
            t = t0
            for _ in range(steps):
                t2 = t + d
                p0 = (cx + rx * math.cos(t), cy + ry * math.sin(t))
                p3 = (cx + rx * math.cos(t2), cy + ry * math.sin(t2))
                p1 = (p0[0] - k * rx * math.sin(t), p0[1] + k * ry * math.cos(t))
                p2 = (p3[0] + k * rx * math.sin(t2), p3[1] - k * ry * math.cos(t2))
                path.cubicTo(p1[0], p1[1], p2[0], p2[1], p3[0], p3[1])
                t = t2
            cur = (cx + rx * math.cos(t), cy + ry * math.sin(t))


def bounds_x(strokes):
    p = pathops.Path()
    for s in strokes:
        add_stroke(p, s)
    if not p.contours:
        return 0, 0
    b = p.controlPointBounds
    return b[0], b[2]


def accent(kind, cx, top, upper):
    h = 90 if upper else 130
    b = top + (40 if upper else 90)
    if kind == 'acute':
        return [poly((cx - 40, b), (cx + 60, b + h))]
    if kind == 'grave':
        return [poly((cx - 60, b + h), (cx + 40, b))]
    if kind == 'circ':
        return [poly((cx - 110, b), (cx, b + h), (cx + 110, b))]
    if kind == 'tilde':
        m = b + h * 0.55
        return [[('M', cx - 120, b + 10), ('C', cx - 90, m + 60, cx - 40, m + 40, cx, m),
                 ('C', cx + 40, m - 40, cx + 90, m - 60, cx + 120, b + h - 10)]]
    if kind == 'uml':
        return [dot(cx - 90, b + h / 2), dot(cx + 90, b + h / 2)]
    if kind == 'ced':
        return [[('M', cx + 10, 0), ('L', cx - 10, -70), ('Q', cx + 100, -80, cx + 70, -150), ('Q', cx + 40, -210, cx - 60, -190)]]
    raise ValueError(kind)


ACCENTED = {}
for base, marks in {
    'a': 'àáâãä', 'e': 'èéêë', 'i': 'ìíîï', 'o': 'òóôõö', 'u': 'ùúûü', 'n': '    ñ', 'c': '     ç',
    'A': 'ÀÁÂÃÄ', 'E': 'ÈÉÊË', 'I': 'ÌÍÎÏ', 'O': 'ÒÓÔÕÖ', 'U': 'ÙÚÛÜ', 'N': '    Ñ', 'C': '     Ç',
}.items():
    for kind, ch in zip(['grave', 'acute', 'circ', 'tilde', 'uml', 'ced'], marks):
        if ch.strip():
            ACCENTED[ch] = (base, kind)
if 'ñ' in ACCENTED:
    ACCENTED['ñ'] = ('n', 'tilde')
    ACCENTED['Ñ'] = ('N', 'tilde')
    ACCENTED['ç'] = ('c', 'ced')
    ACCENTED['Ç'] = ('C', 'ced')


def compose(ch, mono):
    base, kind = ACCENTED[ch]
    strokes = MONO_SERIFS[base] if mono and base in MONO_SERIFS else G[base][0]
    if base == 'i':
        strokes = [st for st in strokes if not is_dot(st)]
    x0, x1 = bounds_x(strokes)
    upper = base.isupper()
    cx = (x0 + x1) / 2
    if base == 'i' and mono:
        cx = 0
    top = CAP if upper else X
    return strokes, strokes + accent(kind, cx, top, upper)


class Style:
    def __init__(self, family, sub, weight, stroke, cap, join, side, mono=None, slant=0.0, miter=4.0):
        self.family = family
        self.sub = sub
        self.weight = weight
        self.stroke = stroke
        self.cap = cap
        self.join = join
        self.side = side
        self.mono = mono
        self.slant = slant
        self.miter = miter


def is_dot(s):
    return len(s) == 2 and s[0][0] == 'M' and s[1][0] == 'L' and abs(s[0][1] - s[1][1]) < 1 and abs(s[0][2] - s[1][2]) < 1


def outline(strokes, style, dx, sx=1.0):
    total = pathops.Path()
    for s in strokes:
        center = pathops.Path()
        add_stroke(center, s)
        if sx != 1.0 or dx:
            center.transform(sx, 0, 0, 1, dx, 0)
        cap = style.cap
        if is_dot(s) and cap == pathops.LineCap.BUTT_CAP:
            cap = pathops.LineCap.SQUARE_CAP
        center.stroke(style.stroke * (1.12 if is_dot(s) else 1.0), cap, style.join, style.miter)
        center.convertConicsToQuads()
        total.addPath(center)
    total.simplify(fix_winding=True)
    return total


def build(style):
    chars = list(G) + list(ACCENTED)
    order = ['.notdef'] + ['uni%04X' % ord(c) for c in chars]
    cmap = {ord(c): 'uni%04X' % ord(c) for c in chars}
    charstrings = {}
    metrics = {}
    half = style.stroke / 2.0

    nd = T2CharStringPen(500, None)
    nd.moveTo((60, 0))
    nd.lineTo((440, 0))
    nd.lineTo((440, 700))
    nd.lineTo((60, 700))
    nd.closePath()
    charstrings['.notdef'] = nd.getCharString()
    metrics['.notdef'] = (500, 60)

    for ch in chars:
        name = 'uni%04X' % ord(ch)
        if ch in ACCENTED:
            measure, strokes = compose(ch, style.mono)
            width = None
        else:
            strokes, width = G[ch]
            if style.mono and ch in MONO_SERIFS:
                strokes = MONO_SERIFS[ch]
            measure = strokes
        if not strokes:
            adv = width if not style.mono else style.mono
            pen = T2CharStringPen(adv, None)
            charstrings[name] = pen.getCharString()
            metrics[name] = (adv, 0)
            continue
        x0, x1 = bounds_x(measure)
        w = x1 - x0
        if style.mono:
            room = style.mono - 2 * (half + style.side)
            sx = min(1.0, room / w) if w > 0 else 1.0
            if 0 < w < room * 0.72 and ch.isalpha() and ch not in 'iljIJ':
                sx = room * 0.72 / w
            dx = (style.mono - w * sx) / 2.0 - x0 * sx
            adv = style.mono
        else:
            sx = 1.0
            dx = half + style.side - x0
            adv = int(round(w + 2 * (half + style.side)))
        path = outline(strokes, style, dx, sx)
        if style.slant:
            path.transform(1, 0, style.slant, 1, 0, 0)
        pen = T2CharStringPen(adv, None)
        path.draw(pen)
        charstrings[name] = pen.getCharString()
        b = path.controlPointBounds if path.contours else (0, 0, 0, 0)
        metrics[name] = (adv, int(math.floor(b[0])))

    fb = FontBuilder(1000, isTTF=False)
    fb.setupGlyphOrder(order)
    fb.setupCharacterMap(cmap)
    ps_name = (style.family + '-' + style.sub).replace(' ', '')
    fb.setupCFF(ps_name, {'FullName': style.family + ' ' + style.sub}, charstrings, {})
    fb.setupHorizontalMetrics(metrics)
    fb.setupHorizontalHeader(ascent=930, descent=-250)
    fb.setupNameTable({'familyName': style.family, 'styleName': style.sub, 'psName': ps_name})
    fb.setupOS2(
        sTypoAscender=930, sTypoDescender=-250, sTypoLineGap=0,
        usWinAscent=1000, usWinDescent=320,
        sxHeight=X + int(half), sCapHeight=CAP + int(half),
        usWeightClass=style.weight, fsSelection=0x80 | (0x20 if style.weight >= 700 else 0x40),
        achVendID='FSHI',
        version=4,
    )
    if style.weight >= 700:
        fb.updateHead(macStyle=1)
    fb.setupPost(isFixedPitch=1 if style.mono else 0)
    os.makedirs(OUT, exist_ok=True)
    out = os.path.join(OUT, ps_name + '.otf')
    fb.save(out)
    return out


ROUND = (pathops.LineCap.ROUND_CAP, pathops.LineJoin.ROUND_JOIN)
SQUARE = (pathops.LineCap.BUTT_CAP, pathops.LineJoin.MITER_JOIN)

STYLES = [
    Style('Fishi Text', 'Regular', 400, 78, *ROUND, side=46),
    Style('Fishi Text', 'Bold', 700, 116, *ROUND, side=40),
    Style('Fishi Display', 'Heavy', 800, 148, *SQUARE, side=22, miter=1.25),
    Style('Fishi Mono', 'Regular', 400, 74, *ROUND, side=24, mono=560),
]

if __name__ == '__main__':
    for s in STYLES:
        print(build(s))
