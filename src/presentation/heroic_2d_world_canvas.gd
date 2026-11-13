extends Node2D
## Independent true-2D battlefield. All bodies and outcomes are observations;
## this canvas owns no simulation, collision, command sender or 3D viewport.
const Atlas = preload("res://src/presentation/heroic_2d_atlas.gd")
const Units = preload("res://src/presentation/heroic_pixel_units.gd")
const Pose = preload("res://src/presentation/strategic_action_pose.gd")
const BodyMotionM76 = preload("res://src/presentation/heroic_actor_motion_m76.gd")
const Landscape = preload("res://src/presentation/strategic_landscape_plan.gd")
const Capture = preload("res://src/presentation/strategic_capture_readout.gd")
const Objectives = preload("res://src/presentation/strategic_field_objective_readout.gd")
const Palette = preload("res://src/presentation/strategic_side_palette.gd")
const ReadableFont = preload("res://src/presentation/strategic_font.gd")
const HitFeedback = preload("res://src/presentation/strategic_hit_feedback.gd")
const CombatFeedbackR9 = preload("res://src/presentation/strategic_combat_feedback_r9.gd")
const BuildingBrush = preload("res://src/presentation/heroic_pixel_brush.gd")
const DecorationPlan = preload("res://src/presentation/heroic_decoration_plan.gd")
const PixelDecorations = preload("res://src/presentation/heroic_pixel_decorations.gd")
const Collection = preload("res://src/presentation/heroic_collection.gd")
const CollectionTerrain = preload("res://src/presentation/heroic_collection_terrain.gd")
const RoadTiles = preload("res://src/presentation/heroic_road_tiles.gd")
const HomeTerrain = preload("res://src/presentation/heroic_home_terrain.gd")
const CollectionProps = preload("res://src/presentation/heroic_collection_props.gd")
const CollectionEffects = preload("res://src/presentation/heroic_collection_effects.gd")
const CombatEffects = preload("res://src/presentation/heroic_combat_effects.gd")
const ReworkR7Effects = preload("res://src/presentation/heroic_rework_r7_effects.gd")
const R7Spectacle = preload("res://src/presentation/heroic_r7_spectacle.gd")
const RosterV5 = preload("res://src/presentation/heroic_roster_v5.gd")
const TowerEffects = preload("res://src/presentation/heroic_tower_effects.gd")
const Expeditions = preload("res://src/presentation/heroic_expedition_markers.gd")
const ActorReadout = preload("res://src/presentation/heroic_actor_readout.gd")
const AuraArt = preload("res://src/presentation/heroic_aura_art.gd")
const Empowerment = preload("res://src/presentation/heroic_empowerment_art.gd")
const OutpostSlotUI = preload("res://src/presentation/strategic_outpost_slot_ui.gd")
const MAX_VISIBLE_DECORATIONS := 72
const BUILDING_KEYS := {"BASE":"castle","BARRACKS":"hall","RANGE":"house_c","TOWER":"chapel","SITE_TOWER":"chapel","ESSENCE_MINE":"workshop","FOUNDRY":"house_b","ALTAR":"chapel","WORKSHOP":"workshop","DRAGON_ROOST":"house_f"}
const FACTION_TINTS := {"HUMAN":Color.WHITE,"UNDEAD":Color(0.82,0.81,0.92),"MACHINE":Color(0.94,0.9,0.77),"FOREST":Color(0.84,1.0,0.8),"HIGHLAND":Color(0.91,0.98,1.0),"UNDERGROUND":Color(0.89,0.8,0.96)}
const MAX_BUILDING_FRAMES := 96
const FALLBACK_BUILDING_SCALE := 1.8
static var _building_frames: Dictionary = {}
static var _building_frame_order: Array[String] = []
static var _building_bakes := 0
var camera: RefCounted
var selected_army := ""
var selected_unit_type_r12 := ""
var selected_unit := ""
var selected_worker_id := ""
var selected_site_id := ""
var selected_building_id := ""
var view_side_id := "PLAYER"
var feedback_marks: Array = []
var field_reward_marks: Array = []
var aim: Dictionary = {}
var blueprint_type := ""
var blueprint_point := Vector2.ZERO
var landscape_plan: Dictionary = {}
var snapshot: Dictionary = {}:
	set(value):
		if is_same(snapshot,value): return
		var next_tick:=int(value.get("tick",-1))
		var continuous:bool=next_tick==int(snapshot.get("tick",-1))+1 and value.get("seed")==snapshot.get("seed") and next_tick>0
		_previous_actor_positions_m76.clear()
		if continuous:
			for group:String in ["workers","soldiers"]:
				for actor:Dictionary in snapshot.get(group,[]):
					if int(actor.get("hp",0))>0:_previous_actor_positions_m76[str(actor.get("id",""))]={"position":Vector2(actor.get("position",Vector2.ZERO)),"life":int(actor.get("life_generation",1))}
		snapshot=value
		_empower_context=Empowerment.prepare(value)
		_hit_feedback.observe(value)
		_combat_feedback_r9.observe(value,view_side_id)
		_refresh_landscape()
var presentation_seed_override := -1:
	set(value):
		if presentation_seed_override==value: return
		presentation_seed_override=value
		_refresh_landscape()
var _signature := ""
var _terrain_rebuilds := 0
var _terrain_tiles := 0
var _ground_texture: Texture2D
var _ground_bounds := Rect2()
var _ground_pixel := 2.0
var _decorations: Array[Dictionary] = []
var _decoration_plan: Dictionary = {}
var _visible_decorations := 0
var _faded_decorations := 0
var _hidden_decorations := 0
var _hit_feedback := HitFeedback.new()
var _combat_feedback_r9 := CombatFeedbackR9.new()
var screen_shake_enabled := true
var _feedback_shift_r9 := Vector2.ZERO
var _feedback_heads_r9: Dictionary = {}

func reset_feedback() -> void:
	_hit_feedback.reset()
	_combat_feedback_r9.reset()
	_feedback_shift_r9=Vector2.ZERO

func feedback_screen_offset_r9() -> Vector2:
	return _feedback_shift_r9
var _ready_assets := false
var _collection_ground_report: Dictionary = {}
var _visible_combat_actions := 0
var _visible_combat_statuses := 0
var _r7_spectacle_draw_scope: Dictionary = {}
var _overview_units: Dictionary = {}
var _last_actor_bars: Array[Dictionary] = []
var _empower_context:Dictionary={}
var interpolation_fraction_m76:=1.0
var _previous_actor_positions_m76:Dictionary={}

func render_actor_position_m76(unit:Dictionary)->Vector2:
	var point:=Vector2(unit.get("position",Vector2.ZERO))
	var previous:Dictionary=_previous_actor_positions_m76.get(str(unit.get("id","")),{})
	if previous.is_empty() or int(unit.get("hp",0))<=0 or int(unit.get("life_generation",1))!=int(previous.life):return point
	# Teleport/revival/discontinuous observations snap instead of sliding bodies
	# through the map. Nothing here is fed back to authoritative movement.
	var origin:Vector2=previous.position
	if origin.distance_squared_to(point)>128.0*128.0:return point
	return origin.lerp(point,clampf(interpolation_fraction_m76,0.0,1.0))


func _ready() -> void:
	name="HeroicPixelBattlefield"
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	_ready_assets=bool(Atlas.validate_installation().ready)
	_refresh_landscape()


func _refresh_landscape() -> void:
	if snapshot.is_empty(): return
	var facts := snapshot.duplicate(false)
	if presentation_seed_override>=0: facts["seed"]=presentation_seed_override
	var signature := Landscape.signature(facts) + ":" + DecorationPlan.VERSION + ":" + str(Collection.status().profile) + ":" + CollectionTerrain.VERSION
	if signature==_signature: return
	_signature=signature
	landscape_plan=Landscape.build(facts,"TILED")
	_terrain_rebuilds+=1
	_decoration_plan = DecorationPlan.build(facts, landscape_plan)
	_decorations.assign(_decoration_plan.get("entries", []))
	_ready_assets=bool(Atlas.validate_installation().ready)
	if _ready_assets: _bake_ground()
	set_meta("landscape_summary",{"signature":_signature,"rebuilds":_terrain_rebuilds,"roads":landscape_plan.get("roads",[]).size(),"decorations":_decorations.size(),"decoration_version":DecorationPlan.VERSION,"decoration_summary":_decoration_plan.get("summary",{}).duplicate(true),"failures":landscape_plan.get("failures",[]).duplicate(true)})


func _bake_ground() -> void:
	_ground_bounds=Rect2(landscape_plan.get("bounds",Rect2i(0,0,3200,2000)))
	_ground_pixel=maxf(2.0,maxf(_ground_bounds.size.x,_ground_bounds.size.y)/2048.0)
	if Collection.active():
		var baked := CollectionTerrain.bake(snapshot,landscape_plan,_decorations,_ground_bounds,_ground_pixel)
		_collection_ground_report = baked.duplicate(false)
		_collection_ground_report.erase("image")
		var pixels: Image = baked.get("image")
		if pixels == null:
			_ready_assets = false
			_ground_texture = null
			return
		_terrain_tiles = int(baked.get("terrain_tiles",0))
		_ground_texture = ImageTexture.create_from_image(pixels)
		return
	var size := Vector2i(ceili(_ground_bounds.size.x/_ground_pixel),ceili(_ground_bounds.size.y/_ground_pixel))
	var image := Image.create(size.x,size.y,false,Image.FORMAT_RGBA8)
	image.fill(Color("4dbc27"))
	var columns := ceili(float(size.x)/16.0)
	var rows := ceili(float(size.y)/16.0)
	var water: Dictionary = {}
	var wet: Array[Dictionary] = []
	for obstacle: Dictionary in snapshot.get("terrain",[]):
		if obstacle.get("kind") in ["LAKE","RIVER"]: wet.append(obstacle)
	for y: int in range(-1,rows+1):
		for x: int in range(-1,columns+1):
			var point := _ground_bounds.position+Vector2(x*16+8,y*16+8)*_ground_pixel
			for obstacle: Dictionary in wet:
				if point.distance_squared_to(Vector2(obstacle.get("position",Vector2.ZERO)))<=pow(float(obstacle.get("radius",40)),2): water[Vector2i(x,y)]=true;break
	_terrain_tiles=columns*rows
	var seed := int(landscape_plan.get("seed",0))
	var grass_variants: Dictionary={}
	for y: int in range(rows):
		for x: int in range(columns):
			var cell := Vector2i(x,y)
			var world := _ground_bounds.position+Vector2(x*16+8,y*16+8)*_ground_pixel
			var tile := "grass"
			if water.has(cell):
				var n := not water.has(cell+Vector2i.UP)
				var s := not water.has(cell+Vector2i.DOWN)
				var w := not water.has(cell+Vector2i.LEFT)
				var e := not water.has(cell+Vector2i.RIGHT)
				tile="shore_nw" if n and w else "shore_ne" if n and e else "shore_sw" if s and w else "shore_se" if s and e else "shore_n" if n else "shore_s" if s else "shore_w" if w else "shore_e" if e else "water"
			var tile_image: Image=Atlas.region_image(tile)
			if not water.has(cell):
				var faction:=_faction_at(world)
				var variant_key:=tile+":"+faction
				if not grass_variants.has(variant_key):
					var colored:=tile_image.duplicate() as Image
					var tint: Color={"HUMAN":Color(0.84,0.88,0.86),"FOREST":Color(0.74,0.85,0.77),"UNDEAD":Color(0.73,0.76,0.88),"MACHINE":Color(0.9,0.86,0.72),"HIGHLAND":Color(0.9,0.96,1.1),"UNDERGROUND":Color(0.8,0.76,0.9)}.get(faction,Color.WHITE)
					for py: int in range(16):
						for px: int in range(16): colored.set_pixel(px,py,colored.get_pixel(px,py)*tint)
					grass_variants[variant_key]=colored
				tile_image=grass_variants[variant_key]
			image.blit_rect(tile_image,Rect2i(0,0,16,16),Vector2i(x*16,y*16))
	# Actual transparent, rounded author grass clumps, not axis-aligned blocks
	# of the dense tile. A quiet ground keeps mobile actors and routes readable.
	var grass_patch:=Atlas.region_image("grass_patch").duplicate() as Image
	for py: int in range(grass_patch.get_height()):
		for px: int in range(grass_patch.get_width()):
			var color:=grass_patch.get_pixel(px,py)
			grass_patch.set_pixel(px,py,Color(color.r*0.8,color.g*0.85,color.b*0.82,color.a*0.8))
	for y: int in range(2,rows-2,4):
		for x: int in range(2,columns-2,4):
			var clump_key:=_key("clump:%d:%d:%d" % [x,y,seed])
			if clump_key%100>=24: continue
			var clear:=true
			for dy: int in range(-2,3):
				for dx: int in range(-2,3):
					if water.has(Vector2i(x+dx,y+dy)): clear=false
			if clear: image.blend_rect(grass_patch,Rect2i(Vector2i.ZERO,grass_patch.get_size()),Vector2i(x*16-24+int(clump_key%13),y*16-24+int((clump_key/13)%13)))
	var road_report := RoadTiles.paint(image,landscape_plan,_ground_bounds,_ground_pixel,"STARTER")
	_collection_ground_report = {"profile":"STARTER","road_geometry":"whole-authored-road-tiles","road_materials":road_report.duplicate(true)}
	if not bool(road_report.get("ready",false)):
		_ready_assets = false
		_ground_texture = null
		return
	# Painted grass clumps and flowers break up plain fill without repeating a
	# noisy checkerboard. These are baked once, never hundreds of live actors.
	for decor: Dictionary in _decorations:
		if str(decor.get("layer","")) != "ground": continue
		var pos := (Vector2(decor.position)-_ground_bounds.position)/_ground_pixel
		var patch: Dictionary = PixelDecorations.ground_patch(decor)
		if patch.is_empty(): continue
		# The shared composer returns world-sized pixels; the map cache stores
		# one texel per _ground_pixel world units, not a per-object texture.
		var pixels: Image = (patch.image as Image).duplicate()
		var extent := Vector2i(maxi(1,roundi(pixels.get_width()/_ground_pixel)),maxi(1,roundi(pixels.get_height()/_ground_pixel)))
		pixels.resize(extent.x,extent.y,Image.INTERPOLATE_NEAREST)
		image.blend_rect(pixels,Rect2i(Vector2i.ZERO,pixels.get_size()),Vector2i((pos-Vector2(patch.anchor)/_ground_pixel).round()))
	_ground_texture=ImageTexture.create_from_image(image)


func _screen(world: Vector2) -> Vector2:
	return camera.world_to_screen(world)-(get_parent() as Control).position+_feedback_shift_r9


func _visible(point: Vector2, margin: float = 100.0) -> bool:
	return Rect2(Vector2.ZERO,(get_parent() as Control).size).grow(margin).has_point(point)


var _draw_pose_cache_m81: Dictionary = {}
var _draw_pose_active_m81 := false

func _draw() -> void:
	RosterV5.begin_draw(self)
	Units.begin_draw_m90()
	_draw_pose_cache_m81.clear()
	_draw_pose_active_m81 = true
	_draw_contents_m81()
	_draw_pose_active_m81 = false
	_draw_pose_cache_m81.clear()
	Units.end_draw_m90()

func _pose_for_draw_m81(unit: Dictionary, tick: int) -> Dictionary:
	if not _draw_pose_active_m81: return Pose.for_unit(unit,tick)
	var id := str(unit.get("id",""))
	if id.is_empty(): return Pose.for_unit(unit,tick)
	var cached: Dictionary = _draw_pose_cache_m81.get(id,{})
	if not cached.is_empty():
		# Duplicate ids are legal observations. Never borrow another actor body.
		return cached.pose if is_same(cached.actor,unit) and int(cached.tick)==tick else Pose.for_unit(unit,tick)
	var pose := Pose.for_unit(unit,tick)
	_draw_pose_cache_m81[id] = {"actor":unit,"tick":tick,"pose":pose}
	return pose

func _draw_contents_m81() -> void:
	_visible_combat_statuses = 0
	_r7_spectacle_draw_scope={}
	if camera==null or snapshot.is_empty(): return
	_feedback_heads_r9.clear()
	_feedback_shift_r9=_combat_feedback_r9.camera_offset(snapshot,-1,screen_shake_enabled,func(p:Vector2)->bool:return _visible(camera.world_to_screen(p)-(get_parent() as Control).position,0))
	if not _ready_assets or _ground_texture==null:
		draw_rect(Rect2(Vector2.ZERO,(get_parent() as Control).size),Color("182a24"))
		var missing := not bool(Atlas.validate_installation().get("ready",false))
		var reason := str(_collection_ground_report.get("failures",[]))
		var caption := "Heroic 素材未通过校验，请按启动提示检查本地素材。" if missing else "地表生成未完成："+reason
		draw_string(ReadableFont.readable(),Vector2(30,90),caption,HORIZONTAL_ALIGNMENT_LEFT,1000,22,Color("f1dda6"))
		return
	var factor := float(camera.get_scale())
	_visible_decorations = 0
	_faded_decorations = 0
	_hidden_decorations = 0
	var obscuring_bodies := _decoration_occluders()
	draw_texture_rect(_ground_texture,Rect2(_screen(_ground_bounds.position),_ground_bounds.size*factor),false)
	OutpostSlotUI.draw(self, snapshot, Callable(self,"_screen"), factor, view_side_id)
	# Crop plots are flat ground: paint them before actors regardless of the
	# source's Y foot. Only the shelter/mine and resource cue enter depth order.
	for source: Dictionary in snapshot.get("resource_sources", []):
		var foot := _screen(Vector2(source.get("position", Vector2.ZERO)))
		if resource_visible_on_screen(source, foot, Rect2(Vector2.ZERO, (get_parent() as Control).size), factor): CollectionProps.draw_resource_floor(self, foot, source, factor)
	_draw_aura_sources(factor)
	var r7_visual := ReworkR7Effects.visual_plan(snapshot,view_side_id) if shows_transient_effects() else {}
	var spectacle := R7Spectacle.plan(snapshot,view_side_id,r7_visual.pending) if not r7_visual.is_empty() else {}
	var roster_v5 := RosterV5.plan(snapshot,view_side_id) if shows_transient_effects() else {}
	if not roster_v5.is_empty():RosterV5.draw(self,roster_v5,Callable(self,"_screen"),factor,"REAR")
	_r7_spectacle_draw_scope=spectacle
	if not r7_visual.is_empty(): ReworkR7Effects.draw_atmosphere(self,r7_visual.atmosphere,Callable(self,"_screen"),factor)
	if not spectacle.is_empty(): R7Spectacle.draw(self,spectacle,Callable(self,"_screen"),factor,"REAR")
	var objects: Array[Dictionary] = []
	for terrain: Dictionary in snapshot.get("terrain",[]):
		if terrain.get("kind") not in ["LAKE","RIVER"]: objects.append({"kind":"terrain","value":terrain})
	for site: Dictionary in snapshot.get("sites",[]):
		if site.get("kind")=="VILLAGE": objects.append({"kind":"site","value":site})
	for source: Dictionary in snapshot.get("resource_sources",[]): objects.append({"kind":"resource","value":source})
	for building: Dictionary in snapshot.get("buildings",[]): objects.append({"kind":"building","value":building})
	for camp: Dictionary in snapshot.get("neutral_camps", []): objects.append({"kind":"camp","value":camp})
	for loot: Dictionary in snapshot.get("neutral_loot", []): objects.append({"kind":"loot","value":loot})
	for decoration: Dictionary in _decorations:
		if str(decoration.get("layer","")) == "prop": objects.append({"kind":"decoration","value":decoration})
	for collection: String in ["workers","soldiers"]:
		for unit: Dictionary in snapshot.get(collection,[]): objects.append({"kind":"unit","value":unit})
	objects.sort_custom(func(a: Dictionary,b: Dictionary)->bool:
		var ap:=Vector2(a.value.get("position",Vector2.ZERO));var bp:=Vector2(b.value.get("position",Vector2.ZERO))
		return str(a.value.get("id",""))<str(b.value.get("id","")) if ap.y==bp.y else ap.y<bp.y)
	for object: Dictionary in objects:
		var value: Dictionary=object.value
		if str(object.kind)=="unit" and not ActorReadout.visible_to(value,view_side_id): continue
		var point:=_screen(render_actor_position_m76(value) if str(object.kind)=="unit" else Vector2(value.get("position",Vector2.ZERO)))
		# Enlarged resource pictures can be visible while their source foot is
		# outside the viewport. Cull their actual alpha/badge union, not an
		# unrelated interaction radius or a guessed anchor margin.
		if str(object.kind) == "resource":
			if not resource_visible_on_screen(value,point,Rect2(Vector2.ZERO,(get_parent() as Control).size),factor): continue
		elif str(object.kind) == "building":
			if not Rect2(Vector2.ZERO, (get_parent() as Control).size).intersects(Rect2(point + building_visual_bounds(value, factor).position, building_visual_bounds(value, factor).size)): continue
		elif not _visible(point,200*factor): continue
		match str(object.kind):
			"terrain": _draw_terrain_prop(point,value,factor)
			"resource": _draw_resource(point,value,factor)
			"site": _draw_village(point,value,factor)
			"camp": Expeditions.draw_camp(self, point, value, factor)
			"loot": Expeditions.draw_loot(self, point, value, factor)
			"decoration":
				if _visible_decorations >= MAX_VISIBLE_DECORATIONS: continue
				var envelope := PixelDecorations.visual_bounds(value,factor)
				if not Rect2(Vector2.ZERO,(get_parent() as Control).size).intersects(Rect2(point+envelope.position,envelope.size)): continue
				var opacity := _decoration_opacity(value,obscuring_bodies)
				if opacity <= 0:
					_hidden_decorations += 1
					continue
				if PixelDecorations.draw(self,point,value,factor,opacity):
					_visible_decorations += 1
					if opacity < 1: _faded_decorations += 1
			"building":
				_feedback_heads_r9[str(value.get("id",""))]=Vector2(0,building_visual_bounds(value,factor).position.y-10)
				draw_building_sprite(self,point,value,factor)
				_draw_building_state(point,value,factor)
				if value.get("building_type") == "SHOP":
					var shop_bounds := building_visual_bounds(value, factor)
					draw_string(ReadableFont.readable(), point + Vector2(-64, shop_bounds.position.y - 9), "英雄商店", HORIZONTAL_ALIGNMENT_CENTER, 128, 15, Color("f2dfa6"))
			"unit": _draw_unit(point,value,factor)
	# Synchronous read-only draw context; never retain a match observation or
	# change the virtual method shared by the optional relief canvas.
	_r7_spectacle_draw_scope={}
	if not r7_visual.is_empty(): ReworkR7Effects.draw_atmosphere(self,r7_visual.atmosphere,Callable(self,"_screen"),factor,"FRONT")
	_draw_action_effects(factor)
	_draw_r7_status_overlays(factor)
	if shows_transient_effects(): ReworkR7Effects.draw_pending(self,snapshot,Callable(self,"_screen"),factor,view_side_id,r7_visual)
	if not spectacle.is_empty(): R7Spectacle.draw(self,spectacle,Callable(self,"_screen"),factor,"FRONT")
	if not roster_v5.is_empty():RosterV5.draw(self,roster_v5,Callable(self,"_screen"),factor,"FRONT")
	# All HP/MP and hero frames are a final actor overlay, not buried in the
	# Y-sorted bodies, buildings or scenery that happen to be in front.
	_draw_actor_overlays(factor)
	if shows_transient_effects():CombatFeedbackR9.draw_numbers(self,_combat_feedback_r9.numbers(snapshot),Callable(self,"_screen"),func(id:String)->Vector2:return _feedback_heads_r9.get(id,Vector2(0,-40*factor)),factor)
	_draw_orders(factor)
	var captures:=get_capture_readouts()
	set_meta("capture_readouts",captures.duplicate(true))
	for readout: Dictionary in captures: _draw_capture(readout)
	set_meta("tower_readouts",get_tower_readouts())
	for readout: Dictionary in get_tower_readouts():
		if readout.selected: draw_arc(readout.center,readout.screen_range,0,TAU,72,Color("e9d593",0.65),2)
		if readout.firing:
			var tower := _find(snapshot, str(readout.id), ["buildings"])
			var body := CollectionProps.inspect_building(tower, factor)
			var origin := Vector2(readout.center) + Vector2(0, Rect2(body.get("body_bounds", Rect2(0, -64 * factor, 1, 1))).position.y + 12 * factor)
			TowerEffects.draw(self,origin,readout,factor)
	if not blueprint_type.is_empty():
		var point:=_screen(blueprint_point)
		var observation:=get_blueprint_observation()
		draw_building_sprite(self,point,observation,factor)
		draw_arc(point,(float(observation.radius)+4)*factor,0,TAU,32,Color("c7edb2"),2)
		set_meta("blueprint_radius",int(observation.radius))
	var objectives: Array[Dictionary]=[]
	for readout: Dictionary in captures:
		var objective: Dictionary=readout.get("field_objective",{})
		if objective.is_empty(): continue
		var marker:=Vector2(readout.card_rect.end.x+11,readout.card_rect.get_center().y)
		Objectives.draw_marker(self,marker,objective,bool(readout.compact))
		objectives.append({"site_id":str(readout.id),"kind":str(objective.kind),"state":str(objective.state),"position":marker})
	set_meta("field_objective_marks",objectives)
	for mark: Dictionary in field_reward_marks.slice(0,4):
		var age:=float(mark.get("age",0));var lifetime:=float(mark.get("lifetime",2))
		if age<0 or age>=lifetime: continue
		var point:=_screen(Vector2(mark.get("position",Vector2.ZERO)))
		var color:=Color(1,0.9,0.57,1.0-age/maxf(lifetime,0.01))
		draw_string(ReadableFont.readable(),point+Vector2(-90,-55-age*14),str(mark.get("caption","探索补给")),HORIZONTAL_ALIGNMENT_CENTER,180,15,color)


func _draw_terrain_prop(point: Vector2, terrain: Dictionary, factor: float) -> void:
	if CollectionTerrain.draw_prop(self,point,terrain,_faction_at(Vector2(terrain.get("position",Vector2.ZERO))),factor): return
	var kind:=str(terrain.get("kind",""))
	var radius:=float(terrain.get("radius",40))
	var key:=_key(str(terrain.get("id",point)))
	if kind=="TREE":
		var pine:=_faction_at(Vector2(terrain.get("position",Vector2.ZERO))) in ["HIGHLAND","UNDEAD"]
		var scale_factor:=radius/16.0*factor
		var offsets: Array[Vector2]=[Vector2(-0.5,-0.15),Vector2(0.45,-0.05),Vector2(0,0.5)]
		for i: int in range(3): Atlas.draw_sprite(self,"pine" if pine else "oak",point+offsets[i]*radius*factor,scale_factor*(0.84+float((key+i)%3)*0.1),_faction_tint(_faction_at(Vector2(terrain.get("position",Vector2.ZERO)))))
	elif kind in ["MOUNTAIN","RUIN"]:
		Atlas.draw_sprite(self,"mountain_big" if key%2==0 else "mountain_ridge",point,radius/17.0*factor)
	else: Atlas.draw_sprite(self,"stones",point,factor*1.8)


func _decoration_occluders() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for collection: String in ["workers","soldiers","buildings"]:
		for entity: Dictionary in snapshot.get(collection,[]):
			if int(entity.get("hp",0)) <= 0 or not bool(entity.get("alive",true)): continue
			var point := Vector2(entity.get("position",Vector2.ZERO))
			var bounds := building_visual_bounds(entity,1.0) if collection == "buildings" else Units.visual_bounds(_unit_observation(entity),float(entity.get("visual_radius",entity.get("radius",12))),_pose_for_draw_m81(entity,int(snapshot.get("tick",0))))
			result.append({"bounds":Rect2(point+bounds.position,bounds.size).grow(6),"building":collection=="buildings"})
	# Only noninteractive prop ornaments are cleared. Source locations, map
	# obstacle geometry, harvesting stations and click targets never change.
	for source: Dictionary in snapshot.get("resource_sources",[]):
		var resource := CollectionProps.inspect_resource(source,1.0)
		if not resource.get("supported",false): continue
		var bounds: Rect2 = resource.bounds
		result.append({"bounds":Rect2(Vector2(source.get("position",Vector2.ZERO))+bounds.position,bounds.size).grow(10),"building":true,"resource":true})
	# An empty construction pad is a persistent interaction surface too. Keep
	# its actual icon AND font label free of decorative carts/trees/crates.
	# Only current-view pads add occluders: do not grow all-map per-prop work.
	# This does not move scenery, reorder actors or allow clicks through roofs.
	if OutpostSlotUI.enabled(snapshot):
		var factor := float(camera.get_scale()) if camera != null else 1.0
		if factor > 0:
			var local := OutpostSlotUI.visual_envelope(factor)
			var field := get_parent() as Control
			for slot: Dictionary in snapshot.get("building_slots",[]):
				if bool(slot.get("occupied",false)) or not bool(slot.get("visible",true)): continue
				var point := Vector2(slot.get("position",Vector2.ZERO))
				if camera != null and field != null:
					var screen_bounds := Rect2(_screen(point)+local.position,local.size)
					if not Rect2(Vector2.ZERO,field.size).intersects(screen_bounds): continue
				result.append({"bounds":Rect2(point+local.position/factor,local.size/factor),"building":true,"outpost_slot":true})
	return result


func _decoration_opacity(entry: Dictionary, occluders: Array[Dictionary]) -> float:
	if str(entry.get("layer","")) != "prop": return 1.0
	var local := PixelDecorations.visual_bounds(entry,1.0)
	var body := Rect2(Vector2(entry.get("position",Vector2.ZERO))+local.position,local.size)
	var result := 1.0
	for occluder: Dictionary in occluders:
		if not body.intersects(Rect2(occluder.bounds)): continue
		if bool(occluder.building): return 0.0
		result = 0.2
	return result


func decoration_visibility(entry: Dictionary) -> float:
	return _decoration_opacity(entry,_decoration_occluders())


func get_decoration_entries() -> Array[Dictionary]:
	return _decorations.duplicate(true)


func _draw_resource(point: Vector2, source: Dictionary, factor: float) -> void:
	if CollectionProps.draw_resource(self,point,source,factor,false): return
	var food:=str(source.get("resource_type",source.get("kind","")))=="FOOD"
	var available:=int(source.get("remaining",source.get("stock",1)))>0
	var modulation:=Color.WHITE if available else Color("949b7b")
	if food:
		for i: int in range(3): Atlas.draw_sprite(self,["field_green","field_ripe","field_bloom"][i],point+Vector2((i-1)*24,abs(i-1)*9)*factor,2.0*factor,modulation)
	else:
		Atlas.draw_sprite(self,"mountain",point+Vector2(-22,-8)*factor,2.4*factor,modulation)
		Atlas.draw_sprite(self,"cave",point,1.7*factor,modulation)
		for i: int in range(4): draw_rect(Rect2((point+Vector2(14+i*5,3-(i%2)*4)*factor).round(),Vector2(4,3)*factor),Color("dfc465") if available else Color("8b8b72"))


static func resource_visible_on_screen(source: Dictionary, foot: Vector2, viewport: Rect2, factor: float = 1.0) -> bool:
	if not foot.is_finite() or not viewport.position.is_finite() or not viewport.size.is_finite() or not is_finite(factor) or factor <= 0: return false
	var bounds := CollectionProps.resource_visual_bounds(source,factor)
	return viewport.intersects(Rect2(foot+bounds.position,bounds.size)) if bounds.has_area() else viewport.grow(200*factor).has_point(foot)


func get_resource_readouts() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if camera == null: return result
	var factor := float(camera.get_scale())
	for source: Dictionary in snapshot.get("resource_sources",[]):
		var art := CollectionProps.inspect_resource(source,factor)
		if not art.get("supported",false): continue
		var point := _screen(Vector2(source.get("position",Vector2.ZERO)))
		var bounds: Rect2 = art.bounds
		var badge: Rect2 = art.get("badge_bounds",Rect2())
		result.append({"id":str(source.get("id","")),"kind":str(source.get("resource_type",source.get("kind",""))),"position":Vector2(source.get("position",Vector2.ZERO)),"remaining":int(source.get("remaining",source.get("remaining_amount",source.get("stock",1)))),"state":str(source.get("state","")),"active":bool(source.get("active",false)),"provenance":str(art.provenance),"original_art":bool(art.get("original_art",false)),"depleted":bool(art.get("depleted",false)),"screen_bounds":Rect2(point+bounds.position,bounds.size),"badge_bounds":Rect2(point+badge.position,badge.size) if badge.has_area() else Rect2(),"click_semantics":"unchanged-site-radius"})
	return result


func _draw_village(point: Vector2, site: Dictionary, factor: float) -> void:
	var key:=_key(str(site.get("id","")))
	Atlas.draw_sprite(self,"house_d" if key%2==0 else "house_e",point+Vector2(-17,2)*factor,2.25*factor)
	Atlas.draw_sprite(self,"house_a" if key%3==0 else "house_c",point+Vector2(17,-12)*factor,2.0*factor)
	_flag(self,point+Vector2(0,-34)*factor,Palette.side_color(str(site.get("owner",""))),factor)


static func building_sprite_key(building: Dictionary) -> String:
	return str(BUILDING_KEYS.get(str(building.get("building_type","BASE")),"house_a"))


static func building_visual_scale(building: Dictionary, factor: float) -> float:
	var licensed := CollectionProps.inspect_building(building,factor)
	if bool(licensed.get("supported",false)): return float(licensed.scale)
	return factor*(1.55 if building.get("building_type")=="BASE" else 3.4 if building.get("building_type")=="TOWER" else 3.0)


static func building_visual_bounds(building: Dictionary, factor: float) -> Rect2:
	if not is_finite(factor) or factor<=0: return Rect2()
	var licensed := CollectionProps.inspect_building(building,factor)
	if bool(licensed.get("supported",false)): return licensed.bounds
	var frame:=_building_frame(building)
	return Rect2(Vector2(frame.rect.position)*factor*FALLBACK_BUILDING_SCALE,Vector2(frame.rect.size)*factor*FALLBACK_BUILDING_SCALE)


static func draw_building_sprite(canvas: Object, point: Vector2, building: Dictionary, factor: float) -> void:
	if factor<=0 or not is_finite(factor): return
	if CollectionProps.draw_building(canvas,point,building,factor): return
	var frame:=_building_frame(building)
	var bounds:=building_visual_bounds(building,factor)
	if canvas is CanvasItem: canvas.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	canvas.draw_texture_rect(frame.texture,Rect2(point+bounds.position,bounds.size),false)


static func _building_frame(building: Dictionary) -> Dictionary:
	# Current HP, queue progress and simulation tick never generate art frames.
	var key:=JSON.stringify([str(building.get("building_type","BASE")),str(building.get("faction_id","HUMAN")),str(building.get("side","")),clampi(int(building.get("base_tier",1)),1,3),bool(building.get("complete",false)),int(building.get("hp",0))>0])
	if _building_frames.has(key):
		_building_frame_order.erase(key)
		_building_frame_order.append(key)
		return _building_frames[key]
	var brush:=BuildingBrush.new()
	_paint_building(brush,Vector2.ZERO,building,1.0)
	var used: Rect2i=brush.image.get_used_rect()
	if used.size.x<=0 or used.size.y<=0: used=Rect2i(BuildingBrush.FOOT,Vector2i.ONE)
	var cropped: Image=brush.image.get_region(used)
	var frame:={"key":key,"image":cropped,"texture":ImageTexture.create_from_image(cropped),"rect":Rect2(Vector2(used.position-BuildingBrush.FOOT),Vector2(used.size)),"source_commands":brush.commands,"clipped_commands":brush.clipped,"pixel_hash":cropped.get_data().hex_encode().sha256_text()}
	while _building_frame_order.size()>=MAX_BUILDING_FRAMES: _building_frames.erase(_building_frame_order.pop_front())
	_building_frames[key]=frame
	_building_frame_order.append(key)
	_building_bakes+=1
	return frame


static func building_body_contains(building: Dictionary, offset: Vector2, factor: float) -> bool:
	if not offset.is_finite() or not is_finite(factor) or factor<=0: return false
	if bool(CollectionProps.inspect_building(building,factor).get("supported",false)): return CollectionProps.building_body_contains(building,offset,factor)
	var frame:=_building_frame(building)
	var point:=Vector2i((offset/(factor*FALLBACK_BUILDING_SCALE)-Vector2(frame.rect.position)).floor())
	var image: Image=frame.image
	return Rect2i(Vector2i.ZERO,image.get_size()).has_point(point) and image.get_pixelv(point).a>0.1


static func building_cache_stats() -> Dictionary:
	var bytes:=0
	for frame: Dictionary in _building_frames.values(): bytes+=(frame.image as Image).get_width()*(frame.image as Image).get_height()*4
	return {"frames":_building_frames.size(),"capacity":MAX_BUILDING_FRAMES,"bakes":_building_bakes,"texture_bytes":bytes,"maximum_texture_bytes":MAX_BUILDING_FRAMES*BuildingBrush.SIZE.x*BuildingBrush.SIZE.y*4}


static func inspect_building(building: Dictionary) -> Dictionary:
	var licensed := CollectionProps.inspect_building(building)
	if bool(licensed.get("supported",false)):
		licensed["key"] = "licensed:" + str(licensed.file)
		return licensed
	var frame:=_building_frame(building)
	return {"key":frame.key,"rect":frame.rect,"pixel_hash":frame.pixel_hash,"source_commands":frame.source_commands,"clipped_commands":frame.clipped_commands}


static func _paint_building(canvas: Object, point: Vector2, building: Dictionary, factor: float) -> void:
	var type:=str(building.get("building_type","BASE"))
	var tint:=_faction_tint(str(building.get("faction_id","HUMAN")))
	if int(building.get("hp",0))<=0:
		Atlas.draw_sprite(canvas,"stones",point,factor*2)
		Atlas.draw_sprite(canvas,"deadwood",point+Vector2(4,0)*factor,factor*1.4)
		return
	if not bool(building.get("complete",false)): tint=Color(tint,0.42)
	Atlas.draw_sprite(canvas,building_sprite_key(building),point,building_visual_scale(building,factor),tint)
	var team:=Palette.side_color(str(building.get("side","")))
	if type=="BASE":
		_flag(canvas,point+Vector2(-29,-82)*factor,team,factor)
		_flag(canvas,point+Vector2(28,-82)*factor,team,factor)
		for i: int in range(maxi(0,int(building.get("base_tier",1))-1)): canvas.draw_rect(Rect2(point+Vector2(-8+i*9,-91)*factor,Vector2(6,5)*factor),Color("e2c87d"))
	elif type=="TOWER":
		canvas.draw_rect(Rect2(point+Vector2(-10,-44)*factor,Vector2(20,38)*factor),Color("665b58"))
		canvas.draw_rect(Rect2(point+Vector2(-8,-44)*factor,Vector2(16,37)*factor),Color("a7a18b"))
		for y: int in range(4): canvas.draw_line(point+Vector2(-8,-40+y*9)*factor,point+Vector2(8,-40+y*9)*factor,Color("716d67"),maxf(factor,1))
		canvas.draw_rect(Rect2(point+Vector2(-14,-56)*factor,Vector2(28,13)*factor),Color("4d4e51"))
		canvas.draw_rect(Rect2(point+Vector2(-12,-54)*factor,Vector2(24,9)*factor),team.darkened(0.2))
		for x: int in [-12,-2,8]: canvas.draw_rect(Rect2(point+Vector2(x,-61)*factor,Vector2(6,7)*factor),Color("c4bda4"))
		_flag(canvas,point+Vector2(0,-72)*factor,team,factor*0.8)
	else:
		_flag(canvas,point+Vector2(-15,-48)*factor,team,factor*0.85)
		if type=="RANGE":
			canvas.draw_rect(Rect2(point+Vector2(14,-16)*factor,Vector2(14,17)*factor),Color("6a5038"))
			canvas.draw_circle(point+Vector2(21,-10)*factor,5*factor,Color("dfc386"));canvas.draw_circle(point+Vector2(21,-10)*factor,2*factor,team)
		elif type=="FOUNDRY" or type=="WORKSHOP":
			canvas.draw_rect(Rect2(point+Vector2(11,-55)*factor,Vector2(8,27)*factor),Color("69635c"))
			canvas.draw_rect(Rect2(point+Vector2(10,-57)*factor,Vector2(10,4)*factor),Color("b2ac91"))
			canvas.draw_rect(Rect2(point+Vector2(10,-15)*factor,Vector2(12,8)*factor),Color("efb960"))
		elif type=="ALTAR":
			canvas.draw_line(point+Vector2(0,-61)*factor,point+Vector2(0,-43)*factor,Color("eed598"),maxf(2*factor,1))
			canvas.draw_line(point+Vector2(-6,-54)*factor,point+Vector2(6,-54)*factor,Color("eed598"),maxf(2*factor,1))
		elif type=="DRAGON_ROOST":
			Atlas.draw_sprite(canvas,"mountain",point+Vector2(18,0)*factor,factor*2)
			canvas.draw_rect(Rect2(point+Vector2(8,-28)*factor,Vector2(12,16)*factor),Color("cba67c"))
			canvas.draw_rect(Rect2(point+Vector2(10,-27)*factor,Vector2(8,8)*factor),Color("e4cba1"))
	if not bool(building.get("complete",false)):
		for x: int in [-25,25]: canvas.draw_line(point+Vector2(x,4)*factor,point+Vector2(x,-57)*factor,Color("d9ba7e"),maxf(factor*2,1))
		for y: int in [-14,-34,-54]: canvas.draw_line(point+Vector2(-27,y)*factor,point+Vector2(27,y)*factor,Color("b99760"),maxf(factor*2,1))


func _draw_building_state(point: Vector2, building: Dictionary, factor: float) -> void:
	if int(building.get("hp",0))<=0: return
	var complete:=bool(building.get("complete",false))
	if not complete: _bar(point+Vector2(-26,8)*factor,52*factor,float(building.get("progress",0))/maxf(float(building.get("max_progress",100)),1),Color("d3c58c"))
	elif int(building.get("hp",0))<int(building.get("max_hp",1)): _bar(point+Vector2(-26,8)*factor,52*factor,float(building.get("hp",0))/maxf(float(building.get("max_hp",1)),1),Palette.side_color(str(building.get("side",""))))
	if not building.get("queue",[]).is_empty():
		var queue: Dictionary=building.queue[0]
		_bar(point+Vector2(-26,15)*factor,52*factor,float(queue.get("progress",0))/maxf(float(queue.get("max_progress",100)),1),Color("dfb867"))
	if not building.get("base_upgrade",{}).is_empty():
		var upgrade: Dictionary=building.base_upgrade
		_bar(point+Vector2(-26,22)*factor,52*factor,float(upgrade.get("progress",0))/maxf(float(upgrade.get("max_progress",100)),1),Color("8ebdd0"))
	if not building.get("tower_upgrade",{}).is_empty():
		var upgrade: Dictionary=building.tower_upgrade
		_bar(point+Vector2(-26,22)*factor,52*factor,float(upgrade.get("progress",0))/maxf(float(upgrade.get("duration_ticks",1)),1),Color("c4a6dd"))


func _draw_unit(point: Vector2, unit: Dictionary, factor: float) -> void:
	var tick:=int(snapshot.get("tick",0))
	var pose:=_pose_for_draw_m81(unit,tick)
	var body_pose:=BodyMotionM76.for_body(unit,pose,tick,interpolation_fraction_m76)
	var cast_offset := RosterV5.body_offset(unit,tick)
	if str(unit.get("hero_archetype","")) in ReworkR7Effects.Catalog.ENABLED_HEROES:
		var casting := R7Spectacle.cast_body(unit,body_pose,_r7_spectacle_draw_scope)
		body_pose=casting.pose
		cast_offset=Vector2(casting.offset)
	var radius:=maxf(float(unit.get("visual_radius",unit.get("radius",12)))*factor,3)
	var alive:=int(unit.get("hp",0))>0 and bool(unit.get("alive",true))
	if alive:
		draw_set_transform(point)
		draw_set_transform_matrix(Transform2D(0,Vector2(radius, radius*0.3),0,point+Vector2(0,2)))
		draw_circle(Vector2.ZERO,1,Color(0.08,0.15,0.1,0.3))
		draw_set_transform(Vector2.ZERO)
		if ActorReadout.is_hero(unit):
			ActorReadout.draw_hero_ellipse(self,point,unit,Units.ground_footprint(_unit_observation(unit),radius),factor)
	var selected: bool = str(unit.get("id","")) in [selected_unit,selected_worker_id] or (not selected_army.is_empty() and str(unit.get("warband_id",""))==selected_army and (selected_unit_type_r12.is_empty() or unit.get("unit_type")==selected_unit_type_r12))
	if selected and alive: draw_arc(point,radius+5,0,TAU,32,Color("fff2a6"),2)
	var visual:=_unit_observation(unit)
	var empower:Array=[]
	if str(unit.get("unit_type",""))=="hero":
		var active:=Empowerment.read(unit,_empower_context)
		if not active.is_empty():empower=Empowerment.plan(point,unit,active,tick,factor,Units.stable_visual_bounds(visual,radius))
	Empowerment.draw(self,empower,"REAR")
	_feedback_heads_r9[str(unit.get("id",""))]=Vector2(0,Units.stable_visual_bounds(visual,radius).position.y-10)
	Units.draw(self,point+cast_offset*factor+_combat_feedback_r9.body_offset(unit,tick)*factor,visual,radius,body_pose)
	Empowerment.draw(self,empower,"FRONT")
	AuraArt.draw_beneficiaries(self,point,unit,factor,tick)
	var bounds:=Rect2()
	var has_bounds:=false
	var injury:=_hit_feedback.read(str(unit.get("id","")),tick)
	if shows_transient_effects() and not injury.is_empty():
		bounds=Units.visual_bounds(visual,radius,body_pose);has_bounds=true
		CombatEffects.draw_hit(self,point+Vector2(0,bounds.position.y*0.45),unit,injury,factor)
	if shows_transient_effects():
		for status: Dictionary in unit.get("status_effects",[]).slice(0,3):
			if str(status.get("id",""))=="INNATE_AURA": continue
			if ReworkR7Effects.Catalog.has_skill(str(status.get("skill_id",""))): continue
			if _visible_combat_statuses >= 128: break
			if not has_bounds:
				bounds=Units.visual_bounds(visual,radius,body_pose);has_bounds=true
			if CombatEffects.draw_status(self,point,point+Vector2(0,bounds.position.y-5),unit,status,tick,factor): _visible_combat_statuses += 1

func _draw_r7_status_overlays(factor: float) -> void:
	if not shows_transient_effects(): return
	var tick := int(snapshot.get("tick",0))
	for unit: Dictionary in snapshot.get("soldiers",[]):
		for status: Dictionary in unit.get("status_effects",[]).slice(0,3):
			if not ReworkR7Effects.Catalog.has_skill(str(status.get("skill_id",""))): continue
			if _visible_combat_statuses >= 128: return
			if not ActorReadout.living(unit) or not ActorReadout.visible_to(unit,view_side_id): break
			var point := _screen(render_actor_position_m76(unit))
			if not _visible(point,140): break
			if ReworkR7Effects.draw_status(self,point,point,unit,status,tick,factor): _visible_combat_statuses += 1

func _draw_actor_overlays(factor: float) -> void:
	_last_actor_bars.clear()
	var still_present: Dictionary = {}
	for collection: String in ["workers","soldiers"]:
		for unit: Dictionary in snapshot.get(collection,[]):
			if not ActorReadout.living(unit) or not ActorReadout.visible_to(unit,view_side_id): continue
			var id := str(unit.get("id",""))
			still_present[id]=true
			var point := _screen(render_actor_position_m76(unit))
			if not _visible(point,140): continue
			var radius := maxf(float(unit.get("visual_radius",unit.get("radius",12)))*factor,3)
			var stable := Units.stable_visual_bounds(_unit_observation(unit),radius)
			var overview := bool(_overview_units.get(id,false))
			if stable.size.y < 24: overview=true
			elif stable.size.y > 28: overview=false
			_overview_units[id]=overview
			var selected: bool = id in [selected_unit,selected_worker_id] or (not selected_army.is_empty() and str(unit.get("warband_id",""))==selected_army and (selected_unit_type_r12.is_empty() or unit.get("unit_type")==selected_unit_type_r12))
			var info := ActorReadout.draw_bars(self,point,unit,stable,overview and not selected)
			if not info.is_empty():
				info["id"]=id
				info["point"]=point
				_last_actor_bars.append(info)
	for id: String in _overview_units.keys():
		if not still_present.has(id): _overview_units.erase(id)
	set_meta("actor_bars",_last_actor_bars.duplicate(true))


func _draw_aura_sources(factor: float) -> void:
	var readouts := ActorReadout.aura_sources(snapshot,view_side_id)
	var viewport := Rect2(Vector2.ZERO,(get_parent() as Control).size)
	for source: Dictionary in readouts:
		var point := _screen(Vector2(source.position))
		var radius := maxf(float(source.radius)*factor,60*factor)
		if not viewport.intersects(Rect2(point-Vector2.ONE*radius,Vector2.ONE*radius*2)): continue
		ActorReadout.draw_aura_source(self,point,source,factor,str(source.source_id)==selected_unit,int(snapshot.get("tick",0)))
	set_meta("aura_sources",readouts.duplicate(true))


func actor_bar_readouts() -> Array[Dictionary]:
	return _last_actor_bars.duplicate(true)


func _draw_action_effects(factor: float) -> void:
	_visible_combat_actions = 0
	if not shows_transient_effects(): return
	var tick:=int(snapshot.get("tick",0))
	var actors: Array = snapshot.get("soldiers",[]).duplicate()
	actors.append_array(snapshot.get("workers",[]))
	for soldier: Dictionary in actors:
		if not ActorReadout.visible_to(soldier,view_side_id): continue
		var pose:=_pose_for_draw_m81(soldier,tick)
		var action:=str(pose.action)
		if action.begins_with("SKILL_") and pose.get("skill",{}).has("r7_handler"): continue
		if action not in ["ATTACK","HEAL","POTION"] and not action.begins_with("SKILL_"): continue
		var point:=_screen(Vector2(soldier.get("position",Vector2.ZERO)))
		var target:=_screen(Vector2(pose.target_position))
		var art := CombatEffects.inspect_action(soldier,pose)
		var extent: Vector2 = art.get("visual_extent",Vector2(100,100))
		var margin := maxf(100,maxf(extent.x,extent.y)*factor)
		if not _visible(point,margin) and not _visible(target,margin): continue
		if _visible_combat_actions >= CombatEffects.MAX_ACTIONS: break
		var impacts: Array = []
		if action.begins_with("SKILL_"):
			for value: Variant in soldier.get("last_skill_targets",[]).slice(0,CombatEffects.MAX_IMPACTS):
				if value is Dictionary and (value.get("position") is Vector2i or value.get("position") is Vector2):
					impacts.append(_screen(Vector2(value.position)))
		if CombatEffects.draw_action(self,point,target,soldier,pose,factor,impacts): _visible_combat_actions += 1


func combat_effect_stats() -> Dictionary:
	var result := CombatEffects.debug_stats()
	result["visible_actions"] = _visible_combat_actions
	result["visible_statuses"] = _visible_combat_statuses
	result["max_visible_statuses"] = 128
	return result


func read_control_intent_r12() -> Dictionary:
	var facts := snapshot
	var army_id := selected_army
	var id := selected_army+"::type::"+selected_unit_type_r12
	var cohort: Dictionary = snapshot.get("type_cohorts_r12",{}).get(id,{})
	if not selected_unit_type_r12.is_empty() and not cohort.is_empty():
		# Read-only display projection, not an extra permanent roster entry.
		facts=snapshot.duplicate(false)
		facts["warbands"]=snapshot.get("warbands",[]).duplicate(false)
		facts.warbands.append(cohort)
		army_id=id
	return read_selected_intent(facts,selected_unit,army_id,view_side_id)

func _draw_orders(factor: float) -> void:
	var intent:=read_control_intent_r12()
	if not intent.is_empty():
		var origin:=_screen(intent.origin);var target:=_screen(intent.target)
		var color:=Color("edbb74") if intent.kind=="ATTACK_MOVE" else Color("e9987a") if intent.kind=="ATTACK" else Color("b6ead1")
		var count:=clampi(int(origin.distance_to(target)/16),1,100)
		for i: int in range(count): draw_line(origin.lerp(target,float(i)/count),origin.lerp(target,(i+0.42)/count),Color(color,0.6),1.5)
		_destination(target,color,10)
	for value: Variant in feedback_marks.slice(0,16):
		if not value is Dictionary: continue
		var mark: Dictionary=value
		var location: Variant=mark.get("position")
		if mark.get("kind")=="SELECT":
			var selected:=_find(snapshot,str(mark.get("subject_id","")),["workers","soldiers","warbands"])
			if selected.is_empty() or not _living(selected): continue
			location=selected.get("position",selected.get("anchor"))
		if not _point(location): continue
		var point:=_screen(Vector2(location))
		var alpha:=clampf(1-float(mark.get("age",0))/maxf(float(mark.get("lifetime",1)),0.01),0,1)
		var color:=Color(0.95,0.69,0.46,alpha) if mark.get("kind")=="REJECT" else Color(0.9,0.96,0.66,alpha)
		_destination(point,color,10+float(mark.get("age",0))*12)
		if not str(mark.get("caption","")).is_empty(): draw_string(ReadableFont.readable(),point+Vector2(13,26),str(mark.caption),HORIZONTAL_ALIGNMENT_LEFT,170,13,color)
	var preview:=read_aim(snapshot,aim)
	if not preview.is_empty():
		var origin:=_screen(preview.origin);var target:=_screen(preview.target)
		var color:=Color("b8e6d1") if preview.within_range else Color("e6a47d")
		if float(preview.range)>0: draw_arc(origin,float(preview.range)*factor,0,TAU,64,Color(color,0.3),1)
		if float(preview.radius)>0: draw_arc(target,float(preview.radius)*factor,0,TAU,48,color,2)
		draw_line(origin,target,Color(color,0.5),1)
		_destination(target,color,10)


func _destination(point: Vector2, color: Color, radius: float) -> void:
	for i: int in range(4):
		var direction:=Vector2.from_angle(i*TAU/4)
		draw_line(point+direction*(radius+5),point+direction*radius,color,2)
	draw_arc(point,radius,0,TAU,24,color,1.5)


func get_capture_readouts() -> Array[Dictionary]:
	var result: Array[Dictionary]=[]
	if camera==null or snapshot.is_empty() or not get_parent() is Control: return result
	var factor:=float(camera.get_scale())
	var subject:=selected_unit if not selected_unit.is_empty() else selected_army
	var visible_sites:Array[Dictionary]=[]
	var first_by_id:Dictionary={}
	for site:Dictionary in snapshot.get("sites",[]):
		var id:=str(site.get("id",""))
		if not first_by_id.has(id):first_by_id[id]=site
	for site:Dictionary in snapshot.get("sites",[]):
		# read_all/read_site historically resolve duplicate IDs to the first
		# record. Keep that behavior and order, including invalid-point rejection.
		var first:Dictionary=first_by_id[str(site.get("id",""))]
		if not Capture._point(first.get("position")):continue
		if not _visible(_screen(Vector2(first.position)),130*factor):continue
		var candidate:=Capture.read_site(snapshot,str(site.get("id","")),subject,"UNIT" if not selected_unit.is_empty() else "ARMY",view_side_id)
		if not candidate.is_empty():visible_sites.append(candidate)
	for readout: Dictionary in visible_sites:
		var point:=_screen(Vector2(readout.position))
		if not _visible(point,130*factor): continue
		readout["screen_center"]=point
		readout["status_radius"]=clampf(32*factor,20,40)
		readout["range_radius"]=float(readout.radius)*factor
		readout["selected"]=str(readout.id)==selected_site_id
		readout["show_range"]=bool(readout.running) or bool(readout.selected) or readout.state=="CONTESTED"
		readout["expanded"]=bool(readout.show_range) or (readout.state=="PREPARATION" and Capture._total(readout.observed_presence)>0)
		readout["compact"]=not bool(readout.expanded) and not bool(readout.selected)
		readout["motion"]={"active":bool(readout.running),"pulse":float(int(snapshot.get("tick",0))%20)/20.0 if readout.running else 0.0,"direction":int(readout.stage_direction),"flag_raise_ratio":float(readout.ratio)}
		var card_size:=Vector2(182,60) if readout.expanded else Vector2(50,15)
		var top:=point.y-44*factor-card_size.y-8
		for building: Dictionary in snapshot.get("buildings",[]):
			if int(building.get("hp",0))>0 and Vector2(building.get("position",Vector2.ZERO)).distance_squared_to(Vector2(readout.position))<64*64:
				top=minf(top,_screen(Vector2(building.position)).y+building_visual_bounds(building,factor).position.y-card_size.y-10)
		var view_size: Vector2=(get_parent() as Control).size
		var card_position:=Vector2(clampf(point.x-card_size.x*0.5,2,maxf(2,view_size.x-card_size.x-2)),clampf(top,2,maxf(2,view_size.y-card_size.y-2)))
		readout["card_rect"]=Rect2(card_position,card_size)
		result.append(readout)
	return result


func _draw_capture(readout: Dictionary) -> void:
	var point: Vector2=readout.screen_center
	var owner:=Palette.side_color(str(readout.owner))
	var active:=Palette.side_color(str(readout.capture_side))
	var card: Rect2=readout.card_rect
	draw_rect(card,Color("233329",0.92))
	draw_rect(card,Color(owner,0.7),false,1)
	if readout.show_range:
		draw_arc(point,float(readout.range_radius),0,TAU,72,Color(owner,0.35),1)
		draw_arc(point,float(readout.status_radius),-PI/2,-PI/2+TAU*float(readout.ratio),48,active,3)
	if readout.running:
		var pulse:=float(readout.motion.pulse)
		draw_arc(point,float(readout.status_radius)+4+pulse*8,0,TAU,40,Color(Palette.side_color(str(readout.leader)),(1-pulse)*0.65),2)
		var position:=point+Vector2(float(readout.status_radius)+12,-5-float(readout.ratio)*18)
		_flag(self,position,Palette.side_color(str(readout.leader)),0.8)
	if readout.compact:
		draw_rect(Rect2(card.position+Vector2(4,5),Vector2(7,6)),owner)
		_bar(card.position+Vector2(15,5),30,float(readout.ratio),active)
	else:
		draw_string(ReadableFont.readable(),card.position+Vector2(6,14),str(readout.status_caption),HORIZONTAL_ALIGNMENT_LEFT,170,12,Color("e8e1bf"))
		draw_string(ReadableFont.readable(),card.position+Vector2(6,30),str(readout.progress_caption),HORIZONTAL_ALIGNMENT_LEFT,170,13,active)
		_bar(card.position+Vector2(6,35),170,float(readout.ratio),active)
		draw_string(ReadableFont.readable(),card.position+Vector2(6,54),str(readout.presence_caption),HORIZONTAL_ALIGNMENT_LEFT,170,12,Color("c8d2b7"))
	if readout.selected: draw_string(ReadableFont.readable(),point+Vector2(-30,float(readout.range_radius)+15),"+%d人口" % int(readout.capacity),HORIZONTAL_ALIGNMENT_LEFT,100,13,owner)


func get_tower_readouts() -> Array[Dictionary]:
	var result: Array[Dictionary]=[]
	if camera==null: return result
	var factor:=float(camera.get_scale());var tick:=int(snapshot.get("tick",0))
	for building: Dictionary in snapshot.get("buildings",[]):
		if int(building.get("attack_range",0))<=0 or int(building.get("hp",0))<=0 or not building.get("complete",false): continue
		var point:=_screen(Vector2(building.position))
		var age:=tick-int(building.get("last_action_tick",-1000000))
		var targets: Array=[]
		for hit: Variant in building.get("last_action_targets",[]):
			if hit is Dictionary and hit.get("position") is Vector2i:targets.append({"id":str(hit.get("id","")),"position":_screen(Vector2(hit.position)),"primary":bool(hit.get("primary",false))})
		if targets.is_empty() and not str(building.get("last_action_target_id","")).is_empty():targets.append({"id":str(building.last_action_target_id),"position":_screen(Vector2(building.get("last_action_target_position",building.position))),"primary":true})
		result.append({"id":str(building.id),"center":point,"target":_screen(Vector2(building.get("last_action_target_position",building.position))),"attack_range":int(building.get("attack_range",0)),"screen_range":float(building.get("attack_range",0))*factor,"selected":str(building.id)==selected_building_id,"defense_active":bool(building.get("defense_active",true)),"firing":shows_transient_effects() and snapshot.get("phase")=="BATTLE" and building.get("defense_active",true) and building.get("last_action_kind")=="ATTACK" and age>=0 and age<8,"age":age,"target_id":str(building.get("last_action_target_id","")),"targets":targets,"attack_type":str(building.get("attack_type","PIERCE")),"faction_id":str(building.get("faction_id","HUMAN")),"tower_identity":str(building.get("tower_identity","")),"source_tick":int(building.get("last_action_tick",-1))})
	return result


func get_blueprint_observation() -> Dictionary:
	if blueprint_type.is_empty(): return {}
	var radius:=int(snapshot.get("catalog",{}).get("buildings",{}).get(blueprint_type,{}).get("radius",40 if blueprint_type=="BASE" else 24 if blueprint_type=="TOWER" else 32))
	return {"building_type":blueprint_type,"radius":radius,"side":"PLAYER","faction_id":_side_faction("PLAYER"),"hp":1,"complete":false,"state":"BLUEPRINT","progress":0,"max_progress":100,"base_tier":1}


func shows_transient_effects() -> bool:
	return snapshot.get("outcome","ONGOING")=="ONGOING"


func visual_body_bounds(id: String, kind: String) -> Rect2:
	if camera==null: return Rect2()
	var value:=_find(snapshot,id,["buildings"] if kind=="building" else ["workers","soldiers"])
	if value.is_empty(): return Rect2()
	var point: Vector2=camera.world_to_screen(Vector2(value.get("position",Vector2.ZERO)))
	var local:=building_visual_bounds(value,float(camera.get_scale())) if kind=="building" else Units.visual_bounds(_unit_observation(value),maxf(float(value.get("visual_radius",value.get("radius",12)))*float(camera.get_scale()),3),Pose.for_unit(value,int(snapshot.get("tick",0))))
	return Rect2(point+local.position,local.size)


func visual_body_contains(id: String, kind: String, screen_point: Vector2) -> bool:
	if camera==null or not screen_point.is_finite(): return false
	var value:=_find(snapshot,id,["buildings"] if kind=="building" else ["workers","soldiers"])
	if value.is_empty() or int(value.get("hp",0))<=0 or not bool(value.get("alive",true)): return false
	var offset: Vector2=screen_point-camera.world_to_screen(Vector2(value.get("position",Vector2.ZERO)))
	var factor:=float(camera.get_scale())
	if kind=="building":
		if not bool(value.get("complete",false)): return false
		return building_body_contains(value,offset,factor)
	return Units.body_contains(_unit_observation(value),maxf(float(value.get("visual_radius",value.get("radius",12)))*factor,3),Pose.for_unit(value,int(snapshot.get("tick",0))),offset)


func get_diagnostics() -> Dictionary:
	var actions: Dictionary={}
	for collection: String in ["workers","soldiers"]:
		for unit: Dictionary in snapshot.get(collection,[]):
			var pose:=Pose.for_unit(unit,int(snapshot.get("tick",0)))
			var frame:=Units.inspect(_unit_observation(unit),pose)
			actions[str(unit.get("id",""))]={"action":str(pose.action),"phase":float(pose.phase),"frame_key":str(frame.key)}
	var source_stats := Atlas.debug_stats()
	var decoration_stats := PixelDecorations.debug_stats()
	var failures: Array = source_stats.get("failures",[]).duplicate()
	failures.append_array(decoration_stats.get("failures",[]))
	failures.append_array(_collection_ground_report.get("failures",[]))
	return {"mode":"heroic2d-m34","ready":_ready_assets and bool(decoration_stats.get("ready",false)),"atlas":source_stats,"collection":Collection.debug_stats(),"collection_ground":_collection_ground_report.duplicate(true),"collection_terrain":CollectionTerrain.debug_stats(),"collection_buildings":CollectionProps.debug_stats(),"collection_effects":CollectionEffects.debug_stats(),"actors":actions.size(),"observed_actions":actions,"terrain_rebuilds":_terrain_rebuilds,"terrain_tiles":_terrain_tiles,"decorations":_decorations.size(),"decoration_version":DecorationPlan.VERSION,"decoration_plan":_decoration_plan.get("summary",{}).duplicate(true),"decoration_failures":_decoration_plan.get("failures",[]).duplicate(true),"decoration_cache":decoration_stats,"visible_decorations":_visible_decorations,"faded_decorations":_faded_decorations,"hidden_decorations":_hidden_decorations,"capture_readouts":get_capture_readouts().size(),"physics_nodes":0,"three_d_nodes":0,"unit_cache":Units.debug_stats(),"ground_pixel_bytes":int(_ground_texture.get_width()*_ground_texture.get_height()*4) if _ground_texture!=null else 0,"failures":failures}


func _unit_observation(unit: Dictionary) -> Dictionary:
	if unit.has("faction_id"): return unit
	var detached:=unit.duplicate(false)
	detached["faction_id"]=_side_faction(str(unit.get("side","PLAYER")))
	return detached


func _side_faction(side_id: String) -> String:
	for side: Dictionary in snapshot.get("match_config",{}).get("sides",[]):
		if side.get("side_id")==side_id: return str(side.get("faction_id","HUMAN"))
	return "HUMAN"


func _faction_at(point: Vector2) -> String:
	if landscape_plan.get("road_mode")=="TILED":
		return HomeTerrain.faction_at(point,landscape_plan.get("home_zones",[]),int(landscape_plan.get("seed",0)))
	for zone: Dictionary in landscape_plan.get("home_zones",[]):
		if point.distance_squared_to(Vector2(zone.position))<pow(float(zone.get("radius",500)),2): return str(zone.get("faction_id","HUMAN"))
	return "HUMAN"


static func _faction_tint(id: String) -> Color:
	return FACTION_TINTS.get(id,Color.WHITE)


static func _flag(canvas: Object, point: Vector2, color: Color, factor: float) -> void:
	canvas.draw_line(point+Vector2(0,17)*factor,point-Vector2(0,6)*factor,Color("4b4032"),maxf(2*factor,1))
	canvas.draw_rect(Rect2((point+Vector2(2,-5)*factor).round(),Vector2(12,8)*factor),color.darkened(0.25))
	canvas.draw_rect(Rect2((point+Vector2(2,-5)*factor).round(),Vector2(10,5)*factor),color)


func _bar(point: Vector2, width: float, ratio: float, color: Color) -> void:
	draw_rect(Rect2(point.round(),Vector2(width,4)),Color("29352a"))
	draw_rect(Rect2(point.round(),Vector2(width*clampf(ratio,0,1),3)),color)


static func unit_health_bar_rect(body_bounds: Rect2, screen_radius: float) -> Rect2:
	if not body_bounds.position.is_finite() or not body_bounds.size.is_finite() or not is_finite(screen_radius) or screen_radius <= 0: return Rect2()
	var width := roundf(maxf(32,screen_radius*2.4))
	return Rect2(Vector2(-width*0.5,body_bounds.position.y-10).round(),Vector2(width,6))


static func draw_unit_health_bar(canvas: Object, point: Vector2, body_bounds: Rect2, screen_radius: float, ratio: float, color: Color) -> void:
	if not point.is_finite() or not is_finite(ratio): return
	var bar := unit_health_bar_rect(body_bounds,screen_radius)
	if bar.size == Vector2.ZERO: return
	bar.position = (point+bar.position).round()
	# Unit-only screen-space readability; producer/capture meters keep _bar.
	canvas.draw_rect(bar,Color("101b1b"))
	var inner := bar.grow(-1)
	canvas.draw_rect(inner,Color("29352a"))
	var filled := floorf(inner.size.x*clampf(ratio,0,1))
	if filled > 0: canvas.draw_rect(Rect2(inner.position,Vector2(filled,inner.size.y)),color)


static func _key(value: String) -> int:
	return value.sha256_text().substr(0,12).hex_to_int()


static func read_selected_intent(facts: Dictionary, unit_id: String="", army_id: String="", view_side: String="PLAYER") -> Dictionary:
	var source:=_find(facts,unit_id,["soldiers"]) if not unit_id.is_empty() else _find(facts,army_id,["warbands"])
	if source.is_empty() or source.get("side")!=view_side or not _living(source): return {}
	var origin: Variant=source.get("position",source.get("anchor"))
	if not _point(origin): return {}
	var army:=source if unit_id.is_empty() else _find(facts,str(source.get("warband_id","")),["warbands"])
	var direct:=str(source.get("direct_intent","")) if not unit_id.is_empty() else ""
	if direct=="HOLD": return {}
	var kind:=direct if not direct.is_empty() else str(army.get("intent","HOLD"))
	var target: Variant=null
	if direct=="MOVE": target=source.get("direct_destination")
	elif direct=="ATTACK":
		var victim:=_find(facts,str(source.get("target_id","")),["soldiers","workers","buildings"])
		if victim.is_empty() or not _living(victim): return {}
		target=victim.get("position")
	elif kind in ["MOVE","ATTACK_MOVE","RETREAT"]: target=army.get("destination")
	elif kind in ["FOCUS","ATTACK_BASE"]:
		var victim:=_find(facts,str(army.get("target_warband_id","")) if kind=="FOCUS" else str(army.get("target_base_id","")),["warbands"] if kind=="FOCUS" else ["buildings"])
		if victim.is_empty() or not _living(victim): return {}
		target=victim.get("anchor",victim.get("position"))
	else: return {}
	if not _point(target) or Vector2(origin).distance_squared_to(Vector2(target))<=49: return {}
	return {"origin":Vector2(origin),"target":Vector2(target),"kind":"ATTACK" if kind in ["ATTACK","FOCUS","ATTACK_BASE"] else "ATTACK_MOVE" if kind=="ATTACK_MOVE" else "MOVE","intent":kind,"subject_id":source.get("id","")}


static func read_aim(facts: Dictionary, request: Dictionary) -> Dictionary:
	if request.is_empty(): return {}
	var unit:=_find(facts,str(request.get("unit_id","")),["soldiers"])
	if unit.is_empty() or not _living(unit) or unit.get("side")!="PLAYER": return {}
	var skill: Dictionary={}
	for hero: Dictionary in facts.get("heroes",{}).get("officers",[]):
		if str(hero.get("unit_id",hero.get("id","")))!=str(unit.get("id","")): continue
		for entry: Dictionary in hero.get("skills",[]):
			if str(entry.get("id",""))==str(request.get("skill_id","")): skill=entry
	if skill.is_empty(): return {}
	var origin: Variant=unit.get("position")
	var target: Variant=origin if skill.get("target_mode","POINT")=="SELF" else request.get("target_position",origin)
	if not _point(origin) or not _point(target): return {}
	var distance:=maxf(float(skill.get("range",0)),0)
	return {"origin":Vector2(origin),"target":Vector2(target),"range":distance,"radius":maxf(float(skill.get("radius",0)),0),"name":str(skill.get("name","技能范围")),"effect":str(skill.get("effect","")),"within_range":Vector2(origin).distance_squared_to(Vector2(target))<=distance*distance}


static func _find(facts: Dictionary, id: String, lists: Array) -> Dictionary:
	if id.is_empty(): return {}
	for list: String in lists:
		for entity: Dictionary in facts.get(list,[]):
			if str(entity.get("id",""))==id: return entity
	return {}


static func _living(entity: Dictionary) -> bool:
	return int(entity.get("living_count",0))>0 if entity.has("living_count") else int(entity.get("hp",0))>0 and bool(entity.get("alive",true))


static func _point(value: Variant) -> bool:
	return (value is Vector2 or value is Vector2i) and Vector2(value).is_finite()
