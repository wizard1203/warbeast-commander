extends RefCounted
## Original source-detail M70 buildings. Six immutable shared atlases;
## ownership, construction and death stay separate from the source artwork.
const ROOT := "res://assets/art/original/m70-buildings/"
const MANIFEST := ROOT+"manifest.json"
const FACTIONS := ["HUMAN","UNDEAD","MACHINE","FOREST","HIGHLAND","UNDERGROUND"]
const KINDS := ["BARRACKS","RANGE","ALTAR","FOUNDRY","WORKSHOP","TOWER","DRAGON_ROOST","ESSENCE_MINE","SHOP"]
const SIZE := Vector2i(384,384)
const FRAME := Vector2i(128,128)
const FOOT := Vector2(64,116)
const MAX_BYTES := 4*1024*1024
const TeamMaterial = preload("res://src/presentation/heroic_team_material_m70.gd")
const OutpostsV2 = preload("res://src/presentation/heroic_outposts_architecture_v2.gd")
const OutpostsV3Magic = preload("res://src/presentation/heroic_outposts_magic_camps_v3.gd")
static var _attempted := false
static var _specs: Dictionary = {}
static var _images: Dictionary = {}
static var _textures: Dictionary = {}
static var _mask_textures: Dictionary = {}
static var _roles: Dictionary = {}
static var _failures: Array[String] = []

static func reset_cache() -> void:
	OutpostsV3Magic.reset_cache()
	OutpostsV2.reset_cache()
	_attempted=false
	_specs.clear();_images.clear();_textures.clear();_mask_textures.clear();_roles.clear();_failures.clear()

static func _prepare() -> void:
	if _attempted:return
	_attempted=true
	var raw: Variant=JSON.parse_string(FileAccess.get_file_as_string(MANIFEST)) if FileAccess.file_exists(MANIFEST) else null
	if not raw is Dictionary or raw.get("schema_version")!=1 or raw.get("accepted")!=true or raw.get("status")!="accepted" or raw.get("provenance")!="original-source-recompile-m70" or not _dimensions(raw.get("frame_size"),FRAME) or not _dimensions(raw.get("anchor"),Vector2i(FOOT)) or not raw.get("assets") is Dictionary:
		_failures.append("M70 architectural manifest is absent or not explicitly accepted")
		return
	for faction: String in FACTIONS:
		var spec: Dictionary=raw.assets.get(faction,{})
		var file:=str(spec.get("file",""))
		if file!="runtime/"+faction.to_lower()+"-architecture-v1.png" or int(spec.get("width",0))!=384 or int(spec.get("height",0))!=384 or not spec.get("roles") is Dictionary:
			_failures.append("Architecture metadata differs: "+faction);continue
		var directory:=DirAccess.open(ROOT+"runtime")
		if directory==null or directory.is_link(file.get_file()) or not FileAccess.file_exists(ROOT+file) or FileAccess.get_sha256(ROOT+file)!=str(spec.get("sha256","")) or FileAccess.get_file_as_bytes(ROOT+file).size()!=int(spec.get("bytes",0)):
			_failures.append("Architecture source hash/path differs: "+faction);continue
		var source:=Image.new()
		if source.load_png_from_buffer(FileAccess.get_file_as_bytes(ROOT+file))!=OK or source.get_size()!=SIZE:
			_failures.append("Architecture PNG cannot be decoded: "+faction);continue
		source.convert(Image.FORMAT_RGBA8)
		var valid:=true
		for index: int in range(KINDS.size()):
			var kind:=str(KINDS[index])
			var rect:=Rect2i(index%3*128,index/3*128,128,128)
			var frame:=source.get_region(rect)
			var used:=frame.get_used_rect()
			var meta: Dictionary=spec.roles.get(kind,{})
			if not used.has_area() or not Rect2i(1,1,126,126).encloses(used) or frame.get_data().hex_encode().sha256_text()!=str(meta.get("frame_pixel_sha256","")):
				_failures.append("Architecture role pixels/gutter differ: "+faction+":"+kind);valid=false;break
		if not valid:continue
		_specs[faction]=spec.duplicate(true)
		_images[faction]=source
		_textures[faction]=ImageTexture.create_from_image(source)
		var mask_atlas:=Image.create(SIZE.x,SIZE.y,false,Image.FORMAT_RGBA8)
		mask_atlas.fill(Color.TRANSPARENT)
		for index: int in range(KINDS.size()):
			var rect:=Rect2i(index%3*128,index/3*128,128,128)
			var frame:=source.get_region(rect)
			var mask:=TeamMaterial.building_mask(frame,str(KINDS[index]),faction)
			mask_atlas.blit_rect(mask,Rect2i(Vector2i.ZERO,FRAME),rect.position)
			_roles[faction+":"+str(KINDS[index])] = {"rect":rect,"used":frame.get_used_rect(),"mask_pixels":TeamMaterial._opaque_count(mask)}
		_mask_textures[faction]=ImageTexture.create_from_image(mask_atlas)

static func _dimensions(value: Variant, expected: Vector2i) -> bool:
	return value is Array and value.size()==2 and typeof(value[0]) in [TYPE_INT,TYPE_FLOAT] and typeof(value[1]) in [TYPE_INT,TYPE_FLOAT] and float(value[0])==expected.x and float(value[1])==expected.y

static func status() -> Dictionary:
	var v2 := OutpostsV2.status()
	v2["outposts_v3_magic"]=OutpostsV3Magic.status()
	if bool(v2.get("ready",false)): return v2
	_prepare()
	return {"ready":_specs.size()==6 and _failures.is_empty(),"factions":_specs.size(),"roles":_roles.size(),"expected_roles":54,"failures":_failures.duplicate(),"atlas_rgba8_bytes":_images.size()*SIZE.x*SIZE.y*4,"maximum_atlas_bytes":MAX_BYTES,"mask_rgba8_bytes":_mask_textures.size()*SIZE.x*SIZE.y*4,"maximum_body_and_mask_bytes":MAX_BYTES*2,"textures":_textures.size(),"mask_textures":_mask_textures.size(),"owner_atlas_copies":0,"provenance":"original-source-recompile-m70","team_materials":TeamMaterial.debug_stats(),"outposts_v2":v2}

static func inspect(building: Dictionary, factor: float) -> Dictionary:
	if not is_finite(factor) or factor<=0 or int(building.get("hp",1))<=0:return {"supported":false}
	var v3 := OutpostsV3Magic.inspect(building,factor)
	if bool(v3.get("supported",false)):return v3
	var v2 := OutpostsV2.inspect(building,factor)
	if bool(v2.get("supported",false)): return v2
	_prepare()
	var faction:=str(building.get("faction_id","HUMAN"))
	var kind:=str(building.get("building_type",""))
	if kind=="SITE_TOWER":kind="TOWER"
	var key:=faction+":"+kind
	if not _roles.has(key):return {"supported":false}
	var role: Dictionary=_roles[key]
	var scale:=1.5*factor
	var used: Rect2i=role.used
	var body:=Rect2((Vector2(used.position)-FOOT)*scale,Vector2(used.size)*scale)
	var pole:=Vector2(body.position.x+body.size.x*0.8,body.position.y)
	var bounds:=body.merge(Rect2(pole+Vector2(-1,-17)*factor,Vector2(14,18)*factor))
	var scaffold:=body.grow(4*factor) if not bool(building.get("complete",false)) else Rect2()
	if scaffold.has_area():bounds=bounds.merge(scaffold)
	return {"supported":true,"provenance":"original-source-recompile-m70","pack":"original-m70","file":_specs[faction].file,"rect":role.rect,"anchor":FOOT,"scale":scale,"source_pixel_scale":1.5,"bounds":bounds,"body_bounds":body,"scaffold_bounds":scaffold,"pole":pole,"alive":true,"pixel_hash":str(_specs[faction].roles[kind].frame_pixel_sha256),"team_accent":"embedded-material-and-pennant","source_unmodified":true,"architecture_key":key,"architecture_faction":faction,"architecture_kind":kind}

static func frame_image(entry: Dictionary) -> Image:
	if entry.get("architecture_provider")=="outposts-v3-magic-camps":return OutpostsV3Magic.frame_image(entry)
	if entry.get("architecture_provider")=="outposts-v2": return OutpostsV2.frame_image(entry)
	_prepare()
	var faction:=str(entry.get("architecture_faction",""))
	if not _images.has(faction):return null
	return (_images[faction] as Image).get_region(Rect2i(entry.rect))

static func body_contains(entry: Dictionary, offset: Vector2) -> bool:
	if entry.get("architecture_provider")=="outposts-v3-magic-camps":return OutpostsV3Magic.body_contains(entry,offset)
	if entry.get("architecture_provider")=="outposts-v2": return OutpostsV2.body_contains(entry,offset)
	if not offset.is_finite() or not bool(entry.get("supported",false)):return false
	var point:=Vector2i((offset/float(entry.scale)+FOOT).floor())
	if not Rect2i(Vector2i.ZERO,FRAME).has_point(point):return false
	var source: Image=_images[str(entry.architecture_faction)]
	return source.get_pixelv(point+Rect2i(entry.rect).position).a>0.1

static func draw_body(canvas: Object, point: Vector2, entry: Dictionary, modulation: Color,side: String="") -> bool:
	if entry.get("architecture_provider")=="outposts-v3-magic-camps":return OutpostsV3Magic.draw_body(canvas,point,entry,modulation,side)
	if entry.get("architecture_provider")=="outposts-v2": return OutpostsV2.draw_body(canvas,point,entry,modulation,side)
	if not point.is_finite() or not bool(entry.get("supported",false)):return false
	if canvas is CanvasItem:canvas.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	var scale:=float(entry.scale)
	canvas.draw_texture_rect_region(_textures[str(entry.architecture_faction)],Rect2((point-FOOT*scale).round(),Vector2(FRAME)*scale),Rect2(entry.rect),modulation)
	canvas.draw_texture_rect_region(_mask_textures[str(entry.architecture_faction)],Rect2((point-FOOT*scale).round(),Vector2(FRAME)*scale),Rect2(entry.rect),TeamMaterial.Palette.side_color(side)*modulation)
	return true
