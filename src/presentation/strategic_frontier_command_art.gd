extends RefCounted
## Shared painted art at the existing draw seam. No Control, hit shape,
## simulation query, per-button texture copy or synthetic gameplay state.
const Collection = preload("res://src/presentation/strategic_frontier_collection.gd")
const PAINTED_SYMBOLS := ["economy", "recruit", "build", "army", "tech", "hero", "move", "attack_move", "attack", "retreat", "hold", "stop", "food", "material", "population", "worker", "health", "mana", "sword", "armor", "range", "equipment", "potion", "menu", "BASE", "BARRACKS", "RANGE", "TOWER", "FOUNDRY", "ALTAR", "WORKSHOP", "DRAGON_ROOST", "resource", "village", "cancel", "refresh", "STEADY", "LOOSE", "COLUMN", "SPEAR", "guard", "bow", "SHIELD_SHOCK", "BULWARK_WARD", "BULWARK_RECOVER", "STARFIRE", "FROST_BIND", "ARCANE_BURST", "PIERCING_SHOT", "ARROW_RAIN", "QUICKDRAW", "SEAL_STRIKE", "WHIRLWIND", "BLOOD_PACT", "IRON_BLADE", "WARD_MAIL", "RALLY", "RECOVER", "AUTO_ATTACK", "AUTO_CAST"]

static func enabled() -> bool:
	return Collection.enabled()

static func button_semantics(disabled: bool, required_tier: int, fact: String, interactive_state: String) -> Dictionary:
	# Disabled is an input permission, not a reason. Consume the existing
	# factual technology/building state instead of presenting every inert
	# button as a locked/unbuilt feature.
	if fact in ["BUILT", "UPGRADED"]: return {"frame":"complete", "badge":"complete", "grayscale":false, "fact":fact}
	if fact in ["CONSTRUCTING", "RUNNING"]: return {"frame":"running", "badge":"running", "grayscale":false, "fact":fact}
	if fact == "UNAFFORDABLE": return {"frame":"unaffordable", "badge":"unaffordable", "grayscale":true, "fact":fact}
	if fact == "LOCKED" or (disabled and required_tier > 0): return {"frame":"disabled", "badge":"lock", "grayscale":true, "fact":fact}
	if disabled: return {"frame":"disabled", "badge":"unavailable", "grayscale":true, "fact":fact}
	return {"frame":interactive_state, "badge":"", "grayscale":false, "fact":fact}

static func draw_status_badge(canvas: Object, point: Vector2, badge: String) -> void:
	if badge.is_empty(): return
	canvas.draw_circle(point, 8, Color("172027"))
	match badge:
		"complete":
			canvas.draw_line(point + Vector2(-5, 0), point + Vector2(-1, 4), Color("b8df9d"), 2)
			canvas.draw_line(point + Vector2(-1, 4), point + Vector2(6, -5), Color("b8df9d"), 2)
		"running":
			canvas.draw_line(point + Vector2(-4, -5), point + Vector2(4, -5), Color("9ac9dc"), 2)
			canvas.draw_line(point + Vector2(-4, 5), point + Vector2(4, 5), Color("9ac9dc"), 2)
			canvas.draw_line(point + Vector2(-4, -4), point + Vector2(4, 4), Color("9ac9dc"), 1.5)
			canvas.draw_line(point + Vector2(4, -4), point + Vector2(-4, 4), Color("9ac9dc"), 1.5)
		"unaffordable":
			canvas.draw_line(point + Vector2(0, -5), point + Vector2(0, 1), Color("ebbe75"), 2)
			canvas.draw_circle(point + Vector2(0, 4), 1.3, Color("ebbe75"))
		"lock":
			canvas.draw_arc(point + Vector2(0, -2), 3, PI, TAU, 12, Color("a8b0ac"), 2)
			canvas.draw_rect(Rect2(point + Vector2(-4, -2), Vector2(8, 7)), Color("a8b0ac"))
			canvas.draw_line(point + Vector2(0, 0), point + Vector2(0, 3), Color("243238"), 1)
		_:
			canvas.draw_line(point + Vector2(-4, 0), point + Vector2(4, 0), Color("a8b0ac"), 2)

static func inspect(symbol: String, disabled: bool = false) -> Dictionary:
	if not enabled(): return {"supported":false}
	var aliases := {"hinge_guard":"guard", "bright_crossbow":"bow", "lancer":"sword", "iron_lancer":"sword", "grove_mender":"potion", "home":"retreat", "CLEAVE":"sword"}
	var canonical := str(aliases.get(symbol, symbol))
	if canonical not in PAINTED_SYMBOLS: return {"supported":false}
	var id := "icon_" + canonical
	var result := Collection.get_entry(id)
	result["symbol"] = symbol
	result["disabled"] = disabled
	return result

static func draw_symbol(canvas: Object, symbol: String, center: Vector2, color: Color, scale_factor: float = 1.0) -> bool:
	var entry := inspect(symbol, _disabled_ink(color))
	if not bool(entry.get("supported", false)): return false
	# Existing consumers draw a dark vector shadow and then the foreground.
	# The atlas already contains material shading: consume the old shadow pass
	# without painting a second full-color icon a pixel below the first one.
	if _shadow_ink(color): return true
	var side := 40.0 * scale_factor
	var destination := Rect2(center - Vector2.ONE * side * 0.5, Vector2.ONE * side)
	var modulate := Color("9aa3a3") if _disabled_ink(color) else Color.WHITE
	return Collection.draw_in_rect(canvas, destination, str(entry.get("entry_id", "")), modulate, _disabled_ink(color))

static func draw_surface(canvas: Object, rect: Rect2, role: String, state: String) -> bool:
	if not enabled(): return false
	var plate := "plate_command"
	if role in ["stone", "panel", "lobby", "strip"]: plate = "plate_panel"
	elif role in ["dock", "map"]: plate = "plate_map"
	elif role == "hero": plate = "plate_hero"
	var entry := Collection.get_entry(plate)
	if not bool(entry.get("supported", false)): return false
	var texture: Texture2D = Collection.texture(str(entry.entry_id))
	if texture == null: return false
	var tint := Color.WHITE
	if state == "disabled": tint = Color("6c7476")
	elif state == "pressed": tint = Color("929a9c")
	elif state == "hover": tint = Color("fff1d9")
	elif state == "complete": tint = Color("d5e1c6")
	elif state == "running": tint = Color("bed6df")
	_nine_slice(canvas, texture, entry.rect, rect, tint, entry.get("nine_slice", []))
	# A quiet, unpatterned center is intentional: text and resource numbers
	# must remain the foreground even on a large stone management panel.
	var quiet := Color(0.035, 0.05, 0.057, 0.30 if rect.size.y < 100 else 0.63)
	canvas.draw_rect(rect.grow(-8), quiet)
	draw_frame(canvas, rect, state)
	return true

static func draw_frame(canvas: Object, rect: Rect2, state: String, accent: Color = Color.TRANSPARENT) -> void:
	var edge := Color("706751")
	if state == "selected": edge = Color("e9bf75")
	elif state == "hover": edge = Color("bdab80")
	elif state == "pressed": edge = Color("4c4740")
	elif state == "disabled": edge = Color("525c60")
	elif state == "complete": edge = Color("95b881")
	elif state == "running": edge = Color("85b8c9")
	elif state == "unaffordable": edge = Color("b89561")
	if accent.a > 0: edge = accent
	canvas.draw_rect(rect.grow(-2), Color("11191f"), false, 2)
	canvas.draw_rect(rect.grow(-3), edge, false, 2 if state == "selected" else 1)
	if state == "pressed":
		canvas.draw_line(rect.position + Vector2(6, 6), rect.position + Vector2(rect.size.x - 6, 6), Color("11181c"), 3)
	elif state == "selected":
		canvas.draw_line(rect.position + Vector2(10, rect.size.y - 4), rect.end - Vector2(10, 4), Color("f3d494"), 3)

static func _nine_slice(canvas: Object, texture: Texture2D, source: Rect2, destination: Rect2, tint: Color, authored_margins: Array) -> void:
	# Share one atlas; draw source regions directly, without nine AtlasTexture
	# resources or one copied bitmap per surface/control.
	var margins := authored_margins if authored_margins.size() == 4 else [18.0, 18.0, 18.0, 18.0]
	var left := clampf(float(margins[0]), 0, source.size.x * 0.45)
	var top := clampf(float(margins[1]), 0, source.size.y * 0.45)
	var right := clampf(float(margins[2]), 0, source.size.x * 0.45)
	var bottom := clampf(float(margins[3]), 0, source.size.y * 0.45)
	var edge := minf(10.0, minf(destination.size.x, destination.size.y) * 0.22)
	var sx := [source.position.x, source.position.x + left, source.end.x - right, source.end.x]
	var sy := [source.position.y, source.position.y + top, source.end.y - bottom, source.end.y]
	var dx := [destination.position.x, destination.position.x + edge, destination.end.x - edge, destination.end.x]
	var dy := [destination.position.y, destination.position.y + edge, destination.end.y - edge, destination.end.y]
	for row: int in range(3):
		for column: int in range(3):
			canvas.draw_texture_rect_region(texture, Rect2(dx[column], dy[row], dx[column + 1] - dx[column], dy[row + 1] - dy[row]), Rect2(sx[column], sy[row], sx[column + 1] - sx[column], sy[row + 1] - sy[row]), tint)

static func _shadow_ink(color: Color) -> bool:
	return maxf(color.r, maxf(color.g, color.b)) < 0.28

static func _disabled_ink(color: Color) -> bool:
	return color.r < 0.62 and color.g < 0.69 and color.b < 0.66 and not _shadow_ink(color)
