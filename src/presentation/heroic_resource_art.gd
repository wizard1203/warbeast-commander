extends RefCounted
## Optional original food/ore props. The two shared images, their grey exhausted
## variants and alpha envelopes belong only to presentation, never map logic.
const Collection = preload("res://src/presentation/heroic_collection.gd")
const ROOT := "res://assets/art/original/m38/resources/"
const MANIFEST := ROOT + "manifest.json"
const PROVENANCE := "original-ai-pixel-m38-resources"
const SIZE := Vector2i(64,64)
const ANCHOR := Vector2(32,58)
const WIDTHS := {"FOOD":150.0,"MATERIAL":130.0}
const MAX_PNG_BYTES := 256*1024
const MAX_MANIFEST_BYTES := 16*1024
const MAX_TEXTURE_BYTES := 2*2*64*64*4
static var _attempted := false
static var _report: Dictionary = {}
static var _assets: Dictionary = {}
static var _source_bytes := 0
static var _texture_bytes := 0


static func reset_cache() -> void:
	_attempted = false
	_report.clear()
	_assets.clear()
	_source_bytes = 0
	_texture_bytes = 0


static func resource_kind(source: Dictionary) -> String:
	return str(source.get("resource_type",source.get("kind",source.get("resource",""))))


static func available(source: Dictionary) -> bool:
	return int(source.get("remaining",source.get("remaining_amount",source.get("stock",1)))) > 0 and str(source.get("state","")) not in ["DEPLETED","EXHAUSTED"]


static func _safe_file(file: String) -> bool:
	return file.begins_with("runtime/") and file.ends_with(".png") and file.count("/") == 1 and not file.contains("..") and not file.contains("\\") and not file.contains(":")


static func _linked(file: String) -> bool:
	var current := "res://"
	for part: String in (ROOT.trim_prefix("res://")+file).split("/",false):
		var parent := DirAccess.open(current)
		if parent == null or parent.is_link(part): return true
		current = current.path_join(part)
	return false


static func _number(value: Variant) -> float:
	return float(value) if typeof(value) in [TYPE_INT,TYPE_FLOAT] else NAN


static func _pair(value: Variant, expected: Vector2i) -> bool:
	return value is Array and value.size() == 2 and _number(value[0]) == expected.x and _number(value[1]) == expected.y


static func _validate(kind: String, value: Variant) -> Dictionary:
	if not value is Dictionary: return {"failure":"Resource asset entry is not a dictionary: "+kind}
	var spec: Dictionary = value
	var file := str(spec.get("file",""))
	if not _safe_file(file) or _linked(file): return {"failure":"Unsafe, missing or linked original resource path: "+kind}
	if str(spec.get("provenance",PROVENANCE)) != PROVENANCE or not spec.get("prompt_id") is String or str(spec.get("prompt_id","")).is_empty(): return {"failure":"Missing original resource provenance: "+kind}
	if _number(spec.get("width")) != SIZE.x or _number(spec.get("height")) != SIZE.y or not _pair(spec.get("anchor"),Vector2i(ANCHOR)) or _number(spec.get("world_width")) != WIDTHS[kind]: return {"failure":"Original resource dimensions/anchor/world width differ: "+kind}
	var path := ROOT+file
	var handle := FileAccess.open(path,FileAccess.READ)
	if handle == null or handle.get_length() <= 24 or handle.get_length() > MAX_PNG_BYTES or _number(spec.get("bytes")) != handle.get_length(): return {"failure":"Original resource PNG byte envelope differs: "+kind}
	if FileAccess.get_sha256(path) != str(spec.get("sha256","")): return {"failure":"Original resource PNG hash differs: "+kind}
	var header := handle.get_buffer(24)
	if header.slice(0,8).hex_encode() != "89504e470d0a1a0a" or header.slice(12,16).get_string_from_ascii() != "IHDR" or header.slice(16,24).hex_encode() != "0000004000000040": return {"failure":"Original resource PNG header dimensions differ: "+kind}
	var image := Image.new()
	if image.load_png_from_buffer(FileAccess.get_file_as_bytes(path)) != OK or image.get_size() != SIZE: return {"failure":"Original resource PNG decode failed: "+kind}
	image.convert(Image.FORMAT_RGBA8)
	var used := image.get_used_rect()
	if not used.has_area() or not Rect2i(1,1,62,62).encloses(used): return {"failure":"Original resource body is empty or touches its transparent gutter: "+kind}
	var transparent := 0
	for y: int in range(SIZE.y):
		for x: int in range(SIZE.x):
			if image.get_pixel(x,y).a <= 0.1: transparent += 1
	if transparent < 400: return {"failure":"Original resource lacks a meaningful transparent cutout: "+kind}
	var grey := image.duplicate() as Image
	for y: int in range(SIZE.y):
		for x: int in range(SIZE.x):
			var color := image.get_pixel(x,y)
			var light := color.r*0.2126+color.g*0.7152+color.b*0.0722
			grey.set_pixel(x,y,Color(light*0.72,light*0.72,light*0.72,color.a))
	var result := spec.duplicate(true)
	result.merge({"image":image,"grey":grey,"texture":ImageTexture.create_from_image(image),"exhausted_texture":ImageTexture.create_from_image(grey),"used":used,"source_pixel_hash":image.get_data().hex_encode().sha256_text(),"exhausted_pixel_hash":grey.get_data().hex_encode().sha256_text()})
	return {"asset":result}


static func _ensure() -> void:
	if _attempted: return
	_attempted = true
	var failures: Array[String] = []
	var rejected: Dictionary = {}
	var installed := FileAccess.file_exists(MANIFEST)
	var active := Collection.active()
	var approved := false
	if active and installed:
		var handle := FileAccess.open(MANIFEST,FileAccess.READ)
		var value: Variant = null
		if _linked("manifest.json") or handle == null or handle.get_length() <= 0 or handle.get_length() > MAX_MANIFEST_BYTES: failures.append("Original resource manifest path/byte envelope differs")
		else: value = JSON.parse_string(handle.get_as_text())
		if not value is Dictionary or _number(value.get("schema_version")) != 1 or value.get("accepted") != true or typeof(value.get("accepted")) != TYPE_BOOL or str(value.get("status","")) != "accepted" or str(value.get("provenance","")) != PROVENANCE or not value.get("assets") is Dictionary:
			failures.append("Original resource manifest schema/explicit approval differs")
		else:
			approved = true
			for kind: String in value.assets:
				if not WIDTHS.has(kind): failures.append("Unknown original resource identity: "+kind)
			for kind: String in WIDTHS:
				if not value.assets.has(kind): continue
				var checked := _validate(kind,value.assets[kind])
				if checked.has("failure"):
					rejected[kind] = checked.failure
					failures.append(str(checked.failure))
				else:
					var duplicate := false
					for accepted: Dictionary in _assets.values():
						if str(accepted.sha256) == str(checked.asset.sha256): duplicate = true
					if duplicate:
						rejected[kind] = "Distinct food/ore identities cannot reuse the same original image"
						failures.append(str(rejected[kind]))
						continue
					_assets[kind] = checked.asset
					_source_bytes += SIZE.x*SIZE.y*4
					_texture_bytes += SIZE.x*SIZE.y*4*2
	var accepted: Array = _assets.keys()
	accepted.sort()
	var missing: Array[String] = []
	for kind: String in WIDTHS:
		if not _assets.has(kind): missing.append(kind)
	_report = {"ready":active and not _assets.is_empty(),"complete":active and _assets.size() == WIDTHS.size() and failures.is_empty(),"profile_active":active,"installed":installed,"approved_manifest":approved,"accepted_resources":accepted,"missing_resources":missing,"rejected_resources":rejected,"failures":failures,"provenance":PROVENANCE,"source_rgba8_bytes":_source_bytes,"texture_bytes":_texture_bytes,"cpu_pixel_bytes":_texture_bytes,"maximum_texture_bytes":MAX_TEXTURE_BYTES,"owner_atlas_copies":0,"source_images_unmodified":true}


static func status() -> Dictionary:
	_ensure()
	return _report.duplicate(true)


static func source_pixel_hash(kind: String) -> String:
	_ensure()
	return (_assets[kind].image as Image).get_data().hex_encode().sha256_text() if _assets.has(kind) else ""


static func inspect(source: Dictionary, factor: float = 1.0) -> Dictionary:
	if not is_finite(factor) or factor <= 0: return {"supported":false}
	var kind := resource_kind(source)
	if not WIDTHS.has(kind): return {"supported":false}
	_ensure()
	if not _assets.has(kind): return {"supported":false,"fallback_reason":"No accepted original resource image for "+kind}
	var asset: Dictionary = _assets[kind]
	var scale_factor: float = WIDTHS[kind]/float(asset.used.size.x)*factor
	var body := Rect2((Vector2(asset.used.position)-ANCHOR)*scale_factor,Vector2(asset.used.size)*scale_factor)
	var badge_size := clampf(26.0*factor,20.0,30.0)
	# The cue stays near the unchanged source foot, inside MATERIAL's existing
	# max(50*zoom,26px) site circle. Enlarging the illustration does not create
	# a misleading remote floating target or expand gameplay picking.
	var badge_center := Vector2(20,-8)*factor
	var badge := Rect2(badge_center-Vector2.ONE*badge_size*0.5,Vector2.ONE*badge_size)
	var is_available := available(source)
	return {"supported":true,"kind":kind,"provenance":PROVENANCE,"original_art":true,"licensed_art":false,"file":asset.file,"sha256":asset.sha256,"prompt_id":asset.prompt_id,"rect":Rect2i(Vector2i.ZERO,SIZE),"anchor":ANCHOR,"scale":scale_factor,"bounds":body.merge(badge),"body_bounds":body,"badge_bounds":badge,"badge_center":badge_center,"badge_size":badge_size,"available":is_available,"depleted":not is_available,"state":str(source.get("state","")),"source_pixel_hash":asset.source_pixel_hash,"body_pixel_hash":asset.source_pixel_hash if is_available else asset.exhausted_pixel_hash,"source_unmodified":true,"world_width":WIDTHS[kind]}


static func visual_bounds(source: Dictionary, factor: float = 1.0) -> Rect2:
	var info := inspect(source,factor)
	return info.bounds if info.get("supported",false) else Rect2()


static func draw(canvas: Object, point: Vector2, source: Dictionary, factor: float = 1.0) -> bool:
	if not point.is_finite(): return false
	var info := inspect(source,factor)
	if not info.get("supported",false): return false
	var asset: Dictionary = _assets[info.kind]
	var destination := Rect2(point-ANCHOR*float(info.scale),Vector2(SIZE)*float(info.scale))
	if canvas is CanvasItem: canvas.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	canvas.draw_texture_rect_region(asset.texture if info.available else asset.exhausted_texture,destination,Rect2(info.rect),Color.WHITE)
	_badge(canvas,point+Vector2(info.badge_center),float(info.badge_size),str(info.kind),bool(info.available))
	return true


static func _badge(canvas: Object, center: Vector2, extent: float, kind: String, is_available: bool) -> void:
	var s := extent/24.0
	var edge := Color("c4a16a") if is_available else Color("858476")
	var ink := Color("ead39a") if is_available else Color("93968b")
	var outline := PackedVector2Array([Vector2(-8,-12),Vector2(8,-12),Vector2(12,-8),Vector2(12,8),Vector2(8,12),Vector2(-8,12),Vector2(-12,8),Vector2(-12,-8)])
	var inner := PackedVector2Array()
	for vertex: Vector2 in outline:
		inner.append(center+vertex*s*0.86)
	for i: int in range(outline.size()): outline[i] = center+outline[i]*s
	canvas.draw_colored_polygon(outline,edge)
	canvas.draw_colored_polygon(inner,Color("292b24"))
	if kind == "FOOD":
		canvas.draw_rect(Rect2((center+Vector2(-1,-7)*s).round(),Vector2(2,15)*s),ink)
		for y: int in [-5,-1,3]:
			canvas.draw_colored_polygon(PackedVector2Array([center+Vector2(-1,y)*s,center+Vector2(-6,y-4)*s,center+Vector2(-6,y)*s,center+Vector2(-1,y+3)*s]),ink)
			canvas.draw_colored_polygon(PackedVector2Array([center+Vector2(1,y)*s,center+Vector2(6,y-4)*s,center+Vector2(6,y)*s,center+Vector2(1,y+3)*s]),ink)
	else:
		canvas.draw_colored_polygon(PackedVector2Array([center+Vector2(-8,4)*s,center+Vector2(-5,-4)*s,center+Vector2(4,-5)*s,center+Vector2(8,3)*s,center+Vector2(4,7)*s,center+Vector2(-5,7)*s]),ink)
		canvas.draw_colored_polygon(PackedVector2Array([center+Vector2(-5,-4)*s,center+Vector2(4,-5)*s,center+Vector2(8,3)*s,center+Vector2(-1,3)*s]),Color("f2dda8") if is_available else Color("a4a69a"))
	if not is_available:
		canvas.draw_line(center+Vector2(-8,8)*s,center+Vector2(8,-8)*s,Color("262b25"),maxf(4*s,2))
		canvas.draw_line(center+Vector2(-8,8)*s,center+Vector2(8,-8)*s,Color("b99a7d"),maxf(2*s,1))
