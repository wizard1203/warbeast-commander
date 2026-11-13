extends RefCounted
## Six original UI portraits. No animation, battle body, input or rule authority.
const CommandArt = preload("res://src/presentation/heroic_command_art.gd")
const ROOT := "res://assets/art/original/m38/portraits/"
const MANIFEST := ROOT+"manifest.json"
const PROVENANCE := "original-ai-pixel-m38-portraits"
const SIZE := Vector2i(128,192)
const CELL := Vector2i(64,64)
const IDENTITIES := ["hero:COMMANDER","hero:BULWARK","hero:CINDER_STALKER","hero:ECHO_BINDER","hinge_guard","bright_crossbow"]
const MAX_TEXTURE_BYTES := 128*192*4*2
static var _attempted := false
static var _texture: ImageTexture
static var _grey: ImageTexture
static var _entries: Dictionary = {}
static var _failure := ""
static var _pixel_hash := ""
static var _png_hash := ""
static var _loads := 0

static func identity(unit: Dictionary) -> String:
	return "hero:"+str(unit.get("hero_archetype",unit.get("archetype","COMMANDER"))) if str(unit.get("unit_type","")) == "hero" else str(unit.get("unit_type",""))

static func reset_cache() -> void:
	_attempted = false
	_texture = null
	_grey = null
	_entries.clear()
	_failure = ""
	_pixel_hash = ""
	_png_hash = ""
	_loads = 0

static func _number(value: Variant) -> float:
	return float(value) if typeof(value) in [TYPE_INT,TYPE_FLOAT] else NAN

static func _pair(value: Variant, x: int, y: int) -> bool:
	return value is Array and value.size() == 2 and _number(value[0]) == x and _number(value[1]) == y

static func _linked(file: String) -> bool:
	var current := "res://"
	for part: String in (ROOT.trim_prefix("res://")+file).split("/",false):
		var parent := DirAccess.open(current)
		if parent == null or parent.is_link(part): return true
		current = current.path_join(part)
	return false

static func _reject(reason: String) -> void:
	_failure = reason

static func _ensure() -> void:
	if _attempted: return
	_attempted = true
	if not CommandArt.enabled(): return
	if not FileAccess.file_exists(MANIFEST):
		_reject("Optional original portraits absent; canonical same-role artwork remains.")
		return
	var handle := FileAccess.open(MANIFEST,FileAccess.READ)
	if _linked("manifest.json") or handle == null or handle.get_length() <= 0 or handle.get_length() > 128*1024:
		_reject("Original portrait manifest path/byte envelope differs.")
		return
	var parsed: Variant = JSON.parse_string(handle.get_as_text())
	if not parsed is Dictionary or _number(parsed.get("schema_version")) != 1 or typeof(parsed.get("accepted")) != TYPE_BOOL or parsed.get("accepted") != true or str(parsed.get("status","")) != "accepted" or str(parsed.get("provenance","")) != PROVENANCE:
		_reject("Original portrait metadata lacks explicit accepted provenance.")
		return
	if not _pair(parsed.get("cell_size"),64,64) or _number(parsed.get("columns")) != 2 or _number(parsed.get("rows")) != 3 or _number(parsed.get("width")) != 128 or _number(parsed.get("height")) != 192:
		_reject("Original portrait grid differs.")
		return
	var file := str(parsed.get("file",""))
	if not file.begins_with("runtime/") or file.count("/") != 1 or not file.ends_with(".png") or file.contains("..") or file.contains("\\") or file.contains(":") or _linked(file):
		_reject("Unsafe original portrait file.")
		return
	var path := ROOT+file
	var png := FileAccess.open(path,FileAccess.READ)
	if png == null or png.get_length() <= 24 or png.get_length() > 1024*1024 or _number(parsed.get("bytes")) != png.get_length() or FileAccess.get_sha256(path) != str(parsed.get("sha256","")):
		_reject("Original portrait PNG hash or byte envelope differs.")
		return
	var header := png.get_buffer(24)
	if header.slice(0,8).hex_encode() != "89504e470d0a1a0a" or header.slice(12,16).get_string_from_ascii() != "IHDR" or header.slice(16,24).hex_encode() != "00000080000000c0":
		_reject("Original portrait PNG header differs.")
		return
	var image := Image.new()
	if image.load_png_from_buffer(FileAccess.get_file_as_bytes(path)) != OK or image.get_size() != SIZE:
		_reject("Original portrait decode failed.")
		return
	image.convert(Image.FORMAT_RGBA8)
	var assets: Variant = parsed.get("assets")
	if not assets is Dictionary or assets.size() != IDENTITIES.size():
		_reject("Portrait metadata must identify exactly six roles.")
		return
	var entries := {}
	var occupied := {}
	for id: String in IDENTITIES:
		var spec: Variant = assets.get(id)
		if not spec is Dictionary or str(spec.get("prompt_id","")).is_empty() or not spec.get("rect") is Array or spec.rect.size() != 4:
			_reject("Missing exact portrait identity: "+id)
			return
		for value: Variant in spec.rect:
			if not is_finite(_number(value)) or _number(value) != floorf(_number(value)):
				_reject("Nonintegral portrait rectangle: "+id)
				return
		var source := Rect2i(int(spec.rect[0]),int(spec.rect[1]),int(spec.rect[2]),int(spec.rect[3]))
		if source.size != CELL or source.position.x%64 != 0 or source.position.y%64 != 0 or not Rect2i(Vector2i.ZERO,SIZE).encloses(source) or occupied.has(source.position):
			_reject("Overlapping or escaped portrait cell: "+id)
			return
		var used := image.get_region(source).get_used_rect()
		if not used.has_area() or not Rect2i(2,2,60,60).encloses(used):
			_reject("Empty portrait or invalid transparent gutter: "+id)
			return
		occupied[source.position] = true
		entries[id] = {"rect":source,"used":used,"prompt_id":str(spec.prompt_id)}
	_pixel_hash = image.get_data().hex_encode().sha256_text()
	_png_hash = str(parsed.sha256)
	_texture = ImageTexture.create_from_image(image)
	for y: int in range(image.get_height()):
		for x: int in range(image.get_width()):
			var color := image.get_pixel(x,y)
			var light := color.r*0.299+color.g*0.587+color.b*0.114
			image.set_pixel(x,y,Color(light*0.75,light*0.75,light*0.75,color.a))
	_grey = ImageTexture.create_from_image(image)
	_entries = entries
	_loads += 1

static func inspect(unit: Dictionary) -> Dictionary:
	var id := identity(unit)
	if not CommandArt.enabled() or id not in IDENTITIES: return {"supported":false,"identity":id}
	_ensure()
	if not _entries.has(id): return {"supported":false,"identity":id,"fallback_reason":_failure}
	return {"supported":true,"identity":id,"rect":_entries[id].rect,"used":_entries[id].used,"provenance":PROVENANCE,"prompt_id":_entries[id].prompt_id,"original_art":true,"licensed_art":false,"animation":false,"source_pixel_hash":_pixel_hash,"sha256":_png_hash}

static func draw(canvas: Object, rect: Rect2, unit: Dictionary, alive: bool = true) -> bool:
	if not rect.position.is_finite() or not rect.size.is_finite() or rect.size.x <= 0 or rect.size.y <= 0: return false
	var info := inspect(unit)
	if not info.get("supported",false): return false
	var scale_factor := minf(rect.size.x/64.0,rect.size.y/64.0)
	var size := Vector2(CELL)*scale_factor
	var destination := Rect2((rect.get_center()-size*0.5).round(),size)
	if canvas is CanvasItem: canvas.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	canvas.draw_texture_rect_region(_texture if alive else _grey,destination,Rect2(info.rect),Color.WHITE)
	return true

static func status() -> Dictionary:
	_ensure()
	return {"complete":_entries.size()==IDENTITIES.size(),"accepted_count":_entries.size(),"expected_count":IDENTITIES.size(),"accepted_roles":_entries.keys(),"provenance":PROVENANCE,"fallback_reason":_failure,"texture_count":2 if _texture != null else 0,"texture_bytes":MAX_TEXTURE_BYTES if _texture != null else 0,"cpu_pixel_bytes":0,"owner_atlas_copies":0,"loads":_loads,"sha256":_png_hash}

static func debug_stats() -> Dictionary:
	return status()
