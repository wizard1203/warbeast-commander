extends RefCounted
## Six new authored RANGE bodies only; every other V2 building stays untouched.
## Names project the one World table. Art never sets prices, range or ownership.
const ROOT := "res://assets/art/original/outposts-v3-magic-camps/"
const MANIFEST := ROOT + "manifest.json"
const PROVENANCE := "original-new-authored-outposts-v3-magic-camps"
const FACTIONS := ["HUMAN","UNDEAD","MACHINE","FOREST","HIGHLAND","UNDERGROUND"]
const FRAME := Vector2i(128,128)
const FOOT := Vector2(64,116)
const PIXEL_SCALE := 1.5
const World = preload("res://src/simulation/strategic_world.gd")
const TeamMaterial = preload("res://src/presentation/heroic_team_material_m70.gd")
static var _attempted := false
static var _specs: Dictionary = {}
static var _images: Dictionary = {}
static var _textures: Dictionary = {}
static var _masks: Dictionary = {}
static var _failures: Array[String] = []

static func label_for(faction: String) -> String:return str(World.MAGIC_CAMP_NAMES.get(faction,"魔法营"))
static func symbol_for(faction: String) -> String:return "MAGIC_CAMP_"+faction if faction in FACTIONS else "RANGE"

static func reset_cache() -> void:
	_attempted=false;_specs.clear();_images.clear();_textures.clear();_masks.clear();_failures.clear()

static func _digest(image: Image) -> String:
	var hash := HashingContext.new()
	hash.start(HashingContext.HASH_SHA256);hash.update(image.get_data())
	return hash.finish().hex_encode()

static func _dimensions(value: Variant, expected: Vector2i) -> bool:
	# JSON numbers may be floats. Compare numeric values, never coerce a
	# string/fractional coordinate to an integer or weaken the fixed art grid.
	if not value is Array or value.size()!=2:return false
	for index: int in range(2):
		if typeof(value[index]) not in [TYPE_INT,TYPE_FLOAT] or not is_finite(float(value[index])) or float(value[index])!=float(expected[index]):return false
	return true

static func _verified_file(relative: String, sha: String, bytes: int) -> bool:
	var parts := relative.split("/")
	if parts.size()!=2 or parts[0] not in ["source","runtime"] or parts[1] in ["",".",".."] or not parts[1].ends_with(".png") or bytes<=24 or bytes>32*1024*1024 or sha.length()!=64:return false
	var root := DirAccess.open(ROOT)
	var directory := DirAccess.open(ROOT+parts[0])
	if root==null or root.is_link(parts[0]) or directory==null or directory.is_link(parts[1]):return false
	var file := FileAccess.open(ROOT+relative,FileAccess.READ)
	return file!=null and file.get_length()==bytes and FileAccess.get_sha256(ROOT+relative)==sha

static func _blue_mask(image: Image) -> Image:
	var mask := Image.create(FRAME.x,FRAME.y,false,Image.FORMAT_RGBA8)
	mask.fill(Color.TRANSPARENT)
	for y: int in range(FRAME.y):
		for x: int in range(FRAME.x):
			var color := image.get_pixel(x,y)
			if color.a>0.5 and color.h>0.54 and color.h<0.72 and color.s>0.3 and color.v>0.25:
				var shade := clampf(color.v*1.08,0.4,1.0)
				mask.set_pixel(x,y,Color(shade,shade,shade,1))
	return mask

static func _prepare() -> void:
	if _attempted:return
	_attempted=true
	var file := FileAccess.open(MANIFEST,FileAccess.READ)
	if file==null or file.get_length()<=0 or file.get_length()>1024*1024:
		_failures.append("V3 magic-camp manifest absent/unreadable; unchanged V2 fallback");return
	var raw: Variant = JSON.parse_string(file.get_as_text())
	if not raw is Dictionary or raw.get("schema_version")!=1 or raw.get("accepted")!=true or raw.get("status")!="accepted" or raw.get("compile_ready")!=true or raw.get("provenance")!=PROVENANCE or raw.get("factions")!=FACTIONS or not _dimensions(raw.get("frame_size"),FRAME) or not _dimensions(raw.get("anchor"),Vector2i(FOOT)) or not raw.get("assets") is Dictionary:
		_failures.append("V3 magic-camp pack lacks all-six explicit acceptance");return
	for faction: String in FACTIONS:
		var record: Variant = raw.assets.get(faction,{})
		if not record is Dictionary:
			_failures.append(faction+": magic-camp metadata is not an object");continue
		var spec: Dictionary = record
		if spec.get("file")!="runtime/"+faction.to_lower()+"-magic-camp-v3.png" or spec.get("source_file")!="source/"+faction.to_lower()+".png" or not _verified_file(str(spec.get("file","")),str(spec.get("sha256","")),int(spec.get("bytes",0))) or not _verified_file(str(spec.get("source_file","")),str(spec.get("source_sha256","")),int(spec.get("source_bytes",0))):
			_failures.append(faction+": magic-camp source/runtime bytes or SHA differs");continue
		var image := Image.new()
		if image.load_png_from_buffer(FileAccess.get_file_as_bytes(ROOT+spec.file))!=OK or image.get_size()!=FRAME:
			_failures.append(faction+": magic-camp PNG dimensions/decode differs");continue
		image.convert(Image.FORMAT_RGBA8)
		var used := image.get_used_rect()
		if not used.has_area() or not Rect2i(1,1,126,126).encloses(used) or _digest(image)!=str(spec.get("frame_pixel_sha256","")):
			_failures.append(faction+": magic-camp pixels/gutter differs");continue
		_specs[faction]=spec.duplicate(true);_images[faction]=image
		_textures[faction]=ImageTexture.create_from_image(image)
		_masks[faction]=ImageTexture.create_from_image(_blue_mask(image))

static func status() -> Dictionary:
	_prepare()
	return {"ready":_specs.size()==6 and _failures.is_empty(),"factions":_specs.size(),"expected_roles":6,"kind":"RANGE","provenance":PROVENANCE,"failures":_failures.duplicate(),"atlas_rgba8_bytes":_images.size()*128*128*4,"mask_rgba8_bytes":_masks.size()*128*128*4,"owner_atlas_copies":0}

static func inspect(building: Dictionary, factor: float=1.0) -> Dictionary:
	if building.get("building_type","")!="RANGE" or not is_finite(factor) or factor<=0 or int(building.get("hp",1))<=0:return {"supported":false}
	_prepare()
	var faction := str(building.get("faction_id","HUMAN"))
	if _specs.size()!=6 or not _failures.is_empty() or not _specs.has(faction):return {"supported":false}
	var image: Image = _images[faction]
	var used := image.get_used_rect()
	var scale := PIXEL_SCALE*factor
	var body := Rect2((Vector2(used.position)-FOOT)*scale,Vector2(used.size)*scale)
	var pole := Vector2(body.position.x+body.size.x*0.8,body.position.y)
	var bounds := body.merge(Rect2(pole+Vector2(-1,-17)*factor,Vector2(14,18)*factor))
	var scaffold := body.grow(4*factor) if not bool(building.get("complete",false)) else Rect2()
	if scaffold.has_area():bounds=bounds.merge(scaffold)
	return {"supported":true,"architecture_provider":"outposts-v3-magic-camps","architecture_key":faction+":RANGE:v3","architecture_faction":faction,"architecture_kind":"RANGE","label":label_for(faction),"icon_symbol":symbol_for(faction),"provenance":PROVENANCE,"pack":"original-outposts-v3-magic-camps","file":_specs[faction].file,"rect":Rect2i(Vector2i.ZERO,FRAME),"anchor":FOOT,"scale":scale,"source_pixel_scale":PIXEL_SCALE,"bounds":bounds,"body_bounds":body,"scaffold_bounds":scaffold,"pole":pole,"alive":true,"pixel_hash":_specs[faction].frame_pixel_sha256,"team_accent":"authored-blue-cloth-and-pennant","source_unmodified":true}

static func frame_image(entry: Dictionary) -> Image:
	_prepare()
	var faction := str(entry.get("architecture_faction",""))
	return (_images[faction] as Image).get_region(Rect2i(Vector2i.ZERO,FRAME)) if _images.has(faction) else null

static func body_contains(entry: Dictionary, offset: Vector2) -> bool:
	if not offset.is_finite() or not bool(entry.get("supported",false)) or float(entry.get("scale",0))<=0:return false
	var faction := str(entry.get("architecture_faction",""))
	if not _images.has(faction):return false
	var point := Vector2i((offset/float(entry.scale)+FOOT).floor())
	return Rect2i(Vector2i.ZERO,FRAME).has_point(point) and (_images[faction] as Image).get_pixelv(point).a>0.1

static func draw_body(canvas: Object, point: Vector2, entry: Dictionary, modulation: Color, side: String="") -> bool:
	var faction := str(entry.get("architecture_faction",""))
	if not _textures.has(faction) or not point.is_finite() or not bool(entry.get("supported",false)):return false
	if canvas is CanvasItem:canvas.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	var rect := Rect2((point-FOOT*float(entry.scale)).round(),Vector2(FRAME)*float(entry.scale))
	TeamMaterial._retain_draw_texture_m81(canvas,_textures[faction])
	TeamMaterial._retain_draw_texture_m81(canvas,_masks[faction])
	canvas.draw_texture_rect(_textures[faction],rect,false,modulation)
	canvas.draw_texture_rect(_masks[faction],rect,false,TeamMaterial.Palette.side_color(side)*modulation)
	return true

static func _symbol_faction(symbol: String) -> String:
	if symbol=="RANGE":return "HUMAN"
	var faction := symbol.trim_prefix("MAGIC_CAMP_")
	return faction if symbol.begins_with("MAGIC_CAMP_") and faction in FACTIONS else ""

static func inspect_symbol(symbol: String) -> Dictionary:
	var faction := _symbol_faction(symbol)
	if faction.is_empty():return {"supported":false}
	var entry := inspect({"building_type":"RANGE","faction_id":faction,"hp":1,"complete":true})
	entry["symbol"]=symbol
	return entry

static func draw_symbol(canvas: Object, symbol: String, center: Vector2, color: Color, factor: float=1.0) -> bool:
	var entry := inspect_symbol(symbol)
	if not bool(entry.get("supported",false)) or not center.is_finite() or not is_finite(factor) or factor<=0:return false
	if maxf(color.r,maxf(color.g,color.b))<0.28:return true
	var faction := str(entry.architecture_faction)
	var used := (_images[faction] as Image).get_used_rect()
	var scale := 40.0*factor/float(maxi(used.size.x,used.size.y))
	var rect := Rect2(center-Vector2(used.size)*scale*0.5,Vector2(used.size)*scale)
	if canvas is CanvasItem:canvas.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	TeamMaterial._retain_draw_texture_m81(canvas,_textures[faction])
	TeamMaterial._retain_draw_texture_m81(canvas,_masks[faction])
	canvas.draw_texture_rect_region(_textures[faction],rect,Rect2(used),Color("838e8d") if color.r<0.62 and color.g<0.69 and color.b<0.66 else Color.WHITE)
	canvas.draw_texture_rect_region(_masks[faction],rect,Rect2(used),TeamMaterial.Palette.side_color("PLAYER"))
	return true
