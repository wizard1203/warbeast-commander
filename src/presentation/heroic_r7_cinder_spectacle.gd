extends RefCounted
## V4 authored spectacle layer. Fixed atlas images, not combat or world paths.
## Canonical forward is +X; all clocks, contacts and origin->target travel are
## owned by the existing simulation/dispatcher, never by these pixel images.
const SIZE := 192
const FRAMES := 12
const ANCHOR := Vector2i(96, 136)
const P := {
	"ink": Color("17121d"), "soot": Color("352435"),
	"coal": Color("594048"), "smoke": Color("77717f"),
	"ash": Color("b9aaa0"), "paper": Color("dfc49e"),
	"fold": Color("b88c67"), "ivory": Color("fff0c7"),
	"white": Color("fff9e7"), "wine": Color("8c302e"),
	"red": Color("c44932"), "orange": Color("e9713c"),
	"fire": Color("ffa849"), "gold": Color("ffd77b"),
	"teal": Color("83bcc3"), "mist": Color("c4edf0"),
	"violet": Color("8f8ca4")
}
const ALPHAS := [0, 16, 32, 48, 64, 96, 128, 160, 208, 255]

static func clips() -> Array[String]:
	return ["cinder_q:CAST", "cinder_q:CONTACT", "cinder_w:CAST", "cinder_w:CONTACT",
		"cinder_r:CAST", "cinder_r:CONTACT", "cinder_r:TAIL", "cinder_p:RETURN"]

static func metadata() -> Dictionary:
	return {"version": "r7-cinder-spectacle-v4-20261102-v1", "size": SIZE,
		"frames": FRAMES, "anchor": ANCHOR, "forward": Vector2i.RIGHT,
		"palette": P.duplicate(true), "alpha_levels": ALPHAS.duplicate(),
		"actor_keepout": Rect2i(82, 84, 28, 52), "actor_alpha_cap": 48,
		"provenance": "Original authored pixel geometry; no external images, competitor assets or generated illustrations.",
		"scope": "Cosmetic cast/contact/tail/return; never damage, hit timing, range, cleanse or resource authority."}

static func image(handler: String, phase: String, frame: int) -> Image:
	var out := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	out.fill(Color.TRANSPARENT)
	if frame < 0 or frame >= FRAMES:
		return out
	match handler + ":" + phase:
		"cinder_q:CAST": _q_cast(out, frame)
		"cinder_q:CONTACT": _q_contact(out, frame)
		"cinder_w:CAST": _w_cast(out, frame)
		"cinder_w:CONTACT": _w_contact(out, frame)
		"cinder_r:CAST": _r_cast(out, frame)
		"cinder_r:CONTACT": _r_contact(out, frame)
		"cinder_r:TAIL": _r_tail(out, frame)
		"cinder_p:RETURN": _p_return(out, frame)
	_keep_actor_readable(out)
	return out

static func _a(color: Color, alpha: int) -> Color:
	return Color(color.r, color.g, color.b, float(alpha) / 255.0)

static func _rect(out: Image, x: int, y: int, w: int, h: int, color: Color) -> void:
	var box := Rect2i(x, y, w, h).intersection(Rect2i(0, 0, SIZE, SIZE))
	if box.size.x > 0 and box.size.y > 0:
		out.fill_rect(box, color)

static func _line(out: Image, a: Vector2i, b: Vector2i, width: int, color: Color) -> void:
	var x := a.x
	var y := a.y
	var dx := absi(b.x - x)
	var sx := 1 if x < b.x else -1
	var dy := -absi(b.y - y)
	var sy := 1 if y < b.y else -1
	var error := dx + dy
	for _step: int in range(SIZE * 3):
		_rect(out, x - width / 2, y - width / 2, width, width, color)
		if x == b.x and y == b.y:
			break
		var twice := error * 2
		if twice >= dy:
			error += dy
			x += sx
		if twice <= dx:
			error += dx
			y += sy

static func _poly(out: Image, points: Array, color: Color) -> void:
	var minimum := Vector2i(SIZE, SIZE)
	var maximum := Vector2i.ZERO
	for point: Vector2i in points:
		minimum = Vector2i(mini(minimum.x, point.x), mini(minimum.y, point.y))
		maximum = Vector2i(maxi(maximum.x, point.x), maxi(maximum.y, point.y))
	for y: int in range(maxi(0, minimum.y), mini(SIZE, maximum.y + 1)):
		for x: int in range(maxi(0, minimum.x), mini(SIZE, maximum.x + 1)):
			var inside := false
			var previous := Vector2(points.back())
			for raw: Vector2i in points:
				var point := Vector2(raw)
				if (point.y > y + 0.5) != (previous.y > y + 0.5):
					var cross_x := point.x + (y + 0.5 - point.y) * (previous.x - point.x) / (previous.y - point.y)
					if x + 0.5 < cross_x:
						inside = not inside
				previous = point
			if inside:
				out.set_pixel(x, y, color)

static func _ellipse(out: Image, center: Vector2i, radius: Vector2i, color: Color) -> void:
	for y: int in range(maxi(0, center.y - radius.y), mini(SIZE, center.y + radius.y + 1)):
		for x: int in range(maxi(0, center.x - radius.x), mini(SIZE, center.x + radius.x + 1)):
			var q := Vector2(float(x - center.x) / maxf(1.0, radius.x), float(y - center.y) / maxf(1.0, radius.y))
			if q.length_squared() <= 1.0:
				out.set_pixel(x, y, color)

static func _halo(out: Image, at: Vector2i, radius: Vector2i, color: Color, energy: int = 0) -> void:
	# Four discrete stepped ellipses, not a filtered or full-screen blur.
	_ellipse(out, at, radius, _a(color, 16))
	_ellipse(out, at, Vector2i(radius.x * 3 / 4, radius.y * 3 / 4), _a(color, 32))
	_ellipse(out, at, Vector2i(radius.x / 2, radius.y / 2), _a(color, 64 if energy > 0 else 48))
	_ellipse(out, at, Vector2i(maxi(2, radius.x / 4), maxi(2, radius.y / 4)), _a(color, 96 if energy > 0 else 64))

static func _point(at: Vector2, offset: Vector2, angle: float) -> Vector2i:
	return Vector2i((at + offset.rotated(angle)).round())

static func _curve(out: Image, start: Vector2, c1: Vector2, c2: Vector2, finish: Vector2, width: int, color: Color, alpha: int, hot: bool = true) -> void:
	for layer: int in range(4):
		var previous := Vector2i(start.round())
		for index: int in range(1, 25):
			var t := float(index) / 24.0
			var inv := 1.0 - t
			var p := start * inv * inv * inv + c1 * 3.0 * inv * inv * t + c2 * 3.0 * inv * t * t + finish * t * t * t
			var taper := maxi(1, roundi(width * (0.2 + 0.8 * sin(t * PI))))
			var w := taper + 10 if layer == 0 else taper + 4 if layer == 1 else taper if layer == 2 else maxi(1, taper / 3)
			var tint: Color = _a(color, 16) if layer == 0 else _a(P.ink, alpha) if layer == 1 else _a(color, alpha) if layer == 2 else _a(P.white if hot else P.ash, alpha)
			var current := Vector2i(p.round())
			_line(out, previous, current, w, tint)
			previous = current

static func _leaf(out: Image, at: Vector2, w: int, h: int, angle: float, charred: int = 4, hot: bool = false, alpha: int = 255) -> void:
	var outer := [Vector2(-w / 2, -h / 2), Vector2(w / 2 - 3, -h / 2), Vector2(w / 2, -h / 2 + 3), Vector2(w / 2, h / 2 - charred), Vector2(w / 2 - charred, h / 2), Vector2(-w / 2, h / 2 - 2)]
	var points: Array = []
	for offset: Vector2 in outer:
		points.append(_point(at, offset, angle))
	_poly(out, points, _a(P.ink, alpha))
	points = []
	for offset: Vector2 in outer:
		points.append(_point(at, offset * 0.76, angle))
	_poly(out, points, _a(P.paper, alpha))
	_line(out, _point(at, Vector2(-w * .28, -h * .32), angle), _point(at, Vector2(w * .28, -h * .32), angle), 2, _a(P.ivory, alpha))
	_line(out, _point(at, Vector2(-w * .2, h * .3), angle), _point(at, Vector2(w * .3, h * .1), angle), 3, _a(P.red if hot else P.coal, alpha))
	if hot:
		_line(out, _point(at, Vector2(w * .28, h * .07), angle), _point(at, Vector2(w * .25, -h * .24), angle), 2, _a(P.gold, alpha))

static func _seal(out: Image, at: Vector2, radius: int, angle: float, energy: int) -> void:
	var shape := [Vector2(-radius, -radius + 3), Vector2(radius - 4, -radius), Vector2(radius, -radius + 5), Vector2(radius - 2, radius - 3), Vector2(-radius + 4, radius), Vector2(-radius, radius - 4)]
	var points: Array = []
	for offset: Vector2 in shape:
		points.append(_point(at, offset, angle))
	_poly(out, points, P.ink)
	points = []
	for offset: Vector2 in shape:
		points.append(_point(at, offset * .77, angle))
	_poly(out, points, P.wine)
	var strokes := [
		[Vector2(-.55, -.44), Vector2(.5, -.44)], [Vector2(.05, -.68), Vector2(-.12, .62)],
		[Vector2(-.48, .18), Vector2(.55, .04)], [Vector2(-.5, .58), Vector2(.45, .48)],
		[Vector2(-.35, -.3), Vector2(-.42, .48)], [Vector2(.43, -.21), Vector2(.36, .42)]
	]
	for index: int in range(strokes.size()):
		var stroke: Array = strokes[index]
		_line(out, _point(at, stroke[0] * radius, angle), _point(at, stroke[1] * radius, angle), 3, P.orange if index == energy % 6 else P.fold)
		if index == energy % 6:
			_line(out, _point(at, stroke[0] * radius, angle), _point(at, stroke[1] * radius, angle), 1, P.white)

static func _case(out: Image, at: Vector2i, opened: int) -> void:
	_poly(out, [at + Vector2i(-16, -9), at + Vector2i(10, -13), at + Vector2i(18, -4), at + Vector2i(13, 11), at + Vector2i(-14, 12)], P.ink)
	_poly(out, [at + Vector2i(-12, -6), at + Vector2i(9, -9), at + Vector2i(13, -3), at + Vector2i(10, 7), at + Vector2i(-10, 8)], P.coal)
	_line(out, at + Vector2i(-10, 1), at + Vector2i(11, -1), 3, P.fold)
	_rect(out, at.x - 2, at.y - 1, 4, 7, P.ivory)
	if opened > 0:
		_poly(out, [at + Vector2i(-16, -12 - opened), at + Vector2i(8, -16 - opened), at + Vector2i(14, -8), at + Vector2i(-14, -4)], P.ink)
		_line(out, at + Vector2i(-11, -10 - opened), at + Vector2i(6, -13 - opened), 3, P.fold)
		_line(out, at + Vector2i(-9, -5), at + Vector2i(9, -6), 3, P.fire)

static func _embers(out: Image, f: int, spread: int, cold: bool = false) -> void:
	for i: int in range(9):
		var phase := (f + i * 3) % 12
		var angle := float(i) * 2.39996 + float(f) * .026
		var at := Vector2(96, 95) + Vector2(cos(angle) * spread, sin(angle) * spread * .69) + Vector2(0, -phase * 1.5)
		var p := Vector2i(at.round())
		if p.x < 16 or p.x > 176 or p.y < 15 or p.y > 170:
			continue
		_line(out, p, p + Vector2i(3 - i % 3, -5 - phase % 3), 3, _a(P.coal if cold else P.red, 160))
		_line(out, p + Vector2i(0, -1), p + Vector2i(1, -4 - phase % 3), 1, _a(P.ash if cold else P.gold, 208))

static func _keep_actor_readable(out: Image) -> void:
	# Preserve the actor centre without an opaque rectangular deletion. The
	# designed curves run around this area; only occasional crossing wisps dim.
	for y: int in range(84, 136):
		for x: int in range(82, 110):
			var color := out.get_pixel(x, y)
			if color.a > 48.0 / 255.0:
				out.set_pixel(x, y, _a(color, 48))

static func _q_cast(out: Image, f: int) -> void:
	var t := float(f) / 11.0
	_halo(out, Vector2i(125, 80), Vector2i(41 + f, 47), P.orange, 1)
	_curve(out, Vector2(34, 130), Vector2(25, 42), Vector2(108, 20), Vector2(149, 73 - f), 4 + f % 3, P.orange, 160)
	_curve(out, Vector2(43, 121), Vector2(57, 62), Vector2(135, 40), Vector2(163, 111), 3, P.gold, 208)
	_curve(out, Vector2(126, 115), Vector2(158, 104), Vector2(162, 67), Vector2(129, 49 + f), 4, P.red, 128)
	_case(out, Vector2i(52, 123), 2 + f / 2)
	_leaf(out, Vector2(115 + t * 28, 71 - sin(t * PI) * 20), 27 - f / 3, 39, -.8 + t * 1.1, 6 + f % 3, true)
	_leaf(out, Vector2(53 + t * 15, 65 - f), 13, 22, -1.1 + t, 5, false, 128)
	_embers(out, f, 62)

static func _q_contact(out: Image, f: int) -> void:
	var t := float(f) / 11.0
	_halo(out, Vector2i(120, 76), Vector2i(32, 45), P.orange, 1)
	# Both paths bend inward as an attached page closes. No outward circular
	# impulse: this skill has zero initial direct damage, even when ornate.
	_curve(out, Vector2(37 + t * 16, 121), Vector2(25 + t * 14, 52), Vector2(100, 24 + f), Vector2(124, 68), 5, P.orange, 160)
	_curve(out, Vector2(157 - t * 17, 124), Vector2(176 - f, 86), Vector2(157, 43), Vector2(126, 65), 4, P.fire, 128)
	_leaf(out, Vector2(122, 70 + f % 3), 25 - f / 4, 41 - f / 2, -.22 + sin(t * TAU) * .12, 6 + f % 5, true)
	_seal(out, Vector2(124, 66), 8, -.15, f)
	if f < 7:
		_leaf(out, Vector2(48 + f * 5, 57 + f * 2), 13, 22, .3 + t, 5, false, 128)
	_embers(out, f + 3, 58, f >= 9)

static func _w_cast(out: Image, f: int) -> void:
	var t := float(f) / 11.0
	_halo(out, Vector2i(125, 76), Vector2i(43, 51), P.fire, 1)
	_curve(out, Vector2(31, 137), Vector2(28, 66), Vector2(104, 24), Vector2(165, 61 - f / 2), 9, P.orange, 208)
	_curve(out, Vector2(41, 132), Vector2(58, 64), Vector2(131, 38), Vector2(170, 85), 5, P.gold, 255)
	_case(out, Vector2i(50, 126), 4 + f)
	for i: int in range(4):
		var angle := -.9 + float(i) * .31 + t * .2
		var at := Vector2(84 + i * 20, 74 - i * 9 - sin(t * PI) * (6 + i * 3))
		_leaf(out, at, 15 + i * 3, 29 + i * 3, angle, 5 + i, true, 160 if i == 0 else 255)
	_embers(out, f + 1, 68)

static func _w_contact(out: Image, f: int) -> void:
	var t := float(f) / 11.0
	_halo(out, Vector2i(147, 87), Vector2i(33, 61), P.orange, 1)
	# A long open forward arc with a hot leading edge, not a circular blast.
	_curve(out, Vector2(35 + f, 155), Vector2(114, 149), Vector2(177, 92), Vector2(156 - f / 3, 29 + f / 3), 11 - f / 3, P.orange, 255 if f < 8 else 160)
	_curve(out, Vector2(30, 137), Vector2(100, 132), Vector2(164, 79), Vector2(151, 36), 4, P.gold, 160)
	_curve(out, Vector2(54, 163), Vector2(137, 145), Vector2(173, 106), Vector2(164, 61), 3, P.red, 128)
	for i: int in range(6):
		var angle := -.9 + float(i) * .3 + t * .6
		var at := Vector2(112 + i % 2 * 21 + t * 13, 36 + i * 21 + sin(t * PI + i) * 5)
		_leaf(out, at, maxi(9, 21 - f / 2), maxi(14, 35 - f), angle, 6 + i % 3, true, 255 if f < 7 else 160)
	_embers(out, f + 4, 72, f > 8)

static func _r_cast(out: Image, f: int) -> void:
	var t := float(f) / 11.0
	_halo(out, Vector2i(97, 57), Vector2i(58, 39), P.orange, 1)
	_halo(out, Vector2i(51, 116), Vector2i(25, 35), P.red)
	# Open ascending ink-brackets and a large above-head turning contract seal
	# read as hero invocation. They do not turn the actor into a shield bubble.
	_curve(out, Vector2(38, 153), Vector2(21, 82), Vector2(50, 37), Vector2(86, 27), 7, P.red, 208)
	_curve(out, Vector2(153, 148), Vector2(174, 93), Vector2(153, 29), Vector2(112, 24), 5, P.fire, 160)
	_curve(out, Vector2(43, 130), Vector2(27, 66), Vector2(97, 36), Vector2(146, 61), 4, P.gold, 128)
	_seal(out, Vector2(97, 57), 25 + f / 4, -.47 + t * .63, f)
	_case(out, Vector2i(52, 133), 3 + f / 2)
	_leaf(out, Vector2(42 + f % 3, 79 - f * 2), 17, 31, -.62 + t * .3, 6, true)
	_leaf(out, Vector2(151 - f % 4, 101 - f), 16, 34, .62 - t * .4, 7, true, 208)
	_embers(out, f + 2, 73)

static func _r_contact(out: Image, f: int) -> void:
	# The complete rotated stamp remains inside the cell even in frame zero.
	var drop := [40, 42, 46, 52, 58, 64, 68, 65, 62, 60, 59, 58]
	var y: int = drop[f]
	_halo(out, Vector2i(102, 65), Vector2i(52, 53), P.fire, 1)
	_halo(out, Vector2i(52, 118), Vector2i(28, 43), P.red)
	# The main seal descends vertically; side strokes rise afterwards. No
	# floor-wide shockwave, target multiplication or extra timed contact.
	_curve(out, Vector2(98, 23), Vector2(109, 31), Vector2(104, 38), Vector2(101, y), 5, P.gold, 208)
	if f >= 3:
		_curve(out, Vector2(45, 159), Vector2(18, 109), Vector2(62, 86), Vector2(47 + f % 4, 28), 10, P.orange, 208)
		_curve(out, Vector2(151, 151), Vector2(179, 105), Vector2(131, 72), Vector2(147 - f % 5, 32), 7, P.fire, 160)
		_curve(out, Vector2(54, 143), Vector2(46, 113), Vector2(69, 92), Vector2(64, 59), 4, P.gold, 128)
	_seal(out, Vector2(101, y), 24 if f < 4 else 28 - maxi(0, f - 8), -.16 + sin(float(f) * .6) * .06, f)
	for i: int in range(3):
		if f >= 4:
			_leaf(out, Vector2(30 + i * 14 + f % 2, 132 - i * 26 - (f - 4) * 3), 12 + i * 3, 21, -.7 + float(f) * .05, 5 + i, true, 208)
	_embers(out, f + 5, 73)

static func _r_tail(out: Image, f: int) -> void:
	var t := float(f) / 11.0
	_halo(out, Vector2i(56, 91), Vector2i(29, 62), P.orange)
	_halo(out, Vector2i(142, 83), Vector2i(27, 57), P.red)
	_curve(out, Vector2(47, 163), Vector2(18, 100), Vector2(77, 85), Vector2(45 + f % 5, 22), 5, P.orange, 128)
	_curve(out, Vector2(146, 154), Vector2(171, 119), Vector2(117, 71), Vector2(149 - f % 6, 31), 4, P.fire, 96)
	_curve(out, Vector2(60, 145), Vector2(56, 110), Vector2(81, 91), Vector2(69, 49), 2, P.gold, 128)
	_seal(out, Vector2(119, 75), 14, -.12 + sin(t * TAU) * .07, f)
	_leaf(out, Vector2(120, 99), 17, 35, -.08, 5 + f % 4, true, 160)
	for i: int in range(4):
		var rise := (f + i * 3) % 12
		_leaf(out, Vector2(32 + i % 2 * 118 + sin(float(f + i)) * 3, 150 - rise * 10), 9 + i % 2 * 3, 17, -.6 + rise * .1, 4, false, 64 if rise > 8 else 128)
	_embers(out, f + 2, 69, f % 4 == 3)

static func _p_return(out: Image, f: int) -> void:
	var t := float(f) / 11.0
	_halo(out, Vector2i(124, 101), Vector2i(37, 43), P.teal, 1)
	_curve(out, Vector2(34 + f * 3, 45 + f), Vector2(23, 100), Vector2(73, 149), Vector2(123, 109), 4, P.teal, 160, false)
	_curve(out, Vector2(155 - f, 39 + f * 2), Vector2(175, 93), Vector2(156, 119), Vector2(124, 109), 3, P.mist, 128, false)
	_case(out, Vector2i(124, 120), maxi(0, 12 - f))
	for i: int in range(4):
		var start := Vector2(33 + i * 39, 34 + i % 2 * 16)
		var p := start.lerp(Vector2(125, 107), clampf((t - i * .07) * 1.4, 0.0, 1.0))
		if t < .92:
			_leaf(out, p, maxi(6, 18 - f), maxi(9, 26 - f), -.9 + t * 2.2 + i * .4, 5, false, 208)
	if f >= 3 and f <= 9:
		_poly(out, [Vector2i(117, 113), Vector2i(113, 96), Vector2i(123, 77 + f % 3), Vector2i(132, 94), Vector2i(131, 112)], P.ink)
		_curve(out, Vector2(121, 111), Vector2(116, 98), Vector2(129, 93), Vector2(124, 83 + f % 3), 4, P.teal, 255, false)
		_line(out, Vector2i(123, 106), Vector2i(125, 86 + f % 3), 2, P.white)
	_embers(out, f, 61, true)
