extends RefCounted
## Two new authored military identities. Optional explicit acceptance only;
## an absent/rejected pack retains M53. No simulation, clocks or collision writes.
const ROOT := "res://assets/art/original/outposts-v3-units/"
const MANIFEST := ROOT + "manifest.json"
const PROVENANCE := "original-new-authored-outposts-v3-units"
const IDS := ["bone_archer", "oath_colossus"]
const SPECS := {
	"bone_archer":{"faction":"UNDEAD","size":32,"anchor":Vector2i(16,28),"world_height":40,"nominal_radius":12},
	"oath_colossus":{"faction":"HUMAN","size":64,"anchor":Vector2i(32,60),"world_height":64,"nominal_radius":22},
}
const MAX_FRAMES := 96
const TeamMaterial = preload("res://src/presentation/heroic_team_material_m70.gd")
static var _attempted := false
static var _specs: Dictionary = {}
static var _sources: Dictionary = {}
static var _frames: Dictionary = {}
static var _order: Array[String] = []
static var _failures: Array[String] = []
static var _bakes := 0

static func reset_cache() -> void:
	_attempted=false;_specs.clear();_sources.clear();_frames.clear();_order.clear();_failures.clear();_bakes=0

static func _digest(image: Image) -> String:
	var hash := HashingContext.new()
	hash.start(HashingContext.HASH_SHA256);hash.update(image.get_data())
	return hash.finish().hex_encode()

static func _dimensions(value: Variant, size: Vector2i) -> bool:
	return value is Array and value.size()==2 and typeof(value[0]) in [TYPE_INT,TYPE_FLOAT] and typeof(value[1]) in [TYPE_INT,TYPE_FLOAT] and float(value[0])==size.x and float(value[1])==size.y

static func _numeric_array(value: Variant, count: int) -> bool:
	if not value is Array or value.size()!=count:return false
	for item: Variant in value:
		if typeof(item) not in [TYPE_INT,TYPE_FLOAT] or not is_finite(float(item)):return false
	return true

static func _verified_file(relative: String, sha: String, bytes: int) -> bool:
	var parts := relative.split("/")
	if parts.size()!=2 or parts[0] not in ["source","runtime"] or parts[1] in ["",".",".."] or not parts[1].ends_with(".png") or bytes<=24 or bytes>32*1024*1024 or sha.length()!=64:return false
	var directory := DirAccess.open(ROOT+parts[0])
	var root := DirAccess.open(ROOT)
	if root==null or root.is_link(parts[0]) or directory==null or directory.is_link(parts[1]):return false
	var file := FileAccess.open(ROOT+relative,FileAccess.READ)
	return file!=null and file.get_length()==bytes and FileAccess.get_sha256(ROOT+relative)==sha

static func _prepare() -> void:
	if _attempted:return
	_attempted=true
	var file := FileAccess.open(MANIFEST,FileAccess.READ)
	if file==null or file.get_length()<=0 or file.get_length()>1024*1024:
		_failures.append("V3 actor manifest absent/unreadable; unchanged M53 fallback");return
	var raw: Variant = JSON.parse_string(file.get_as_text())
	if not raw is Dictionary or raw.get("schema_version")!=1 or raw.get("accepted")!=true or raw.get("status")!="accepted" or raw.get("compile_ready")!=true or raw.get("provenance")!=PROVENANCE or raw.get("identities")!=IDS or not raw.get("assets") is Dictionary:
		_failures.append("V3 actor pack has no complete explicit acceptance");return
	for id: String in IDS:
		var expected: Dictionary = SPECS[id]
		var record: Variant = raw.assets.get(id,{})
		if not record is Dictionary:
			_failures.append(id+": V3 actor metadata is not an object");continue
		var spec: Dictionary = record
		var size := int(expected.size)
		if not _dimensions(spec.get("frame_size"),Vector2i(size,size)) or not _dimensions(spec.get("anchor"),expected.anchor) or int(spec.get("world_height",0))!=int(expected.world_height) or int(spec.get("nominal_radius",0))!=int(expected.nominal_radius) or spec.get("file")!="runtime/"+id+"-v3.png" or spec.get("source_file")!="source/"+id+".png" or not spec.get("frames") is Array or spec.frames.size()!=24:
			_failures.append(id+": V3 actor grid/identity metadata differs");continue
		if typeof(spec.get("idle_height")) not in [TYPE_INT,TYPE_FLOAT] or float(spec.idle_height)<=0 or float(spec.idle_height)>=size or not _numeric_array(spec.get("stable_body_bounds"),4) or not _numeric_array(spec.get("footprint"),2) or float(spec.stable_body_bounds[2])<=0 or float(spec.stable_body_bounds[3])<=0 or float(spec.footprint[0])<=0 or float(spec.footprint[1])<=0:
			_failures.append(id+": V3 actor stable body/foot metadata differs");continue
		if not _verified_file(spec.file,str(spec.get("sha256","")),int(spec.get("bytes",0))) or not _verified_file(spec.source_file,str(spec.get("source_sha256","")),int(spec.get("source_bytes",0))):
			_failures.append(id+": source/runtime bytes or SHA differs");continue
		var source := Image.new()
		if source.load_png_from_buffer(FileAccess.get_file_as_bytes(ROOT+spec.file))!=OK or source.get_size()!=Vector2i(size*4,size*6):
			_failures.append(id+": cannot decode V3 actor sheet");continue
		source.convert(Image.FORMAT_RGBA8)
		var valid := true
		for index: int in range(24):
			var cell := source.get_region(Rect2i(index%4*size,index/4*size,size,size))
			var used := cell.get_used_rect()
			if not spec.frames[index] is Dictionary or not used.has_area() or not Rect2i(1,1,size-2,size-2).encloses(used) or _digest(cell)!=str(spec.frames[index].get("pixel_sha256","")):
				_failures.append(id+": cell pixels/gutter differ "+str(index));valid=false;break
		if not valid:continue
		_specs[id]=spec.duplicate(true);_sources[id]=source

static func status() -> Dictionary:
	_prepare()
	return {"ready":not _specs.is_empty(),"complete":_specs.size()==2 and _failures.is_empty(),"accepted_count":_specs.size(),"expected_count":2,"identities":_specs.keys(),"failures":_failures.duplicate(),"provenance":PROVENANCE,"owner_atlas_copies":0}

static func supported(unit: Dictionary, _pose: Dictionary = {}) -> bool:
	var id := str(unit.get("unit_type",""))
	if id not in IDS or bool(unit.get("neutral",false)) or str(unit.get("faction_id",SPECS[id].faction))!=str(SPECS[id].faction):return false
	_prepare()
	return _specs.has(id)

static func _blue_mask(image: Image) -> Image:
	var mask := Image.create(image.get_width(),image.get_height(),false,Image.FORMAT_RGBA8)
	mask.fill(Color.TRANSPARENT)
	for y: int in range(image.get_height()):
		for x: int in range(image.get_width()):
			var color := image.get_pixel(x,y)
			if color.a>0.5 and color.h>0.54 and color.h<0.74 and color.s>0.27 and color.v>0.23:
				var shade := clampf(color.v*1.12,0.4,1.0)
				mask.set_pixel(x,y,Color(shade,shade,shade,1.0))
	return mask

static func _frame(unit: Dictionary, pose: Dictionary) -> Dictionary:
	if not supported(unit,pose):return {}
	var id := str(unit.unit_type)
	var spec: Dictionary = _specs[id]
	var size := int(SPECS[id].size)
	var action := str(pose.get("action","IDLE"))
	var phase := float(pose.get("body_phase_m76",pose.get("phase",0)))
	phase=clampf(phase,0,0.99999) if is_finite(phase) else 0
	var row := 0
	var column := clampi(int(pose.get("body_idle_frame_m76",0)),0,3)
	if action in ["WALK","CARRY"]:
		row=1;column=posmod(floori(float(pose.get("body_animation_tick_m76",pose.get("animation_tick",0)))/3.0),4)
	elif action in ["ATTACK","HARVEST","MINE","BUILD"]:row=2;column=mini(floori(phase*4),3)
	elif action in ["DAMAGE","HURT","HIT"]:row=3;column=mini(floori(phase*4),3)
	elif action=="FALLEN":row=4;column=clampi(floori(float(pose.get("body_death_phase_v3",1.0))*4),0,3)
	elif action.begins_with("SKILL_") or action in ["HEAL","POTION","CAST"]:row=5;column=mini(floori(phase*4),3)
	var mirror := Vector2(pose.get("direction",Vector2.RIGHT)).x<0
	var key := "outposts-v3:"+id+":"+str(row)+":"+str(column)+":"+str(mirror)
	if _frames.has(key):_order.erase(key);_order.append(key);return _frames[key]
	var image: Image = (_sources[id] as Image).get_region(Rect2i(column*size,row*size,size,size))
	if mirror:image.flip_x()
	var used := image.get_used_rect()
	var pixels := image.get_region(used)
	var anchor: Vector2 = Vector2(SPECS[id].anchor)
	if mirror:anchor.x=size-1-anchor.x
	var mask := _blue_mask(pixels)
	var entry := {"key":key,"identity":id,"row":row,"column":column,"mirror":mirror,"image":pixels,"texture":ImageTexture.create_from_image(pixels),"mask_texture":ImageTexture.create_from_image(mask),"rect":Rect2(Vector2(used.position)-anchor,Vector2(used.size)),"pixel_hash":_digest(pixels),"source_rect":Rect2i(column*size,row*size,size,size)}
	while _order.size()>=MAX_FRAMES:_frames.erase(_order.pop_front())
	_frames[key]=entry;_order.append(key);_bakes+=1
	return entry

static func pixel_scale(unit: Dictionary, radius: float) -> float:
	if not is_finite(radius) or radius<=0 or not supported(unit):return 0
	var spec: Dictionary = _specs[str(unit.unit_type)]
	return radius/float(spec.nominal_radius)*float(spec.world_height)/float(spec.idle_height)

static func visual_bounds(unit: Dictionary, radius: float, pose: Dictionary = {}) -> Rect2:
	var scale := pixel_scale(unit,radius)
	var frame := _frame(unit,pose)
	return Rect2(Vector2(frame.rect.position)*scale,Vector2(frame.rect.size)*scale) if scale>0 and not frame.is_empty() else Rect2()

static func draw(canvas: Object, foot: Vector2, unit: Dictionary, radius: float, pose: Dictionary) -> bool:
	var scale := pixel_scale(unit,radius)
	if scale<=0 or not foot.is_finite():return false
	var frame := _frame(unit,pose)
	if frame.is_empty():return false
	if canvas is CanvasItem:canvas.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	var bounds := Rect2((foot+Vector2(frame.rect.position)*scale).round(),Vector2(frame.rect.size)*scale)
	TeamMaterial._retain_draw_texture_m81(canvas,frame.texture)
	canvas.draw_texture_rect(frame.texture,bounds,false)
	if str(pose.get("action",""))!="FALLEN" and int(unit.get("hp",1))>0:
		TeamMaterial._retain_draw_texture_m81(canvas,frame.mask_texture)
		canvas.draw_texture_rect(frame.mask_texture,bounds,false,TeamMaterial.Palette.side_color(str(unit.get("side","PLAYER"))))
	return true

static func body_contains(unit: Dictionary, radius: float, pose: Dictionary, offset: Vector2) -> bool:
	var scale := pixel_scale(unit,radius)
	if scale<=0 or not offset.is_finite():return false
	var frame := _frame(unit,pose)
	if frame.is_empty():return false
	var point := Vector2i((offset/scale-Vector2(frame.rect.position)).floor())
	return Rect2i(Vector2i.ZERO,frame.image.get_size()).has_point(point) and frame.image.get_pixelv(point).a>0.1

static func inspect(unit: Dictionary, pose: Dictionary = {}) -> Dictionary:
	var frame := _frame(unit,pose)
	if frame.is_empty():return {"supported":false,"fallback_reason":status()}
	var spec: Dictionary = _specs[str(unit.unit_type)]
	return {"supported":true,"identity":frame.identity,"category":frame.identity,"key":frame.key,"frame":frame.column,"stage":frame.row,"action":str(pose.get("action","IDLE")),"mirror":frame.mirror,"rect":frame.rect,"source_rect":frame.source_rect,"pixel_hash":frame.pixel_hash,"provenance":PROVENANCE,"source_file":spec.file,"source_sha256":spec.sha256,"logical_size":int(SPECS[str(unit.unit_type)].size),"world_height":spec.world_height,"nominal_radius":spec.nominal_radius,"original_art":true,"generated_art":true,"licensed_art":false,"new_body_identity":true,"team_accent":"authored-blue-cloth-only","owner_atlas_copies":0}

static func stable_visual_bounds(unit: Dictionary, radius: float) -> Rect2:
	var scale := pixel_scale(unit,radius)
	if scale<=0:return Rect2()
	var data: Array = _specs[str(unit.unit_type)].stable_body_bounds
	return Rect2(Vector2(data[0],data[1])*scale,Vector2(data[2],data[3])*scale)

static func ground_footprint(unit: Dictionary, radius: float) -> Vector2:
	if not supported(unit) or not is_finite(radius) or radius<=0:return Vector2.ZERO
	var spec: Dictionary = _specs[str(unit.unit_type)]
	return Vector2(spec.footprint[0],spec.footprint[1])*radius/float(spec.nominal_radius)

static func debug_stats() -> Dictionary:
	var report := status()
	var bytes := 0
	for frame: Dictionary in _frames.values():bytes+=frame.image.get_width()*frame.image.get_height()*8
	report.merge({"frames":_frames.size(),"capacity":MAX_FRAMES,"bakes":_bakes,"texture_bytes":bytes,"maximum_texture_bytes":MAX_FRAMES*64*64*8},true)
	return report
