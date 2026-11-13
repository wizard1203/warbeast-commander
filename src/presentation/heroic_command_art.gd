extends RefCounted
## Original matte command language and an optional shared icon atlas. This
## module observes only supplied presentation state; it owns no input or rules.
const MANIFEST_PATH := "res://assets/art/original/m38/ui/manifest.json"
const ROOT := "res://assets/art/original/m38/ui/"
const PROVENANCE := "original-ai-pixel-m38-ui"
const MAX_RGBA_BYTES := 128 * 192 * 4
const SYMBOLS := ["economy", "recruit", "build", "army", "tech", "menu", "food", "material", "population", "health", "damage", "armor", "range", "move", "attack_move", "retreat", "home", "LOOSE", "COLUMN", "SPEAR", "cancel", "potion", "equipment", "hero"]
static var _attempted := false
static var _entries: Dictionary = {}
static var _ink_bounds: Dictionary = {}
static var _texture: Texture2D
static var _gray_texture: Texture2D
static var _failure := ""
static var _source_bytes := 0


static func enabled() -> bool:
	# Exactly the existing Heroic route. Explicit comparison launchers retain
	# their historical materials and artwork rather than sharing this skin.
	var args := OS.get_cmdline_user_args()
	return not ("--legacy-2d" in args or "--frontier-art" in args or "--classic-art" in args or "--frontier-3d" in args)


static func reset_cache() -> void:
	_attempted = false
	_entries.clear()
	_ink_bounds.clear()
	_texture = null
	_gray_texture = null
	_failure = ""
	_source_bytes = 0


static func fill(role: String, state: String) -> Color:
	# Narrow, desaturated ramps leave the licensed pixel illustrations and
	# warm parchment captions in the foreground, not a busy faux texture.
	var value := Color("30352c")
	if role in ["stone", "panel", "lobby", "strip", "map"]: value = Color("222e2d")
	elif role in ["wood", "dock"]: value = Color("382f27")
	elif role == "hero": value = Color("3b3030")
	elif role == "tech": value = Color("283333")
	if state == "pressed": return value.darkened(0.27)
	if state == "disabled": return value.lerp(Color("242727"), 0.66)
	if state == "hover": return value.lightened(0.08)
	if state in ["selected", "focus"]: return value.lerp(Color("645b39"), 0.20)
	if state == "complete": return value.lerp(Color("354235"), 0.25)
	if state == "running": return value.lerp(Color("304148"), 0.25)
	if state == "unaffordable": return value.lerp(Color("453b2c"), 0.20)
	return value


static func edge(state: String) -> Color:
	match state:
		"hover": return Color("c6ad76")
		"selected", "focus": return Color("e2bc68")
		"pressed": return Color("8a7049")
		"disabled": return Color("4c5950")
		"complete": return Color("9cba83")
		"running": return Color("7ba6b0")
		"unaffordable": return Color("aa895d")
	return Color("827454")


static func style(state: String, role: String) -> StyleBoxFlat:
	var result := StyleBoxFlat.new()
	result.bg_color = fill(role, state)
	result.border_color = edge(state)
	result.set_corner_radius_all(0)
	# Native OptionButton / PopupMenu still require a StyleBoxFlat. The custom
	# painted controls add stepped ink below without changing content margins.
	result.set_border_width_all(2)
	result.shadow_size = 0
	# Content and pointer geometry remain exactly those of the existing HUD.
	result.content_margin_left = 10
	result.content_margin_right = 10
	return result


static func draw_surface(canvas: Object, rect: Rect2, role: String, state: String) -> void:
	if not _valid_rect(rect) or rect.size.x < 12 or rect.size.y < 12: return
	var bounds := Rect2(rect.position.round(), rect.size.floor())
	_pixel_fill(canvas, bounds, fill(role,state), 4)
	if bounds.size.x >= 28 and bounds.size.y >= 28:
		var inner := bounds.grow(-6)
		canvas.draw_rect(inner, fill(role,state).darkened(0.06))
		# One recessed header, not a tiled background behind all the text.
		if role in ["panel","stone","lobby"] and bounds.size.x >= 500 and bounds.size.y >= 300:
			var header_height := 64.0 if role != "lobby" else 108.0
			canvas.draw_rect(Rect2(inner.position,Vector2(inner.size.x,header_height)),fill(role,state).darkened(0.16))
			canvas.draw_rect(Rect2(inner.position+Vector2(8,header_height),Vector2(inner.size.x-16,2)),Color("111d1c"))
			canvas.draw_rect(Rect2(inner.position+Vector2(8,header_height+2),Vector2(inner.size.x-16,1)),edge(state).darkened(0.35))
		# Edge-only wear, capped independently of the surface's total area.
		# Keep the center empty for readable Chinese and collection artwork.
		var count := mini(6,maxi(0,int(bounds.size.x/140)))
		for i: int in range(count):
			var x := 22.0+float(i)*floorf((bounds.size.x-44)/maxi(count,1))
			canvas.draw_rect(Rect2(bounds.position+Vector2(x,7),Vector2(7,1)),fill(role,state).lightened(0.13))
			canvas.draw_rect(Rect2(bounds.position+Vector2(x+3,bounds.size.y-9),Vector2(4,1)),Color("172321"))
		if role in ["wood","dock"]:
			canvas.draw_rect(Rect2(inner.position+Vector2(2,2),Vector2(inner.size.x-4,2)),Color("574731"))
			canvas.draw_rect(Rect2(inner.position+Vector2(2,inner.size.y-4),Vector2(inner.size.x-4,2)),Color("211f1b"))
	draw_frame(canvas,bounds,state)


static func draw_frame(canvas: Object, rect: Rect2, state: String, accent: Color = Color.TRANSPARENT) -> void:
	if not _valid_rect(rect) or rect.size.x < 12 or rect.size.y < 12: return
	var bounds := Rect2(rect.position.round(),rect.size.floor())
	var rim := edge(state) if accent.a == 0 else accent
	# Coarse ink silhouette + one old-gold rim + a dark inner cut. Every mark
	# is an integral filled pixel rectangle, never a filtered beveled vector.
	_pixel_outline(canvas,bounds,Color("080f10"),2,4)
	_pixel_outline(canvas,bounds.grow(-2),rim,1,2)
	_pixel_outline(canvas,bounds.grow(-3),Color("111d1c"),1,1)
	if bounds.size.x < 28 or bounds.size.y < 28: return
	var top_ink := Color("111817") if state=="pressed" else rim.lightened(0.12).darkened(0.22)
	canvas.draw_rect(Rect2(bounds.position+Vector2(7,4),Vector2(bounds.size.x-14,1)),top_ink)
	canvas.draw_rect(Rect2(bounds.position+Vector2(4,7),Vector2(1,bounds.size.y-14)),top_ink)
	canvas.draw_rect(Rect2(bounds.position+Vector2(7,bounds.size.y-5),Vector2(bounds.size.x-14,1)),Color("101917"))
	if state in ["selected","focus","complete","running","unaffordable"]:
		canvas.draw_rect(Rect2(bounds.position+Vector2(10,bounds.size.y-5),Vector2(bounds.size.x-20,2)),rim)
		if state in ["selected","focus"]:
			# Two tiny lit corners give selection a shape cue as well as color.
			canvas.draw_rect(Rect2(bounds.position+Vector2(4,4),Vector2(5,2)),Color("f2d795"))
			canvas.draw_rect(Rect2(bounds.position+Vector2(bounds.size.x-9,bounds.size.y-6),Vector2(5,2)),Color("f2d795"))
	elif state=="hover":
		canvas.draw_rect(Rect2(bounds.position+Vector2(9,4),Vector2(bounds.size.x-18,2)),rim.lightened(0.12))


static func _pixel_fill(canvas: Object, rect: Rect2, color: Color, cut: int) -> void:
	canvas.draw_rect(Rect2(rect.position+Vector2(cut,0),Vector2(rect.size.x-cut*2,rect.size.y)),color)
	canvas.draw_rect(Rect2(rect.position+Vector2(0,cut),Vector2(cut,rect.size.y-cut*2)),color)
	canvas.draw_rect(Rect2(rect.position+Vector2(rect.size.x-cut,cut),Vector2(cut,rect.size.y-cut*2)),color)


static func _pixel_outline(canvas: Object, rect: Rect2, color: Color, width: int, cut: int) -> void:
	canvas.draw_rect(Rect2(rect.position+Vector2(cut,0),Vector2(rect.size.x-cut*2,width)),color)
	canvas.draw_rect(Rect2(rect.position+Vector2(cut,rect.size.y-width),Vector2(rect.size.x-cut*2,width)),color)
	canvas.draw_rect(Rect2(rect.position+Vector2(0,cut),Vector2(width,rect.size.y-cut*2)),color)
	canvas.draw_rect(Rect2(rect.position+Vector2(rect.size.x-width,cut),Vector2(width,rect.size.y-cut*2)),color)
	for corner: Vector2 in [Vector2.ZERO,Vector2.RIGHT,Vector2.DOWN,Vector2.ONE]:
		canvas.draw_rect(Rect2(rect.position+Vector2(width if corner.x==0 else rect.size.x-cut, width if corner.y==0 else rect.size.y-cut),Vector2(maxi(cut-width,1),maxi(cut-width,1))),color)


static func button_semantics(disabled: bool, required_tier: int, fact: String, interactive_state: String) -> Dictionary:
	# Permission and its factual reason remain separate. In particular, a
	# completed technology is not depicted as locked just because it is inert.
	if fact in ["BUILT", "UPGRADED"]: return {"frame":"complete", "badge":"complete", "grayscale":false, "fact":fact}
	if fact in ["CONSTRUCTING", "RUNNING"]: return {"frame":"running", "badge":"running", "grayscale":false, "fact":fact}
	if fact == "BLOCKED_FOUNDRY": return {"frame":"unaffordable", "badge":"paused", "grayscale":false, "fact":fact}
	if fact == "UNAFFORDABLE": return {"frame":"unaffordable", "badge":"unaffordable", "grayscale":true, "fact":fact}
	if fact == "LOCKED" or (disabled and required_tier > 0): return {"frame":"disabled", "badge":"lock", "grayscale":true, "fact":fact}
	if disabled: return {"frame":"disabled", "badge":"unavailable", "grayscale":true, "fact":fact}
	return {"frame":interactive_state, "badge":"", "grayscale":false, "fact":fact}


static func draw_status_badge(canvas: Object, point: Vector2, badge: String) -> void:
	if badge.is_empty(): return
	canvas.draw_rect(Rect2(point - Vector2(7, 7), Vector2(14, 14)), Color("141b1b"))
	canvas.draw_rect(Rect2(point - Vector2(7, 7), Vector2(14, 14)), Color("746c57"), false, 1)
	match badge:
		"complete":
			canvas.draw_line(point + Vector2(-4, 0), point + Vector2(-1, 3), Color("b2c990"), 2)
			canvas.draw_line(point + Vector2(-1, 3), point + Vector2(5, -4), Color("b2c990"), 2)
		"running":
			canvas.draw_line(point + Vector2(-4, -4), point + Vector2(4, -4), Color("8bb9c3"), 1)
			canvas.draw_line(point + Vector2(-4, 4), point + Vector2(4, 4), Color("8bb9c3"), 1)
			canvas.draw_line(point + Vector2(-3, -3), point + Vector2(3, 3), Color("8bb9c3"), 1)
			canvas.draw_line(point + Vector2(3, -3), point + Vector2(-3, 3), Color("8bb9c3"), 1)
		"lock":
			canvas.draw_arc(point + Vector2(0, -2), 3, PI, TAU, 8, Color("b0afa1"), 1)
			canvas.draw_rect(Rect2(point + Vector2(-4, -2), Vector2(8, 7)), Color("9b9e91"))
			canvas.draw_rect(Rect2(point + Vector2(0, 0), Vector2(1, 3)), Color("252c29"))
		"paused":
			canvas.draw_rect(Rect2(point + Vector2(-4, -4), Vector2(3, 8)), Color("d6b977"))
			canvas.draw_rect(Rect2(point + Vector2(1, -4), Vector2(3, 8)), Color("d6b977"))
		"unaffordable":
			canvas.draw_line(point + Vector2(0, -4), point + Vector2(0, 1), Color("d6b977"), 2)
			canvas.draw_rect(Rect2(point + Vector2(-1, 3), Vector2(2, 2)), Color("d6b977"))
		_:
			canvas.draw_line(point + Vector2(-4, 0), point + Vector2(4, 0), Color("9b9e91"), 2)


static func inspect(symbol: String) -> Dictionary:
	if not enabled() or not _ensure_loaded() or not _entries.has(symbol): return {"supported":false}
	return {"supported":true, "symbol":symbol, "rect":_entries[symbol], "ink_bounds":_ink_bounds[symbol], "provenance":PROVENANCE, "shared_texture":true}


static func draw_symbol(canvas: Object, symbol: String, center: Vector2, color: Color, scale_factor: float = 1.0) -> bool:
	if not center.is_finite() or not is_finite(scale_factor) or scale_factor <= 0 or not _valid_color(color): return false
	if enabled() and symbol in ["AUTO_ATTACK", "AUTO_CAST"]:
		_draw_auto_symbol(canvas, symbol, center, color, scale_factor)
		return true
	var entry := inspect(symbol)
	if not bool(entry.get("supported", false)): return false
	# Existing icon clients draw a dark shadow pass. Authored shading is already
	# in the pixels, so consume it without drawing a doubled colored icon.
	if maxf(color.r, maxf(color.g, color.b)) < 0.28: return true
	var disabled := color.r < 0.62 and color.g < 0.69 and color.b < 0.66
	var side := 48.0 * scale_factor
	if canvas is CanvasItem: canvas.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	canvas.draw_texture_rect_region(_gray_texture if disabled else _texture, Rect2((center - Vector2.ONE * side * 0.5).round(), Vector2.ONE * side), Rect2(entry.rect), Color("a3a69d") if disabled else Color.WHITE)
	return true


static func _draw_auto_symbol(canvas: Object, symbol: String, center: Vector2, color: Color, scale_factor: float) -> void:
	# These two small, original code-native signs do not masquerade as atlas
	# artwork. Loop + blade / loop + star distinguish the existing auto toggles.
	var s := scale_factor
	canvas.draw_arc(center, 17 * s, 0.3, 5.4, 16, color.darkened(0.18), 2 * s)
	canvas.draw_line(center + Vector2(10, -14) * s, center + Vector2(10, -7) * s, color, 2 * s)
	canvas.draw_line(center + Vector2(10, -14) * s, center + Vector2(3, -14) * s, color, 2 * s)
	if symbol == "AUTO_ATTACK":
		canvas.draw_line(center + Vector2(-8, 9) * s, center + Vector2(7, -7) * s, color, 4 * s)
		canvas.draw_line(center + Vector2(-9, 0) * s, center + Vector2(0, 9) * s, color, 3 * s)
		canvas.draw_line(center + Vector2(-11, 12) * s, center + Vector2(-7, 8) * s, color, 3 * s)
	else:
		canvas.draw_line(center + Vector2(0, -10) * s, center + Vector2(0, 10) * s, color, 3 * s)
		canvas.draw_line(center + Vector2(-10, 0) * s, center + Vector2(10, 0) * s, color, 3 * s)
		canvas.draw_line(center + Vector2(-6, -6) * s, center + Vector2(6, 6) * s, color, 2 * s)
		canvas.draw_line(center + Vector2(6, -6) * s, center + Vector2(-6, 6) * s, color, 2 * s)


static func debug_stats() -> Dictionary:
	if enabled(): _ensure_loaded()
	return {"enabled":enabled(), "accepted":_texture != null, "accepted_count":_entries.size(), "expected_count":SYMBOLS.size(), "logical_icon_side":48, "provenance":PROVENANCE, "manifest_path":MANIFEST_PATH, "fallback_reason":_failure, "texture_count":2 if _texture != null else 0, "texture_bytes":_source_bytes * 2, "cpu_pixel_bytes":0, "owner_atlas_copies":0}


static func _ensure_loaded() -> bool:
	if _attempted: return _texture != null
	_attempted = true
	if not FileAccess.file_exists(MANIFEST_PATH): return _reject("Optional original UI atlas not installed; existing symbols retained.")
	var text := FileAccess.get_file_as_string(MANIFEST_PATH)
	if text.length() > 128 * 1024: return _reject("Original UI metadata exceeds budget.")
	var parsed: Variant = JSON.parse_string(text)
	if not parsed is Dictionary or not _canonical_number(parsed.get("schema_version"), 1) or str(parsed.get("provenance", "")) != PROVENANCE or not parsed.get("accepted") is bool or parsed.get("accepted") != true or str(parsed.get("status", "")) != "accepted": return _reject("Original UI atlas is not accepted metadata.")
	var cell_size: Variant = parsed.get("cell_size", [])
	# JSON numbers decode as floats. Validate numeric meaning instead of a
	# type-sensitive Array equality against integer literals.
	if not cell_size is Array or cell_size.size() != 2 or not _canonical_number(cell_size[0], 32) or not _canonical_number(cell_size[1], 32) or not _canonical_number(parsed.get("columns"), 4) or not _canonical_number(parsed.get("rows"), 6) or not _canonical_number(parsed.get("width"), 128) or not _canonical_number(parsed.get("height"), 192): return _reject("Original UI atlas grid differs from the canonical layout.")
	var file := str(parsed.get("file", ""))
	if not file.begins_with("runtime/") or not file.ends_with(".png") or file.contains("\\") or file.contains(":") or file.split("/").size() != 2 or file.contains("..") or file.contains("/./"): return _reject("Unsafe original UI atlas path.")
	var path := ROOT + file
	if not FileAccess.file_exists(path): return _reject("Accepted original UI PNG absent.")
	var source_file := FileAccess.open(path, FileAccess.READ)
	if source_file == null or source_file.get_length() <= 0 or source_file.get_length() > 1024 * 1024 or not _canonical_number(parsed.get("bytes"), source_file.get_length()) or FileAccess.get_sha256(path) != str(parsed.get("sha256", "")): return _reject("Original UI PNG hash or length differs.")
	# Verify the bounded IHDR before decoding, not after a hostile PNG has
	# already requested a huge pixel allocation under a small compressed file.
	var encoded := source_file.get_buffer(source_file.get_length())
	if encoded.size() < 24 or encoded.slice(0, 8).hex_encode() != "89504e470d0a1a0a" or encoded.slice(12, 16).get_string_from_ascii() != "IHDR" or _big_endian(encoded, 16) != 128 or _big_endian(encoded, 20) != 192: return _reject("Original UI PNG header differs from the canonical layout.")
	var image := Image.new()
	if image.load_png_from_buffer(encoded) != OK or image.get_size() != Vector2i(128, 192): return _reject("Original UI PNG does not have canonical dimensions.")
	image.convert(Image.FORMAT_RGBA8)
	var entries: Variant = parsed.get("symbols", {})
	if not entries is Dictionary or entries.size() != SYMBOLS.size(): return _reject("Original UI metadata must name all 24 symbols.")
	var accepted_entries: Dictionary = {}
	var accepted_ink_bounds: Dictionary = {}
	var occupied := {}
	for symbol: String in SYMBOLS:
		var cell: Variant = entries.get(symbol, [])
		if not cell is Array or cell.size() != 4: return _reject("Original UI symbol rectangle absent: " + symbol)
		for value: Variant in cell:
			if not (value is int or value is float) or not is_finite(float(value)) or float(value) != floorf(float(value)): return _reject("Original UI symbol rectangle is not integral: " + symbol)
		var source := Rect2i(int(cell[0]), int(cell[1]), int(cell[2]), int(cell[3]))
		if source.size != Vector2i(32, 32) or source.position.x % 32 != 0 or source.position.y % 32 != 0 or not Rect2i(0, 0, 128, 192).encloses(source) or occupied.has(source.position): return _reject("Original UI symbol rectangle overlaps or escapes: " + symbol)
		var count := 0
		var ink_min := Vector2i(32, 32)
		var ink_end := Vector2i.ZERO
		for y: int in range(source.position.y, source.end.y):
			for x: int in range(source.position.x, source.end.x):
				var alpha := image.get_pixel(x, y).a
				var gutter := x < source.position.x + 2 or y < source.position.y + 2 or x >= source.end.x - 2 or y >= source.end.y - 2
				if gutter and alpha > 0: return _reject("Original UI symbol crosses its two-pixel gutter: " + symbol)
				if alpha > 0:
					var local := Vector2i(x, y) - source.position
					ink_min = Vector2i(mini(ink_min.x, local.x), mini(ink_min.y, local.y))
					ink_end = Vector2i(maxi(ink_end.x, local.x + 1), maxi(ink_end.y, local.y + 1))
				if alpha > 0.1: count += 1
		if count < 16: return _reject("Original UI symbol is empty: " + symbol)
		occupied[source.position] = true
		accepted_entries[symbol] = source
		accepted_ink_bounds[symbol] = Rect2i(ink_min, ink_end - ink_min)
	_texture = ImageTexture.create_from_image(image)
	# One shared grayscale atlas, not 24 bitmaps and not one copy per button.
	for y: int in range(image.get_height()):
		for x: int in range(image.get_width()):
			var pixel := image.get_pixel(x, y)
			var luminance := pixel.r * 0.299 + pixel.g * 0.587 + pixel.b * 0.114
			image.set_pixel(x, y, Color(luminance, luminance, luminance, pixel.a))
	_gray_texture = ImageTexture.create_from_image(image)
	_source_bytes = 128 * 192 * 4
	_entries = accepted_entries
	_ink_bounds = accepted_ink_bounds
	return true


static func _reject(reason: String) -> bool:
	_failure = reason
	return false


static func _valid_rect(rect: Rect2) -> bool:
	return rect.position.is_finite() and rect.size.is_finite() and rect.size.x > 0 and rect.size.y > 0


static func _valid_color(color: Color) -> bool:
	return is_finite(color.r) and is_finite(color.g) and is_finite(color.b) and is_finite(color.a)


static func _big_endian(data: PackedByteArray, offset: int) -> int:
	return (int(data[offset]) << 24) | (int(data[offset + 1]) << 16) | (int(data[offset + 2]) << 8) | int(data[offset + 3])


static func _canonical_number(value: Variant, expected: int) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value) == float(expected)
