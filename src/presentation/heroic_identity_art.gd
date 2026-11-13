extends RefCounted
## Optional, explicitly original AI-generated actors. Accepted source sheets are
## immutable; current body frames are shared across owners, units and zoom.
## Absence or rejection never prevents the existing procedural renderer.
const Collection = preload("res://src/presentation/heroic_collection.gd")
const Palette = preload("res://src/presentation/strategic_side_palette.gd")
const TeamMaterial = preload("res://src/presentation/heroic_team_material_m70.gd")
const MANIFEST_PATH := "res://assets/art/original/m53/manifest.json"
const ROOT := "res://assets/art/original/m53/"
const PROVENANCE := "original-ai-pixel-m53"
const FRAME_SIZE := Vector2i(32,32)
const SHEET_SIZE := Vector2i(128,192)
const FOOT := Vector2(16,28)
const COLUMNS := 4
const ROWS := 6
const MAX_FRAMES := 256
const MAX_SOURCE_BYTES := 8*1024*1024
const MAX_FILE_BYTES := 2*1024*1024
const MAX_MANIFEST_BYTES := 128*1024
const IDENTITIES := ["bone_archer","gear_engine","repair_drone","stag_rider","stone_slinger","fire_dragon","echo_shooter","tunnel_rider","spore_mender","hero:CINDER_STALKER","hero:ECHO_BINDER","hero:COIL_MEDIC","hero:SIGNAL_KEEPER","hero:SPORE_GUIDE","hero:QUAKE_PRIEST","hero:ASH_CHANTER","hero:GRAVE_BELL","hero:BLOOM_GUIDE","hero:THORN_CHANTER","hero:HEARTH_KEEPER","hero:STORM_HERALD","hero:GEAR_HUNTER","hero:SPORE_STALKER","hero:EMBER_CAVALIER","oath_colossus","soul_revenant","aether_engine","elder_treant","rune_behemoth","abyss_devourer","hero:BULWARK","hero:RANGER","hero:DUELIST","hero:RIDGE_JARL","hero:MOURN_ORACLE","hero:LEAF_SEER","hero:WIND_COURIER","worker:HUMAN","worker:UNDEAD","worker:MACHINE","worker:FOREST","worker:HIGHLAND","worker:UNDERGROUND"]
const CATEGORIES := {"bone_archer":"bone_archer","gear_engine":"gear_engine","repair_drone":"repair_drone","stag_rider":"stag_rider","stone_slinger":"stone_slinger","fire_dragon":"fire_dragon","echo_shooter":"echo_shooter","tunnel_rider":"tunnel_rider","spore_mender":"spore_mender","hero:CINDER_STALKER":"hero","hero:ECHO_BINDER":"hero","hero:COIL_MEDIC":"hero","hero:SIGNAL_KEEPER":"hero","hero:SPORE_GUIDE":"hero","hero:QUAKE_PRIEST":"hero","hero:ASH_CHANTER":"hero","hero:GRAVE_BELL":"hero","hero:BLOOM_GUIDE":"hero","hero:THORN_CHANTER":"hero","hero:HEARTH_KEEPER":"hero","hero:STORM_HERALD":"hero","hero:GEAR_HUNTER":"hero","hero:SPORE_STALKER":"hero","hero:EMBER_CAVALIER":"hero","oath_colossus":"oath_colossus","soul_revenant":"soul_revenant","aether_engine":"aether_engine","elder_treant":"elder_treant","rune_behemoth":"rune_behemoth","abyss_devourer":"abyss_devourer","hero:BULWARK":"hero","hero:RANGER":"hero","hero:DUELIST":"hero","hero:RIDGE_JARL":"hero","hero:MOURN_ORACLE":"hero","hero:LEAF_SEER":"hero","hero:WIND_COURIER":"hero","worker:HUMAN":"worker","worker:UNDEAD":"worker","worker:MACHINE":"worker","worker:FOREST":"worker","worker:HIGHLAND":"worker","worker:UNDERGROUND":"worker"}
static var _attempted := false
static var _report: Dictionary = {}
static var _specs: Dictionary = {}
static var _sources: Dictionary = {}
static var _frames: Dictionary = {}
static var _order: Array[String] = []
static var _badge: ImageTexture
static var _bakes := 0
static var _source_bytes := 0
static var _status_snapshot_copies := 0


static func reset_cache() -> void:
	_attempted = false
	_report.clear()
	_specs.clear()
	_sources.clear()
	_frames.clear()
	_order.clear()
	_badge = null
	_bakes = 0
	_source_bytes = 0
	_status_snapshot_copies = 0


static func identity_for(unit: Dictionary) -> String:
	var type := str(unit.get("unit_type","worker"))
	return "hero:"+str(unit.get("hero_archetype","COMMANDER")) if type == "hero" else "worker:"+str(unit.get("faction_id","HUMAN")) if type=="worker" else type


static func _safe_file(file: String) -> bool:
	return file.begins_with("runtime/") and file.ends_with(".png") and file.count("/") == 1 and not file.contains("..") and not file.contains("\\") and not file.contains(":") and file.get_file().length() > 4


static func _link_in_path(file: String) -> bool:
	var current := "res://"
	for part: String in (ROOT.trim_prefix("res://")+file).split("/",false):
		var parent := DirAccess.open(current)
		if parent == null or parent.is_link(part): return true
		current = current.path_join(part)
	return false


static func _dimensions(value: Variant, expected: Vector2i) -> bool:
	return value is Array and value.size() == 2 and _number(value[0]) == expected.x and _number(value[1]) == expected.y


static func _number(value: Variant) -> float:
	return float(value) if typeof(value) in [TYPE_INT,TYPE_FLOAT] else NAN


static func _header_dimension(header: PackedByteArray, offset: int) -> int:
	return (int(header[offset]) << 24) | (int(header[offset+1]) << 16) | (int(header[offset+2]) << 8) | int(header[offset+3])


static func _pixel_hash(image: Image) -> String:
	return image.get_data().hex_encode().sha256_text()


static func _validate_source(identity: String, raw: Variant) -> Dictionary:
	if not raw is Dictionary: return {"failure":"Asset metadata is not a dictionary: "+identity}
	var spec: Dictionary = raw
	var file := str(spec.get("file",""))
	var nominal := _number(spec.get("nominal_radius",0))
	var world_height := _number(spec.get("world_height",0))
	if not _safe_file(file): return {"failure":"Unsafe original asset path: "+identity}
	if str(spec.get("provenance","")) != PROVENANCE or not spec.get("prompt_id") is String or str(spec.get("prompt_id","")).is_empty(): return {"failure":"Missing original generation provenance: "+identity}
	if _number(spec.get("width",0)) != SHEET_SIZE.x or _number(spec.get("height",0)) != SHEET_SIZE.y: return {"failure":"Original asset metadata dimensions differ: "+identity}
	if not is_finite(nominal) or nominal <= 0 or nominal > 64 or not is_finite(world_height) or world_height <= 0 or world_height > 200: return {"failure":"Original fixed body scale is invalid: "+identity}
	if _link_in_path(file): return {"failure":"Missing parent directory or linked original asset path: "+identity}
	var path := ROOT+file
	if not FileAccess.file_exists(path): return {"failure":"Missing original asset PNG: "+identity}
	var source_file := FileAccess.open(path,FileAccess.READ)
	if source_file == null or source_file.get_length() <= 24 or source_file.get_length() > MAX_FILE_BYTES or float(source_file.get_length()) != _number(spec.get("bytes",-1)): return {"failure":"Original PNG byte envelope differs: "+identity}
	if FileAccess.get_sha256(path) != str(spec.get("sha256","")): return {"failure":"Original PNG hash differs: "+identity}
	var header := source_file.get_buffer(24)
	if header.slice(0,8).hex_encode() != "89504e470d0a1a0a" or header.slice(12,16).get_string_from_ascii() != "IHDR" or _header_dimension(header,16) != SHEET_SIZE.x or _header_dimension(header,20) != SHEET_SIZE.y: return {"failure":"Original PNG header dimensions differ: "+identity}
	if _source_bytes+SHEET_SIZE.x*SHEET_SIZE.y*4 > MAX_SOURCE_BYTES: return {"failure":"Original PNG source budget exceeded: "+identity}
	var source := Image.new()
	if source.load_png_from_buffer(FileAccess.get_file_as_bytes(path)) != OK or source.get_size() != SHEET_SIZE: return {"failure":"Original PNG cannot be decoded: "+identity}
	source.convert(Image.FORMAT_RGBA8)
	var row_hashes: Dictionary = {}
	for row: int in range(ROWS):
		row_hashes[row] = {}
		for column: int in range(COLUMNS):
			var frame := source.get_region(Rect2i(column*FRAME_SIZE.x,row*FRAME_SIZE.y,FRAME_SIZE.x,FRAME_SIZE.y))
			var used := frame.get_used_rect()
			if used.size.x <= 0 or used.size.y <= 0: return {"failure":"Empty original action frame: %s:%d:%d"%[identity,row,column]}
			if not Rect2i(1,1,FRAME_SIZE.x-2,FRAME_SIZE.y-2).encloses(used): return {"failure":"Original action frame touches transparent gutter: %s:%d:%d"%[identity,row,column]}
			row_hashes[row][_pixel_hash(frame)] = true
	if row_hashes[1].size() < 2 or row_hashes[2].size() < 2: return {"failure":"Original walk/attack strip lacks actual distinct poses: "+identity}
	var idle_height := source.get_region(Rect2i(0,0,FRAME_SIZE.x,FRAME_SIZE.y)).get_used_rect().size.y
	var accepted := spec.duplicate(true)
	accepted["path"] = path
	accepted["native_scale"] = world_height/float(idle_height)
	accepted["idle_height"] = idle_height
	accepted["source_pixel_hash"] = _pixel_hash(source)
	return {"spec":accepted,"source":source}


static func status() -> Dictionary:
	if _attempted:
		_status_snapshot_copies += 1
		return _report.duplicate(true)
	_attempted = true
	var failures: Array[String] = []
	var rejected: Dictionary = {}
	var missing: Array[String] = []
	var installed := FileAccess.file_exists(MANIFEST_PATH)
	var active_profile := Collection.active()
	var approved_manifest := false
	if active_profile and installed:
		var manifest_file := FileAccess.open(MANIFEST_PATH,FileAccess.READ)
		var data: Variant = null
		if _link_in_path("manifest.json"):
			failures.append("Original manifest path is missing or linked")
		elif manifest_file == null or manifest_file.get_length() <= 0 or manifest_file.get_length() > MAX_MANIFEST_BYTES:
			failures.append("Original manifest byte envelope differs")
		else: data = JSON.parse_string(manifest_file.get_as_text())
		if not data is Dictionary or _number(data.get("schema_version",0)) != 1 or str(data.get("provenance","")) != PROVENANCE or typeof(data.get("accepted")) != TYPE_BOOL or data.get("accepted") != true or str(data.get("status","")) != "accepted" or not _dimensions(data.get("frame_size"),FRAME_SIZE) or not _dimensions(data.get("anchor"),Vector2i(FOOT)) or _number(data.get("columns",0)) != COLUMNS or _number(data.get("rows",0)) != ROWS or not data.get("assets") is Dictionary:
			failures.append("Original manifest schema/grid/provenance/explicit approval differs")
		else:
			approved_manifest = true
			var assets: Dictionary = data.assets
			for identity: String in assets:
				if identity not in IDENTITIES: failures.append("Unknown original identity is not eligible: "+identity)
			for identity: String in IDENTITIES:
				if not assets.has(identity): continue
				var candidate := _validate_source(identity,assets[identity])
				if candidate.has("failure"):
					rejected[identity] = candidate.failure
					failures.append(str(candidate.failure))
				else:
					_specs[identity] = candidate.spec
					_sources[identity] = candidate.source
					_source_bytes += SHEET_SIZE.x*SHEET_SIZE.y*4
	for identity: String in IDENTITIES:
		if not _specs.has(identity): missing.append(identity)
	var accepted_roles: Array = _specs.keys()
	accepted_roles.sort()
	_report = {"ready":active_profile and not _specs.is_empty(),"complete":active_profile and _specs.size() == IDENTITIES.size() and failures.is_empty(),"installed":installed,"profile_active":active_profile,"approved_manifest":approved_manifest,"accepted_roles":accepted_roles,"accepted_count":_specs.size(),"expected_count":IDENTITIES.size(),"missing_roles":missing,"rejected_roles":rejected,"failures":failures,"provenance":PROVENANCE,"source_rgba8_bytes":_source_bytes,"maximum_source_bytes":MAX_SOURCE_BYTES}
	_status_snapshot_copies += 1
	return _report.duplicate(true)


static func fallback_reason(unit: Dictionary) -> String:
	var identity := identity_for(unit)
	var report := status()
	if identity not in IDENTITIES: return "No explicit original generated identity is mapped."
	if not bool(report.profile_active): return "Original generated roster is inactive outside the licensed collection profile."
	if not bool(report.installed): return "Optional original generated roster manifest is absent."
	if not bool(report.approved_manifest): return "Optional original roster manifest lacks valid explicit accepted approval or schema."
	if report.rejected_roles.has(identity): return str(report.rejected_roles[identity])
	if not _specs.has(identity): return "No accepted original generated sheet is installed for "+identity+"."
	return ""


static func supported(unit: Dictionary, _pose: Dictionary = {}) -> bool:
	if identity_for(unit) not in IDENTITIES: return false
	if not _attempted: status()
	return _specs.has(identity_for(unit))


static func source_pixel_hash(identity: String) -> String:
	# Fresh read-only evidence of the retained source Image, not cached metadata
	# and not a mutable source Image handed to callers.
	if not _attempted: status()
	return _pixel_hash(_sources[identity]) if _sources.has(identity) else ""


static func _frame(unit: Dictionary, pose: Dictionary) -> Dictionary:
	if not supported(unit,pose): return {}
	var identity := identity_for(unit)
	var action := str(pose.get("action","IDLE"))
	var row := 0
	var column := clampi(int(pose.get("body_idle_frame_m76",0)),0,3) if action=="IDLE" else 0
	var phase := float(pose.get("body_phase_m76",pose.get("phase",0)))
	phase = clampf(phase,0,0.9999) if is_finite(phase) else 0
	if action in ["WALK","CARRY"]:
		row = 1
		column = posmod(floori(float(pose.get("body_animation_tick_m76",pose.get("animation_tick",0)))/3.0),COLUMNS) if pose.has("body_animation_tick_m76") or pose.has("animation_tick") else 0 if float(pose.get("step",0)) < -0.2 else 2 if float(pose.get("step",0)) > 0.2 else 1
	elif action in ["ATTACK","HARVEST","MINE","BUILD"]: row = 2;column = mini(floori(phase*COLUMNS),COLUMNS-1)
	elif action in ["DAMAGE","HURT","HIT"]: row = 3;column = mini(floori(phase*COLUMNS),COLUMNS-1)
	elif action == "FALLEN": row = 4;column = COLUMNS-1
	elif action.begins_with("SKILL_") or action in ["HEAL","POTION"]: row = 5;column = mini(floori(phase*COLUMNS),COLUMNS-1)
	var mirror := Vector2(pose.get("direction",Vector2.RIGHT)).x < 0
	var key := "%s:%s:%d:%d:%s"%[PROVENANCE,identity,row,column,str(mirror)]
	if _frames.has(key):
		_order.erase(key)
		_order.append(key)
		return _frames[key]
	var source_rect := Rect2i(column*FRAME_SIZE.x,row*FRAME_SIZE.y,FRAME_SIZE.x,FRAME_SIZE.y)
	var image: Image = (_sources[identity] as Image).get_region(source_rect)
	if mirror: image.flip_x()
	var used := image.get_used_rect()
	var cropped := image.get_region(used)
	var anchor := Vector2(FRAME_SIZE.x-1-FOOT.x,FOOT.y) if mirror else FOOT
	var frame := {"key":key,"identity":identity,"image":cropped,"texture":ImageTexture.create_from_image(cropped),"rect":Rect2(Vector2(used.position)-anchor,Vector2(used.size)),"pixel_hash":_pixel_hash(cropped),"mirror":mirror,"row":row,"column":column,"source_rect":source_rect}
	while _order.size() >= MAX_FRAMES: _frames.erase(_order.pop_front())
	_frames[key] = frame
	_order.append(key)
	_bakes += 1
	return frame


static func pixel_scale(unit: Dictionary, radius: float) -> float:
	if not is_finite(radius) or radius <= 0 or not supported(unit): return 0
	var spec: Dictionary = _specs[identity_for(unit)]
	return radius/float(spec.nominal_radius)*float(spec.native_scale)


static func visual_bounds(unit: Dictionary, radius: float, pose: Dictionary = {}) -> Rect2:
	var factor := pixel_scale(unit,radius)
	if factor <= 0: return Rect2()
	var frame := _frame(unit,pose)
	if frame.is_empty(): return Rect2()
	return Rect2(Vector2(frame.rect.position)*factor,Vector2(frame.rect.size)*factor)


static func _badge_texture() -> ImageTexture:
	if _badge == null:
		var image := Image.create(5,3,false,Image.FORMAT_RGBA8)
		image.fill(Color("202634"))
		image.fill_rect(Rect2i(1,1,3,1),Color.WHITE)
		_badge = ImageTexture.create_from_image(image)
	return _badge


static func draw(canvas: Object, foot: Vector2, unit: Dictionary, radius: float, pose: Dictionary) -> bool:
	var factor := pixel_scale(unit,radius)
	if not foot.is_finite() or factor <= 0: return false
	var frame := _frame(unit,pose)
	if frame.is_empty(): return false
	if canvas is CanvasItem: canvas.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	# The resolved frame and scale already define these exact local bounds.
	var bounds := Rect2(Vector2(frame.rect.position)*factor,Vector2(frame.rect.size)*factor)
	canvas.draw_texture_rect(frame.texture,Rect2((foot+bounds.position).round(),bounds.size),false)
	TeamMaterial.draw_actor(canvas,foot,unit,pose,frame,factor,32)
	return true


static func body_contains(unit: Dictionary, radius: float, pose: Dictionary, offset: Vector2) -> bool:
	var factor := pixel_scale(unit,radius)
	if factor <= 0 or not offset.is_finite(): return false
	var frame := _frame(unit,pose)
	if frame.is_empty(): return false
	var point := Vector2i((offset/factor-Vector2(frame.rect.position)).floor())
	var image: Image = frame.image
	return Rect2i(Vector2i.ZERO,image.get_size()).has_point(point) and image.get_pixelv(point).a > 0.1


static func inspect(unit: Dictionary, pose: Dictionary = {}) -> Dictionary:
	var frame := _frame(unit,pose)
	if frame.is_empty(): return {"supported":false,"generated_art":false,"fallback_reason":fallback_reason(unit)}
	var spec: Dictionary = _specs[identity_for(unit)]
	return {"supported":true,"key":frame.key,"identity":frame.identity,"category":CATEGORIES[frame.identity],"action":str(pose.get("action","IDLE")),"frame":frame.column,"stage":frame.row,"pixel_hash":frame.pixel_hash,"rect":frame.rect,"mirror":frame.mirror,"original_art":true,"licensed_art":false,"generated_art":true,"provenance":PROVENANCE,"source_file":spec.file,"source_sha256":spec.sha256,"source_pixel_hash":spec.source_pixel_hash,"source_rect":frame.source_rect,"native_scale":spec.native_scale,"nominal_radius":spec.nominal_radius,"world_height":spec.world_height,"prompt_id":spec.prompt_id,"stable_body_bounds":spec.get("stable_body_bounds",[]),"outline_logical_pixels":1,"civilian":str(unit.get("unit_type",""))=="worker","equipment":"work_tool_and_basket" if str(unit.get("unit_type",""))=="worker" else "","team_accent":"fitted-tabard-armour-harness","team_color":Palette.side_color(str(unit.get("side","PLAYER")))}


static func debug_stats() -> Dictionary:
	var report := status()
	var bytes := 0
	for frame: Dictionary in _frames.values(): bytes += (frame.image as Image).get_width()*(frame.image as Image).get_height()*4
	report["frames"] = _frames.size()
	report["capacity"] = MAX_FRAMES
	report["bakes"] = _bakes
	report["texture_bytes"] = bytes+(60 if _badge != null else 0)
	report["maximum_texture_bytes"] = MAX_FRAMES*FRAME_SIZE.x*FRAME_SIZE.y*4+60
	report["cpu_pixel_bytes"] = _source_bytes+bytes
	report["owner_atlas_copies"] = 0
	report["status_snapshot_copies"] = _status_snapshot_copies
	return report


static func stable_visual_bounds(unit: Dictionary, radius: float) -> Rect2:
	if not supported(unit): return Rect2()
	var spec: Dictionary = _specs[identity_for(unit)]
	var data: Array = spec.get("stable_body_bounds",[])
	var factor := pixel_scale(unit,radius)
	return Rect2(Vector2(data[0],data[1])*factor,Vector2(data[2],data[3])*factor) if data.size()==4 else visual_bounds(unit,radius,{"action":"IDLE"})


static func ground_footprint(unit: Dictionary, radius: float) -> Vector2:
	if not supported(unit): return Vector2.ZERO
	var data: Array = _specs[identity_for(unit)].get("footprint",[22,9])
	return Vector2(data[0],data[1])*radius/float(_specs[identity_for(unit)].nominal_radius)

