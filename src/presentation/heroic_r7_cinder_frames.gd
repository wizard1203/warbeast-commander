extends RefCounted
## Original, hard-pixel frames for the R7 testament keeper. Bake once to the
## shared atlas; this module owns no clock, texture cache, actor or combat state.
## Canonical origin is (48, 64). W opens towards +X before the consumer rotates it.
const SIZE := 96
const FRAMES := 8
const PALETTE := {
	"ink": Color("17151d"), "edge": Color("29212c"),
	"coal": Color("43323a"), "smoke": Color("70656f"),
	"vapor": Color("aaa7a4"), "ash": Color("c2b6a2"),
	"shade": Color("92775f"), "paper": Color("d5bc91"),
	"ivory": Color("f1dfb5"), "fold": Color("b89b75"),
	"wine": Color("783731"), "red": Color("b54d35"),
	"ember": Color("ef8750"), "light": Color("f8cf79"),
	"seal": Color("889d99")
}

static func clips() -> Array[String]:
	return [
		"cinder_q:TRAVEL", "cinder_q:IMPACT", "cinder_q:LOOP", "cinder_q:END",
		"cinder_w:WINDUP", "cinder_w:IMPACT", "cinder_w:END",
		"cinder_r:MARK", "cinder_r:IMPACT", "cinder_r:LOOP", "cinder_r:END",
		"cinder_p:PROC"
	]

static func metadata() -> Dictionary:
	return {
		"version": "r7-cinder-frames-20261102-v3", "origin": Vector2i(48, 64),
		"size": SIZE, "frames": FRAMES, "forward": Vector2i.RIGHT,
		"palette": PALETTE.duplicate(true), "palette_includes_transparent": 16,
		"provenance": "Original hand-authored pixel geometry; no third-party image or model output.",
		"semantics": "Presentation only. TRAVEL/MARK/WINDUP do not imply damage; LOOP ends with the real status."
	}

static func image(handler: String, phase: String, frame: int) -> Image:
	var out := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	out.fill(Color.TRANSPARENT)
	if frame < 0 or frame >= FRAMES:
		return out
	match handler + ":" + phase:
		"cinder_q:TRAVEL": _q_travel(out, frame)
		"cinder_q:IMPACT": _q_attach(out, frame)
		"cinder_q:LOOP": _q_burn(out, frame)
		"cinder_q:END": _q_end(out, frame)
		"cinder_w:WINDUP": _w_windup(out, frame)
		"cinder_w:IMPACT": _w_scatter(out, frame)
		"cinder_w:END": _w_end(out, frame)
		"cinder_r:MARK": _r_mark(out, frame)
		"cinder_r:IMPACT": _r_stamp(out, frame)
		"cinder_r:LOOP": _r_burn(out, frame)
		"cinder_r:END": _r_end(out, frame)
		"cinder_p:PROC": _p_return(out, frame)
	return out

# Integer-only raster primitives. They are deliberately not CanvasItem draws:
# they are used by the atlas bake, never as per-frame battle allocations.
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

static func _polygon(out: Image, points: Array, color: Color) -> void:
	if points.size() < 3:
		return
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

static func _paper(out: Image, x: int, y: int, w: int, h: int, slant: int, burn: int = 0) -> void:
	# The missing lower-right corner is a silhouette, not a dark square painted
	# onto a full sheet. Both a thick outside edge and an internal fold remain.
	var cut := clampi(burn, 2, maxi(2, w - 3))
	_polygon(out, [Vector2i(x + slant, y), Vector2i(x + w + slant, y + 1), Vector2i(x + w, y + h - cut), Vector2i(x + w - cut, y + h), Vector2i(x, y + h - 1)], PALETTE.ink)
	_polygon(out, [Vector2i(x + 2 + slant, y + 2), Vector2i(x + w - 2 + slant, y + 3), Vector2i(x + w - 2, y + h - cut - 1), Vector2i(x + w - cut - 1, y + h - 2), Vector2i(x + 2, y + h - 3)], PALETTE.paper)
	_line(out, Vector2i(x + 3 + slant, y + 3), Vector2i(x + w - 3 + slant, y + 4), 1, PALETTE.ivory)
	_line(out, Vector2i(x + 3, y + h - 4), Vector2i(x + 3 + slant, y + 5), 1, PALETTE.fold)
	if burn > 0:
		_line(out, Vector2i(x + w - cut - 1, y + h - 3), Vector2i(x + w - 2, y + h - cut - 1), 3, PALETTE.coal)
		_line(out, Vector2i(x + w - cut - 2, y + h - 4), Vector2i(x + w - 3, y + h - cut - 2), 1, PALETTE.red)

static func _script(out: Image, x: int, y: int, reach: int, hot: bool) -> void:
	var paths := [
		[Vector2i(0, 0), Vector2i(9, 1)], [Vector2i(6, -2), Vector2i(3, 6)],
		[Vector2i(1, 7), Vector2i(10, 5)], [Vector2i(8, 7), Vector2i(5, 12)],
		[Vector2i(0, 13), Vector2i(12, 15)], [Vector2i(7, 12), Vector2i(4, 20)]
	]
	for index: int in range(clampi(reach, 0, paths.size())):
		var path: Array = paths[index]
		_line(out, Vector2i(x, y) + path[0], Vector2i(x, y) + path[1], 2, PALETTE.wine)
		if hot and index == reach - 1:
			_line(out, Vector2i(x, y) + path[0], Vector2i(x, y) + path[1], 1, PALETTE.ember)
			_rect(out, x + path[1].x, y + path[1].y, 2, 2, PALETTE.light)

static func _fleck(out: Image, x: int, y: int, phase: int, hot: bool = true) -> void:
	# Not identical translated squares: an edged fork opens into an L, then ash.
	if phase % 3 == 0:
		_line(out, Vector2i(x, y + 3), Vector2i(x + 2, y), 2, PALETTE.edge)
		_rect(out, x + 1, y + 1, 1, 2, PALETTE.ember if hot else PALETTE.ash)
	elif phase % 3 == 1:
		_rect(out, x, y, 3, 2, PALETTE.red if hot else PALETTE.smoke)
		_rect(out, x + 2, y - 2, 2, 3, PALETTE.light if hot else PALETTE.vapor)
	else:
		_rect(out, x, y, 2, 2, PALETTE.smoke)
		_rect(out, x + 2, y - 1, 1, 1, PALETTE.ash)

static func _curl(out: Image, x: int, y: int, frame: int) -> void:
	var shift := frame % 3
	_line(out, Vector2i(x, y), Vector2i(x + 3 + shift, y - 3), 2, PALETTE.smoke)
	_line(out, Vector2i(x + 3 + shift, y - 3), Vector2i(x + 1 + shift, y - 6), 2, PALETTE.vapor)
	_rect(out, x + shift, y - 8, 2, 2, PALETTE.ash)

static func _tongue(out: Image, x: int, y: int, height: int, width: int, lean: int, f: int) -> void:
	# Tapered, broken-side ink-fire with an off-centre hot nib. It stays hard
	# alpha; the separate renderer atmosphere owns low-alpha light and shadow.
	var kink := 2 + f % 3
	_polygon(out, [Vector2i(x - width, y), Vector2i(x - width - 1, y - height / 3), Vector2i(x + lean - kink, y - height * 2 / 3), Vector2i(x + lean, y - height), Vector2i(x + lean + 2, y - height * 2 / 3), Vector2i(x + width + 2, y - height / 4), Vector2i(x + width - 1, y)], PALETTE.ink)
	_polygon(out, [Vector2i(x - width + 1, y - 1), Vector2i(x - width + 1, y - height / 3), Vector2i(x + lean - 1, y - height * 2 / 3), Vector2i(x + lean, y - height + 3), Vector2i(x + lean + 1, y - height / 2), Vector2i(x + width, y - 3)], PALETTE.red)
	_polygon(out, [Vector2i(x - 1, y - 2), Vector2i(x + lean - 1, y - height / 2), Vector2i(x + lean, y - height + 6), Vector2i(x + 2, y - height / 3), Vector2i(x + 1, y - 2)], PALETTE.ember)
	_line(out, Vector2i(x, y - 3), Vector2i(x + lean, y - height / 2), 1, PALETTE.light)
	if height > 15:
		_line(out, Vector2i(x + lean, y - height / 2), Vector2i(x + lean + 1, y - height / 2 - 3), 1, PALETTE.ivory)

static func _ink_sliver(out: Image, start: Vector2i, tip: Vector2i, bend: int, hot: bool) -> void:
	# An asymmetric taper reads as a forward brush cut in a still frame. Its
	# paper-white leading lip is separated from the dim, torn charcoal back.
	var middle := Vector2i((start.x + tip.x) / 2, (start.y + tip.y) / 2 + bend)
	_polygon(out, [start, middle + Vector2i(0, -3), tip, middle + Vector2i(-2, 3), start + Vector2i(3, 2)], PALETTE.ink)
	_line(out, start + Vector2i(3, 0), middle, 2, PALETTE.wine)
	_line(out, middle, tip - Vector2i(2, 0), 2, PALETTE.ember if hot else PALETTE.shade)
	if hot:
		_line(out, middle + Vector2i(1, -1), tip - Vector2i(1, 0), 1, PALETTE.ivory)

static func _nib(out: Image, at: Vector2i, f: int) -> void:
	# A diamond-like pen tip, not a radial impact sparkle or an explosion.
	_polygon(out, [at + Vector2i(-3, 1), at + Vector2i(0, -4 - f % 2), at + Vector2i(3, 0), at + Vector2i(0, 4)], PALETTE.wine)
	_line(out, at + Vector2i(0, 2), at + Vector2i(0, -3), 2, PALETTE.light)
	_rect(out, at.x, at.y - 2, 1, 2, PALETTE.ivory)

static func _box(out: Image, x: int, y: int, opening: int) -> void:
	_polygon(out, [Vector2i(x - 11, y - 7), Vector2i(x + 8, y - 9), Vector2i(x + 13, y - 4), Vector2i(x + 10, y + 8), Vector2i(x - 10, y + 8)], PALETTE.ink)
	_polygon(out, [Vector2i(x - 8, y - 5), Vector2i(x + 7, y - 6), Vector2i(x + 10, y - 3), Vector2i(x + 7, y + 5), Vector2i(x - 7, y + 5)], PALETTE.coal)
	_line(out, Vector2i(x - 7, y + 1), Vector2i(x + 7, y), 2, PALETTE.shade)
	_rect(out, x - 1, y, 3, 5, PALETTE.ash)
	if opening > 0:
		_polygon(out, [Vector2i(x - 10, y - 9 - opening), Vector2i(x + 7, y - 11 - opening), Vector2i(x + 10, y - 6), Vector2i(x - 9, y - 4)], PALETTE.ink)
		_line(out, Vector2i(x - 7, y - 8 - opening), Vector2i(x + 5, y - 10 - opening), 2, PALETTE.shade)
		_rect(out, x - 6, y - 5, 11, 2, PALETTE.wine)

static func _q_travel(out: Image, f: int) -> void:
	var widths := [10, 12, 15, 18, 17, 15, 12, 10]
	var fold := [5, 4, 2, -1, -4, -2, 2, 4]
	var w: int = widths[f]
	var skew: int = fold[f]
	# The small page turns edge-on, opens, then refolds; the consumer supplies
	# the actual short arc. This local turn never changes the world position.
	_paper(out, 48 - w / 2, 39 + absi(skew) / 2, w, 22 - absi(skew), skew, 2 + f / 3)
	_script(out, 46, 44, 1 + f % 3, f >= 5)
	_polygon(out, [Vector2i(42, 41), Vector2i(48, 46 + f % 2), Vector2i(45, 52)], PALETTE.fold)
	_nib(out, Vector2i(49 + skew / 2, 44 + f % 3), f)
	_ink_sliver(out, Vector2i(23 + f % 3, 55), Vector2i(40, 49), -3, f > 2)
	for i: int in range(3):
		_fleck(out, 34 - i * 6 + f % 2, 53 + i * 2 - f % 3, f + i, i == 0)

static func _q_attach(out: Image, f: int) -> void:
	var spread := [8, 13, 17, 19, 18, 18, 18, 18]
	var w: int = spread[f]
	_paper(out, 48 - w / 2, 35, w, 26, 2 - mini(f, 2), 2 + f / 3)
	# A stitched dark corner catches the armour; no radial impact or blast.
	_line(out, Vector2i(43, 38), Vector2i(48, 35), 2, PALETTE.ink)
	_rect(out, 46, 36, 3, 2, PALETTE.ash)
	_script(out, 44, 40, mini(6, 1 + f), true)
	_nib(out, Vector2i(46 + f % 5, 40 + mini(f, 4) * 3), f)
	if f >= 3:
		_tongue(out, 56, 61, 13 + f % 3 * 2, 2, -2 + f % 3, f)
		_fleck(out, 55 + f % 2, 55 - (f - 3), f)
	if f >= 5:
		_curl(out, 53, 35, f)

static func _q_burn(out: Image, f: int) -> void:
	# Two unequal, offset tongues form a restrained single-target silhouette.
	# Q is still below R in length, brightness area and detached fragment count.
	_tongue(out, 37, 63, 17 + (f + 1) % 4 * 2, 3, [-3, -2, 0, 1, 2, 0, -1, -2][f], f)
	_tongue(out, 60, 52, 10 + f % 3 * 2, 2, [2, 1, 0, -1, -2, 0, 1, 2][f], f + 2)
	_paper(out, 39, 33, 20, 31, -1 + f % 3, 3 + f % 4)
	_script(out, 43, 39, 6, false)
	# The bright nib follows the signature, rather than a generic flame shell.
	var nibs := [Vector2i(43, 39), Vector2i(51, 40), Vector2i(48, 43), Vector2i(46, 47), Vector2i(52, 46), Vector2i(49, 51), Vector2i(44, 53), Vector2i(47, 58)]
	var nib: Vector2i = nibs[f]
	_nib(out, nib, f)
	_ink_sliver(out, Vector2i(32, 53 + f % 3), Vector2i(38, 42 + f % 2), -3, f % 3 == 0)
	_fleck(out, 60 - f % 3, 51 - f * 2, f)
	_curl(out, 37 + f % 3, 35 - f % 2, f)
	if f % 2 == 0:
		_fleck(out, 36, 60 - f, f + 1, false)

static func _q_end(out: Image, f: int) -> void:
	if f < 5:
		_paper(out, 39 + f / 2, 33 + f, 20 - f, 29 - f * 3, f % 2, 3 + f)
		# All strokes blank progressively. Remaining corners cool, not reignite.
		_script(out, 44, 40 + f, maxi(0, 3 - f), false)
	for i: int in range(4):
		if f + i < 9:
			_fleck(out, 38 + i * 7 + (f * (i - 1)) / 3, 57 - f * 3 + i % 2 * 4, f + i, false)
	if f < 6:
		_curl(out, 57 - f, 36 - f, f)

static func _w_windup(out: Image, f: int) -> void:
	_box(out, 44, 63, 1 + f)
	# Inner light stays bounded by the actual case; dark lid and back remain
	# readable before the directional fan is released or interrupted.
	_polygon(out, [Vector2i(38, 57), Vector2i(49, 54), Vector2i(54 + f, 57 - f / 2), Vector2i(49, 61), Vector2i(39, 60)], PALETTE.wine)
	_line(out, Vector2i(40, 58), Vector2i(50 + f, 56), 2, PALETTE.ember if f < 4 else PALETTE.light)
	if f >= 3:
		_tongue(out, 53, 60, 14 + f, 3, 3 + f / 2, f)
	# Distinct widths, tears and progressive fan angles, not a rotated rectangle.
	for i: int in range(3):
		var reach := 5 + f * (i + 2) / 3
		var y := 47 - i * 5 + (2 - f / 3) * i
		_paper(out, 43 + reach, y, 8 + i * 2, 17 + i * 3, 1 + i * 2 + f / 2, 3 + i)
		_line(out, Vector2i(49 + reach, y + 5), Vector2i(52 + reach, y + 9), 1, PALETTE.wine)
	_rect(out, 40, 56, 8, 2, PALETTE.red if f > 4 else PALETTE.shade)
	if f > 3:
		_fleck(out, 62 + f, 44 - f / 2, f)
		_ink_sliver(out, Vector2i(55, 55), Vector2i(72 + f, 39 - f % 2), -2, true)

static func _w_scatter(out: Image, f: int) -> void:
	# The fan has five asymmetrical, notched pages; its envelope is directional.
	# This is a single cut gesture, never a circular or ground-persistent fire.
	var distances := [7, 12, 19, 26, 33, 38, 40, 41]
	var distance: int = distances[f]
	for i: int in range(5):
		var stagger := i % 2 * 3
		var x := 40 + distance - absi(i - 2) * 4
		# Keep the lower page plus its falling splinter inside the atlas cell.
		# A tighter five-page fan changes the actual authored envelope instead
		# of clipping pixels or shaving off the dark silhouette at bake time.
		var y := 35 + i * 7 - (distance * (2 - i)) / 7
		var w := maxi(5, 13 - f / 2 + stagger)
		var h := maxi(6, 19 - f + (i % 3) * 2)
		_ink_sliver(out, Vector2i(x - 19, y + h / 2 + (i - 2) * 2), Vector2i(x + w + 1, y + h / 2), (2 - i) * 2, f >= 2 and f <= 5)
		_paper(out, x, y, w, h, 3 - i, 4 + (f + i) % 4)
		_line(out, Vector2i(x + 4, y + 4), Vector2i(x + 7, y + 10), 2, PALETTE.wine)
		if f >= 2 and f <= 4:
			_line(out, Vector2i(x + w - 2, y + 3), Vector2i(x + w - 4, y + h - 5), 2, PALETTE.ivory)
		if f >= 4:
			_fleck(out, x - 3, y + h + 2, f + i, false)
		if f >= 2 and f <= 5 and i % 2 == 0:
			_tongue(out, x + w - 3, y + h - 3, 9 + i + f % 2, 2, 3, f + i)
	if f <= 3:
		_line(out, Vector2i(47 + distance, 34), Vector2i(52 + distance, 43), 2, PALETTE.light)

static func _w_end(out: Image, f: int) -> void:
	for i: int in range(5):
		var x := 66 + i % 2 * 6 + (f * (i - 1)) / 4
		var y := 29 + i * 10 + f * 2
		if f < 4:
			_polygon(out, [Vector2i(x, y), Vector2i(x + 8 - f, y + 1), Vector2i(x + 3, y + 8 - f), Vector2i(x - 2, y + 4)], PALETTE.ink)
			_line(out, Vector2i(x + 1, y + 2), Vector2i(x + 4, y + 3), 2, PALETTE.ash)
		if f + i % 3 < 8:
			_fleck(out, x - f, y - 2, f + i, false)

static func _scroll(out: Image, top: int, bottom: int, width: int, curl: int, blank: bool = false) -> void:
	var left := 48 - width / 2
	_paper(out, left, top, width, maxi(8, bottom - top), 0, 3 + curl % 3)
	# Rolled ends use stepped profiles and inside shading, not plain boxes.
	_polygon(out, [Vector2i(left - 4, top), Vector2i(left + width + 3, top), Vector2i(left + width + 5, top + 3), Vector2i(left + width + 2, top + 7), Vector2i(left - 3, top + 6), Vector2i(left - 5, top + 3)], PALETTE.ink)
	_line(out, Vector2i(left - 2, top + 2), Vector2i(left + width + 1, top + 2), 2, PALETTE.ivory)
	_line(out, Vector2i(left - 1, top + 5), Vector2i(left + width, top + 5), 2, PALETTE.fold)
	if bottom - top > 16:
		_line(out, Vector2i(left + 3, bottom - 3), Vector2i(left + width - 4, bottom - 2), 3, PALETTE.shade)
		_rect(out, left + width - 3, bottom - 4, 4, 4, PALETTE.ink)
	if not blank and bottom - top > 25:
		_script(out, left + 6, top + 12, 6, false)
		_line(out, Vector2i(left + width - 7, top + 11), Vector2i(left + width - 8, bottom - 9), 1, PALETTE.fold)

static func _seal(out: Image, x: int, y: int, lit: bool, split: int = 0) -> void:
	_polygon(out, [Vector2i(x - 9, y - 8), Vector2i(x + 7, y - 9), Vector2i(x + 10, y - 6), Vector2i(x + 8, y + 8), Vector2i(x - 9, y + 8)], PALETTE.ink)
	_rect(out, x - 6, y - 6, 12, 12, PALETTE.wine)
	_line(out, Vector2i(x - 4, y - 3), Vector2i(x + 3, y - 3), 2, PALETTE.light if lit else PALETTE.ash)
	_line(out, Vector2i(x, y - 5), Vector2i(x - 1, y + 5), 2, PALETTE.ember if lit else PALETTE.fold)
	_line(out, Vector2i(x - 4, y + 3), Vector2i(x + 4, y + 2), 2, PALETTE.light if lit else PALETTE.ash)
	if split > 0:
		_line(out, Vector2i(x - 4, y + 7), Vector2i(x + split, y + 3), 2, PALETTE.ink)

static func _r_mark(out: Image, f: int) -> void:
	var bottom := 28 + f * 4
	_scroll(out, 18, bottom, 16, f)
	# A detachable seal is visible throughout the real, dispellable warning.
	# Its descending height is not a damage tick or an uncleanseable timer.
	_seal(out, 64, 28 + f * 2, f % 3 == 2)
	_line(out, Vector2i(56, 22), Vector2i(62, 26 + f * 2), 1, PALETTE.fold)
	if f >= 4:
		_line(out, Vector2i(43, bottom - 8), Vector2i(49, bottom - 7), 2, PALETTE.red)
		_nib(out, Vector2i(47, bottom - 9), f)
	_ink_sliver(out, Vector2i(34, 59), Vector2i(39, 34 - f), -4, false)
	_curl(out, 31, 31 - f / 2, f)

static func _r_stamp(out: Image, f: int) -> void:
	# A narrow, incomplete charter leaves the actor visible. R's authority is
	# the one main seal and the rising separated nibs, not an opaque big scroll.
	_paper(out, 41, 24, 16, 38, f % 2, 4 + f % 3)
	_script(out, 44, 30, 6, false)
	var heights := [15, 24, 36, 46, 49, 47, 45, 44]
	var y: int = heights[f]
	# One heavy ash-case impression, with a short vertical recoil and a narrow
	# paper crease. No annular wave, splash radius, meteor or group explosion.
	_box(out, 48, y, 0)
	if f >= 3:
		_seal(out, 48, 55, f <= 5, f - 2)
		_line(out, Vector2i(39, 36), Vector2i(37, 47 + f % 2), 2, PALETTE.ember)
		_tongue(out, 34, 61, 24 + f % 3 * 3, 3, -2 + f % 3, f)
		_tongue(out, 64, 55, 20 + (f + 1) % 3 * 3, 3, 2 - f % 3, f + 2)
		_nib(out, Vector2i(48, 51), f)
	if f >= 2 and f <= 4:
		_line(out, Vector2i(48, 22), Vector2i(48, y - 9), 3, PALETTE.ash)
		_rect(out, 47, y - 13, 2, 4, PALETTE.ivory)
	if f >= 5:
		_fleck(out, 32, 57 - f, f)
		_fleck(out, 64, 58 - f, f + 1)
		_paper(out, 27 + f % 3, 46 - f * 2, 7, 11, -2, 3)
		_paper(out, 67 + f % 2, 57 - f * 2, 6, 9, 2, 3)

static func _r_burn(out: Image, f: int) -> void:
	_tongue(out, 36, 64, 28 + (f + 1) % 4 * 3, 3, [-4, -2, 0, 2, 1, -1, -3, -4][f], f)
	_tongue(out, 62, 52, 19 + f % 4 * 3, 3, [3, 1, -1, -2, 0, 2, 3, 1][f], f + 3)
	_ink_sliver(out, Vector2i(30, 62), Vector2i(34 + f % 3, 30), -4, f % 3 == 1)
	_paper(out, 41, 24, 16, 38, f % 2, 4 + f % 3)
	_seal(out, 48, 55, false, 2)
	# Large, finite brush strokes distinguish the ultimate from Q's small
	# contract corner. Only the current stroke burns, never the whole body.
	var strokes := [
		[Vector2i(39, 25), Vector2i(55, 26)],
		[Vector2i(49, 21), Vector2i(44, 34)],
		[Vector2i(38, 36), Vector2i(54, 33)],
		[Vector2i(51, 35), Vector2i(46, 44)],
		[Vector2i(38, 43), Vector2i(55, 47)],
		[Vector2i(48, 40), Vector2i(43, 51)],
		[Vector2i(40, 57), Vector2i(54, 59)],
		[Vector2i(52, 53), Vector2i(47, 63)]
	]
	for i: int in range(strokes.size()):
		var path: Array = strokes[i]
		_line(out, path[0], path[1], 3, PALETTE.wine)
		if i == f:
			_line(out, path[0], path[1], 2, PALETTE.ember)
			_nib(out, path[1], f)
	# Detached curved corners rise in different lanes. The open space between
	# them is important: this is not an opaque smoke screen or an area attack.
	_paper(out, 26 + f % 3, 56 - f * 3, 7, 11, -2, 3 + f % 2)
	_paper(out, 67 + f % 2, 47 - (f + 3) % 8 * 3, 6, 9, 2, 3)
	_fleck(out, 32 - f % 2, 49 - f * 3, f)
	_fleck(out, 65 + f % 3, 42 - f * 2, f + 1)
	_curl(out, 33, 20, f)
	if f > 3:
		_curl(out, 62, 16 - f % 2, f + 1)

static func _r_end(out: Image, f: int) -> void:
	if f < 6:
		_paper(out, 41 + f / 2, 24 + f * 3, 16 - f, 38 - f * 4, 0, 3 + f)
		if f < 3:
			_seal(out, 48, 55, false, 3 + f)
		_line(out, Vector2i(38 + f, 42 + f * 2), Vector2i(55 - f, 42 + f * 2), 2, PALETTE.ash)
	for i: int in range(5):
		if f + i % 2 < 8:
			_fleck(out, 33 + i * 7 + (f * (i - 2)) / 4, 44 - f * 3 + i % 2 * 11, f + i, false)
	if f < 5:
		_curl(out, 30 + f * 2, 22 - f, f)

static func _p_return(out: Image, f: int) -> void:
	_box(out, 48, 64, maxi(0, 6 - f))
	# Mana is a returned ink-lamp, not a new damaging fire projectile. A bright
	# slit closes into the case and its detached nib cools by the last frame.
	if f >= 2 and f <= 6:
		_polygon(out, [Vector2i(43, 58), Vector2i(44, 49 - (f % 3) * 2), Vector2i(49, 43 + f % 2), Vector2i(53, 51), Vector2i(52, 58)], PALETTE.ink)
		_line(out, Vector2i(47, 57), Vector2i(48, 47 + f % 3), 3, PALETTE.seal)
		_line(out, Vector2i(48, 54), Vector2i(49, 47 + f % 3), 1, PALETTE.ivory)
	var corners := [Vector2i(22, 28), Vector2i(76, 35), Vector2i(35, 14)]
	for i: int in range(corners.size()):
		var origin: Vector2i = corners[i]
		var t := clampf(float(f - i + 1) / 6.0, 0.0, 1.0)
		var p := Vector2i(Vector2(origin).lerp(Vector2(48, 57), t))
		if t < 1.0:
			# Individual bent triangular corners turn and narrow as they return.
			var span := maxi(3, 8 - f + i)
			_polygon(out, [p + Vector2i(-span, -3), p + Vector2i(span, -1), p + Vector2i(2 - i, span), p + Vector2i(-3, 1)], PALETTE.ink)
			_polygon(out, [p + Vector2i(-span + 2, -1), p + Vector2i(span - 2, 0), p + Vector2i(1, span - 2)], PALETTE.ash)
			_line(out, p + Vector2i(-2, 1), p + Vector2i(1, 4), 1, PALETTE.smoke)
	if f >= 3 and f <= 6:
		_rect(out, 45, 59, 7, 7, PALETTE.ink)
		_rect(out, 47, 60, 3, 4, PALETTE.seal if f == 3 or f == 6 else PALETTE.ivory)
		_line(out, Vector2i(42, 55), Vector2i(44, 58), 2, PALETTE.seal)
		_line(out, Vector2i(54, 55), Vector2i(52, 58), 2, PALETTE.ash)
	if f >= 5:
		_curl(out, 39 + f, 47 - f, f)
