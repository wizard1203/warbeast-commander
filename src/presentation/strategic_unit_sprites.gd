extends RefCounted
## One shared original art seam. Detailed source shapes are rasterized once
## per quantized observed frame, never submitted per unit every redraw.
const Brush = preload("res://src/presentation/strategic_pixel_brush.gd")
const Troops = preload("res://src/presentation/strategic_troop_sprite_art.gd")
const Creatures = preload("res://src/presentation/strategic_creature_sprite_art.gd")
const HeroArt = preload("res://src/presentation/strategic_hero_sprite_art.gd")
const Attachments = preload("res://src/presentation/strategic_sprite_attachments.gd")
const Units = preload("res://src/simulation/strategic_unit_catalog.gd")
const Heroes = preload("res://src/simulation/strategic_hero_catalog.gd")
const Palette = preload("res://src/presentation/strategic_side_palette.gd")
const PrerenderedArt = preload("res://src/presentation/strategic_prerendered_art.gd")
const FrontierArt = preload("res://src/presentation/strategic_frontier_art.gd")
const ExpansionActors=preload("res://src/presentation/heroic_expansion_actors_m66.gd")
const MageActors=preload("res://src/presentation/heroic_mage_actors_m68.gd")
const RangedActors=preload("res://src/presentation/heroic_ranged_roles_m68.gd")
const MAX_FRAMES := 192
const LARGE := ["oath_cavalry","stitched_guard","gear_engine","stag_rider","fire_dragon","tunnel_rider"]
static var _frames: Dictionary = {}
static var _order: Array[String] = []
static var _bakes := 0
static var _hits := 0

static func pixel_scale(unit: Dictionary,radius: float) -> float:
	if not is_finite(radius) or radius<=0:return 0
	return _pixel(str(unit.get("unit_type","hinge_guard")),radius)

static func weapon_offset(unit: Dictionary,pose: Dictionary,radius: float) -> Vector2:
	if not is_finite(radius) or radius<=0:return Vector2.ZERO
	if bool(FrontierArt.inspect_unit(unit,pose).get("supported",false)):
		return FrontierArt.weapon_offset(unit,pose,radius)
	if bool(PrerenderedArt.inspect_unit(unit,pose).get("supported",false)):
		return PrerenderedArt.weapon_offset(unit,pose,radius)
	var frame:=_frame(unit,pose)
	var point:=Attachments.offset(frame.unit,frame.pose)
	if frame.mirror:point.x=-point.x
	return point*_pixel(str(frame.unit.unit_type),radius)

static func visual_bounds(unit: Dictionary,radius: float) -> Rect2:
	if not is_finite(radius) or radius<=0: return Rect2()
	var type := str(unit.get("unit_type","hinge_guard"))
	var rect := Rect2(-50,-76,100,90) if type in LARGE else Rect2(-32,-68,64,78) if type=="hero" else Rect2(-30,-58,60,68)
	var pixel := _pixel(type,radius)
	var legacy := Rect2(rect.position*pixel,rect.size*pixel)
	var frontier := FrontierArt.unit_bounds(unit,radius)
	if frontier.size != Vector2.ZERO:
		# Keep carrying/death/skill fallback pixels selectable and uncropped.
		return frontier if frontier.encloses(legacy) else frontier.merge(legacy)
	var preview := PrerenderedArt.unit_bounds(unit,radius)
	if preview.size != Vector2.ZERO:
		# Unsupported observed states (e.g. loaded CARRY) retain legacy art.
		# Its tiny-radius pixel floor must remain inside hit/cull envelopes too.
		return preview if preview.encloses(legacy) else preview.merge(legacy)
	return legacy

static func draw(canvas: Object,center: Vector2,unit: Dictionary,radius: float,pose: Dictionary) -> void:
	if not center.is_finite() or not is_finite(radius) or radius<=0: return
	var frame := _frame(unit,pose)
	var pixel := _pixel(str(frame.unit.unit_type),radius)
	var rect: Rect2i = frame.rect
	var destination := Rect2(center.round()+Vector2(rect.position)*pixel,Vector2(rect.size)*pixel)
	_nearest(canvas)
	canvas.draw_texture_rect(frame.texture,destination,false)

static func draw_portrait(canvas: Object,rect: Rect2,archetype: String,alive: bool=true) -> void:
	if not rect.position.is_finite() or not rect.size.is_finite() or rect.size.x<=0 or rect.size.y<=0: return
	var added:={"unit_type":"hero","hero_archetype":archetype,"side":"PLAYER"}
	if RangedActors.supported(added) or MageActors.supported(added) or ExpansionActors.supported(added):
		var body:=RangedActors.frame(added,{"action":"IDLE"}) if RangedActors.supported(added) else MageActors.frame(added,{"action":"IDLE"}) if MageActors.supported(added) else ExpansionActors.frame(added,{"action":"IDLE"})
		var source_size:=Vector2(body.image.get_size())
		var fit:=minf(rect.size.x/source_size.x,rect.size.y/source_size.y)
		_nearest(canvas)
		canvas.draw_texture_rect_region(body.texture,Rect2((rect.get_center()-source_size*fit*.5).round(),source_size*fit),Rect2(Vector2.ZERO,source_size),Color.WHITE if alive else Color("777e78"))
		return
	var frame := _frame({"unit_type":"hero","hero_archetype":archetype,"side":"PLAYER"},{"action":"IDLE","direction":Vector2.RIGHT})
	var texture: Texture2D=frame.texture
	var source_size:=Vector2(texture.get_width(),minf(texture.get_height(),46))
	var scale_factor:=minf(rect.size.x/source_size.x,rect.size.y/source_size.y)
	var size:=source_size*scale_factor
	_nearest(canvas)
	canvas.draw_texture_rect_region(texture,Rect2((rect.get_center()-size*0.5).round(),size),Rect2(Vector2.ZERO,source_size),Color.WHITE if alive else Color("777e78"))

static func inspect(unit: Dictionary,pose: Dictionary={}) -> Dictionary:
	# Inspector receives an independent image, not a mutable cache reference.
	var frame := _frame(unit,pose)
	var image: Image=frame.image
	var copy := Image.create_from_data(image.get_width(),image.get_height(),false,Image.FORMAT_RGBA8,image.get_data())
	var owner:=Palette.side_color(str(frame.unit.side))
	var owner_pixels:=0
	var opaque:=0
	var colors: Dictionary={}
	var mask:=PackedByteArray()
	for y: int in range(image.get_height()):
		for x: int in range(image.get_width()):
			var color:=image.get_pixel(x,y)
			var visible:=color.a>0.5
			mask.append(1 if visible else 0)
			if not visible: continue
			opaque+=1
			colors[color.to_rgba32()]=true
			if color.is_equal_approx(owner): owner_pixels+=1
	return {"image":copy,"rect":frame.rect,"key":frame.key,"pixel_hash":image.get_data().hex_encode().sha256_text(),"silhouette_hash":mask.hex_encode().sha256_text(),"opaque_pixels":opaque,"owner_pixels":owner_pixels,"colors":colors.size(),"source_commands":frame.source_commands,"clipped_commands":frame.clipped,"canvas_size":Brush.SIZE,"identity":frame.unit.duplicate(true),"pose":frame.pose.duplicate(true),"mirror":frame.mirror}

static func cache_stats() -> Dictionary:
	var bytes:=0
	for frame: Dictionary in _frames.values(): bytes+=int(frame.rect.size.x)*int(frame.rect.size.y)*4
	return {"frames":_frames.size(),"capacity":MAX_FRAMES,"bakes":_bakes,"hits":_hits,"cpu_pixel_bytes":bytes,"maximum_cpu_pixel_bytes":MAX_FRAMES*Brush.SIZE.x*Brush.SIZE.y*4}

static func clear_cache() -> void:
	_frames.clear()
	_order.clear()
	_bakes=0
	_hits=0

static func _frame(source: Dictionary,raw_pose: Dictionary) -> Dictionary:
	var type:=str(source.get("unit_type","hinge_guard"))
	if not Units.UNITS.has(type): type="hinge_guard"
	var archetype:=str(source.get("hero_archetype","COMMANDER")) if type=="hero" else ""
	if type=="hero" and not Heroes.PROFILES.has(archetype): archetype="COMMANDER"
	var defaults: Dictionary=Heroes.PROFILES[archetype] if type=="hero" else Units.UNITS[type]
	var faction:=str(source.get("faction_id",defaults.get("faction_id","HUMAN")))
	if faction not in ["HUMAN","UNDEAD","MACHINE","FOREST","HIGHLAND","UNDERGROUND"]: faction="HUMAN"
	var side:=str(source.get("side","PLAYER"))
	if not Palette.COLORS.has(side): side="NEUTRAL"
	var role:=str(source.get("role",defaults.get("role","FRONTLINE")))
	if role not in ["RESERVE","FOOD","MATERIAL","CONSTRUCTION_REPAIR","WORKER","FRONTLINE","RANGED","SUPPORT","HEAVY","CAVALRY","HERO"]: role="RESERVE"
	var cargo:=str(source.get("cargo_type",""))
	if cargo not in ["FOOD","MATERIAL"]: cargo=""
	var unit: Dictionary={"unit_type":type,"hero_archetype":archetype,"side":side,"faction_id":faction,"body_kind":str(defaults.get("body_kind","HUMANOID")),"role":role,"cargo_amount":1 if int(source.get("cargo_amount",0))>0 else 0,"cargo_type":cargo}
	var action:=str(raw_pose.get("action","IDLE"))
	if action.begins_with("SKILL_"): action="SKILL_CAST"
	if action not in ["IDLE","WALK","CARRY","ATTACK","HEAL","POTION","FALLEN","HARVEST","MINE","BUILD","SKILL_CAST"]: action="IDLE"
	var phase:=float(raw_pose.get("phase",0))
	if not is_finite(phase): phase=0
	var phase_bucket:=clampi(floori(clampf(phase,0,1)*4),0,3) if action not in ["IDLE","WALK","CARRY","FALLEN"] else 0
	var step:=float(raw_pose.get("step",0))
	if not is_finite(step): step=0
	var step_bucket:=clampi(roundi(step),-1,1) if action in ["WALK","CARRY"] or bool(raw_pose.get("moving",false)) else 0
	var direction: Vector2=raw_pose.get("direction",Vector2.RIGHT)
	var mirror:=direction.x<0
	var pose: Dictionary={"action":action,"phase":float(phase_bucket)/3,"step":float(step_bucket),"moving":step_bucket!=0,"direction":Vector2.RIGHT}
	var key:=JSON.stringify([type,archetype,unit.side,faction,unit.role,unit.body_kind,unit.cargo_amount,unit.cargo_type,action,phase_bucket,step_bucket,mirror])
	if _frames.has(key):
		_hits+=1
		_order.erase(key)
		_order.append(key)
		return _frames[key]
	var brush:=Brush.new()
	if type=="hero": HeroArt.paint(brush,unit,pose)
	elif type in LARGE: Creatures.paint(brush,unit,pose)
	else: Troops.paint(brush,unit,pose)
	var foot:=Brush.FOOT
	if mirror:
		brush.image.flip_x()
		foot.x=Brush.SIZE.x-1-foot.x
	var used:=brush.image.get_used_rect()
	if used.size.x<=0 or used.size.y<=0: used=Rect2i(foot,Vector2i.ONE)
	var image:=brush.image.get_region(used)
	var frame: Dictionary={"key":key,"unit":unit,"pose":pose,"mirror":mirror,"image":image,"texture":ImageTexture.create_from_image(image),"rect":Rect2i(used.position-foot,used.size),"source_commands":brush.commands,"clipped":brush.clipped}
	while _order.size()>=MAX_FRAMES:
		_frames.erase(_order.pop_front())
	_frames[key]=frame
	_order.append(key)
	_bakes+=1
	return frame

static func _pixel(type: String,radius: float) -> float:
	return maxf(radius/16.0*1.12,0.15) if type in LARGE else maxf(radius/12.0*1.18,0.15)

static func _nearest(canvas: Object) -> void:
	if canvas is CanvasItem and canvas.texture_filter!=CanvasItem.TEXTURE_FILTER_NEAREST: canvas.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
