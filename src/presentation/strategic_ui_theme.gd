class_name StrategicUITheme
extends RefCounted
const FrontierCommandArt = preload("res://src/presentation/strategic_frontier_command_art.gd")
const HeroicCommandArt = preload("res://src/presentation/heroic_command_art.gd")
## Original, editable material language. Pure local geometry and semantic roles:
## no nodes, textures, authority queries, random state or pointer ownership.

static func style(state: String = "normal", role: String = "command") -> StyleBoxFlat:
	if HeroicCommandArt.enabled(): return HeroicCommandArt.style(state, role)
	var result := StyleBoxFlat.new()
	result.bg_color = _fill(role, state)
	result.border_color = _metal(state)
	# Native OptionButton popup/caption compatibility and old focus contracts.
	result.set_corner_radius_all(4)
	result.set_border_width_all(2)
	result.shadow_color = Color(0, 0, 0, 0.38)
	result.shadow_size = 3
	result.shadow_offset = Vector2(0, 2)
	result.content_margin_left = 10
	result.content_margin_right = 10
	if FrontierCommandArt.enabled():
		result.set_corner_radius_all(3)
		result.set_border_width_all(1)
		result.shadow_size = 2
	return result

static func draw_surface(canvas: Object, rect: Rect2, role: String = "command", state: String = "normal") -> void:
	if rect.size.x < 12 or rect.size.y < 12: return
	if HeroicCommandArt.enabled():
		HeroicCommandArt.draw_surface(canvas, rect, role, state)
		return
	if FrontierCommandArt.draw_surface(canvas, rect, role, state): return
	canvas.draw_rect(rect, _fill(role, state))
	var family := _family(role)
	match family:
		"stone": _stone(canvas, rect, state)
		"wood": _wood(canvas, rect, state)
		"iron": _iron(canvas, rect, state)
		_: _leather(canvas, rect, role, state)
	draw_frame(canvas, rect, role, state)

static func draw_frame(canvas: Object, rect: Rect2, role: String = "command", state: String = "normal", accent: Color = Color.TRANSPARENT) -> void:
	if rect.size.x < 12 or rect.size.y < 12: return
	if HeroicCommandArt.enabled():
		HeroicCommandArt.draw_frame(canvas, rect, state, accent)
		return
	if FrontierCommandArt.enabled():
		FrontierCommandArt.draw_frame(canvas, rect, state, accent)
		return
	var metal := _metal(state) if accent.a == 0 else accent
	var highlight := metal.lightened(0.28)
	var shadow := Color("11191b")
	var outer := rect.grow(-1)
	canvas.draw_rect(outer, shadow, false, 2)
	canvas.draw_rect(rect.grow(-3), metal.darkened(0.22), false, 2)
	canvas.draw_line(rect.position + Vector2(4, 4), rect.position + Vector2(rect.size.x - 4, 4), highlight, 1)
	canvas.draw_line(rect.position + Vector2(4, 4), rect.position + Vector2(4, rect.size.y - 4), highlight, 1)
	canvas.draw_line(rect.end - Vector2(4, 4), rect.position + Vector2(4, rect.size.y - 4), shadow, 2)
	canvas.draw_line(rect.end - Vector2(4, 4), rect.position + Vector2(rect.size.x - 4, 4), shadow, 2)
	canvas.draw_rect(rect.grow(-7), Color("172021"), false, 1)
	# Copper corner clamps use folded geometry rather than another flat border.
	var clamp_size := minf(19, minf(rect.size.x, rect.size.y) * 0.23)
	for corner: Vector2 in [Vector2.ZERO, Vector2(1, 0), Vector2(0, 1), Vector2.ONE]:
		var origin := rect.position + rect.size * corner
		var direction := Vector2(1 if corner.x == 0 else -1, 1 if corner.y == 0 else -1)
		var points := PackedVector2Array()
		for point: Vector2 in [Vector2(2, 2), Vector2(clamp_size, 2), Vector2(clamp_size, 6), Vector2(7, 6), Vector2(6, 7), Vector2(6, clamp_size), Vector2(2, clamp_size)]:
			points.append(origin + point * direction)
		canvas.draw_colored_polygon(points, metal)
		var rivet := origin + Vector2(8, 8) * direction
		canvas.draw_circle(rivet + Vector2(0, 1), 2.1, shadow)
		canvas.draw_circle(rivet, 1.5, highlight)
		canvas.draw_line(rivet + Vector2(-0.8, 0), rivet + Vector2(0.8, 0), metal.darkened(0.55), 1)
	if state == "pressed":
		canvas.draw_rect(rect.grow(-8), Color("101b1e"), false, 2)
	elif state == "hover":
		canvas.draw_rect(rect.grow(-5), Color("e4c48b"), false, 1)
	elif state == "selected":
		canvas.draw_rect(rect.grow(-5), Color("edc67e"), false, 2)

static func draw_connection(canvas: Object, start: Vector2, end: Vector2, complete: bool) -> void:
	if HeroicCommandArt.enabled():
		canvas.draw_line(start + Vector2(0, 1), end + Vector2(0, 1), Color("101718"), 4)
		canvas.draw_line(start, end, Color("a18b60") if complete else Color("666b61"), 2)
		return
	# Etched iron groove with a copper core; caller supplies actual tech facts.
	canvas.draw_line(start + Vector2(0, 1), end + Vector2(0, 1), Color("121d21"), 6)
	canvas.draw_line(start, end, Color("596a67"), 4)
	canvas.draw_line(start, end, Color("c4b77c") if complete else Color("6c7978"), 2)

static func _family(role: String) -> String:
	if role in ["stone", "panel", "lobby", "strip", "map"]: return "stone"
	if role == "dock": return "wood"
	if role == "tech": return "iron"
	return "leather"

static func _fill(role: String, state: String) -> Color:
	var color := Color("34302b")
	match _family(role):
		"stone": color = Color("26343b")
		"wood": color = Color("3d3024")
		"iron": color = Color("283137")
		_: color = Color("40312a") if role == "hero" else Color("30372f")
	if state == "pressed": return color.darkened(0.38)
	if state == "disabled": return color.lerp(Color("232a2b"), 0.7)
	if state == "hover": return color.lightened(0.16)
	if state == "selected": return color.lightened(0.08)
	return color

static func _metal(state: String) -> Color:
	if state == "disabled": return Color("62665e")
	if state == "selected": return Color("e2b96c")
	if state == "pressed": return Color("b18d54")
	if state == "hover": return Color("cea571")
	return Color("96734f")

static func _stone(canvas: Object, rect: Rect2, state: String) -> void:
	var seam := Color(0.04, 0.08, 0.10, 0.44)
	var light := Color(0.40, 0.46, 0.45, 0.12 if state != "disabled" else 0.06)
	var course := 34 if rect.size.y > 100 else 22
	var course_index := 0
	for y: int in range(12, int(rect.size.y) - 10, course):
		var start := rect.position + Vector2(9, y)
		canvas.draw_line(start, rect.position + Vector2(rect.size.x - 9, y), seam, 2)
		canvas.draw_line(start + Vector2(0, 2), rect.position + Vector2(rect.size.x - 9, y + 2), light, 1)
		var offset := 44 if course_index % 2 == 0 else 97
		for x: int in range(offset, int(rect.size.x) - 12, 127):
			canvas.draw_line(rect.position + Vector2(x, y), rect.position + Vector2(x, minf(y + course, rect.size.y - 10)), seam, 2)
		course_index += 1
	# Small hand-cut chips: fixed, bounded and sparse, never across a caption.
	for x: int in range(27, int(rect.size.x) - 21, 83):
		canvas.draw_polyline(PackedVector2Array([rect.position + Vector2(x, 10), rect.position + Vector2(x + 4, 12), rect.position + Vector2(x + 10, 11)]), light, 1)
	if role_is_large(rect):
		canvas.draw_rect(Rect2(rect.position + Vector2(12, 12), Vector2(rect.size.x - 24, 62)), Color("1b272e"))
		canvas.draw_line(rect.position + Vector2(12, 75), rect.position + Vector2(rect.size.x - 12, 75), Color("6c6852"), 1)

static func role_is_large(rect: Rect2) -> bool:
	return rect.size.x > 500 and rect.size.y > 400

static func _wood(canvas: Object, rect: Rect2, state: String) -> void:
	var grain := Color(0.08, 0.045, 0.025, 0.40 if state != "disabled" else 0.18)
	for y: int in range(11, int(rect.size.y) - 8, 13):
		canvas.draw_polyline(PackedVector2Array([rect.position + Vector2(9, y), rect.position + Vector2(rect.size.x * 0.28, y + 2), rect.position + Vector2(rect.size.x * 0.63, y - 1), rect.position + Vector2(rect.size.x - 9, y + 1)]), grain, 1)
	for x: int in range(91, int(rect.size.x) - 15, 152):
		canvas.draw_line(rect.position + Vector2(x, 8), rect.position + Vector2(x, rect.size.y - 8), Color("1b1d1b"), 3)
		canvas.draw_line(rect.position + Vector2(x + 2, 8), rect.position + Vector2(x + 2, rect.size.y - 8), Color("625039"), 1)
	if rect.size.x > 180:
		for x: int in [13, int(rect.size.x) - 20]:
			canvas.draw_rect(Rect2(rect.position + Vector2(x, 8), Vector2(6, rect.size.y - 16)), Color("27302f"))

static func _leather(canvas: Object, rect: Rect2, role: String, state: String) -> void:
	var inset := rect.grow(-10)
	canvas.draw_rect(inset, _fill(role, state).darkened(0.09))
	# A quiet center retains icon/text contrast; stitches remain on the seam.
	var stitch := Color("92764c") if state != "disabled" else Color("505a50")
	for x: int in range(14, int(rect.size.x) - 13, 9):
		for y: float in [11, rect.size.y - 12]:
			canvas.draw_line(rect.position + Vector2(x, y), rect.position + Vector2(x + 3, y + 1), stitch, 1)
	for y: int in range(18, int(rect.size.y) - 15, 9):
		for x: float in [11, rect.size.x - 12]:
			canvas.draw_line(rect.position + Vector2(x, y), rect.position + Vector2(x + 1, y + 3), stitch, 1)
	# Folded leather at the bottom, not a full-screen translucent embellishment.
	canvas.draw_line(rect.position + Vector2(15, rect.size.y - 14), rect.end - Vector2(15, 14), Color("151e1d"), 2)
	if role == "hero":
		canvas.draw_line(rect.position + Vector2(56, 10), rect.position + Vector2(56, rect.size.y - 10), Color("7c6146"), 1)

static func _iron(canvas: Object, rect: Rect2, state: String) -> void:
	var sheen := Color(0.44, 0.50, 0.51, 0.10 if state != "disabled" else 0.04)
	for y: int in range(12, int(rect.size.y) - 10, 7):
		canvas.draw_line(rect.position + Vector2(11, y), rect.position + Vector2(rect.size.x - 11, y), sheen, 1)
	var notch := minf(9, rect.size.y * 0.13)
	for x: float in [12, rect.size.x - 20]:
		canvas.draw_rect(Rect2(rect.position + Vector2(x, 12), Vector2(8, notch)), Color("1a2429"))
