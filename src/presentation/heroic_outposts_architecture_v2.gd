extends RefCounted
## Reversible all-six-faction authored architecture pack. Candidate compilation
## alone never enables it; missing/rejected/stale packs return to unchanged M70.
const ROOT := "res://assets/art/original/outposts-v2-buildings/"
const MANIFEST := ROOT + "manifest.json"
const PROVENANCE := "original-new-authored-outposts-v2-buildings"
const FACTIONS := ["HUMAN","UNDEAD","MACHINE","FOREST","HIGHLAND","UNDERGROUND"]
const KINDS := ["BARRACKS","RANGE","ALTAR","FOUNDRY","WORKSHOP","TOWER","DRAGON_ROOST","ESSENCE_MINE","SHOP"]
const FRAME := Vector2i(128,128)
const SIZE := Vector2i(384,384)
const FOOT := Vector2(64,116)
const PIXEL_SCALE := 1.5
const MAX_BODY_BYTES := 4*1024*1024
const MAX_SOURCE_FILE_BYTES := 32*1024*1024
const TeamMaterial = preload("res://src/presentation/heroic_team_material_m70.gd")
static var _attempted := false
static var _ready := false
static var _specs: Dictionary = {}
static var _images: Dictionary = {}
static var _textures: Dictionary = {}
static var _mask_textures: Dictionary = {}
static var _roles: Dictionary = {}
static var _mask_reports: Dictionary = {}
static var _failures: Array[String] = []

static func reset_cache() -> void:
	_attempted=false
	_ready=false
	_specs.clear();_images.clear();_textures.clear();_mask_textures.clear();_roles.clear();_mask_reports.clear();_failures.clear()

static func _dimensions(value: Variant, expected: Vector2i) -> bool:
	return value is Array and value.size()==2 and typeof(value[0]) in [TYPE_INT,TYPE_FLOAT] and typeof(value[1]) in [TYPE_INT,TYPE_FLOAT] and float(value[0])==expected.x and float(value[1])==expected.y

static func _digest(image: Image) -> String:
	var hasher := HashingContext.new()
	hasher.start(HashingContext.HASH_SHA256)
	hasher.update(image.get_data())
	return hasher.finish().hex_encode()

static func _verified_file(relative: String, expected: String, bytes: int) -> bool:
	if bytes<=0 or bytes>MAX_SOURCE_FILE_BYTES or expected.length()!=64 or relative.is_empty(): return false
	var parts := relative.split("/")
	if parts.size()!=2 or parts[0] not in ["source","runtime"] or parts[1] in ["",".",".."]: return false
	var parent := DirAccess.open(ROOT)
	var directory := DirAccess.open(ROOT+parts[0])
	if parent==null or parent.is_link(parts[0]) or directory==null or directory.is_link(parts[1]): return false
	var path := ROOT+relative
	var file := FileAccess.open(path,FileAccess.READ)
	return file!=null and file.get_length()==bytes and FileAccess.get_sha256(path)==expected

static func _prepare() -> void:
	if _attempted: return
	_attempted=true
	if not FileAccess.file_exists(MANIFEST):
		_failures.append("V2 accepted manifest absent; using M70")
		return
	var manifest_file := FileAccess.open(MANIFEST,FileAccess.READ)
	if manifest_file==null or manifest_file.get_length()>1024*1024:
		_failures.append("V2 manifest unreadable or too large; using M70")
		return
	var raw: Variant = JSON.parse_string(manifest_file.get_as_text())
	if not raw is Dictionary or raw.get("schema_version")!=1 or raw.get("accepted")!=true or raw.get("status")!="accepted" or raw.get("compile_ready")!=true or raw.get("provenance")!=PROVENANCE or raw.get("kinds")!=KINDS or int(raw.get("columns",0))!=3 or int(raw.get("rows",0))!=3 or float(raw.get("source_pixel_scale",0))!=PIXEL_SCALE or not _dimensions(raw.get("frame_size"),FRAME) or not _dimensions(raw.get("anchor"),Vector2i(FOOT)) or not raw.get("assets") is Dictionary:
		_failures.append("V2 manifest is not a complete explicitly accepted pack; using M70")
		return
	var prepared_images: Dictionary = {}
	var prepared_roles: Dictionary = {}
	for faction: String in FACTIONS:
		var spec: Dictionary = raw.assets.get(faction,{})
		var runtime_file := "runtime/"+faction.to_lower()+"-architecture-v2.png"
		var source_file := "source/"+faction.to_lower()+".png"
		if spec.get("file")!=runtime_file or spec.get("source_file")!=source_file or int(spec.get("width",0))!=SIZE.x or int(spec.get("height",0))!=SIZE.y or not spec.get("roles") is Dictionary:
			_failures.append("V2 faction metadata differs: "+faction)
			continue
		if not _verified_file(runtime_file,str(spec.get("sha256","")),int(spec.get("bytes",0))) or not _verified_file(source_file,str(spec.get("source_sha256","")),int(spec.get("source_bytes",0))):
			_failures.append("V2 original/runtime source path, bytes or SHA differs: "+faction)
			continue
		var source := Image.new()
		if source.load_png_from_buffer(FileAccess.get_file_as_bytes(ROOT+runtime_file))!=OK or source.get_size()!=SIZE:
			_failures.append("V2 atlas cannot decode: "+faction)
			continue
		source.convert(Image.FORMAT_RGBA8)
		var valid := true
		for index: int in range(KINDS.size()):
			var kind := str(KINDS[index])
			var rect := Rect2i(index%3*128,index/3*128,128,128)
			var frame := source.get_region(rect)
			var used := frame.get_used_rect()
			var meta: Dictionary = spec.roles.get(kind,{})
			if not used.has_area() or not Rect2i(2,2,124,124).encloses(used) or _digest(frame)!=str(meta.get("frame_pixel_sha256","")):
				_failures.append("V2 frame alpha/gutter/SHA differs: "+faction+":"+kind)
				valid=false
				break
			prepared_roles[faction+":"+kind]={"rect":rect,"used":used}
		if valid: prepared_images[faction]=source
	if prepared_images.size()!=6 or prepared_roles.size()!=54 or not _failures.is_empty():
		_failures.append("V2 must qualify all six new source sheets before enabling any faction; using M70")
		return
	for faction: String in FACTIONS:
		var source: Image = prepared_images[faction]
		_images[faction]=source
		_specs[faction]=raw.assets[faction].duplicate(true)
		_textures[faction]=ImageTexture.create_from_image(source)
		var mask := Image.create(SIZE.x,SIZE.y,false,Image.FORMAT_RGBA8)
		mask.fill(Color.TRANSPARENT)
		for kind: String in KINDS:
			var role: Dictionary = prepared_roles[faction+":"+kind]
			var pixels := source.get_region(Rect2i(role.rect))
			# The NEW author brief reserves saturated deep-blue livery across all
			# factions. Legacy M70 gold/violet heuristics must not dye these bodies.
			var material := _blue_livery_mask(pixels)
			mask.blit_rect(material,Rect2i(Vector2i.ZERO,FRAME),Rect2i(role.rect).position)
			_roles[faction+":"+kind]=role
			_mask_reports[faction+":"+kind]=_mask_report(pixels,material)
		_mask_textures[faction]=ImageTexture.create_from_image(mask)
	_ready=true

static func status() -> Dictionary:
	_prepare()
	return {"ready":_ready,"provenance":PROVENANCE,"factions":_specs.size(),"roles":_roles.size(),"expected_roles":54,"fallback":"M70" if not _ready else "","failures":_failures.duplicate(),"atlas_rgba8_bytes":_images.size()*SIZE.x*SIZE.y*4,"mask_rgba8_bytes":_mask_textures.size()*SIZE.x*SIZE.y*4,"maximum_atlas_bytes":MAX_BODY_BYTES,"maximum_body_and_mask_bytes":MAX_BODY_BYTES*2,"textures":_textures.size(),"mask_textures":_mask_textures.size(),"owner_atlas_copies":0,"v2_mask_rule":"interior saturated deep-blue cloth only; hue0.56-0.70 saturation>0.35 value>0.20","mask_roles":_mask_reports.duplicate(true),"mask_review":"too little/large marks nativeQA, never expands into gold/copper/whole-body fallback","team_materials":TeamMaterial.debug_stats()}

static func _blue_livery_mask(image: Image) -> Image:
	var mask := Image.create(image.get_width(),image.get_height(),false,Image.FORMAT_RGBA8)
	mask.fill(Color.TRANSPARENT)
	for y: int in range(1,image.get_height()-1):
		for x: int in range(1,image.get_width()-1):
			var point := Vector2i(x,y)
			var color := image.get_pixelv(point)
			if color.a<0.5 or color.h<0.56 or color.h>0.70 or color.s<=0.35 or color.v<=0.20: continue
			var interior := true
			for direction: Vector2i in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
				if image.get_pixelv(point+direction).a<0.5: interior=false;break
			if not interior: continue
			var shade := clampf(0.4+(color.r*0.27+color.g*0.57+color.b*0.16)*0.7,0.48,1.0)
			mask.set_pixelv(point,Color(shade,shade,shade,1))
	return mask

static func _mask_report(body: Image, mask: Image) -> Dictionary:
	var opaque := 0
	var selected := 0
	for y: int in range(body.get_height()):
		for x: int in range(body.get_width()):
			if body.get_pixel(x,y).a>0.5: opaque+=1
			if mask.get_pixel(x,y).a>0.5: selected+=1
	var ratio := float(selected)/maxi(opaque,1)
	var issues: Array[String] = []
	if selected<8 or ratio<0.002: issues.append("too-little-livery-native-review")
	if ratio>0.18: issues.append("too-large-livery-native-review")
	return {"body_pixels":opaque,"mask_pixels":selected,"mask_fraction":ratio,"native_qa":issues,"fallback_dye_added":false}

static func inspect(building: Dictionary, factor: float) -> Dictionary:
	var kind := str(building.get("building_type",""))
	if kind=="SITE_TOWER": kind="TOWER"
	if kind not in KINDS or not is_finite(factor) or factor<=0 or int(building.get("hp",1))<=0: return {"supported":false}
	_prepare()
	if not _ready: return {"supported":false,"fallback_reason":_failures.duplicate()}
	var faction := str(building.get("faction_id","HUMAN"))
	var key := faction+":"+kind
	if not _roles.has(key): return {"supported":false}
	var role: Dictionary = _roles[key]
	var scale := PIXEL_SCALE*factor
	var used: Rect2i = role.used
	var body := Rect2((Vector2(used.position)-FOOT)*scale,Vector2(used.size)*scale)
	var pole := Vector2(body.position.x+body.size.x*0.8,body.position.y)
	var bounds := body.merge(Rect2(pole+Vector2(-1,-17)*factor,Vector2(14,18)*factor))
	var scaffold := body.grow(4*factor) if not bool(building.get("complete",false)) else Rect2()
	if scaffold.has_area(): bounds=bounds.merge(scaffold)
	return {"supported":true,"architecture_provider":"outposts-v2","provenance":PROVENANCE,"pack":"original-outposts-v2","file":_specs[faction].file,"rect":role.rect,"anchor":FOOT,"scale":scale,"source_pixel_scale":PIXEL_SCALE,"bounds":bounds,"body_bounds":body,"scaffold_bounds":scaffold,"pole":pole,"alive":true,"pixel_hash":_specs[faction].roles[kind].frame_pixel_sha256,"team_accent":"embedded-material-and-pennant","source_unmodified":true,"architecture_key":key,"architecture_faction":faction,"architecture_kind":kind}

static func frame_image(entry: Dictionary) -> Image:
	_prepare()
	var faction := str(entry.get("architecture_faction",""))
	return (_images[faction] as Image).get_region(Rect2i(entry.rect)) if _ready and _images.has(faction) else null

static func body_contains(entry: Dictionary, offset: Vector2) -> bool:
	if not _ready or not offset.is_finite() or not bool(entry.get("supported",false)): return false
	var pixel := Vector2i((offset/float(entry.scale)+FOOT).floor())
	if not Rect2i(Vector2i.ZERO,FRAME).has_point(pixel): return false
	return (_images[str(entry.architecture_faction)] as Image).get_pixelv(pixel+Rect2i(entry.rect).position).a>0.1

static func draw_body(canvas: Object, point: Vector2, entry: Dictionary, modulation: Color, side: String="") -> bool:
	if not _ready or not point.is_finite() or not bool(entry.get("supported",false)): return false
	if canvas is CanvasItem: canvas.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	var destination := Rect2((point-FOOT*float(entry.scale)).round(),Vector2(FRAME)*float(entry.scale))
	canvas.draw_texture_rect_region(_textures[str(entry.architecture_faction)],destination,Rect2(entry.rect),modulation)
	canvas.draw_texture_rect_region(_mask_textures[str(entry.architecture_faction)],destination,Rect2(entry.rect),TeamMaterial.Palette.side_color(side)*modulation)
	return true
