extends RefCounted
## Optional, presentation-only Blender-to-2D slice. No simulation, clocks,
## side-tinted atlas copies or per-instance textures are created here.
const MANIFEST_PATH := "res://assets/art/classic_slice/manifest.json"
const Palette = preload("res://src/presentation/strategic_side_palette.gd")
const MAX_TEXTURE_BYTES := 32 * 1024 * 1024
const DIRECTIONS := ["E", "SE", "S", "SW", "W", "NW", "N", "NE"]
static var _override := -1
static var _attempted := false
static var _manifest: Dictionary = {}
static var _atlases: Dictionary = {}
static var _hit_masks: Dictionary = {}
static var _failures: Array[String] = []

static func enabled() -> bool:
	return _override == 1 if _override >= 0 else "--classic-art" in OS.get_cmdline_user_args()

static func set_enabled(value: bool) -> void:
	_override = 1 if value else 0

static func clear_override() -> void:
	_override = -1

static func reset_cache() -> void:
	_attempted = false
	_manifest.clear()
	_atlases.clear()
	_hit_masks.clear()
	_failures.clear()

static func debug_stats() -> Dictionary:
	if enabled(): _ensure_loaded()
	var base_count := 0
	var mask_count := 0
	var texture_bytes := 0
	var hit_mask_bytes := 0
	for atlas: Dictionary in _atlases.values():
		base_count += 1
		texture_bytes += int(atlas.bytes)
		if atlas.get("mask") != null: mask_count += 1
	for hit_mask: Dictionary in _hit_masks.values(): hit_mask_bytes += PackedByteArray(hit_mask.bits).size()
	return {"enabled":enabled(), "atlas_textures":base_count, "mask_textures":mask_count,
		"texture_bytes":texture_bytes, "loaded_atlases":_atlases.keys(),
		"failures":_failures.duplicate(), "owner_atlas_copies":0,
		"retained_cpu_images":0, "hit_mask_bytes":hit_mask_bytes, "manifest_path":MANIFEST_PATH}

static func inspect(kind: String, source: Variant, pose: Dictionary = {}) -> Dictionary:
	if not enabled() or not _ensure_loaded(): return {"supported":false}
	var entry_id := ""
	var observation: Dictionary = source if source is Dictionary else {}
	match kind.to_lower():
		"unit":
			entry_id = str(observation.get("unit_type", ""))
			if entry_id not in ["worker", "hinge_guard", "bright_crossbow"]: return {"supported":false}
			if str(observation.get("faction_id", "HUMAN")) != "HUMAN": return {"supported":false}
			if int(observation.get("hp", 1)) <= 0 or not bool(observation.get("alive", true)): return {"supported":false}
		"building":
			entry_id = str(observation.get("building_type", ""))
			if entry_id not in ["BASE", "BARRACKS"] or str(observation.get("faction_id", "HUMAN")) != "HUMAN": return {"supported":false}
			if int(observation.get("hp", 0)) <= 0 or not bool(observation.get("complete", false)) or int(observation.get("base_tier", 1)) != 1: return {"supported":false}
		"prop": entry_id = str(source) if source is String else str(observation.get("entry_id", observation.get("id", "")))
		_: return {"supported":false}
	var entry: Dictionary = _manifest.get("entries", {}).get(entry_id, {})
	if entry.is_empty() or not _atlases.has(str(entry.get("atlas", ""))): return {"supported":false}
	var action := str(pose.get("action", "IDLE"))
	if action in ["HARVEST", "MINE", "BUILD"]: action = "WORK"
	var actions: Dictionary = entry.get("frames", {})
	# Missing work/attack/death art must not invent another activity.
	if not actions.has(action): return {"supported":false}
	var facings: Array = actions[action]
	if facings.is_empty(): return {"supported":false}
	var facing := _direction_index(pose.get("direction", Vector2.RIGHT)) if facings.size() == 8 else 0
	var frames: Array = facings[facing]
	if frames.is_empty(): return {"supported":false}
	var frame_index := 0
	if action == "WALK":
		var tick := maxi(int(pose.get("animation_tick", observation.get("last_move_tick", 0))), 0)
		frame_index = posmod(floori(float(tick) / 2.0), frames.size())
	elif action != "IDLE":
		var phase := float(pose.get("phase", 0))
		if not is_finite(phase): phase = 0
		frame_index = clampi(floori(clampf(phase, 0, 1) * frames.size()), 0, frames.size() - 1)
	var frame: Dictionary = frames[frame_index]
	var rect_data: Array = frame.rect
	var anchor_data: Array = frame.anchor
	var anchor := Vector2(float(anchor_data[0]), float(anchor_data[1]))
	var weapon_data: Array = frame.get("weapon", anchor_data)
	return {"supported":true, "entry_id":entry_id, "action":action,
		"direction_index":facing, "frame_index":frame_index,
		"rect":Rect2(float(rect_data[0]), float(rect_data[1]), float(rect_data[2]), float(rect_data[3])),
		"anchor":anchor, "weapon":Vector2(float(weapon_data[0]), float(weapon_data[1])),
		"atlas_id":str(entry.atlas), "reference_radius":float(entry.get("reference_radius", 12)),
		"display_scale":float(entry.get("display_scale", 1)), "side":str(observation.get("side", "NEUTRAL"))}

static func inspect_unit(unit: Dictionary, pose: Dictionary = {}) -> Dictionary:
	return inspect("unit", unit, pose)

static func draw_unit(canvas: Object, center: Vector2, unit: Dictionary, radius: float, pose: Dictionary) -> bool:
	if not center.is_finite() or not is_finite(radius) or radius <= 0: return false
	var frame := inspect("unit", unit, pose)
	if not bool(frame.get("supported", false)): return false
	# The transparent Eevee bake contains self-shading, not a ground catcher.
	# One anchored, bounded foot shadow grounds it without inventing collision.
	canvas.draw_rect(Rect2(center.round() + Vector2(-radius * 0.9, -radius * 0.12), Vector2(radius * 1.8, radius * 0.4)), Color(0.025, 0.035, 0.025, 0.3))
	_draw(canvas, center, frame, radius / float(frame.reference_radius))
	return true

static func unit_bounds(unit: Dictionary, radius: float) -> Rect2:
	if not is_finite(radius) or radius <= 0: return Rect2()
	return _bounds("unit", unit, radius)

static func weapon_offset(unit: Dictionary, pose: Dictionary, radius: float) -> Vector2:
	var frame := inspect("unit", unit, pose)
	if not bool(frame.get("supported", false)) or not is_finite(radius) or radius <= 0: return Vector2.ZERO
	return (Vector2(frame.weapon) - Vector2(frame.anchor)) * float(frame.display_scale) * radius / float(frame.reference_radius)

static func draw_building(canvas: Object, center: Vector2, building: Dictionary, scale_factor: float) -> bool:
	if not center.is_finite() or not is_finite(scale_factor) or scale_factor <= 0: return false
	var frame := inspect("building", building)
	if not bool(frame.get("supported", false)): return false
	var radius := float(building.get("radius", frame.reference_radius))
	if not is_finite(radius) or radius <= 0: return false
	_draw(canvas, center, frame, scale_factor * radius / float(frame.reference_radius))
	return true

static func building_bounds(building: Dictionary, scale_factor: float) -> Rect2:
	if not is_finite(scale_factor) or scale_factor <= 0: return Rect2()
	var radius := float(building.get("radius", 40))
	if not is_finite(radius) or radius <= 0: return Rect2()
	return _bounds("building", building, radius * scale_factor)

static func building_body_contains(building: Dictionary, offset: Vector2, scale_factor: float) -> bool:
	if not offset.is_finite() or not is_finite(scale_factor) or scale_factor <= 0: return false
	var frame := inspect("building", building)
	if not bool(frame.get("supported", false)): return false
	var pixel := float(frame.display_scale) * scale_factor * float(building.get("radius", frame.reference_radius)) / float(frame.reference_radius)
	if not is_finite(pixel) or pixel <= 0: return false
	var point := Vector2i((offset / pixel + Vector2(frame.anchor)).floor())
	var rect: Rect2 = frame.rect
	if point.x < 0 or point.y < 0 or point.x >= int(rect.size.x) or point.y >= int(rect.size.y): return false
	var entry_id := str(frame.entry_id)
	if not _hit_masks.has(entry_id): _cache_hit_mask(frame)
	var hit_mask: Dictionary = _hit_masks.get(entry_id, {})
	if hit_mask.is_empty(): return false
	var bits: PackedByteArray = hit_mask.bits
	return bits[point.y * int(hit_mask.width) + point.x] != 0

static func draw_prop(canvas: Object, center: Vector2, entry_id: String, scale_factor: float = 1) -> bool:
	if not center.is_finite() or not is_finite(scale_factor) or scale_factor <= 0: return false
	var frame := inspect("prop", entry_id)
	if not bool(frame.get("supported", false)): return false
	_draw(canvas, center, frame, scale_factor)
	return true

static func prop_bounds(entry_id: String, scale_factor: float = 1) -> Rect2:
	var frame := inspect("prop", entry_id)
	if not bool(frame.get("supported", false)) or not is_finite(scale_factor) or scale_factor <= 0: return Rect2()
	var pixel := float(frame.display_scale) * scale_factor
	return Rect2(-Vector2(frame.anchor) * pixel, Rect2(frame.rect).size * pixel)

static func _bounds(kind: String, source: Dictionary, screen_radius: float) -> Rect2:
	var entry_frame := inspect(kind, source)
	if not bool(entry_frame.get("supported", false)): return Rect2()
	var entry: Dictionary = _manifest.entries[entry_frame.entry_id]
	var scale_factor := float(entry_frame.display_scale) * screen_radius / float(entry_frame.reference_radius)
	var bounds: Rect2 = entry.bounds
	return Rect2(bounds.position * scale_factor, bounds.size * scale_factor)

static func _draw(canvas: Object, center: Vector2, frame: Dictionary, scale_factor: float) -> void:
	var atlas: Dictionary = _atlases[frame.atlas_id]
	var source: Rect2 = frame.rect
	var pixel := scale_factor * float(frame.display_scale)
	var destination := Rect2(center.round() - Vector2(frame.anchor) * pixel, source.size * pixel)
	canvas.draw_texture_rect_region(atlas.texture, destination, source)
	if atlas.get("mask") != null:
		canvas.draw_texture_rect_region(atlas.mask, destination, source, Palette.side_color(str(frame.side)))

static func _direction_index(value: Variant) -> int:
	var direction: Vector2 = value if value is Vector2 else Vector2.RIGHT
	if not direction.is_finite() or direction.is_zero_approx(): return 0
	return posmod(roundi(direction.angle() / (PI / 4)), 8)

static func _failure(message: String) -> void:
	if message not in _failures and _failures.size() < 12: _failures.append(message)

static func _ensure_loaded() -> bool:
	if _attempted: return not _manifest.is_empty()
	_attempted = true
	if not FileAccess.file_exists(MANIFEST_PATH):
		_failure("Classic art manifest is absent; legacy art retained.")
		return false
	var contents := FileAccess.get_file_as_string(MANIFEST_PATH)
	if contents.length() > 4 * 1024 * 1024:
		_failure("Classic art manifest exceeds its bounded metadata budget.")
		return false
	var parsed: Variant = JSON.parse_string(contents)
	if not parsed is Dictionary or int(parsed.get("schema_version", 0)) != 1 or parsed.get("directions", []) != DIRECTIONS or not parsed.get("entries") is Dictionary or not parsed.get("atlases") is Dictionary:
		_failure("Classic art manifest schema is invalid; legacy art retained.")
		return false
	if parsed.entries.size() > 64 or parsed.atlases.size() > 8:
		_failure("Classic art manifest exceeds its bounded entry or atlas count.")
		return false
	var total_bytes := 0
	for id: String in parsed.atlases:
		if _atlases.size() >= 8:
			_failure("Classic art atlas count exceeds its bounded budget.")
			break
		var spec: Variant = parsed.atlases[id]
		if not spec is Dictionary: continue
		var image := _load_texture(str(spec.get("image", "")))
		if image == null: continue
		var mask: Texture2D
		var mask_path := str(spec.get("mask", ""))
		if not mask_path.is_empty():
			mask = _load_texture(mask_path)
			if mask == null or mask.get_size() != image.get_size():
				_failure("Classic art mask differs from its atlas: " + id)
				continue
		var bytes := image.get_width() * image.get_height() * 4 * (2 if mask != null else 1)
		if total_bytes + bytes > MAX_TEXTURE_BYTES:
			_failure("Classic art allocation exceeds 32 MiB; atlas retained on legacy path: " + id)
			continue
		# Per-texture filtering avoids changing the entire shared CanvasItem:
		# legacy pixel fallbacks may remain nearest while these bakes are linear.
		_atlases[id] = {"texture":_filtered(image), "mask":_filtered(mask) if mask != null else null, "bytes":bytes}
		total_bytes += bytes
	var valid_entries: Dictionary = {}
	for id: String in parsed.entries:
		var entry: Variant = parsed.entries[id]
		if _valid_entry(entry):
			entry["bounds"] = _entry_bounds(entry)
			valid_entries[id] = entry
		else: _failure("Invalid classic art entry; legacy art retained: " + id)
	if valid_entries.is_empty(): return false
	_manifest = {"entries":valid_entries}
	return true

static func _filtered(texture: Texture2D) -> CanvasTexture:
	var result := CanvasTexture.new()
	result.diffuse_texture = texture
	result.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	return result

static func _cache_hit_mask(frame: Dictionary) -> void:
	# Only two static building hit silhouettes are retained, not decoded atlas
	# images. Transparent corners of the bake must not become invisible buttons.
	var texture: CanvasTexture = _atlases[frame.atlas_id].texture
	var image := texture.diffuse_texture.get_image()
	if image == null or image.is_empty(): return
	var rect: Rect2 = frame.rect
	var bits := PackedByteArray()
	bits.resize(int(rect.size.x) * int(rect.size.y))
	for y: int in range(int(rect.size.y)):
		for x: int in range(int(rect.size.x)):
			bits[y * int(rect.size.x) + x] = 1 if image.get_pixel(int(rect.position.x) + x, int(rect.position.y) + y).a > 0.15 else 0
	_hit_masks[str(frame.entry_id)] = {"width":int(rect.size.x), "bits":bits}

static func _load_texture(path: String) -> Texture2D:
	if not path.begins_with("res://assets/art/classic_slice/") or ".." in path or not (FileAccess.file_exists(path) or ResourceLoader.exists(path)):
		_failure("Classic art texture is absent or outside the slice: " + path)
		return null
	var texture: Texture2D
	if FileAccess.file_exists(path) and not _has_import_cache(path):
		# Source checkouts can launch before the editor has imported new PNGs.
		# Decode once, upload once, and retain only the shared GPU texture.
		var source := Image.load_from_file(path)
		if source != null and not source.is_empty() and source.get_width() * source.get_height() * 4 <= MAX_TEXTURE_BYTES:
			source.fix_alpha_edges()
			texture = ImageTexture.create_from_image(source)
	else:
		texture = load(path) as Texture2D
	if texture == null or texture.get_width() <= 0 or texture.get_height() <= 0 or texture.get_width() > 8192 or texture.get_height() > 8192:
		_failure("Classic art texture dimensions are invalid: " + path)
		return null
	return texture

static func _has_import_cache(path: String) -> bool:
	if not FileAccess.file_exists(path + ".import"): return false
	var imported := ConfigFile.new()
	if imported.load(path + ".import") != OK: return false
	var cached := str(imported.get_value("remap", "path", ""))
	return not cached.is_empty() and FileAccess.file_exists(cached) and FileAccess.get_modified_time(path) <= FileAccess.get_modified_time(cached)

static func _valid_entry(value: Variant) -> bool:
	if not value is Dictionary or not _atlases.has(str(value.get("atlas", ""))) or not value.get("frames") is Dictionary: return false
	if not _finite_array([value.get("reference_radius"), value.get("display_scale")], 2): return false
	var reference := float(value.get("reference_radius", 0))
	var display_scale := float(value.get("display_scale", 0))
	if not is_finite(reference) or reference <= 0 or not is_finite(display_scale) or display_scale <= 0: return false
	if not value.frames.has("IDLE"): return false
	var texture: Texture2D = _atlases[str(value.atlas)].texture
	var atlas_rect := Rect2(0, 0, texture.get_width(), texture.get_height())
	for facings: Variant in value.frames.values():
		if not facings is Array or facings.size() not in [1, 8]: return false
		for frames: Variant in facings:
			if not frames is Array or frames.is_empty() or frames.size() > 16: return false
			for frame: Variant in frames:
				if not frame is Dictionary or not _finite_array(frame.get("rect"), 4) or not _finite_array(frame.get("anchor"), 2): return false
				var rect: Array = frame.rect
				var bounds := Rect2(float(rect[0]), float(rect[1]), float(rect[2]), float(rect[3]))
				if bounds.size.x <= 0 or bounds.size.y <= 0 or not atlas_rect.encloses(bounds): return false
				var anchor: Array = frame.anchor
				if not Rect2(Vector2.ZERO, bounds.size).has_point(Vector2(float(anchor[0]), float(anchor[1]))): return false
				if frame.has("weapon") and not _finite_array(frame.weapon, 2): return false
	return true

static func _entry_bounds(entry: Dictionary) -> Rect2:
	var result := Rect2()
	var first := true
	for facings: Array in entry.frames.values():
		for frames: Array in facings:
			for frame: Dictionary in frames:
				var rect: Array = frame.rect
				var anchor: Array = frame.anchor
				var bounds := Rect2(-Vector2(float(anchor[0]), float(anchor[1])), Vector2(float(rect[2]), float(rect[3])))
				result = bounds if first else result.merge(bounds)
				first = false
	return result

static func _finite_array(value: Variant, count: int) -> bool:
	if not value is Array or value.size() != count: return false
	for number: Variant in value:
		if not (number is int or number is float) or not is_finite(float(number)): return false
	return true
