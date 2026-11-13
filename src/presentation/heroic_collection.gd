extends RefCounted
## Shared, local, verified pixels. Callers must not mutate returned source images.
const MANIFEST_PATH := "res://assets/art/heroic/collection-manifest.json"
const ROOT := "res://assets/third_party/heroic_collection/"
const MAX_TEXTURE_BYTES := 24 * 1024 * 1024
const INSTALL_COMMAND := "node tools/install_heroic_collection.mjs --from-dir '/path/to/asset-library'"
static var _attempted := false
static var _report: Dictionary = {}
static var _specs: Dictionary = {}
static var _images: Dictionary = {}
static var _textures: Dictionary = {}
static var _loaded_bytes := 0


static func reset_cache() -> void:
	_attempted = false
	_report.clear()
	_specs.clear()
	_images.clear()
	_textures.clear()
	_loaded_bytes = 0


static func _safe_file(file: String) -> bool:
	return not file.is_empty() and not file.begins_with("/") and not file.contains("\\") and not file.contains(":") and not file.split("/").has("..") and not file.split("/").has(".") and file.ends_with(".png")


static func status() -> Dictionary:
	if _attempted: return _report.duplicate(true)
	_attempted = true
	if not DirAccess.dir_exists_absolute(ROOT):
		if FileAccess.file_exists(ROOT.trim_suffix("/")):
			_report = {"ready":false,"profile":"collection","installed":true,"files":0,"failures":["Collection runtime root is not a directory"],"install_command":INSTALL_COMMAND}
			return _report.duplicate(true)
		_report = {"ready":true,"profile":"starter","installed":false,"files":0,"failures":[],"install_command":INSTALL_COMMAND}
		return _report.duplicate(true)
	var failures: Array[String] = []
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST_PATH)) if FileAccess.file_exists(MANIFEST_PATH) else null
	var bytes := 0
	if not parsed is Dictionary or int(parsed.get("schema_version",0)) != 1 or str(parsed.get("runtime_root","")) != ROOT:
		failures.append("Collection manifest missing or invalid")
	else:
		var packs: Dictionary = parsed.get("packs",{})
		for pack: String in ["overworld","buildings","creatures","icons","magic"]:
			var files: Dictionary = packs.get(pack,{}).get("files",{})
			if files.is_empty(): failures.append("Collection manifest has no files: " + pack)
			for name: String in files:
				var spec: Dictionary = files[name]
				if not _safe_file(name):
					failures.append("Unsafe collection path: " + pack)
					continue
				var path := ROOT + pack + "/" + name
				if not FileAccess.file_exists(path):
					failures.append("Missing collection PNG: " + pack + "/" + name)
					continue
				var file := FileAccess.open(path,FileAccess.READ)
				if file == null or file.get_length() != int(spec.get("bytes",-1)) or file.get_length() > 4*1024*1024 or FileAccess.get_sha256(path) != str(spec.get("sha256","")):
					failures.append("Altered collection PNG: " + pack + "/" + name)
					continue
				var header := file.get_buffer(24)
				if header.size() < 24 or header.slice(0,8).hex_encode() != "89504e470d0a1a0a" or header.slice(12,16).get_string_from_ascii() != "IHDR":
					failures.append("Invalid collection PNG header: " + pack + "/" + name)
					continue
				var width := _big_endian(header,16)
				var height := _big_endian(header,20)
				if width != int(spec.get("width",0)) or height != int(spec.get("height",0)) or width <= 0 or height <= 0:
					failures.append("Collection PNG dimensions differ: " + pack + "/" + name)
					continue
				bytes += width*height*4
				_specs[pack+":"+name] = {"path":path,"width":width,"height":height,"pack":pack,"file":name}
		if bytes > MAX_TEXTURE_BYTES or int(parsed.get("texture_budget_bytes",0)) != MAX_TEXTURE_BYTES: failures.append("Collection selected pixels exceed shared budget")
		if bytes != int(parsed.get("selected_rgba8_bytes",-1)): failures.append("Collection selected RGBA8 total differs")
	_report = {"ready":failures.is_empty(),"profile":"collection","installed":true,"files":_specs.size(),"selected_rgba8_bytes":bytes,"texture_budget_bytes":MAX_TEXTURE_BYTES,"failures":failures,"install_command":INSTALL_COMMAND,"attribution":"Heroic Asset Series artwork by Aleksandr Makarov (iknowkingrabbit)"}
	if not failures.is_empty(): _specs.clear()
	return _report.duplicate(true)


static func _big_endian(data: PackedByteArray, offset: int) -> int:
	return (int(data[offset]) << 24) | (int(data[offset+1]) << 16) | (int(data[offset+2]) << 8) | int(data[offset+3])


static func active() -> bool:
	var state := status()
	return bool(state.ready) and str(state.profile) == "collection"


static func image(pack: String, file: String) -> Image:
	if not active(): return null
	var key := pack + ":" + file
	if not _specs.has(key): return null
	if _images.has(key): return _images[key]
	var spec: Dictionary = _specs[key]
	var amount := int(spec.width)*int(spec.height)*4
	if _loaded_bytes + amount > MAX_TEXTURE_BYTES: return null
	var source := Image.new()
	if source.load_png_from_buffer(FileAccess.get_file_as_bytes(spec.path)) != OK or source.get_size() != Vector2i(int(spec.width),int(spec.height)): return null
	source.convert(Image.FORMAT_RGBA8)
	_images[key] = source
	_loaded_bytes += amount
	return source


static func texture(pack: String, file: String) -> Texture2D:
	var key := pack + ":" + file
	if _textures.has(key): return _textures[key]
	var source := image(pack,file)
	if source == null: return null
	_textures[key] = ImageTexture.create_from_image(source)
	return _textures[key]


static func draw_region(canvas: Object, pack: String, file: String, rect: Rect2i, foot: Vector2, anchor: Vector2, scale_factor: float, modulation: Color = Color.WHITE) -> bool:
	if not foot.is_finite() or not anchor.is_finite() or not is_finite(scale_factor) or scale_factor <= 0: return false
	var source := image(pack,file)
	if source == null or not Rect2i(Vector2i.ZERO,source.get_size()).encloses(rect) or rect.size.x <= 0 or rect.size.y <= 0: return false
	var pixels := texture(pack,file)
	if pixels == null: return false
	if canvas is CanvasItem: canvas.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	canvas.draw_texture_rect_region(pixels,Rect2((foot-anchor*scale_factor).round(),Vector2(rect.size)*scale_factor),Rect2(rect),modulation)
	return true


static func debug_stats() -> Dictionary:
	var report := status()
	report["loaded_images"] = _images.size()
	report["textures"] = _textures.size()
	report["loaded_rgba8_bytes"] = _loaded_bytes
	report["cpu_pixel_bytes"] = _loaded_bytes
	report["owner_atlas_copies"] = 0
	return report
