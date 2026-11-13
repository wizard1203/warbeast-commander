extends RefCounted
## Real, locally licensed Heroic Starter sheets. Regions were inspected on the
## acquired sheets; no game screenshot, paid preview or pre-rendered fallback.
const MANIFEST_PATH := "res://assets/art/heroic/manifest.json"
const MAX_TEXTURE_BYTES := 4 * 1024 * 1024
const INSTALL_COMMAND := "node tools/install_heroic_starter.mjs '/path/to/HAS Starter Pack.zip'"
const Collection = preload("res://src/presentation/heroic_collection.gd")
const REGIONS := {
	"grass": ["land",16,0,16,16,0,0],
	"grass_dense": ["land",16,16,16,16,0,0],
	"grass_patch": ["land",160,224,48,48,24,24],
	"water": ["land",112,144,16,16,0,0],
	"shore_nw": ["land",96,128,16,16,0,0],
	"shore_n": ["land",112,128,16,16,0,0],
	"shore_ne": ["land",128,128,16,16,0,0],
	"shore_w": ["land",96,144,16,16,0,0],
	"shore_e": ["land",128,144,16,16,0,0],
	"shore_sw": ["land",96,160,16,16,0,0],
	"shore_s": ["land",112,160,16,16,0,0],
	"shore_se": ["land",128,160,16,16,0,0],
	"flowers": ["land",32,0,32,16,16,13],
	"flowers_small": ["land",32,16,32,16,16,13],
	"stones": ["land",64,0,32,16,16,12],
	"stones_small": ["land",64,16,32,16,16,12],
	"bush": ["land",96,16,16,16,8,14],
	"bush_wide": ["land",112,0,16,16,8,13],
	"deadwood": ["land",128,0,32,16,16,13],
	"reeds": ["land",192,0,32,16,16,14],
	"cave": ["land",224,0,32,32,16,27],
	"oak": ["trees",16,0,16,16,8,15],
	"oak_pair": ["trees",32,0,32,32,16,30],
	"pine": ["trees",16,48,16,16,8,15],
	"pine_pair": ["trees",32,48,32,32,16,30],
	"mountain": ["mountains",16,0,16,16,8,15],
	"mountain_big": ["mountains",208,0,32,32,16,30],
	"mountain_ridge": ["mountains",240,0,32,48,16,45],
	"castle": ["objects",16,16,48,48,24,44],
	"house_a": ["objects",64,0,16,16,8,15],
	"house_b": ["objects",80,0,16,16,8,15],
	"house_c": ["objects",96,0,16,16,8,15],
	"hall": ["objects",80,16,16,16,8,15],
	"chapel": ["objects",96,16,16,16,8,15],
	"workshop": ["objects",64,16,16,16,8,15],
	"house_d": ["objects",64,32,16,16,8,15],
	"house_e": ["objects",80,32,16,16,8,15],
	"house_f": ["objects",96,32,16,16,8,15],
	"field_soil": ["objects",112,0,16,16,8,14],
	"field_green": ["objects",112,16,16,16,8,14],
	"field_bloom": ["objects",112,32,16,16,8,14],
	"field_ripe": ["objects",112,48,16,16,8,14],
	"road_stamp": ["road",0,64,16,16,8,8],
	"road_fill": ["road",96,16,16,16,0,0],
}
static var _attempted := false
static var _textures: Dictionary = {}
static var _images: Dictionary = {}
static var _regions: Dictionary = {}
static var _report: Dictionary = {}


static func reset_cache() -> void:
	_attempted = false
	_textures.clear()
	_images.clear()
	_regions.clear()
	_report.clear()


static func validate_installation() -> Dictionary:
	if _attempted: return _report.duplicate(true)
	_attempted = true
	var failures: Array[String] = []
	var bytes := 0
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST_PATH)) if FileAccess.file_exists(MANIFEST_PATH) else null
	if not parsed is Dictionary or int(parsed.get("schema_version",0)) != 1:
		failures.append("Heroic Starter manifest missing or invalid: " + MANIFEST_PATH)
	else:
		var root := str(parsed.get("runtime_root",""))
		if root != "res://assets/third_party/heroic_local/": failures.append("Heroic runtime root is not the protected local directory")
		var sheets: Dictionary = parsed.get("sheets",{})
		for key: String in ["land","mountains","objects","river","road","tileset","trees"]:
			var spec: Dictionary = sheets.get(key,{})
			var name := str(spec.get("file",""))
			if name.is_empty() or "/" in name or ".." in name:
				failures.append("Invalid Heroic sheet: " + key)
				continue
			var path := root + name
			if not FileAccess.file_exists(path):
				failures.append("Missing Heroic sheet: " + name)
				continue
			var file := FileAccess.open(path,FileAccess.READ)
			if file == null or file.get_length() != int(spec.get("bytes",-1)) or FileAccess.get_sha256(path) != str(spec.get("sha256","")):
				failures.append("Altered Heroic sheet: " + name)
				continue
			var image := Image.new()
			if image.load_png_from_buffer(file.get_buffer(file.get_length())) != OK or image.get_size() != Vector2i(int(spec.get("width",0)),int(spec.get("height",0))):
				failures.append("Invalid Heroic PNG dimensions: " + name)
				continue
			image.convert(Image.FORMAT_RGBA8)
			bytes += image.get_width()*image.get_height()*4
			_images[key] = image
			_textures[key] = ImageTexture.create_from_image(image)
		if bytes > MAX_TEXTURE_BYTES or int(parsed.get("texture_budget_bytes",0)) != MAX_TEXTURE_BYTES: failures.append("Heroic sheets exceed or disagree with the shared texture budget")
		if bytes != int(parsed.get("texture_rgba8_bytes",-1)): failures.append("Heroic shared RGBA8 total differs from the pinned manifest")
		for key: String in REGIONS:
			var values: Array = REGIONS[key]
			var image: Image = _images.get(str(values[0]))
			var rect := Rect2i(int(values[1]),int(values[2]),int(values[3]),int(values[4]))
			if image == null or not Rect2i(Vector2i.ZERO,image.get_size()).encloses(rect): failures.append("Heroic source region is out of bounds: " + key)
	var collection := Collection.status()
	var command := INSTALL_COMMAND
	if not bool(collection.get("ready",false)):
		failures.append_array(collection.get("failures",[]))
		command = str(collection.get("install_command",INSTALL_COMMAND))
	_report = {"ready":failures.is_empty(),"sheets":_textures.size(),"texture_bytes":bytes,"cpu_pixel_bytes":bytes,"regions":REGIONS.size(),"owner_atlas_copies":0,"failures":failures,"install_command":command,"manifest_path":MANIFEST_PATH,"profile":str(collection.get("profile","starter")),"collection":collection}
	if not failures.is_empty():
		_textures.clear()
		_images.clear()
	return _report.duplicate(true)


static func inspect(key: String) -> Dictionary:
	if not _attempted: validate_installation()
	if not bool(_report.get("ready",false)) or not REGIONS.has(key): return {"supported":false}
	var v: Array = REGIONS[key]
	return {"supported":true,"key":key,"sheet":str(v[0]),"rect":Rect2(v[1],v[2],v[3],v[4]),"anchor":Vector2(v[5],v[6])}


static func sprite_bounds(key: String, scale_factor: float = 1.0) -> Rect2:
	if not is_finite(scale_factor) or scale_factor <= 0: return Rect2()
	var entry := inspect(key)
	if not entry.supported: return Rect2()
	return Rect2(-Vector2(entry.anchor)*scale_factor,Rect2(entry.rect).size*scale_factor)


static func draw_sprite(canvas: Object, key: String, foot: Vector2, scale_factor: float = 1.0, modulation: Color = Color.WHITE) -> bool:
	if not foot.is_finite(): return false
	var bounds := sprite_bounds(key,scale_factor)
	if bounds.size == Vector2.ZERO: return false
	var entry := inspect(key)
	if canvas is CanvasItem: canvas.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	canvas.draw_texture_rect_region(_textures[entry.sheet],Rect2((foot+bounds.position).round(),bounds.size),entry.rect,modulation)
	return true


static func body_contains(key: String, offset: Vector2, scale_factor: float = 1.0) -> bool:
	if not offset.is_finite() or not is_finite(scale_factor) or scale_factor <= 0: return false
	var entry := inspect(key)
	if not entry.supported: return false
	var point := Vector2i((offset/scale_factor+Vector2(entry.anchor)).floor())
	var rect: Rect2 = entry.rect
	if point.x<0 or point.y<0 or point.x>=int(rect.size.x) or point.y>=int(rect.size.y): return false
	var image: Image = _images[entry.sheet]
	return image.get_pixelv(Vector2i(rect.position)+point).a > 0.1


static func region_image(key: String) -> Image:
	var entry := inspect(key)
	if not entry.supported: return null
	# Private immutable shared crops are only consumed by our terrain baker.
	if not _regions.has(key): _regions[key] = (_images[entry.sheet] as Image).get_region(Rect2i(entry.rect))
	return _regions[key]


static func debug_stats() -> Dictionary:
	return validate_installation()
