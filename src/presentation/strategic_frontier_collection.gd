extends RefCounted
## Shared, bounded presentation-only sprites. No per-instance image ownership.
const FrontierArt = preload("res://src/presentation/strategic_frontier_art.gd")
const MANIFEST_PATH := "res://assets/art/frontier_collection/manifest.json"
const ASSET_ROOT := "res://assets/art/frontier_collection/"
const MAX_TEXTURE_BYTES := 40 * 1024 * 1024
const MAX_SHARED_FRONTIER_BYTES := 64 * 1024 * 1024
const RESERVED_GROUND_BYTES := 4 * 256 * 256 * 4
const MAX_MASK_BYTES := 8 * 1024 * 1024
const MAX_TEXTURE_SIDE := 2048
static var _override := -1
static var _attempted := false
static var _entries: Dictionary = {}
static var _atlases: Dictionary = {}
static var _masks: Dictionary = {}
static var _failures: Array[String] = []


static func enabled() -> bool:
	return _override == 1 if _override >= 0 else FrontierArt.enabled()


static func set_enabled(value: bool) -> void:
	_override = 1 if value else 0


static func clear_override() -> void:
	_override = -1


static func reset_cache() -> void:
	_attempted = false
	_entries.clear()
	_atlases.clear()
	_masks.clear()
	_failures.clear()


static func get_entry(entry_id: String) -> Dictionary:
	if not enabled() or not _ensure_loaded(): return {"supported":false}
	return _entries.get(entry_id,{"supported":false}).duplicate()


static func entry_ids(kind: String = "") -> Array[String]:
	var result: Array[String] = []
	if not enabled() or not _ensure_loaded(): return result
	for entry_id: String in _entries:
		if kind.is_empty() or str(_entries[entry_id].kind) == kind: result.append(entry_id)
	result.sort()
	return result


static func texture(entry_or_atlas_id: String, disabled: bool = false) -> Texture2D:
	if not enabled() or not _ensure_loaded(): return null
	var atlas_id := str(_entries.get(entry_or_atlas_id,{}).get("atlas_id",entry_or_atlas_id))
	var atlas: Dictionary = _atlases.get(atlas_id,{})
	return atlas.get("gray_texture",atlas.get("texture")) if disabled else atlas.get("texture")


static func draw(canvas: Object, center: Vector2, entry_id: String, scale_factor: float = 1, modulate: Color = Color.WHITE) -> bool:
	if not center.is_finite() or not is_finite(scale_factor) or scale_factor <= 0 or not _finite_color(modulate): return false
	var entry := get_entry(entry_id)
	if not entry.get("supported",false): return false
	var destination := bounds(entry_id,scale_factor)
	destination.position += center
	canvas.draw_texture_rect_region(texture(entry_id),destination,entry.rect,modulate)
	return true


static func draw_in_rect(canvas: Object, destination: Rect2, entry_id: String, modulate: Color = Color.WHITE, disabled: bool = false) -> bool:
	if not destination.position.is_finite() or not destination.size.is_finite() or destination.size.x <= 0 or destination.size.y <= 0 or not _finite_color(modulate): return false
	var entry := get_entry(entry_id)
	if not entry.get("supported",false): return false
	var source: Rect2 = entry.rect
	var fitted := source.size * minf(destination.size.x/source.size.x,destination.size.y/source.size.y)
	canvas.draw_texture_rect_region(texture(entry_id,disabled),Rect2(destination.get_center()-fitted*0.5,fitted),source,modulate)
	return true


static func bounds(entry_id: String, scale_factor: float = 1) -> Rect2:
	if not is_finite(scale_factor) or scale_factor <= 0: return Rect2()
	var entry := get_entry(entry_id)
	if not entry.get("supported",false): return Rect2()
	var pixel := float(entry.display_scale)*scale_factor
	return Rect2(-Vector2(entry.anchor)*pixel,Rect2(entry.rect).size*pixel)


static func body_contains(entry_id: String, offset: Vector2, scale_factor: float = 1) -> bool:
	if not offset.is_finite() or not is_finite(scale_factor) or scale_factor <= 0: return false
	var entry := get_entry(entry_id)
	if not entry.get("supported",false): return false
	var pixel := float(entry.display_scale)*scale_factor
	var point := Vector2i((offset/pixel+Vector2(entry.anchor)).floor())
	var rect: Rect2 = entry.rect
	if point.x < 0 or point.y < 0 or point.x >= int(rect.size.x) or point.y >= int(rect.size.y): return false
	if not _masks.has(entry_id): _cache_mask(entry_id,entry)
	var mask: Dictionary = _masks.get(entry_id,{})
	return not mask.is_empty() and PackedByteArray(mask.bits)[point.y*int(mask.width)+point.x] != 0


static func debug_stats() -> Dictionary:
	if enabled(): _ensure_loaded()
	var bytes := 0
	var masks := 0
	for atlas: Dictionary in _atlases.values(): bytes += int(atlas.bytes)
	for mask: Dictionary in _masks.values(): masks += PackedByteArray(mask.bits).size()
	return {"enabled":enabled(),"entries":_entries.size(),"atlas_textures":_atlases.size(),"texture_bytes":bytes,
		"hit_mask_bytes":masks,"owner_atlas_copies":0,"retained_cpu_images":0,"failures":_failures.duplicate(),"manifest_path":MANIFEST_PATH}


static func _ensure_loaded() -> bool:
	if _attempted: return not _entries.is_empty()
	_attempted = true
	if not FileAccess.file_exists(MANIFEST_PATH):
		_failure("Frontier collection absent; previous presentation retained.")
		return false
	var contents := FileAccess.get_file_as_string(MANIFEST_PATH)
	if contents.length() > 2*1024*1024: return _failure("Collection metadata exceeds its budget.")
	var parsed: Variant = JSON.parse_string(contents)
	if not parsed is Dictionary or int(parsed.get("schema_version",0)) != 1 or not parsed.get("entries") is Dictionary or not parsed.get("atlases") is Dictionary:
		return _failure("Collection metadata schema is invalid.")
	if parsed.entries.size() > 256 or parsed.atlases.size() > 12: return _failure("Collection object counts exceed their budget.")
	var bytes := 0
	for atlas_id: String in parsed.atlases:
		var spec: Variant = parsed.atlases[atlas_id]
		if not spec is Dictionary: continue
		var path := str(spec.get("image",""))
		if not path.begins_with(ASSET_ROOT) or ".." in path or not path.ends_with(".png") or not FileAccess.file_exists(path):
			_failure("Collection PNG absent or outside its root: "+atlas_id)
			continue
		var declared_width := int(spec.get("width",0))
		var declared_height := int(spec.get("height",0))
		if declared_width <= 0 or declared_height <= 0 or declared_width > MAX_TEXTURE_SIDE or declared_height > MAX_TEXTURE_SIDE or declared_width*declared_height*4+bytes > MAX_TEXTURE_BYTES:
			_failure("Collection declared dimensions exceed their bounded allocation: "+atlas_id)
			continue
		var image := Image.new()
		if image.load_png_from_buffer(FileAccess.get_file_as_bytes(path)) != OK or image.is_empty():
			_failure("Collection PNG cannot decode: "+atlas_id)
			continue
		var allocation := image.get_width()*image.get_height()*4
		if image.get_width() > MAX_TEXTURE_SIDE or image.get_height() > MAX_TEXTURE_SIDE or allocation+bytes > MAX_TEXTURE_BYTES or image.get_width() != int(spec.get("width",0)) or image.get_height() != int(spec.get("height",0)) or allocation != int(spec.get("rgba_bytes",0)):
			_failure("Collection PNG dimensions or allocation are invalid: "+atlas_id)
			continue
		if str(spec.get("sha256","")).is_empty() or FileAccess.get_sha256(path) != str(spec.sha256):
			_failure("Collection PNG hash differs from metadata: "+atlas_id)
			continue
		image.convert(Image.FORMAT_RGBA8)
		image.fix_alpha_edges()
		var shared := CanvasTexture.new()
		shared.diffuse_texture = ImageTexture.create_from_image(image)
		shared.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		_atlases[atlas_id] = {"texture":shared,"bytes":allocation}
		bytes += allocation
		var gray_path := str(spec.get("gray_image",""))
		if not gray_path.is_empty():
			if not gray_path.begins_with(ASSET_ROOT) or ".." in gray_path or not gray_path.ends_with(".png") or not FileAccess.file_exists(gray_path) or bytes+allocation > MAX_TEXTURE_BYTES:
				_failure("Collection gray PNG absent, unsafe or exceeds allocation: "+atlas_id)
				continue
			var gray_image := Image.new()
			if gray_image.load_png_from_buffer(FileAccess.get_file_as_bytes(gray_path)) != OK or gray_image.get_size() != image.get_size() or str(spec.get("gray_sha256","")).is_empty() or FileAccess.get_sha256(gray_path) != str(spec.gray_sha256):
				_failure("Collection gray PNG dimensions or hash differ: "+atlas_id)
				continue
			gray_image.convert(Image.FORMAT_RGBA8)
			gray_image.fix_alpha_edges()
			var gray_texture := CanvasTexture.new()
			gray_texture.diffuse_texture = ImageTexture.create_from_image(gray_image)
			gray_texture.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
			_atlases[atlas_id]["gray_texture"] = gray_texture
			_atlases[atlas_id]["bytes"] = allocation*2
			bytes += allocation
	var base: Variant = JSON.parse_string(FileAccess.get_file_as_string(FrontierArt.MANIFEST_PATH)) if FileAccess.file_exists(FrontierArt.MANIFEST_PATH) else {}
	if base is Dictionary and bytes+int(base.get("texture_bytes",0))+RESERVED_GROUND_BYTES > MAX_SHARED_FRONTIER_BYTES:
		_atlases.clear()
		return _failure("Collection plus frontier base/ground exceeds the shared 64 MiB budget.")
	if parsed.has("texture_bytes") and int(parsed.texture_bytes) != bytes:
		_atlases.clear()
		return _failure("Collection actual allocation differs from its declared total.")
	var declared_budget := int(parsed.get("budget_bytes",MAX_TEXTURE_BYTES))
	var reserved_bytes := int(base.get("texture_bytes",0))+RESERVED_GROUND_BYTES if base is Dictionary else RESERVED_GROUND_BYTES
	var declared_shared_budget := int(parsed.get("aggregate_budget_bytes",parsed.get("shared_budget_bytes",MAX_SHARED_FRONTIER_BYTES)))
	if declared_budget <= 0 or declared_budget > MAX_TEXTURE_BYTES or bytes > declared_budget or declared_shared_budget <= 0 or declared_shared_budget > MAX_SHARED_FRONTIER_BYTES or bytes+reserved_bytes > declared_shared_budget:
		_atlases.clear()
		return _failure("Collection exceeds its declared allocation budget.")
	for entry_id: String in parsed.entries:
		var entry: Variant = parsed.entries[entry_id]
		if not _valid_entry(entry):
			_failure("Collection entry invalid; prior presentation retained: "+entry_id)
			continue
		var rect: Array = entry.rect
		_entries[entry_id] = {"supported":true,"entry_id":entry_id,"atlas_id":str(entry.atlas),
			"rect":Rect2(float(rect[0]),float(rect[1]),float(rect[2]),float(rect[3])),
			"anchor":Vector2(float(entry.anchor[0]),float(entry.anchor[1])),"display_scale":float(entry.display_scale),
			"ground_radius":float(entry.ground_radius),"family":str(entry.get("family","")),
			"variant":int(entry.get("variant",0)),"kind":str(entry.get("kind","")),
			"reference_radius":float(entry.get("reference_radius",40)),"nine_slice":entry.get("nine_slice",[]).duplicate(),
			"complete_display_envelope_radius":float(entry.get("complete_display_envelope_radius",0))}
	if _entries.is_empty(): _atlases.clear()
	return not _entries.is_empty()


static func _valid_entry(entry: Variant) -> bool:
	if not entry is Dictionary or not _atlases.has(str(entry.get("atlas",""))): return false
	if not _finite_array(entry.get("rect"),4) or not _finite_array(entry.get("anchor"),2) or not _finite_array([entry.get("display_scale"),entry.get("ground_radius")],2): return false
	var raw: Array = entry.rect
	for number: Variant in raw:
		if float(number) != floorf(float(number)): return false
	var region := Rect2(float(raw[0]),float(raw[1]),float(raw[2]),float(raw[3]))
	var atlas: Texture2D = _atlases[str(entry.atlas)].texture
	if region.size.x <= 0 or region.size.y <= 0 or not Rect2(0,0,atlas.get_width(),atlas.get_height()).encloses(region): return false
	if float(entry.display_scale) <= 0 or float(entry.display_scale) > 8 or float(entry.ground_radius) < 0: return false
	if float(entry.anchor[0]) < 0 or float(entry.anchor[1]) < 0 or float(entry.anchor[0]) > region.size.x or float(entry.anchor[1]) > region.size.y: return false
	if entry.has("reference_radius") and (not _finite_array([entry.reference_radius],1) or float(entry.reference_radius) <= 0): return false
	if entry.has("nine_slice"):
		if not _finite_array(entry.nine_slice,4): return false
		for margin: Variant in entry.nine_slice:
			if float(margin) < 0: return false
	if str(entry.get("kind","")) == "decor":
		if float(entry.ground_radius) > 32: return false
		var offset := -Vector2(float(entry.anchor[0]),float(entry.anchor[1]))*float(entry.display_scale)
		var size := region.size*float(entry.display_scale)
		for corner: Vector2 in [offset,offset+size,offset+Vector2(size.x,0),offset+Vector2(0,size.y)]:
			if corner.length() > float(entry.ground_radius)+0.0001: return false
	return true


static func _cache_mask(entry_id: String, entry: Dictionary) -> void:
	var shared: CanvasTexture = texture(entry_id)
	var image := shared.diffuse_texture.get_image()
	if image == null or image.is_empty(): return
	var rect: Rect2 = entry.rect
	var byte_count := int(rect.size.x)*int(rect.size.y)
	if byte_count > MAX_MASK_BYTES: return
	var retained := 0
	for mask: Dictionary in _masks.values(): retained += PackedByteArray(mask.bits).size()
	while not _masks.is_empty() and (retained+byte_count > MAX_MASK_BYTES or _masks.size() >= 128):
		var oldest := str(_masks.keys()[0])
		retained -= PackedByteArray(_masks[oldest].bits).size()
		_masks.erase(oldest)
	var bits := PackedByteArray()
	bits.resize(byte_count)
	for y: int in range(int(rect.size.y)):
		for x: int in range(int(rect.size.x)):
			bits[y*int(rect.size.x)+x] = 1 if image.get_pixel(int(rect.position.x)+x,int(rect.position.y)+y).a > 0.2 else 0
	_masks[entry_id] = {"width":int(rect.size.x),"bits":bits}


static func _failure(message: String) -> bool:
	if message not in _failures and _failures.size() < 16: _failures.append(message)
	return false


static func _finite_array(value: Variant, count: int) -> bool:
	if not value is Array or value.size() != count: return false
	for number: Variant in value:
		if not (number is int or number is float) or not is_finite(float(number)): return false
	return true


static func _finite_color(value: Color) -> bool:
	return is_finite(value.r) and is_finite(value.g) and is_finite(value.b) and is_finite(value.a)
