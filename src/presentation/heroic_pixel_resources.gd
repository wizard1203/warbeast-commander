extends RefCounted
## Source-faithful work sites. The author pixels stay in local licensed packs;
## components, cues and ground/elevated passes never change harvesting facts.
const Atlas = preload("res://src/presentation/heroic_2d_atlas.gd")
const Collection = preload("res://src/presentation/heroic_collection.gd")
const EssenceArt = preload("res://src/presentation/heroic_essence_art.gd")
const MANIFEST := "res://assets/art/heroic/pixel-world-manifest.json"
const LOCAL_ROOT := "res://assets/third_party/heroic_world_local/"
const MINE_MEMBER := "HAS Buildings Pack/Mines/GoldMine/GoldMine.png"
const MINE_SHA := "2fb5fd14f438f04d31a7252b19e1f8fd76c0680767c91d1a38b535ece792dea2"
const GOLD_VEIN := "HAS Buildings Pack/Mines/GoldMine/GoldVein.png"
const VERSION := "heroic-pixel-work-sites-m41-v2"
const SOURCE_SCALE := 3.0
# Keep the service face at the authoritative source foot. The field grows west
# and the mine facade east, away from the larger neighbouring base's roof.
const FIELD_OFFSET := Vector2(-48, -12)
const MINE_OFFSET := Vector2(24, 0)
static var _mine_attempted := false
static var _mine_image: Image
static var _mine_texture: Texture2D
static var _mine_grey: Texture2D
static var _mine_reason := "Optional author mine not installed; existing licensed pixel composition used."
static var _metadata: Dictionary = {}

static func available(source: Dictionary) -> bool:
	return int(source.get("remaining", source.get("remaining_amount", source.get("stock", 1)))) > 0 and str(source.get("state", "")) not in ["DEPLETED", "EXHAUSTED"]

static func _linked(path: String) -> bool:
	var current := "res://"
	for part: String in path.trim_prefix("res://").split("/", false):
		var parent := DirAccess.open(current)
		if parent == null or parent.is_link(part): return true
		current = current.path_join(part)
	return false

static func _ensure_mine() -> void:
	if _mine_attempted: return
	_mine_attempted = true
	if not FileAccess.file_exists(MANIFEST) or _linked(MANIFEST): return
	var contract := FileAccess.open(MANIFEST, FileAccess.READ)
	if contract == null or contract.get_length() > 16384: return
	var parsed: Variant = JSON.parse_string(contract.get_as_text())
	if not parsed is Dictionary or parsed.get("schema_version") != 1 or parsed.get("pack_id") != "heroic-pixel-world-m41" or parsed.get("runtime_root") != LOCAL_ROOT: return
	var files: Variant = parsed.get("files", {})
	if not files is Dictionary: return
	var candidate: Variant = files.get(MINE_MEMBER, {})
	if not candidate is Dictionary: return
	var spec: Dictionary = candidate
	if spec.get("file") != "GoldMine.png" or spec.get("sha256") != MINE_SHA or spec.get("width") != 32 or spec.get("height") != 32 or spec.get("bytes") != 1007: return
	var path := LOCAL_ROOT + "GoldMine.png"
	if not FileAccess.file_exists(path) or _linked(path): return
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null or file.get_length() != 1007 or FileAccess.get_sha256(path) != MINE_SHA:
		_mine_reason = "Optional author mine integrity rejected; existing licensed pixel composition used."
		return
	var image := Image.new()
	if image.load_png_from_buffer(file.get_buffer(1007)) != OK or image.get_size() != Vector2i(32, 32): return
	image.convert(Image.FORMAT_RGBA8)
	_mine_image = image
	_mine_texture = ImageTexture.create_from_image(image)
	var grey := image.duplicate() as Image
	for y: int in range(32):
		for x: int in range(32):
			var c := grey.get_pixel(x, y)
			var light := (c.r * 0.299 + c.g * 0.587 + c.b * 0.114) * 0.7
			grey.set_pixel(x, y, Color(light, light, light, c.a))
	_mine_grey = ImageTexture.create_from_image(grey)
	_mine_reason = ""

static func _part(asset: String, key: String, offset: Vector2, scale: float, floor_part: bool = false) -> Dictionary:
	var cache_key := asset + ":" + key
	if not _metadata.has(cache_key):
		var spec: Dictionary = {}
		if asset == "starter":
			var entry := Atlas.inspect(key)
			var pixels := Atlas.region_image(key)
			if bool(entry.get("supported", false)) and pixels != null:
				spec = {"rect":entry.rect, "anchor":entry.anchor, "used":pixels.get_used_rect(), "key":key, "asset":asset}
		elif asset == "collection":
			var pixels := Collection.image("buildings", key)
			if pixels != null: spec = {"rect":Rect2i(Vector2i.ZERO, pixels.get_size()), "anchor":Vector2(16, 30), "used":pixels.get_used_rect(), "file":key, "asset":asset}
		elif asset == "optional-mine":
			_ensure_mine()
			if _mine_image != null: spec = {"rect":Rect2i(0, 0, 32, 32), "anchor":Vector2(16, 30), "used":_mine_image.get_used_rect(), "file":LOCAL_ROOT + "GoldMine.png", "sha256":MINE_SHA, "asset":asset}
		if spec.is_empty(): return {}
		_metadata[cache_key] = spec
	var result: Dictionary = _metadata[cache_key].duplicate()
	var used: Rect2i = result.used
	result["offset"] = offset
	result["scale"] = scale
	result["floor"] = floor_part
	result["bounds"] = Rect2(offset + (Vector2(used.position) - Vector2(result.anchor)) * scale, Vector2(used.size) * scale)
	return result

static func inspect(source: Dictionary, factor: float = 1.0) -> Dictionary:
	if not is_finite(factor) or factor <= 0: return {"supported":false}
	if str(source.get("resource_type",source.get("resource",source.get("kind","")))) == "ESSENCE": return EssenceArt.inspect(source,factor)
	if not bool(Atlas.validate_installation().get("ready", false)): return {"supported":false}
	var kind := str(source.get("resource_type", source.get("resource", source.get("kind", ""))))
	if kind not in ["FOOD", "MATERIAL"]: return {"supported":false}
	var active := available(source)
	var parts: Array[Dictionary] = []
	var provenance := "licensed-starter-pixel-composition"
	if kind == "FOOD":
		parts.append(_part("starter", "house_b", (FIELD_OFFSET + Vector2(-48, -46)) * factor, SOURCE_SCALE * factor))
		for row: int in range(2):
			for column: int in range(3):
				parts.append(_part("starter", "field_ripe" if active else "field_soil", (FIELD_OFFSET + Vector2((column - 1) * 42, row * 36 - 18)) * factor, SOURCE_SCALE * factor, true))
	else:
		_ensure_mine()
		if _mine_texture != null:
			parts.append(_part("optional-mine", "mine", MINE_OFFSET * factor, SOURCE_SCALE * factor))
			provenance = "licensed-heroic-gold-mine-m41"
		else:
			parts.append(_part("starter", "cave", (MINE_OFFSET + Vector2(-6, 0)) * factor, 2.5 * factor))
			if Collection.active():
				parts.append(_part("collection", GOLD_VEIN, (MINE_OFFSET + Vector2(26, 4)) * factor, 1.5 * factor))
				provenance = "licensed-heroic-starter-mine-composition"
	var bounds := Rect2()
	for part: Dictionary in parts:
		if part.is_empty(): return {"supported":false, "fallback_reason":"Required existing licensed work-site component missing"}
		bounds = bounds.merge(part.bounds) if bounds.has_area() else Rect2(part.bounds)
	var body := bounds
	var badge_size := clampf(22 * factor, 18, 28)
	var badge_center := Vector2(0, 10) * factor
	var badge := Rect2(badge_center - Vector2.ONE * badge_size * 0.5, Vector2.ONE * badge_size)
	return {"supported":true, "kind":kind, "provenance":provenance, "licensed_art":true, "original_art":false, "source_unmodified":true, "parts":parts, "bounds":body.merge(badge), "body_bounds":body, "badge_bounds":badge, "badge_center":badge_center, "badge_size":badge_size, "available":active, "depleted":not active, "state":str(source.get("state", "")), "optional_mine":_mine_texture != null if kind == "MATERIAL" else false, "fallback_reason":_mine_reason if kind == "MATERIAL" else "", "version":VERSION}

static func _draw_part(canvas: Object, point: Vector2, part: Dictionary, active: bool) -> void:
	var foot: Vector2 = point + Vector2(part.offset)
	var tint := Color.WHITE if active or bool(part.floor) else Color("868b7b")
	if part.asset == "starter": Atlas.draw_sprite(canvas, str(part.key), foot, float(part.scale), tint)
	elif part.asset == "collection": Collection.draw_region(canvas, "buildings", str(part.file), part.rect, foot, part.anchor, float(part.scale), tint)
	else:
		canvas.draw_texture_rect_region(_mine_texture if active else _mine_grey, Rect2((foot - Vector2(part.anchor) * float(part.scale)).round(), Vector2(32, 32) * float(part.scale)), Rect2(part.rect), Color.WHITE)

static func draw_floor(canvas: Object, point: Vector2, source: Dictionary, factor: float = 1.0) -> bool:
	if not point.is_finite(): return false
	var info := inspect(source, factor)
	if not bool(info.get("supported", false)): return false
	if info.kind == "ESSENCE": return true # Rocky foot is in the elevated sprite.
	if canvas is CanvasItem: canvas.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	for part: Dictionary in info.parts:
		if bool(part.floor): _draw_part(canvas, point, part, bool(info.available))
	return true

static func draw(canvas: Object, point: Vector2, source: Dictionary, factor: float = 1.0, include_floor: bool = true) -> bool:
	if not point.is_finite(): return false
	var info := inspect(source, factor)
	if not bool(info.get("supported", false)): return false
	if info.kind == "ESSENCE":
		EssenceArt.draw(canvas,point,source,factor)
		_draw_badge(canvas,point+Vector2(info.badge_center),float(info.badge_size),"ESSENCE",bool(info.available))
		return true
	if canvas is CanvasItem: canvas.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	for part: Dictionary in info.parts:
		if include_floor or not bool(part.floor): _draw_part(canvas, point, part, bool(info.available))
	_draw_badge(canvas, point + Vector2(info.badge_center), float(info.badge_size), str(info.kind), bool(info.available))
	return true

static func _draw_badge(canvas: Object, point: Vector2, extent: float, kind: String, active: bool) -> void:
	var s := extent / 22.0
	var ink := Color("e5c977") if active else Color("8c9486")
	canvas.draw_rect(Rect2((point - Vector2.ONE * extent * 0.5).round(), Vector2.ONE * extent), Color("212b29"))
	canvas.draw_rect(Rect2((point - Vector2.ONE * extent * 0.5).round(), Vector2.ONE * extent), Color("938369"), false, maxf(s, 1))
	if kind == "FOOD":
		canvas.draw_rect(Rect2(point + Vector2(-1, -7) * s, Vector2(2, 15) * s), ink)
		for y: int in [-5, -1, 3]:
			canvas.draw_rect(Rect2(point + Vector2(-5, y - 1) * s, Vector2(4, 3) * s), ink)
			canvas.draw_rect(Rect2(point + Vector2(1, y - 3) * s, Vector2(4, 3) * s), ink)
	elif kind == "ESSENCE":
		for part: Array in [[-5,-3,3,9],[-1,-7,4,14],[4,-1,3,7]]:
			canvas.draw_rect(Rect2(point+Vector2(part[0],part[1])*s,Vector2(part[2],part[3])*s),Color("c1a0d8") if active else ink)
	else:
		canvas.draw_rect(Rect2(point + Vector2(-6, -3) * s, Vector2(12, 8) * s), ink)
		canvas.draw_rect(Rect2(point + Vector2(-3, -6) * s, Vector2(7, 4) * s), ink.lightened(0.12))
	if not active: canvas.draw_line(point + Vector2(-7, 7) * s, point + Vector2(7, -7) * s, Color("c2a592"), maxf(2 * s, 1))

static func debug_stats() -> Dictionary:
	_ensure_mine()
	return {"version":VERSION, "resource_types":["FOOD", "MATERIAL", "ESSENCE"], "provenance":"licensed-pixel-source-compositions-and-original-spirit-vein", "optional_mine":_mine_texture != null, "optional_mine_reason":_mine_reason, "optional_texture_bytes":8192 if _mine_texture != null else 0, "optional_cpu_bytes":4096 if _mine_image != null else 0, "metadata_entries":_metadata.size(), "metadata_capacity":8, "owner_atlas_copies":0, "generated_m38_priority":false,"essence":EssenceArt.debug_stats()}
