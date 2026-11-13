extends RefCounted
## Opt-in, detached-observation frontier sprites. Four authored facings and
## short factual action keys are presentation only, never game authority.
const MANIFEST_PATH := "res://assets/art/frontier_slice/manifest.json"
const ASSET_ROOT := "res://assets/art/frontier_slice/"
const Palette = preload("res://src/presentation/strategic_side_palette.gd")
const MAX_TEXTURE_BYTES := 64 * 1024 * 1024
const MAX_TEXTURE_SIDE := 2048
const MAX_HIT_MASK_BYTES := 8 * 1024 * 1024
const DIRECTIONS := ["E", "S", "W", "N"]
const UNIT_IDS := ["worker", "hinge_guard", "bright_crossbow"]
const BUILDING_IDS := ["BASE", "BARRACKS", "TOWER"]
static var _override := -1
static var _attempted := false
static var _manifest: Dictionary = {}
static var _atlases: Dictionary = {}
static var _hit_masks: Dictionary = {}
static var _failures: Array[String] = []


static func enabled() -> bool:
	return _override == 1 if _override >= 0 else "--frontier-art" in OS.get_cmdline_user_args()


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
	var texture_bytes := 0
	var mask_count := 0
	var hit_mask_bytes := 0
	for atlas: Dictionary in _atlases.values():
		texture_bytes += int(atlas.bytes)
		if atlas.get("mask") != null: mask_count += 1
	for mask: Dictionary in _hit_masks.values(): hit_mask_bytes += PackedByteArray(mask.bits).size()
	return {"enabled":enabled(), "atlas_textures":_atlases.size(), "mask_textures":mask_count,
		"texture_bytes":texture_bytes, "loaded_atlases":_atlases.keys(), "hit_mask_bytes":hit_mask_bytes,
		"failures":_failures.duplicate(), "owner_atlas_copies":0, "retained_cpu_images":0,
		"manifest_path":MANIFEST_PATH, "directions":DIRECTIONS.duplicate()}


static func inspect(kind: String, source: Variant, pose: Dictionary = {}) -> Dictionary:
	if not enabled() or not _ensure_loaded(): return {"supported":false}
	var observation: Dictionary = source if source is Dictionary else {}
	var entry_id := ""
	match kind.to_lower():
		"unit":
			entry_id = str(observation.get("unit_type", ""))
			if entry_id not in UNIT_IDS or str(observation.get("faction_id", "HUMAN")) != "HUMAN": return {"supported":false}
			if int(observation.get("hp", 1)) <= 0 or not bool(observation.get("alive", true)): return {"supported":false}
		"building":
			entry_id = str(observation.get("building_type", ""))
			if entry_id not in BUILDING_IDS or str(observation.get("faction_id", "HUMAN")) != "HUMAN": return {"supported":false}
			if int(observation.get("hp", 0)) <= 0 or not bool(observation.get("complete", false)) or int(observation.get("base_tier", 1)) != 1: return {"supported":false}
		"prop":
			entry_id = str(source) if source is String else str(observation.get("entry_id", observation.get("id", "")))
		_: return {"supported":false}
	var entries: Dictionary = _manifest.get("entries", {})
	if not entries.has(entry_id):
		var aliases := {"tree_oak":"oak", "rock":"rocks"}
		entry_id = str(aliases.get(entry_id, entry_id))
	var entry: Dictionary = entries.get(entry_id, {})
	if entry.is_empty(): return {"supported":false}
	var action := str(pose.get("action", "IDLE"))
	# Missing carrying/death/skill art must fall through, not pose as idle.
	var actions: Dictionary = entry.frames
	# A specifically authored mining pose is not generic food/building work.
	# Generic WORK remains compatible only when the exact observation has no
	# separately authored action; no missing work action is replaced by IDLE.
	if not actions.has(action) and action in ["HARVEST", "MINE", "BUILD"]: action = "WORK"
	if not actions.has(action): return {"supported":false}
	var facings: Array = actions[action]
	var facing := _direction_index(pose.get("direction", Vector2.RIGHT)) if facings.size() == 4 else 0
	var frames: Array = facings[facing]
	var frame_index := 0
	if action == "WALK":
		var tick := maxi(int(pose.get("animation_tick", observation.get("last_move_tick", 0))), 0)
		frame_index = posmod(floori(float(tick) / 3.0), frames.size())
	elif action != "IDLE":
		var phase := float(pose.get("phase", 0))
		if not is_finite(phase): phase = 0
		frame_index = clampi(floori(clampf(phase, 0, 1) * frames.size()), 0, frames.size() - 1)
	var frame: Dictionary = frames[frame_index]
	var rect: Array = frame.rect
	var anchor: Array = frame.anchor
	var weapon: Array = frame.get("weapon", anchor)
	return {"supported":true, "entry_id":entry_id, "action":action,
		"direction_index":facing, "frame_index":frame_index, "atlas_id":str(entry.atlas),
		"rect":Rect2(float(rect[0]), float(rect[1]), float(rect[2]), float(rect[3])),
		"anchor":Vector2(float(anchor[0]), float(anchor[1])), "weapon":Vector2(float(weapon[0]), float(weapon[1])),
		"reference_radius":float(entry.reference_radius), "display_scale":float(entry.display_scale),
		"side":str(observation.get("side", "NEUTRAL"))}


static func inspect_unit(unit: Dictionary, pose: Dictionary = {}) -> Dictionary:
	return inspect("unit", unit, pose)


static func draw_unit(canvas: Object, center: Vector2, unit: Dictionary, radius: float, pose: Dictionary) -> bool:
	if not center.is_finite() or not is_finite(radius) or radius <= 0: return false
	var frame := inspect_unit(unit, pose)
	if not bool(frame.get("supported", false)): return false
	var shadow := PackedVector2Array()
	for index: int in range(16):
		var angle := float(index) * TAU / 16.0
		shadow.append(center.round() + Vector2(cos(angle) * radius * 0.95, sin(angle) * radius * 0.18 + radius * 0.08))
	canvas.draw_colored_polygon(shadow, Color(0.025, 0.035, 0.025, 0.24))
	_draw(canvas, center, frame, radius / float(frame.reference_radius))
	return true


static func draw_occluded_unit(canvas: Object, center: Vector2, unit: Dictionary, radius: float, pose: Dictionary) -> bool:
	if not center.is_finite() or not is_finite(radius) or radius <= 0: return false
	var frame := inspect_unit(unit,pose)
	if not bool(frame.get("supported",false)): return false
	# A transparent, team-tinted repeat of the factual sprite is an inspection
	# aid, not another actor or an invented foreground body/shadow.
	var tint: Color = Palette.side_color(str(unit.get("side",""))).lightened(0.25)
	tint.a = 0.44
	_draw(canvas,center,frame,radius / float(frame.reference_radius),tint)
	return true


static func unit_opaque_probes(unit: Dictionary, radius: float, pose: Dictionary) -> Array[Vector2]:
	var result: Array[Vector2] = []
	if not is_finite(radius) or radius <= 0: return result
	var frame := inspect_unit(unit,pose)
	if not bool(frame.get("supported",false)): return result
	var rect: Rect2 = frame.rect
	var pixel := float(frame.display_scale) * radius / float(frame.reference_radius)
	for y_ratio: float in [0.2,0.35,0.5,0.65,0.8]:
		for x_ratio: float in [0.25,0.375,0.5,0.625,0.75]:
			var point := Vector2i(mini(floori(rect.size.x*x_ratio),int(rect.size.x)-1),mini(floori(rect.size.y*y_ratio),int(rect.size.y)-1))
			if _frame_pixel_contains(frame,point): result.append((Vector2(point)+Vector2(0.5,0.5)-Vector2(frame.anchor))*pixel)
	return result


static func unit_bounds(unit: Dictionary, radius: float) -> Rect2:
	return _bounds("unit", unit, radius) if is_finite(radius) and radius > 0 else Rect2()


static func weapon_offset(unit: Dictionary, pose: Dictionary, radius: float) -> Vector2:
	var frame := inspect_unit(unit, pose)
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
	var radius := float(building.get("radius", 40))
	if not is_finite(scale_factor) or scale_factor <= 0 or not is_finite(radius) or radius <= 0: return Rect2()
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
	return _frame_pixel_contains(frame,point)


static func draw_prop(canvas: Object, center: Vector2, entry_id: String, scale_factor: float = 1, side: String = "NEUTRAL", modulate: Color = Color.WHITE) -> bool:
	if not center.is_finite() or not is_finite(scale_factor) or scale_factor <= 0 or not _finite_color(modulate): return false
	var frame := inspect("prop", {"entry_id":entry_id, "side":side})
	if not bool(frame.get("supported", false)): return false
	_draw(canvas, center, frame, scale_factor, modulate)
	return true


static func prop_bounds(entry_id: String, scale_factor: float = 1) -> Rect2:
	if not is_finite(scale_factor) or scale_factor <= 0: return Rect2()
	var frame := inspect("prop", entry_id)
	if not bool(frame.get("supported", false)): return Rect2()
	var pixel := float(frame.display_scale) * scale_factor
	return Rect2(-Vector2(frame.anchor) * pixel, Rect2(frame.rect).size * pixel)


static func prop_body_contains(entry_id: String, offset: Vector2, scale_factor: float = 1) -> bool:
	if not offset.is_finite() or not is_finite(scale_factor) or scale_factor <= 0: return false
	var frame := inspect("prop",entry_id)
	if not bool(frame.get("supported",false)): return false
	var pixel := float(frame.display_scale) * scale_factor
	if not is_finite(pixel) or pixel <= 0: return false
	return _frame_pixel_contains(frame,Vector2i((offset/pixel+Vector2(frame.anchor)).floor()))


static func _bounds(kind: String, observation: Dictionary, screen_radius: float) -> Rect2:
	var frame := inspect(kind, observation)
	if not bool(frame.get("supported", false)): return Rect2()
	var entry: Dictionary = _manifest.entries[frame.entry_id]
	var pixel := float(frame.display_scale) * screen_radius / float(frame.reference_radius)
	var bounds: Rect2 = entry.bounds
	return Rect2(bounds.position * pixel, bounds.size * pixel)


static func _draw(canvas: Object, center: Vector2, frame: Dictionary, scale_factor: float, modulate: Color = Color.WHITE) -> void:
	var atlas: Dictionary = _atlases[frame.atlas_id]
	var source: Rect2 = frame.rect
	var pixel := scale_factor * float(frame.display_scale)
	var destination := Rect2(center.round() - Vector2(frame.anchor) * pixel, source.size * pixel)
	canvas.draw_texture_rect_region(atlas.texture, destination, source, modulate)
	if atlas.get("mask") != null: canvas.draw_texture_rect_region(atlas.mask, destination, source, Palette.side_color(str(frame.side)) * modulate)


static func _direction_index(value: Variant) -> int:
	var direction: Vector2 = value if value is Vector2 else Vector2.RIGHT
	if not direction.is_finite() or direction.is_zero_approx(): return 0
	return posmod(roundi(direction.angle() / (PI / 2)), 4)


static func _failure(message: String) -> void:
	if message not in _failures and _failures.size() < 12: _failures.append(message)


static func _ensure_loaded() -> bool:
	if _attempted: return not _manifest.is_empty()
	_attempted = true
	if not FileAccess.file_exists(MANIFEST_PATH):
		_failure("Frontier art manifest is absent; previous art retained.")
		return false
	var contents := FileAccess.get_file_as_string(MANIFEST_PATH)
	if contents.length() > 4 * 1024 * 1024:
		_failure("Frontier art metadata exceeds its bounded budget.")
		return false
	var parsed: Variant = JSON.parse_string(contents)
	if not parsed is Dictionary or int(parsed.get("schema_version", 0)) != 1 or parsed.get("directions", []) != DIRECTIONS or not parsed.get("entries") is Dictionary or not parsed.get("atlases") is Dictionary:
		_failure("Frontier art manifest schema is invalid; previous art retained.")
		return false
	if parsed.entries.size() > 64 or parsed.atlases.size() > 8:
		_failure("Frontier art metadata exceeds bounded entry/atlas counts.")
		return false
	if not _finite_array([parsed.get("budget_bytes"), parsed.get("texture_bytes")], 2) or float(parsed.budget_bytes) <= 0 or float(parsed.budget_bytes) > MAX_TEXTURE_BYTES or float(parsed.texture_bytes) <= 0 or float(parsed.texture_bytes) > float(parsed.budget_bytes):
		_failure("Frontier art declares an invalid texture allocation budget.")
		return false
	var total_bytes := 0
	for atlas_id: String in parsed.atlases:
		var spec: Variant = parsed.atlases[atlas_id]
		if not spec is Dictionary: continue
		var image := _load_image(str(spec.get("image", "")))
		if image == null: continue
		if int(spec.get("width", 0)) != image.get_width() or int(spec.get("height", 0)) != image.get_height() or int(spec.get("rgba_bytes", 0)) != image.get_width() * image.get_height() * 4:
			_failure("Frontier atlas dimensions/allocation differ from metadata: " + atlas_id)
			continue
		var mask: Image
		var mask_path := str(spec.get("mask", ""))
		if not mask_path.is_empty():
			mask = _load_image(mask_path)
			if mask == null or mask.get_size() != image.get_size():
				_failure("Frontier mask differs from its atlas: " + atlas_id)
				continue
		var bytes := image.get_width() * image.get_height() * 4 * (2 if mask != null else 1)
		if total_bytes + bytes > int(parsed.budget_bytes):
			_failure("Frontier atlas allocation exceeds 64 MiB: " + atlas_id)
			continue
		_atlases[atlas_id] = {"texture":_texture(image), "mask":_texture(mask) if mask != null else null, "bytes":bytes}
		total_bytes += bytes
	if total_bytes != int(parsed.texture_bytes): _failure("Frontier actual atlas allocation differs from its declared total.")
	var valid_entries: Dictionary = {}
	for entry_id: String in parsed.entries:
		var entry: Variant = parsed.entries[entry_id]
		if _valid_entry(entry_id, entry):
			entry["bounds"] = _entry_bounds(entry)
			valid_entries[entry_id] = entry
		else: _failure("Invalid frontier entry; previous art retained: " + entry_id)
	if valid_entries.is_empty():
		_atlases.clear()
		_failure("Frontier art has no valid entries; previous art retained.")
		return false
	_manifest = {"entries":valid_entries}
	return true


static func _load_image(path: String) -> Image:
	if not path.begins_with(ASSET_ROOT) or ".." in path or not path.ends_with(".png") or not FileAccess.file_exists(path):
		_failure("Frontier PNG absent or outside its asset root: " + path)
		return null
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null or file.get_length() > MAX_TEXTURE_BYTES:
		_failure("Frontier PNG exceeds its bounded file budget: " + path)
		return null
	file.close()
	# Source PNGs work before an editor import. The decoded Image is local to
	# this one-time load; only shared GPU textures remain in the runtime cache.
	var image := Image.new()
	if image.load_png_from_buffer(FileAccess.get_file_as_bytes(path)) != OK or image.is_empty() or image.get_width() > MAX_TEXTURE_SIDE or image.get_height() > MAX_TEXTURE_SIDE or image.get_width() * image.get_height() * 4 > MAX_TEXTURE_BYTES:
		_failure("Frontier PNG dimensions exceed the bounded budget: " + path)
		return null
	image.convert(Image.FORMAT_RGBA8)
	if image.detect_alpha() == Image.ALPHA_NONE or image.get_used_rect().size == Vector2i.ZERO:
		_failure("Frontier atlas must contain visible art and transparent space: " + path)
		return null
	image.fix_alpha_edges()
	return image


static func _texture(image: Image) -> CanvasTexture:
	var result := CanvasTexture.new()
	result.diffuse_texture = ImageTexture.create_from_image(image)
	result.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	return result


static func _frame_pixel_contains(frame: Dictionary, point: Vector2i) -> bool:
	var rect: Rect2 = frame.rect
	if point.x < 0 or point.y < 0 or point.x >= int(rect.size.x) or point.y >= int(rect.size.y): return false
	var key := "%s:%d:%d:%d:%d" % [str(frame.entry_id),int(rect.position.x),int(rect.position.y),int(rect.size.x),int(rect.size.y)]
	if not _hit_masks.has(key): _cache_hit_mask(frame,key)
	var mask: Dictionary = _hit_masks.get(key,{})
	if mask.is_empty(): return false
	var bits: PackedByteArray = mask.bits
	return bits[point.y * int(mask.width) + point.x] != 0


static func _cache_hit_mask(frame: Dictionary, key: String) -> void:
	# Bounded shared byte silhouettes serve body clicks and occlusion probes;
	# no per-instance textures or retained decoded atlas Images are created.
	var texture: CanvasTexture = _atlases[frame.atlas_id].texture
	var image := texture.diffuse_texture.get_image()
	if image == null or image.is_empty(): return
	var rect: Rect2 = frame.rect
	var byte_count := int(rect.size.x) * int(rect.size.y)
	if byte_count > MAX_HIT_MASK_BYTES: return
	var retained := 0
	for mask: Dictionary in _hit_masks.values(): retained += PackedByteArray(mask.bits).size()
	while not _hit_masks.is_empty() and (retained + byte_count > MAX_HIT_MASK_BYTES or _hit_masks.size() >= 64):
		var oldest: String = str(_hit_masks.keys()[0])
		retained -= PackedByteArray(_hit_masks[oldest].bits).size()
		_hit_masks.erase(oldest)
	var bits := PackedByteArray()
	bits.resize(byte_count)
	for y: int in range(int(rect.size.y)):
		for x: int in range(int(rect.size.x)):
			bits[y * int(rect.size.x) + x] = 1 if image.get_pixel(int(rect.position.x) + x, int(rect.position.y) + y).a > 0.2 else 0
	_hit_masks[key] = {"width":int(rect.size.x), "bits":bits}


static func _valid_entry(entry_id: String, value: Variant) -> bool:
	if not value is Dictionary or not _atlases.has(str(value.get("atlas", ""))) or not value.get("frames") is Dictionary: return false
	if not _finite_array([value.get("reference_radius"), value.get("display_scale")], 2): return false
	if float(value.reference_radius) <= 0 or float(value.display_scale) <= 0 or not value.frames.has("IDLE") or value.frames.size() > 16: return false
	var texture: Texture2D = _atlases[str(value.atlas)].texture
	var atlas_rect := Rect2(0, 0, texture.get_width(), texture.get_height())
	for facings: Variant in value.frames.values():
		if not facings is Array or facings.size() != (4 if entry_id in UNIT_IDS else 1): return false
		for frames: Variant in facings:
			if not frames is Array or frames.is_empty() or frames.size() > 16: return false
			for frame: Variant in frames:
				if not frame is Dictionary or not _finite_array(frame.get("rect"), 4) or not _finite_array(frame.get("anchor"), 2): return false
				var rect: Array = frame.rect
				for coordinate: Variant in rect:
					if float(coordinate) != floorf(float(coordinate)): return false
				var region := Rect2(float(rect[0]), float(rect[1]), float(rect[2]), float(rect[3]))
				if region.size.x <= 0 or region.size.y <= 0 or not atlas_rect.encloses(region): return false
				var anchor: Array = frame.anchor
				# Ground contact may lie on the bottom/right edge after alpha trim.
				# A pivot is a boundary coordinate, not a sampled image pixel.
				if float(anchor[0]) < 0 or float(anchor[0]) > region.size.x or float(anchor[1]) < 0 or float(anchor[1]) > region.size.y: return false
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


static func _finite_color(value: Color) -> bool:
	return is_finite(value.r) and is_finite(value.g) and is_finite(value.b) and is_finite(value.a)
