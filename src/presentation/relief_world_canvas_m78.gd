extends "res://src/presentation/heroic_2d_world_canvas.gd"
## Optional M78 paper-cut battlefield. The inherited observation/input seam is
## unchanged. No physics, rule shortcuts, reduced army, or AI throttling lives
## here. Static ground is baked once; actor bodies share one finite atlas.
const ReliefAtlas = preload("res://src/presentation/relief_atlas_m78.gd")
const FLOOR_COLORS := {"HUMAN":"#a3ad89","UNDEAD":"#999b9e","MACHINE":"#b1a78a","FOREST":"#87a185","HIGHLAND":"#b5bfba","UNDERGROUND":"#9b93a4"}
var _relief_objects: Array[Dictionary] = []
var _relief_facts: Dictionary = {}
var _relief_actors: Dictionary = {}
var _relief_poses: Dictionary = {}
var _relief_body_count := 0
var _relief_refreshes := 0
var _relief_ground_error := ""
var _relief_side := ""


func _ready() -> void:
	name="ReliefPaperBattlefieldM78"
	texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
	_ready_assets=ReliefAtlas.ensure()
	_refresh_landscape()


func _refresh_landscape() -> void:
	if snapshot.is_empty():return
	var facts: Dictionary=snapshot.duplicate(false)
	if presentation_seed_override>=0:facts["seed"]=presentation_seed_override
	var signature: String=Landscape.signature(facts)+":relief-m78"
	if signature==_signature:return
	_signature=signature
	# The common planner is detached and uses actual canonical circles, sites,
	# source positions and legal whole road cells. It is also the minimap plan.
	landscape_plan=Landscape.build(facts,"TILED")
	_terrain_rebuilds+=1
	_decorations.clear()
	for decoration: Dictionary in landscape_plan.get("decorations",[]):
		_decorations.append(decoration.duplicate(false))
	_bake_relief_ground()
	set_meta("landscape_summary",{"signature":_signature,"rebuilds":_terrain_rebuilds,"roads":landscape_plan.get("roads",[]).size(),"decorations":_decorations.size(),"failures":landscape_plan.get("failures",[]).duplicate(true),"mode":"relief-m78"})


func _bake_relief_ground() -> void:
	_ground_bounds=Rect2(landscape_plan.get("bounds",Rect2i(0,0,3200,2000)))
	if not _ground_bounds.has_area():return
	_ground_pixel=maxf(1.0,maxf(_ground_bounds.size.x,_ground_bounds.size.y)/2048.0)
	var extent:=Vector2i(ceili(_ground_bounds.size.x/_ground_pixel),ceili(_ground_bounds.size.y/_ground_pixel))
	var parts: PackedStringArray=[]
	parts.append('<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" viewBox="0 0 %.2f %.2f"><defs><radialGradient id="field"><stop stop-color="#a8b393"/><stop offset="1" stop-color="#899a7f"/></radialGradient><linearGradient id="lake" x2="0.5" y2="1"><stop stop-color="#78a7a7"/><stop offset="1" stop-color="#3d6b7a"/></linearGradient>' % [extent.x,extent.y,_ground_bounds.size.x,_ground_bounds.size.y])
	for i: int in range(landscape_plan.get("home_zones",[]).size()):
		var zone: Dictionary=landscape_plan.home_zones[i]
		parts.append('<radialGradient id="home%d"><stop stop-color="%s" stop-opacity="0.75"/><stop offset="0.65" stop-color="%s" stop-opacity="0.4"/><stop offset="1" stop-color="%s" stop-opacity="0"/></radialGradient>' % [i,str(FLOOR_COLORS.get(str(zone.faction_id),"#a3ad89")),str(FLOOR_COLORS.get(str(zone.faction_id),"#a3ad89")),str(FLOOR_COLORS.get(str(zone.faction_id),"#a3ad89"))])
	parts.append('</defs><rect width="100%" height="100%" fill="url(#field)"/>')
	for i: int in range(landscape_plan.get("home_zones",[]).size()):
		var zone: Dictionary=landscape_plan.home_zones[i]
		var at:=Vector2(zone.position)-_ground_bounds.position
		# Culture is a multi-lobed patch with distinct field geometry, not just
		# a hard colored circle. Everything remains presentation-only.
		for lobe: int in range(4):
			var offset:=Vector2.from_angle(lobe*TAU/4.0+0.35)*110.0
			parts.append('<ellipse cx="%.2f" cy="%.2f" rx="470" ry="370" fill="url(#home%d)"/>' % [at.x+offset.x,at.y+offset.y,i])
	var origin:=Vector2(landscape_plan.get("road_grid_origin",_ground_bounds.position))-_ground_bounds.position
	_terrain_tiles=landscape_plan.get("road_cells",[]).size()
	for cell: Vector2i in landscape_plan.get("road_cells",[]):
		var point:=origin+Vector2(cell)*32.0
		parts.append('<rect x="%.1f" y="%.1f" width="32" height="32" fill="#b7b19a" stroke="#9a9e86" stroke-width="0.8"/>' % [point.x,point.y])
	# Quiet irregular land engravings are baked; they are not live draw calls.
	for entry: Dictionary in _decorations:
		var point:=Vector2(entry.get("position",Vector2.ZERO))-_ground_bounds.position
		var hash_value:=posmod(str(entry.get("position")).hash(),97)
		parts.append('<path d="M%.1f %.1f l12 -4 l15 2 m-14 6 l13 -2" fill="none" stroke="#74896c" stroke-opacity="0.24" stroke-width="2"/>' % [point.x,point.y])
		if str(entry.get("kind",""))=="HOMELAND":
			var faction:=str(entry.get("faction_id","HUMAN"))
			var color: String="#cbc8b3" if faction=="HIGHLAND" else "#605b69" if faction=="UNDERGROUND" else "#c5b48e" if faction=="MACHINE" else "#7e9577"
			parts.append('<path d="M%.1f %.1f l-%d -15 l34 -8 l21 12 l-17 15Z" fill="%s" fill-opacity="0.32"/>' % [point.x,point.y,20+hash_value%15,color])
	for terrain: Dictionary in snapshot.get("terrain",[]):
		var kind:=str(terrain.get("kind",""))
		var point:=Vector2(terrain.get("position",Vector2.ZERO))-_ground_bounds.position
		var radius:=maxf(1,float(terrain.get("radius",40)))
		if kind in ["LAKE","RIVER"]:
			parts.append('<circle cx="%.1f" cy="%.1f" r="%.1f" fill="#b3b59b"/><circle cx="%.1f" cy="%.1f" r="%.1f" fill="url(#lake)" stroke="#729b9b" stroke-width="3"/>' % [point.x,point.y,radius+7,point.x,point.y,radius])
		elif kind in ["TREE","MOUNTAIN","ICE","GLACIER","LAVA","LAVA_FIELD","RUIN"]:
			parts.append('<circle cx="%.1f" cy="%.1f" r="%.1f" fill="%s" fill-opacity="0.32"/>' % [point.x,point.y,radius,"#617b63" if kind=="TREE" else "#768783"])
	parts.append('</svg>')
	var image:=Image.new()
	var result:=image.load_svg_from_string("".join(parts))
	if result!=OK:
		_relief_ground_error="GROUND_SVG_%d" % result
		_ground_texture=null
		return
	_relief_ground_error=""
	_ground_texture=ImageTexture.create_from_image(image)


func _refresh_relief_observation() -> void:
	if is_same(snapshot,_relief_facts) and _relief_side==view_side_id:return
	_relief_facts=snapshot
	_relief_side=view_side_id
	_relief_refreshes+=1
	_relief_objects.clear()
	_relief_actors.clear()
	_relief_poses.clear()
	for category: String in ["terrain","sites","resource_sources","buildings","neutral_camps","neutral_loot","workers","soldiers"]:
		for value: Dictionary in snapshot.get(category,[]):
			if not ActorReadout.visible_to(value,view_side_id):continue
			if category=="terrain" and str(value.get("kind","")) in ["LAKE","RIVER"]:continue
			if category=="sites" and str(value.get("kind",""))!="VILLAGE":continue
			var is_actor:=category in ["workers","soldiers"]
			var actor:=_unit_observation(value) if is_actor else value
			if is_actor:
				_relief_actors[str(actor.get("id",""))]=actor
				_relief_poses[str(actor.get("id",""))]=Pose.for_unit(actor,int(snapshot.get("tick",0)))
			_relief_objects.append({"kind":category,"value":actor})
	for value: Dictionary in _decorations:
		if str(value.get("kind","")) in ["GRASS","SNOW_PATCH"]:continue
		_relief_objects.append({"kind":"decoration","value":value})
	_relief_objects.sort_custom(func(a: Dictionary,b: Dictionary)->bool:
		var ay:=Vector2(a.value.get("position",Vector2.ZERO)).y
		var by:=Vector2(b.value.get("position",Vector2.ZERO)).y
		return str(a.value.get("id",""))<str(b.value.get("id","")) if ay==by else ay<by)


func _draw() -> void:
	if camera==null or snapshot.is_empty():return
	if not ReliefAtlas.ensure() or _ground_texture==null:
		draw_rect(Rect2(Vector2.ZERO,(get_parent() as Control).size),Color("899a7f"))
		return
	_refresh_relief_observation()
	var factor:=float(camera.get_scale())
	_visible_combat_statuses=0
	_visible_decorations=0
	_relief_body_count=0
	draw_texture_rect(_ground_texture,Rect2(_screen(_ground_bounds.position),_ground_bounds.size*factor),false)
	_draw_aura_sources(factor)
	for object: Dictionary in _relief_objects:
		var value: Dictionary=object.value
		# Spectator perspective may change without advancing the fixed tick.
		if not ActorReadout.visible_to(value,view_side_id):continue
		var kind:=str(object.kind)
		var point:=_screen(render_actor_position_m76(value) if kind in ["workers","soldiers"] else Vector2(value.get("position",Vector2.ZERO)))
		if not _visible(point,260*factor):continue
		match kind:
			"workers","soldiers":_draw_unit(point,value,factor)
			"buildings":
				_draw_relief_building(point,value,factor)
				_draw_building_state(point,value,factor)
			"sites":
				ReliefAtlas.draw(self,point,"building:HUMAN:VILLAGE",factor*0.77)
				ReliefAtlas.draw(self,point+Vector2(0,-40)*factor,"team",factor*1.1,Palette.side_color(str(value.get("owner",""))))
			"resource_sources":_draw_resource(point,value,factor)
			"terrain":_draw_terrain_prop(point,value,factor)
			"neutral_camps":
				if str(value.get("state",""))!="CLEARED":
					ReliefAtlas.draw(self,point,"camp",factor*0.68)
					draw_string(ReadableFont.readable(),point+Vector2(-72,-65)*factor,str(value.get("label","野外守军"))+" · "+str(value.get("remaining_count",0)),HORIZONTAL_ALIGNMENT_CENTER,144*factor,13,Color("f1e4bd"))
			"neutral_loot":
				if str(value.get("state",""))=="AVAILABLE":ReliefAtlas.draw(self,point,"loot",factor*0.4)
			"decoration":
				var type:=str(value.get("kind",""))
				var key: String="mushroom" if type in ["MUSHROOM","CRYSTAL"] else "stone" if type in ["STONE","SCRAP","HOMELAND"] else "flower" if type=="FLOWER" else "tree"
				ReliefAtlas.draw(self,point,key,factor*0.23)
				_visible_decorations+=1
	_draw_action_effects(factor)
	_draw_actor_overlays(factor)
	_draw_orders(factor)
	var captures:=get_capture_readouts()
	set_meta("capture_readouts",captures.duplicate(true))
	for readout: Dictionary in captures:_draw_capture(readout)
	var towers:=get_tower_readouts()
	set_meta("tower_readouts",towers)
	for readout: Dictionary in towers:
		if readout.selected:draw_arc(readout.center,readout.screen_range,0,TAU,64,Color("e9d593",0.65),2)
		if readout.firing:
			var tower:=_find(snapshot,str(readout.id),["buildings"])
			var bounds:=ReliefAtlas.bounds(ReliefAtlas.building_key(tower),factor)
			TowerEffects.draw(self,Vector2(readout.center)+Vector2(0,bounds.position.y+20*factor),readout,factor)
	if not blueprint_type.is_empty():
		var point:=_screen(blueprint_point)
		var observation:=get_blueprint_observation()
		_draw_relief_building(point,observation,factor)
		draw_arc(point,(float(observation.radius)+4)*factor,0,TAU,32,Color("c7edb2"),2)
		set_meta("blueprint_radius",int(observation.radius))
	var objectives: Array[Dictionary]=[]
	for readout: Dictionary in captures:
		var objective: Dictionary=readout.get("field_objective",{})
		if objective.is_empty():continue
		var marker:=Vector2(readout.card_rect.end.x+11,readout.card_rect.get_center().y)
		Objectives.draw_marker(self,marker,objective,bool(readout.compact))
		objectives.append({"site_id":str(readout.id),"kind":str(objective.kind),"state":str(objective.state),"position":marker})
	set_meta("field_objective_marks",objectives)
	for mark: Dictionary in field_reward_marks.slice(0,4):
		var age:=float(mark.get("age",0));var lifetime:=float(mark.get("lifetime",2))
		if age<0 or age>=lifetime:continue
		var point:=_screen(Vector2(mark.get("position",Vector2.ZERO)))
		draw_string(ReadableFont.readable(),point+Vector2(-90,-55-age*14),str(mark.get("caption","探索补给")),HORIZONTAL_ALIGNMENT_CENTER,180,15,Color(1,0.9,0.57,1-age/maxf(lifetime,0.01)))


func _draw_unit(point: Vector2, unit: Dictionary, factor: float) -> void:
	var pose: Dictionary=_relief_poses.get(str(unit.get("id","")),{})
	if pose.is_empty():pose=Pose.for_unit(unit,int(snapshot.get("tick",0)))
	var action:=str(pose.get("action","IDLE"))
	var alive:=ActorReadout.living(unit)
	var direction: Vector2=pose.get("direction",Vector2.RIGHT)
	var facing: float=-1.0 if direction.x<0 else 1.0
	var frame:=_relief_frame(pose)
	var key:=ReliefAtlas.actor_key(unit,frame)
	var body:=ReliefAtlas.bounds(ReliefAtlas.actor_key(unit,0),factor,facing)
	var radius:=maxf(float(unit.get("visual_radius",unit.get("radius",12)))*factor,3)
	if alive and str(unit.get("unit_type",""))=="hero":
		var color:=Palette.side_color(str(unit.get("side","")))
		_draw_relief_ellipse(point,Vector2(maxf(body.size.x*0.48,19*factor),maxf(body.size.x*0.15,7*factor)),Color(color,0.23),4)
		_draw_relief_ellipse(point,Vector2(maxf(body.size.x*0.44,17*factor),maxf(body.size.x*0.13,6*factor)),Color(color,0.8),1.5)
	var selected:=str(unit.get("id","")) in [selected_unit,selected_worker_id] or (not selected_army.is_empty() and str(unit.get("warband_id",""))==selected_army)
	if selected and alive:_draw_relief_ellipse(point,Vector2(radius+5,(radius+5)*0.43),Color("fff2a6"),2)
	var offset:=_relief_body_offset(pose,factor)
	var tint:=Color.WHITE if alive else Color(0.6,0.6,0.6,0.52)
	if not alive:
		draw_set_transform(point,0.95,Vector2(1,0.55))
		ReliefAtlas.draw(self,Vector2.ZERO,key,factor,tint,facing)
		draw_set_transform(Vector2.ZERO)
	else:
		ReliefAtlas.draw(self,point+offset,key,factor,tint,facing)
		# An enamel chest badge, not a full-size shield covering the face. The
		# actor is baked at 0.60/0.78 scale; the generic badge needs less scale.
		var hero_badge := str(unit.get("unit_type",""))=="hero"
		ReliefAtlas.draw(self,point+offset+Vector2(0,-11 if hero_badge else -8)*factor,"team",factor*(0.50 if hero_badge else 0.35),Palette.side_color(str(unit.get("side",""))),facing)
	_relief_body_count+=1
	if alive:
		var empower:Array=[]
		if str(unit.get("unit_type",""))=="hero":
			var active:=Empowerment.read(unit,_empower_context)
			if not active.is_empty():empower=Empowerment.plan(point,unit,active,int(snapshot.get("tick",0)),factor,body)
		Empowerment.draw(self,empower,"REAR")
		Empowerment.draw(self,empower,"FRONT")
		AuraArt.draw_beneficiaries(self,point,unit,factor)
		var injury:=_hit_feedback.read(str(unit.get("id","")),int(snapshot.get("tick",0)))
		if shows_transient_effects() and not injury.is_empty():CombatEffects.draw_hit(self,point+Vector2(0,body.position.y*0.45),unit,injury,factor)
		if shows_transient_effects():
			for status: Dictionary in unit.get("status_effects",[]).slice(0,3):
				if str(status.get("id",""))=="INNATE_AURA":continue
				if _visible_combat_statuses>=128:break
				if CombatEffects.draw_status(self,point,point+Vector2(0,body.position.y-5),unit,status,int(snapshot.get("tick",0)),factor):_visible_combat_statuses+=1


func _draw_actor_overlays(factor: float) -> void:
	_last_actor_bars.clear()
	for unit: Dictionary in _relief_actors.values():
		if not ActorReadout.living(unit) or not ActorReadout.visible_to(unit,view_side_id):continue
		var point:=_screen(render_actor_position_m76(unit))
		if not _visible(point,140):continue
		var stable:=ReliefAtlas.bounds(ReliefAtlas.actor_key(unit,0),factor)
		var selected:=str(unit.get("id","")) in [selected_unit,selected_worker_id] or (not selected_army.is_empty() and str(unit.get("warband_id",""))==selected_army)
		var info:=ActorReadout.draw_bars(self,point,unit,stable,stable.size.y<24 and not selected)
		if not info.is_empty():
			info["id"]=str(unit.get("id",""));info["point"]=point
			_last_actor_bars.append(info)
	set_meta("actor_bars",_last_actor_bars.duplicate(true))


func _draw_relief_ellipse(point: Vector2, radii: Vector2, color: Color, width: float) -> void:
	draw_set_transform(point,0,Vector2(1,radii.y/maxf(radii.x,1)))
	draw_arc(Vector2.ZERO,radii.x,0,TAU,32,color,width)
	draw_set_transform(Vector2.ZERO)


func _draw_relief_building(point: Vector2, building: Dictionary, factor: float) -> void:
	var key:=ReliefAtlas.building_key(building)
	var alive:=int(building.get("hp",0))>0
	var tint:=Color.WHITE if alive else Color(0.45,0.48,0.44,0.65)
	if not bool(building.get("complete",false)):tint.a=0.48
	ReliefAtlas.draw(self,point,key,factor,tint)
	if alive:
		ReliefAtlas.draw(self,point+Vector2(0,-75)*factor,"team",factor*1.2,Palette.side_color(str(building.get("side",""))))
		var tier:=clampi(int(building.get("base_tier",1)),1,3)
		if str(building.get("building_type",""))=="BASE":
			for i: int in range(tier):draw_circle(point+Vector2(-8+i*8,-125)*factor,2.5*factor,Color("ebd99a"))


func _draw_terrain_prop(point: Vector2, terrain: Dictionary, factor: float) -> void:
	var kind:=str(terrain.get("kind",""))
	var key: String="tree" if kind=="TREE" else "ice" if kind in ["ICE","GLACIER"] else "lava" if kind in ["LAVA","LAVA_FIELD"] else "mountain" if kind in ["MOUNTAIN","RUIN"] else "stone"
	if key=="tree" and _faction_at(Vector2(terrain.get("position",Vector2.ZERO))) in ["HIGHLAND","UNDEAD"]:key="pine"
	var radius:=float(terrain.get("radius",40))
	var scale_value:=factor*maxf(0.3,radius/46.0)
	ReliefAtlas.draw(self,point,key,scale_value)
	if radius>=52:
		ReliefAtlas.draw(self,point+Vector2(-radius*0.45,radius*0.12)*factor,key,scale_value*0.65)
		ReliefAtlas.draw(self,point+Vector2(radius*0.38,radius*0.25)*factor,key,scale_value*0.72)


func _draw_resource(point: Vector2, source: Dictionary, factor: float) -> void:
	var type:=str(source.get("resource_type",source.get("kind","")))
	var key: String="food" if type=="FOOD" else "essence" if type in ["ESSENCE","SPIRIT","SPIRIT_ESSENCE"] else "gold"
	var available:=int(source.get("remaining",source.get("remaining_amount",source.get("stock",1))))>0
	ReliefAtlas.draw(self,point,key,factor*1.16,Color.WHITE if available else Color("949b89"))
	if str(source.get("id",""))==selected_site_id:
		_draw_relief_ellipse(point,Vector2(58,21)*factor,Color("f0d38e"),2)


func get_resource_readouts() -> Array[Dictionary]:
	var result: Array[Dictionary]=[]
	if camera==null:return result
	var factor:=float(camera.get_scale())
	for source: Dictionary in snapshot.get("resource_sources",[]):
		if not ActorReadout.visible_to(source,view_side_id):continue
		var type:=str(source.get("resource_type",source.get("kind","")))
		var key: String="food" if type=="FOOD" else "essence" if type in ["ESSENCE","SPIRIT","SPIRIT_ESSENCE"] else "gold"
		var body:=ReliefAtlas.bounds(key,factor*1.16)
		var point:=_screen(Vector2(source.get("position",Vector2.ZERO)))
		result.append({"id":str(source.get("id","")),"kind":type,"position":source.get("position",Vector2.ZERO),"remaining":int(source.get("remaining",source.get("remaining_amount",source.get("stock",1)))),"state":str(source.get("state","")),"active":bool(source.get("active",false)),"provenance":"original-native-svg-relief-m78","original_art":true,"screen_bounds":Rect2(point+body.position,body.size),"badge_bounds":Rect2(),"click_semantics":"unchanged-site-radius"})
	return result


func get_tower_readouts() -> Array[Dictionary]:
	var result: Array[Dictionary]=[]
	for readout: Dictionary in super.get_tower_readouts():
		var building:=_find(snapshot,str(readout.id),["buildings"])
		if ActorReadout.visible_to(building,view_side_id):result.append(readout)
	return result


func get_capture_readouts() -> Array[Dictionary]:
	var result: Array[Dictionary]=[]
	for readout: Dictionary in super.get_capture_readouts():
		var site:=_find(snapshot,str(readout.id),["sites"])
		if not ActorReadout.visible_to(site,view_side_id):continue
		# Keep the shared capture semantics, replacing only the actual visual
		# roof clearance. A large paper castle cannot overlap its status card.
		var card: Rect2=readout.card_rect
		for building: Dictionary in snapshot.get("buildings",[]):
			if int(building.get("hp",0))<=0 or not ActorReadout.visible_to(building,view_side_id):continue
			if Vector2(building.get("position",Vector2.ZERO)).distance_squared_to(Vector2(readout.position))>=64*64:continue
			var body:=ReliefAtlas.bounds(ReliefAtlas.building_key(building),float(camera.get_scale()))
			card.position.y=minf(card.position.y,maxf(2,_screen(Vector2(building.position)).y+body.position.y-card.size.y-10))
		readout["card_rect"]=card
		result.append(readout)
	return result


func visual_body_bounds(id: String, kind: String) -> Rect2:
	if camera==null:return Rect2()
	var value:=_find(snapshot,id,["buildings"] if kind=="building" else ["workers","soldiers"])
	if value.is_empty() or not ActorReadout.visible_to(value,view_side_id):return Rect2()
	var observation:=value if kind=="building" else _unit_observation(value)
	var pose: Dictionary={} if kind=="building" else Pose.for_unit(observation,int(snapshot.get("tick",0)))
	var key:=ReliefAtlas.building_key(value) if kind=="building" else ReliefAtlas.actor_key(observation,_relief_frame(pose))
	var facing: float=-1.0 if Vector2(pose.get("direction",Vector2.RIGHT)).x<0 else 1.0
	var local:=ReliefAtlas.bounds(key,float(camera.get_scale()),facing)
	var point: Vector2=camera.world_to_screen(Vector2(value.get("position",Vector2.ZERO)) if kind=="building" else render_actor_position_m76(value))
	if kind!="building":point+=_relief_body_offset(pose,float(camera.get_scale()))
	return Rect2(point+local.position,local.size)


func visual_body_contains(id: String, kind: String, screen_point: Vector2) -> bool:
	if camera==null or not screen_point.is_finite():return false
	var value:=_find(snapshot,id,["buildings"] if kind=="building" else ["workers","soldiers"])
	if value.is_empty() or not ActorReadout.living(value) or not ActorReadout.visible_to(value,view_side_id):return false
	if kind=="building" and not bool(value.get("complete",false)):return false
	var observation:=value if kind=="building" else _unit_observation(value)
	var pose: Dictionary={} if kind=="building" else Pose.for_unit(observation,int(snapshot.get("tick",0)))
	var key:=ReliefAtlas.building_key(value) if kind=="building" else ReliefAtlas.actor_key(observation,_relief_frame(pose))
	var facing: float=-1.0 if Vector2(pose.get("direction",Vector2.RIGHT)).x<0 else 1.0
	var origin: Vector2=camera.world_to_screen(Vector2(value.get("position",Vector2.ZERO)) if kind=="building" else render_actor_position_m76(value))
	if kind!="building":origin+=_relief_body_offset(pose,float(camera.get_scale()))
	var offset: Vector2=screen_point-origin
	return ReliefAtlas.contains(key,offset,float(camera.get_scale()),facing)


func get_diagnostics() -> Dictionary:
	return {"mode":"relief-m78","ready":ReliefAtlas.ensure() and _ground_texture!=null,"atlas":ReliefAtlas.stats(),"actors":_relief_actors.size(),"drawn_bodies":_relief_body_count,"observation_refreshes":_relief_refreshes,"terrain_rebuilds":_terrain_rebuilds,"terrain_tiles":_terrain_tiles,"decorations":_decorations.size(),"visible_decorations":_visible_decorations,"physics_nodes":0,"three_d_nodes":0,"ground_pixel_bytes":_ground_texture.get_width()*_ground_texture.get_height()*4 if _ground_texture!=null else 0,"failures":[] if _relief_ground_error.is_empty() else [_relief_ground_error],"animation":"three baked body poses plus observed movement/attack/cast/hit/death response; not six independently authored frame sets","effect_semantics":"existing actual event, aura, empowerment and tower consumers retained","source":"original-native-svg-relief-m78"}


static func _relief_frame(pose: Dictionary) -> int:
	var action:=str(pose.get("action","IDLE"))
	if action in ["WALK","CARRY"]:return 1 if float(pose.get("step",0))>0 else 0
	if action in ["ATTACK","HARVEST","MINE","BUILD","HEAL","POTION"] or action.begins_with("SKILL_"):return 2
	return 0


func _relief_body_offset(pose: Dictionary, factor: float) -> Vector2:
	var action:=str(pose.get("action","IDLE"))
	if action in ["WALK","CARRY"]:return Vector2(0,-absf(sin((float(snapshot.get("tick",0))+interpolation_fraction_m76)*0.52))*2.5*factor)
	if action=="ATTACK" or action.begins_with("SKILL_"):
		var facing: float=-1.0 if Vector2(pose.get("direction",Vector2.RIGHT)).x<0 else 1.0
		return Vector2(facing*sin(float(pose.get("phase",0))*PI)*3*factor,0)
	return Vector2.ZERO
