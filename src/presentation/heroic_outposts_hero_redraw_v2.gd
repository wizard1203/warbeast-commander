extends RefCounted
## Optional two-hero, genuinely authored 64px pilot. This module never changes
## combat radius, pose time, animation rate, VFX or the other 46 hero identities.
## Root owns the shared Units seam; pass the PHYSICAL radius, not its old 1.18x
## display-scaled value. Until both source sheets qualify, callers fall back.
const ROOT := "res://assets/art/original/outposts-v2-heroes/"
const MANIFEST := ROOT+"manifest.json"
const PROVENANCE := "original-new-authored-outposts-v2-heroes"
const HEROES := ["BULWARK","GRAVE_BELL"]
const FACTIONS := {"BULWARK":"HUMAN","GRAVE_BELL":"UNDEAD"}
const ACTION_ROWS := ["IDLE","WALK","ATTACK","HIT","FALLEN","CAST"]
const FRAME := Vector2i(64,64)
const SIZE := Vector2i(256,384)
const FOOT := Vector2(32,58)
const WORLD_HEIGHT := 64.0
const NOMINAL_RADIUS := 14.0
const MAX_FILE_BYTES := 32*1024*1024
const MAX_MANIFEST_BYTES := 512*1024
const TeamMaterial = preload("res://src/presentation/heroic_team_material_m70.gd")
const Palette = preload("res://src/presentation/strategic_side_palette.gd")
static var _attempted := false
static var _ready := false
static var _specs: Dictionary = {}
static var _images: Dictionary = {}
static var _textures: Dictionary = {}
static var _masks: Dictionary = {}
static var _mask_textures: Dictionary = {}
static var _frames: Dictionary = {}
static var _failures: Array[String] = []

static func reset_cache() -> void:
	_attempted=false;_ready=false
	_specs.clear();_images.clear();_textures.clear();_masks.clear();_mask_textures.clear();_frames.clear();_failures.clear()

static func _dimensions(value: Variant, expected: Vector2i) -> bool:
	return value is Array and value.size()==2 and typeof(value[0]) in [TYPE_INT,TYPE_FLOAT] and typeof(value[1]) in [TYPE_INT,TYPE_FLOAT] and float(value[0])==expected.x and float(value[1])==expected.y

static func _digest(image: Image) -> String:
	var hasher := HashingContext.new()
	hasher.start(HashingContext.HASH_SHA256);hasher.update(image.get_data())
	return hasher.finish().hex_encode()

static func _verified_file(relative: String, sha: String, bytes: int) -> bool:
	if bytes<=24 or bytes>MAX_FILE_BYTES or sha.length()!=64: return false
	var parts := relative.split("/")
	if parts.size()!=2 or parts[0] not in ["source","runtime"] or parts[1] in ["",".",".."] or not parts[1].ends_with(".png") or relative.contains("\\") or relative.contains(":"): return false
	var pack := DirAccess.open(ROOT)
	var directory := DirAccess.open(ROOT+parts[0])
	if pack==null or pack.is_link(parts[0]) or directory==null or directory.is_link(parts[1]): return false
	var path := ROOT+relative
	var file := FileAccess.open(path,FileAccess.READ)
	return file!=null and file.get_length()==bytes and FileAccess.get_sha256(path)==sha

static func _prepare() -> void:
	if _attempted: return
	_attempted=true
	if not FileAccess.file_exists(MANIFEST):
		_failures.append("Accepted 64px two-hero pilot absent; use the existing hero renderer")
		return
	var file := FileAccess.open(MANIFEST,FileAccess.READ)
	if file==null or file.get_length()<=0 or file.get_length()>MAX_MANIFEST_BYTES:
		_failures.append("64px pilot manifest unreadable or outside byte limit")
		return
	var raw: Variant = JSON.parse_string(file.get_as_text())
	if not raw is Dictionary or raw.get("schema_version")!=1 or raw.get("accepted")!=true or raw.get("status")!="accepted" or raw.get("compile_ready")!=true or raw.get("provenance")!=PROVENANCE or raw.get("heroes")!=HEROES or raw.get("action_rows")!=ACTION_ROWS or int(raw.get("columns",0))!=4 or int(raw.get("rows",0))!=6 or not _dimensions(raw.get("frame_size"),FRAME) or not _dimensions(raw.get("anchor"),Vector2i(FOOT)) or not raw.get("assets") is Dictionary:
		_failures.append("64px pilot requires both explicitly accepted original sheets and the exact 4x6 action contract")
		return
	var prepared: Dictionary = {}
	var prepared_specs: Dictionary = {}
	for hero: String in HEROES:
		var spec: Dictionary = raw.assets.get(hero,{})
		var runtime_file := "runtime/"+hero.to_lower()+"-redraw-v2.png"
		var source_file := "source/"+hero.to_lower()+".png"
		var author: Dictionary = spec.get("source_authoring_record",{})
		if spec.get("file")!=runtime_file or spec.get("source_file")!=source_file or spec.get("faction")!=FACTIONS[hero] or int(spec.get("width",0))!=SIZE.x or int(spec.get("height",0))!=SIZE.y or float(spec.get("world_height",0))!=WORLD_HEIGHT or float(spec.get("nominal_radius",0))!=NOMINAL_RADIUS or author.get("source_kind")!="new-authored-64px-sheet" or not spec.get("frames") is Array or spec.frames.size()!=24 or not spec.get("stable_body_bounds") is Array or spec.stable_body_bounds.size()!=4 or not _dimensions(spec.get("footprint"),Vector2i(28,12) if hero=="BULWARK" else Vector2i(24,10)):
			_failures.append("64px hero metadata differs: "+hero)
			continue
		if not _verified_file(source_file,str(spec.get("source_sha256","")),int(spec.get("source_bytes",0))) or not _verified_file(runtime_file,str(spec.get("sha256","")),int(spec.get("bytes",0))):
			_failures.append("64px source/runtime SHA, bytes or safe path differs: "+hero)
			continue
		var source := Image.new()
		if source.load_png_from_buffer(FileAccess.get_file_as_bytes(ROOT+runtime_file))!=OK or source.get_size()!=SIZE:
			_failures.append("64px hero sheet cannot decode: "+hero)
			continue
		source.convert(Image.FORMAT_RGBA8)
		var valid := true
		var idle_height := 0
		for index: int in range(24):
			var column := index%4
			var row := index/4
			var pixels := source.get_region(Rect2i(column*64,row*64,64,64))
			var used := pixels.get_used_rect()
			var metadata: Dictionary = spec.frames[index]
			if int(metadata.get("row",-1))!=row or int(metadata.get("column",-1))!=column or not used.has_area() or not Rect2i(1,1,62,62).encloses(used) or _digest(pixels)!=str(metadata.get("pixel_sha256","")):
				_failures.append("64px action frame content/gutter/SHA differs: %s:%d:%d"%[hero,row,column])
				valid=false
				break
			if index==0: idle_height=used.size.y
		if valid and idle_height>=36 and idle_height<=56:
			var accepted := spec.duplicate(true)
			accepted["native_scale"]=WORLD_HEIGHT/float(idle_height)
			prepared[hero]=source;prepared_specs[hero]=accepted
		else:
			_failures.append("64px pilot standing detail/height not qualified: "+hero)
	if prepared.size()!=HEROES.size() or not _failures.is_empty():
		_failures.append("Two-hero pilot is all-or-nothing; no partial identity silently replaced")
		return
	for hero: String in HEROES:
		_specs[hero]=prepared_specs[hero]
		var source: Image = prepared[hero]
		var mask := Image.create(SIZE.x,SIZE.y,false,Image.FORMAT_RGBA8)
		mask.fill(Color.TRANSPARENT)
		for index: int in range(24):
			var rect := Rect2i(index%4*64,index/4*64,64,64)
			var pixels := source.get_region(rect)
			var fitted := TeamMaterial.actor_mask(pixels,Rect2(-FOOT,Vector2(FRAME)),64,{"unit_type":"hero","hero_archetype":hero,"faction_id":FACTIONS[hero]})
			mask.blit_rect(fitted,Rect2i(Vector2i.ZERO,FRAME),rect.position)
		var mirrored := source.duplicate() as Image
		var mirrored_mask := mask.duplicate() as Image
		mirrored.flip_x();mirrored_mask.flip_x()
		for flipped: bool in [false,true]:
			var key := hero+(":mirror" if flipped else ":right")
			var pixels: Image = mirrored if flipped else source
			var material: Image = mirrored_mask if flipped else mask
			_images[key]=pixels;_masks[key]=material
			_textures[key]=ImageTexture.create_from_image(pixels)
			_mask_textures[key]=ImageTexture.create_from_image(material)
			for index: int in range(24):
				var column := index%4
				var row := index/4
				var rect := Rect2i((3-column if flipped else column)*64,row*64,64,64)
				var used := pixels.get_region(rect).get_used_rect()
				var anchor := Vector2(31,58) if flipped else FOOT
				var frame_key := key+":%d:%d"%[row,column]
				_frames[frame_key]={"key":PROVENANCE+":"+frame_key,"sheet_key":key,"rect":rect,"used":used,"anchor":anchor,"body_rect":Rect2(Vector2(used.position)-anchor,Vector2(used.size)),"pixel_hash":_digest(pixels.get_region(rect)),"mirror":flipped,"row":row,"column":column}
	_ready=true

static func status() -> Dictionary:
	_prepare()
	return {"ready":_ready,"provenance":PROVENANCE,"accepted_heroes":_specs.keys() if _ready else [],"expected_heroes":HEROES,"coverage":2 if _ready else 0,"roster_total":48,"fallback":"existing hero renderer" if not _ready else "","failures":_failures.duplicate(),"frame_size":[64,64],"world_height":WORLD_HEIGHT,"physical_radius_input":true,"old_display_multiplier_already_handled":true,"owner_atlas_copies":0,"textures":_textures.size()+_mask_textures.size(),"frames":_frames.size(),"cpu_rgba8_bytes":(_images.size()+_masks.size())*SIZE.x*SIZE.y*4,"texture_rgba8_bytes":(_textures.size()+_mask_textures.size())*SIZE.x*SIZE.y*4,"maximum_body_and_mask_rgba8_bytes_per_memory_domain":2*4*SIZE.x*SIZE.y*4,"memory_claim":"RGBA8 accounting only, not measured RSS/VRAM/FPS"}

static func supported(unit: Dictionary, _pose: Dictionary = {}) -> bool:
	if str(unit.get("unit_type",""))!="hero" or str(unit.get("hero_archetype","")) not in HEROES: return false
	_prepare()
	return _ready and _specs.has(str(unit.hero_archetype))

static func pose_frame(pose: Dictionary) -> Dictionary:
	var action := str(pose.get("action","IDLE"))
	var row := 0
	var column := clampi(int(pose.get("body_idle_frame_m76",0)),0,3) if action=="IDLE" else 0
	var phase := float(pose.get("body_phase_m76",pose.get("phase",0)))
	phase=clampf(phase,0,0.9999) if is_finite(phase) else 0
	if action in ["WALK","CARRY"]:
		row=1
		column=posmod(floori(float(pose.get("body_animation_tick_m76",pose.get("animation_tick",0)))/3.0),4) if pose.has("body_animation_tick_m76") or pose.has("animation_tick") else 0 if float(pose.get("step",0))< -0.2 else 2 if float(pose.get("step",0))>0.2 else 1
	elif action in ["ATTACK","HARVEST","MINE","BUILD"]: row=2;column=mini(floori(phase*4),3)
	elif action in ["DAMAGE","HURT","HIT"]: row=3;column=mini(floori(phase*4),3)
	elif action in ["FALLEN","DEAD","DEATH"]: row=4;column=3
	elif action.begins_with("SKILL_") or action in ["HEAL","POTION","CAST","SKILL"]: row=5;column=mini(floori(phase*4),3)
	return {"action":action,"row":row,"column":column,"mirror":Vector2(pose.get("direction",Vector2.RIGHT)).x<0}

static func _frame(unit: Dictionary, pose: Dictionary) -> Dictionary:
	if not supported(unit,pose): return {}
	var at := pose_frame(pose)
	var key := str(unit.hero_archetype)+(":mirror" if bool(at.mirror) else ":right")+":%d:%d"%[int(at.row),int(at.column)]
	return _frames.get(key,{})

static func pixel_scale(unit: Dictionary, physical_radius: float) -> float:
	if not is_finite(physical_radius) or physical_radius<=0 or not supported(unit): return 0
	return physical_radius/NOMINAL_RADIUS*float(_specs[str(unit.hero_archetype)].native_scale)

static func visual_bounds(unit: Dictionary, physical_radius: float, pose: Dictionary = {}) -> Rect2:
	var frame := _frame(unit,pose)
	var scale := pixel_scale(unit,physical_radius)
	return Rect2(Vector2(frame.body_rect.position)*scale,Vector2(frame.body_rect.size)*scale) if not frame.is_empty() and scale>0 else Rect2()

static func stable_visual_bounds(unit: Dictionary, physical_radius: float) -> Rect2:
	var scale := pixel_scale(unit,physical_radius)
	if scale<=0: return Rect2()
	var data: Array = _specs[str(unit.hero_archetype)].stable_body_bounds
	return Rect2(Vector2(float(data[0]),float(data[1]))*scale,Vector2(float(data[2]),float(data[3]))*scale)

static func ground_footprint(unit: Dictionary, physical_radius: float) -> Vector2:
	if not supported(unit) or not is_finite(physical_radius) or physical_radius<=0: return Vector2.ZERO
	var size: Array = _specs[str(unit.hero_archetype)].footprint
	return Vector2(float(size[0]),float(size[1]))*physical_radius/NOMINAL_RADIUS

static func body_contains(unit: Dictionary, physical_radius: float, pose: Dictionary, offset: Vector2) -> bool:
	var frame := _frame(unit,pose)
	var scale := pixel_scale(unit,physical_radius)
	if frame.is_empty() or scale<=0 or not offset.is_finite(): return false
	var pixel := Vector2i((offset/scale+Vector2(frame.anchor)).floor())
	return Rect2i(Vector2i.ZERO,FRAME).has_point(pixel) and (_images[frame.sheet_key] as Image).get_pixelv(Rect2i(frame.rect).position+pixel).a>0.1

static func draw(canvas: Object, foot: Vector2, unit: Dictionary, physical_radius: float, pose: Dictionary) -> bool:
	var frame := _frame(unit,pose)
	var scale := pixel_scale(unit,physical_radius)
	if frame.is_empty() or scale<=0 or not foot.is_finite(): return false
	if canvas is CanvasItem: canvas.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	var destination := Rect2((foot-Vector2(frame.anchor)*scale).round(),Vector2(FRAME)*scale)
	canvas.draw_texture_rect_region(_textures[frame.sheet_key],destination,Rect2(frame.rect))
	if str(pose.get("action","IDLE")) not in ["FALLEN","DEAD","DEATH"] and int(unit.get("hp",1))>0 and bool(unit.get("alive",true)):
		canvas.draw_texture_rect_region(_mask_textures[frame.sheet_key],destination,Rect2(frame.rect),Palette.side_color(str(unit.get("side","PLAYER"))))
	return true

static func frame_image(unit: Dictionary, pose: Dictionary = {}) -> Image:
	var frame := _frame(unit,pose)
	return (_images[frame.sheet_key] as Image).get_region(Rect2i(frame.rect)) if not frame.is_empty() else null

static func inspect(unit: Dictionary, pose: Dictionary = {}) -> Dictionary:
	var frame := _frame(unit,pose)
	if frame.is_empty(): return {"supported":false,"redraw_v2":false,"fallback_reason":status().failures}
	var spec: Dictionary = _specs[str(unit.hero_archetype)]
	return {"supported":true,"redraw_v2":true,"key":frame.key,"identity":"hero:"+str(unit.hero_archetype),"provenance":PROVENANCE,"source_file":spec.source_file,"source_sha256":spec.source_sha256,"runtime_file":spec.file,"runtime_sha256":spec.sha256,"pixel_hash":frame.pixel_hash,"frame_size":FRAME,"anchor":frame.anchor,"source_rect":frame.rect,"rect":frame.body_rect,"row":frame.row,"stage":frame.row,"column":frame.column,"frame":frame.column,"mirror":frame.mirror,"native_scale":spec.native_scale,"nominal_radius":NOMINAL_RADIUS,"world_height":WORLD_HEIGHT,"physical_radius_input":true,"stable_body_bounds":spec.stable_body_bounds,"team_accent":"shared-fitted-64px-mask","owner_atlas_copies":0,"source_unmodified":true,"actual_coverage":"2 of 48 hero identities"}
